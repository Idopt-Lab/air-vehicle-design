classdef TtpaAero < AerodynamicsBase
%TTPAAERO  Test Twin Propeller Aircraft Level-1 aerodynamic model.
%
%   Geometry/design inputs are read from the requirements JSON.
%   Derived aerodynamic quantities are calculated here.
%   The mission analysis of IHW1 only ever needed the CLEAN airplane, so
%   this class held one drag polar and no CLmax. The constraint analysis
%   needs the airplane in three different configurations - takeoff flaps,
%   landing flaps, gear up or gear down - so this version adds:
%
%       * the aerodynamics block of Ttpa_requirements_IHW2.json, read in
%         the constructor;
%       * get_CLmax(state, con), the CLmax of the configuration the
%         condition is flown in;
%       * get_config_polar(state, con), the whole polar of that
%         configuration.
%
%   The clean polar (drag_polar, e, K, LD_max) is unchanged, so the
%   mission analysis keeps working exactly as it did in IHW1.

    properties
        AR              % Wing aspect ratio, read from requirements JSON
        CD0             % Parasitic drag coefficient, clean configuration

        CLmax_clean     % Maximum lift coefficient, clean
        CLmax_takeoff   % Maximum lift coefficient, takeoff flaps
        CLmax_landing   % Maximum lift coefficient, landing flaps

        CL_stall_margin % CL margin below CLmax used in a climb

        dCD0_flaps_takeoff      % CD0 increment, takeoff flaps
        dCD0_flaps_landing      % CD0 increment, landing flaps
        dCD0_gear_down          % CD0 increment, landing gear extended
        dCD0_propeller_stopped  % CD0 increment, stopped propeller

        de_flaps_takeoff        % e increment, takeoff flaps
        de_flaps_landing        % e increment, landing flaps
    end

    properties (Dependent)
        e               % Oswald efficiency factor
        K               % Induced drag factor
        LD_max          % Maximum lift-to-drag ratio
    end

    methods

        %% Constructor
        function obj = TtpaAero(json_path)
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            % Read requirements JSON
            J = jsondecode(fileread(json_path));

            % Read geometry-owned requirement
            obj.AR = J.geometry.AR;

            % Read aerodynamics-owned data
            A = J.aerodynamics;

            obj.CD0             = A.CD0_clean;
            obj.CLmax_clean     = A.CLmax_clean;
            obj.CLmax_takeoff   = A.CLmax_takeoff;
            obj.CLmax_landing   = A.CLmax_landing;
            obj.CL_stall_margin = A.CL_stall_margin;

            obj.dCD0_flaps_takeoff     = A.delta_CD0_flaps_takeoff;
            obj.dCD0_flaps_landing     = A.delta_CD0_flaps_landing;
            obj.dCD0_gear_down         = A.delta_CD0_gear_down;
            obj.dCD0_propeller_stopped = A.delta_CD0_propeller_stopped;

            obj.de_flaps_takeoff = A.delta_e_flaps_takeoff;
            obj.de_flaps_landing = A.delta_e_flaps_landing;
        end


        %% Oswald Efficiency
        function e = get.e(obj)
            e = 1.78 * (1 - 0.045 * obj.AR^0.68) - 0.64;
        end


        %% Induced Drag Factor
        function K = get.K(obj)

            if isnan(obj.e) || obj.e <= 0 || obj.e > 1
                error('TtpaAero:InvalidOswaldEfficiency', ...
                    'Computed Oswald efficiency e = %.4f is invalid.', obj.e);
            end

            K = 1 / (pi * obj.AR * obj.e);
        end


        %% Drag Polar
        function polar = drag_polar(obj, ~)

            polar.CD0 = obj.CD0;
            polar.K1  = obj.K;
            polar.K2  = 0;

        end


        %% Maximum Lift Coefficient
        function CLmax = get_CLmax(obj, ~, con)
        %GET_CLMAX  Maximum lift coefficient of a configuration.
        %
        %   CLmax = get_CLmax(obj, state, con) returns the CLmax of the
        %   configuration named by con.config. The flight state is not
        %   used at this level of fidelity, exactly as in prop_eff.

            switch string(con.config)

                case "clean"
                    CLmax = obj.CLmax_clean;

                case {"takeoff_flaps_gear_up", "takeoff_flaps_gear_down"}
                    CLmax = obj.CLmax_takeoff;

                case {"landing_flaps_gear_up", "landing_flaps_gear_down"}
                    CLmax = obj.CLmax_landing;

                otherwise
                    error('TtpaAero:UndefinedConfiguration', ...
                        'CLmax is not defined for configuration "%s".', ...
                        string(con.config));

            end

        end


        %% Configuration Polar
        function cfg = get_config_polar(obj, state, con)
        %GET_CONFIG_POLAR  Drag polar and CLmax of a configuration.
        %
        %   cfg = get_config_polar(obj, state, con) returns
        %       cfg.CD0       clean CD0 plus the flap, the gear and, when
        %                     the condition asks for it, the stopped
        %                     propeller increment
        %       cfg.e         clean Oswald efficiency plus the flap increment
        %       cfg.K1        1/(pi*AR*e) of the configuration
        %       cfg.K2        0 at this level of fidelity
        %       cfg.CLmax     CLmax of the configuration
        %       cfg.CL_climb  CLmax minus the stall margin, the lift
        %                     coefficient a climb is flown at
        %
        %   Increments: Roskam Part I, Table 3.6 and Sec. 3.3.

            dCD0 = 0;
            de   = 0;

            switch string(con.config)

                case "clean"
                    % no high-lift increment

                case "takeoff_flaps_gear_up"
                    dCD0 = obj.dCD0_flaps_takeoff;
                    de   = obj.de_flaps_takeoff;

                case "takeoff_flaps_gear_down"
                    dCD0 = obj.dCD0_flaps_takeoff + obj.dCD0_gear_down;
                    de   = obj.de_flaps_takeoff;

                case "landing_flaps_gear_up"
                    dCD0 = obj.dCD0_flaps_landing;
                    de   = obj.de_flaps_landing;

                case "landing_flaps_gear_down"
                    dCD0 = obj.dCD0_flaps_landing + obj.dCD0_gear_down;
                    de   = obj.de_flaps_landing;

                otherwise
                    error('TtpaAero:UndefinedConfiguration', ...
                        'Drag polar is not defined for configuration "%s".', ...
                        string(con.config));

            end

            % Failed engine: the stopped propeller of the dead engine drags
            if con.propeller_stopped
                dCD0 = dCD0 + obj.dCD0_propeller_stopped;
            end

            cfg.config = string(con.config);
            cfg.CD0    = obj.CD0 + dCD0;
            cfg.e      = obj.e + de;
            cfg.K1     = 1 / (pi * obj.AR * cfg.e);
            cfg.K2     = 0;
            cfg.CLmax  = obj.get_CLmax(state, con);

            cfg.CL_climb = cfg.CLmax - obj.CL_stall_margin;

        end


        %% Maximum L/D
        function LD_max = get.LD_max(obj)

            LD_max = 1 / (2 * sqrt(obj.CD0 * obj.K));

        end

    end

end
