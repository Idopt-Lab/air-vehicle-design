classdef TtpaAero < AerodynamicsBase
%TTPAAERO  Test Twin Propeller Aircraft Level-1 aerodynamic model.
%
%   IHW2: add the configuration data and the two configuration methods.
%   The clean polar is unchanged - your mission analysis still uses it.

    properties
        % Declared for you, with the JSON key each one is read from. The
        % property name is NOT always the key: the file names the datum and
        % carries its qualifier, the class keeps the short name the rest of
        % your code uses. Do not rename these.
        AR                       % <- J.geometry.AR
        CD0                      % <- J.aerodynamics.CD0_clean

        CLmax_clean              % <- J.aerodynamics.CLmax_clean
        CLmax_takeoff            % <- J.aerodynamics.CLmax_takeoff
        CLmax_landing            % <- J.aerodynamics.CLmax_landing

        CL_stall_margin          % <- J.aerodynamics.CL_stall_margin

        dCD0_flaps_takeoff       % <- J.aerodynamics.delta_CD0_flaps_takeoff
        dCD0_flaps_landing       % <- J.aerodynamics.delta_CD0_flaps_landing
        dCD0_gear_down           % <- J.aerodynamics.delta_CD0_gear_down
        dCD0_propeller_stopped   % <- J.aerodynamics.delta_CD0_propeller_stopped

        de_flaps_takeoff         % <- J.aerodynamics.delta_e_flaps_takeoff
        de_flaps_landing         % <- J.aerodynamics.delta_e_flaps_landing

    end

    properties (Dependent)
        e
        K
        LD_max
    end

    methods

        %% Constructor
        function obj = TtpaAero(json_path)
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            J = jsondecode(fileread(json_path));

            obj.AR = J.geometry.AR;

            % TODO: read the aerodynamics block, for example
            %   A = J.aerodynamics;
            %   obj.CD0 = A.CD0_clean;
            %   ...

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
        %GET_CLMAX  CLmax of the configuration named by con.config.

            switch string(con.config)

                % TODO: one case per configuration name, and an otherwise
                %       branch that errors on an unknown name

            end

        end


        %% Configuration Polar
        function cfg = get_config_polar(obj, state, con)
        %GET_CONFIG_POLAR  Drag polar and CLmax of the configuration.

            dCD0 = 0;
            de   = 0;

            switch string(con.config)

                % TODO: set dCD0 and de for each configuration.
                %       The gear increment adds on top of the flap increment.

            end

            % TODO: add the stopped-propeller increment when the condition
            %       sets con.propeller_stopped

            cfg.config   = string(con.config);
            cfg.CD0      = ;
            cfg.e        = ;
            cfg.K1       = ;
            cfg.K2       = 0;
            cfg.CLmax    = ;
            cfg.CL_climb = ;

        end


        %% Maximum L/D
        function LD_max = get.LD_max(obj)
            LD_max = 1 / (2 * sqrt(obj.CD0 * obj.K));
        end

    end

end
