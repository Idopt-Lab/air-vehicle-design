classdef TtpaAero < AerodynamicsBase
%TTPAAERO  Test Twin Propeller Aircraft Level-2 aerodynamic model.
%
%   IHW3a UPDATE
%   One property changed, and nothing else. In IHW1 and IHW2 the clean
%   zero-lift drag coefficient was a stored number:
%
%       obj.CD0 = A.CD0_clean;          % 0.028, fixed for ever
%
%   That is correct when the airplane has no geometry, which was the case
%   in both earlier homeworks. It is wrong inside a sizing loop: the loop
%   changes the wing area, the tails follow it, the nacelles follow the
%   engine, and a frozen 0.028 would report the same drag for every one of
%   those airplanes. So CD0 is now DEPENDENT and is computed from the
%   geometry on every read:
%
%       [Raymer Eq. 12.23]   CD0 = Cfe * S_wet / S_ref
%
%   with Cfe = 0.0045 for a light twin-engine airplane, Raymer Table 12.3.
%   That single line is what couples GEOMETRY to DRAG, drag to L/D, L/D to
%   the mission fuel and the mission fuel to the takeoff weight. Without it
%   the sizing loop would still close on weight, but the mission would
%   never notice that the wing had changed.
%
%   AR is now Dependent too, read straight off the injected geometry, so
%   the aspect ratio has exactly one home. Every expression below that used
%   obj.AR is unchanged.
%
%   The IHW2 value, CD0_clean = 0.028, is still read from the JSON and kept
%   as CD0_reference. The run script prints the two side by side: they
%   agree to about one percent, and that agreement is the check that the
%   geometry and the wetted-area build-up are right.
%
%   EVERYTHING ELSE IS IHW2 UNCHANGED - the Oswald efficiency, the induced
%   drag factor, the clean drag polar, get_CLmax and get_config_polar with
%   its five configurations and its flap, gear and stopped-propeller
%   increments.
%
%   INJECTED GEOMETRY
%   TtpaAero(json_path, geom). Build prop, then geom, then aero - see
%   ttpa_disciplines.

    properties
        % Declared with the JSON key each one is read from. The property
        % name is NOT always the key.
        CD0_reference            % <- J.aerodynamics.CD0_clean, CHECK ONLY
        Cfe                      % <- J.aerodynamics.Cfe

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

    properties (SetAccess = immutable)
        geom                     % injected TtpaGeom
    end

    properties (Dependent)
        AR              % Wing aspect ratio, read from the geometry
        CD0             % Clean zero-lift drag coefficient, from S_wet/S_ref
        e               % Oswald efficiency factor
        K               % Induced drag factor
        LD_max          % Maximum lift-to-drag ratio
    end

    methods

        %% Constructor
        function obj = TtpaAero(json_path, geom)
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
                geom (1,1) GeometryBase
            end

            obj.geom = geom;

            % Read requirements JSON
            J = jsondecode(fileread(json_path));

            % Read aerodynamics-owned data
            A = J.aerodynamics;

            obj.CD0_reference   = A.CD0_clean;
            obj.Cfe             = A.Cfe;

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


        %% Aspect Ratio
        function AR = get.AR(obj)
        %GET.AR  Wing aspect ratio, from the geometry model.
        %   In IHW2 this class read J.geometry.AR itself. Now that a real
        %   geometry object exists, the aspect ratio has one home and this
        %   is a view onto it. Every expression below is unchanged.
            AR = obj.geom.AR;
        end


        %% Clean Zero-Lift Drag Coefficient
        function CD0 = get.CD0(obj)
        %GET.CD0  Clean zero-lift drag coefficient [-].
        %
        %   [Raymer Eq. 12.23]   CD0 = Cfe * ( S_wet / S_ref )
        %
        %   The equivalent-skin-friction method. Cfe = 0.0045 for a light
        %   TWIN-engine airplane [Raymer Table 12.3]; a single-engine light
        %   airplane is 0.0055.
        %
        %   THIS IS THE COUPLING. S_wet and S_ref are both Dependent
        %   properties of the geometry, so the moment the sizing loop writes
        %   a new S_ref the wing, the tails and the nacelles resize, the
        %   wetted-area ratio moves, and the next read of CD0 - and of
        %   LD_max, and therefore of the mission fuel - reflects it. Nothing
        %   is cached and nothing has to be told to refresh.
            CD0 = obj.Cfe * obj.geom.S_wet_over_S_ref;
        end


        %% Oswald Efficiency
        function e = get.e(obj)
        %GET.E  Oswald span efficiency factor [-].
        %       e = 1.78 (1 - 0.045 AR^0.68) - 0.64
        %   [Raymer 6th ed. Eq. 12.48, the STRAIGHT-WING form, valid for a
        %   leading-edge sweep below 30 deg. The TTPA is unswept, so this is
        %   the right branch; Eq. 12.49 is the swept-wing form.]
        %
        %   Carried over from IHW1/IHW2 unchanged. The citation is new -
        %   the equation was in the earlier homeworks with no source
        %   attached to it.
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
        %   configuration named by con.config. The flight state is not used
        %   at this level of fidelity, exactly as in prop_eff. Unchanged
        %   from IHW2.

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
        %   Unchanged from IHW2 apart from where the clean CD0 comes from.
        %   It still starts from the CLEAN polar this class provides,
        %   through drag_polar, and adds the increments of the
        %   configuration on top - so the clean polar stays the single
        %   source of the clean values, and it is now the geometry-driven
        %   one.
        %
        %   cfg = get_config_polar(obj, state, con) returns
        %       cfg.CD0       clean CD0 plus the flap, the gear and, when
        %                     the condition asks for it, the stopped
        %                     propeller increment
        %       cfg.e         clean Oswald efficiency plus the flap increment
        %       cfg.K1        1/(pi*AR*e) of the configuration
        %       cfg.K2        the clean K2, 0 at this level of fidelity
        %       cfg.CLmax     CLmax of the configuration
        %       cfg.CL_climb  CLmax minus the stall margin, the lift
        %                     coefficient a climb is flown at
        %
        %   Increments: Roskam Part I, Table 3.6 and Sec. 3.3.

            polar = obj.drag_polar(state);

            switch string(con.config)

                case "clean"
                    dCD0 = 0;
                    de   = 0;

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
            cfg.CD0    = polar.CD0 + dCD0;
            cfg.e      = obj.e + de;
            cfg.K1     = 1 / (pi * obj.AR * cfg.e);
            cfg.K2     = polar.K2;
            cfg.CLmax  = obj.get_CLmax(state, con);

            cfg.CL_climb = cfg.CLmax - obj.CL_stall_margin;

        end


        %% Maximum L/D
        function LD_max = get.LD_max(obj)
        %GET.LD_MAX  Maximum lift-to-drag ratio [-].
        %   Follows CD0, which follows the geometry. This is the property
        %   run_mission reads for the cruise and loiter Breguet segments, so
        %   the mission fuel responds to the airplane the sizing loop has
        %   just laid out WITHOUT a single change to run_mission.
            LD_max = 1 / (2 * sqrt(obj.CD0 * obj.K));

        end

    end

end
