classdef PropulsionLevel1 < PropulsionBase
    % Level I propulsion: type-based tabulated TSFC and simple density-lapse thrust.
    %
    % thrust_lapse uses a power-law density ratio model appropriate for
    % the engine type.  TSFC returns the tabulated cruise value in 1/s.
    %
    % Usage:
    %   prop = PropulsionLevel1('low_bypass_mixed_turbofan');
    %   prop.T0 = 23770;   % set by sizing loop
    %   alpha = prop.thrust_lapse(AircraftState(35000, 0.85));
    %   tsfc  = prop.TSFC(AircraftState(35000, 0.85));

    properties
        engine_type     % normalized engine type string
        lapse_exponent  % exponent n in (rho/rho_sl)^n thrust model
        tsfc_cruise_s   % tabulated cruise TSFC (1/s), set in constructor
    end

    methods
        function obj = PropulsionLevel1(engine_type)
            obj.engine_type = PropulsionUtils.classify_engine_type(engine_type);

            % Thrust lapse exponent: density-ratio power law
            % Turbojet/low-BPR afterburning: T ~ delta (pressure ratio)
            % High-BPR turbofan: T ~ (rho/rho_sl)^0.7 (approximate)
            switch obj.engine_type
                case {"turbojet","low_bypass_mixed_turbofan"}
                    obj.lapse_exponent = 0.7;   % sigma^0.7 empirical for AB turbofan (density ratio, reduced exponent)
                case "high_bypass_turbofan"
                    obj.lapse_exponent = 0.7;
                case {"turboprop","Piston_prop_fixed_pitch","Piston_prop_variable_pitch"}
                    obj.lapse_exponent = 0.9;
                otherwise
                    obj.lapse_exponent = 0.7;
            end

            % Store cruise TSFC in 1/s
            tsfc_struct = PropulsionLevel1.get_TSFC(engine_type);
            obj.tsfc_cruise_s = tsfc_struct.cruise;
        end

        function alpha = thrust_lapse(obj, state)
            % Power-law density ratio model: T(h)/T0 = (rho(h)/rho_sl)^n
            [~, ~, ~, rho_sl] = atmosisa(0);
            alpha = (state.rho / (rho_sl * 0.00194032033))^obj.lapse_exponent;
        end

        function tsfc = TSFC(obj, state) %#ok<INUSD>
            tsfc = obj.tsfc_cruise_s;
        end
    end

    methods (Static)

        function TSFC_out = get_TSFC(engine_type)
            engine_type = PropulsionUtils.classify_engine_type(engine_type);
            switch engine_type
                case "turbojet"
                    TSFC_out.cruise = 0.9/3600;
                    TSFC_out.loiter = 0.8/3600;
                case "low_bypass_mixed_turbofan"
                    TSFC_out.cruise = 0.8/3600;
                    TSFC_out.loiter = 0.7/3600;
                case "high_bypass_turbofan"
                    TSFC_out.cruise = 0.5/3600;
                    TSFC_out.loiter = 0.4/3600;
                case {"Piston_prop_fixed_pitch","Piston_prop_variable_pitch"}
                    TSFC_out.cruise = 0.4/3600;
                    TSFC_out.loiter = 0.5/3600;
                case "turboprop"
                    TSFC_out.cruise = 0.9/3600;
                    TSFC_out.loiter = 0.8/3600;
                otherwise
                    error("Unrecognized engine type: %s", engine_type)
            end
        end

    end

end
