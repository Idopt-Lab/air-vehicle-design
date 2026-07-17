classdef PropL1
%PROPL1  Level-1 propulsion static toolbox.
%
%   Call as PropL1.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16PropL1, etc.) inherit
%   from PropulsionModelL1 and call these statics to implement each abstract method.
%
%   TWO TIERS of statics:
%     High-level — take the student object (obj) and return a computed result.
%                  Student implementations are a single delegation line.
%     Low-level  — pure math; take only scalars/arrays.
%
%   EQUATIONS:
%     thrust_lapse: α = σ^m,  σ = ρ/ρ_SL
%       Exponent m is looked up by engine type (see lookup_lapse_exponent):
%         turbojet / turbojet_AB:              m = 1.0  [Martins Eq. 10.7]
%         low_bypass_turbofan / _AB:           m = 0.6  [Martins Eq. 10.9]
%         high_bypass_turbofan:                m = 0.6  [Martins Eq. 10.9]
%         turboprop:                           m = 1.0  [shaft power ∝ ρ]
%       No Mach correction at Level 1 — see L2/L3 for Mattingly Eq. 2.54.
%       Source: J.R.R.A. Martins, AE481 course notes (metabook), Eqs. 10.7 / 10.9
%     TSFC: categorical lookup by engine type — cruise and loiter conditions only.
%       Raymer 6th ed. Table 3.3; values in lbf_fuel/(hr·lbf_thrust).
%       M < 0.4 → loiter TSFC; M >= 0.4 → cruise TSFC  (L1 approximation).
%       AB operation is not modelled at Level 1 — see L2/L3 for Mattingly Eq. 3.55.

    properties (Constant, Access = private)
        RHO_SL = 0.002377;   % slug/ft³ — ISA sea-level density [Mattingly App. B]
        % TODO (7/13/2026): Standard atmospheric conditions at sea level should be its own class.
    end

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function alpha = get_thrust_lapse(obj, state)
        %GET_THRUST_LAPSE  Density-ratio lapse: α = σ^m, m from engine-type table.
        %   [Martins AE481 course notes (metabook), Eqs. 10.7 / 10.9]
            m = PropL1.lookup_lapse_exponent(obj.engine_type);
            alpha = PropL1.sigma_lapse(state.rho, m);
        end

        function c_t = get_TSFC(obj, state)
        %GET_TSFC  Categorical TSFC from engine-type table (1/hr).
        %   M < 0.4 → loiter TSFC; M >= 0.4 → cruise TSFC.  [Raymer 6th Table 3.3]
        %   Threshold is an L1 approximation — segment type is not in AircraftState.
            tbl = PropL1.lookup_TSFC_table(obj.engine_type);
            if state.mach < 0.4
                c_t = tbl.loiter;
            else
                c_t = tbl.cruise;
            end
        end

        % ================================================================== %
        % LOW-LEVEL: pure math — scalars only.
        % ================================================================== %

        function alpha = sigma_lapse(rho, m)
        %SIGMA_LAPSE  α = σ^m where σ = ρ/ρ_SL.
        %   m = density-ratio exponent from lookup_lapse_exponent:
        %     1.0 for turbojet  [Martins Eq. 10.7]
        %     0.6 for turbofan  [Martins Eq. 10.9]
            sigma = rho / PropL1.RHO_SL;
            alpha = sigma^m;
        end

        function m = lookup_lapse_exponent(engine_type)
        %LOOKUP_LAPSE_EXPONENT  Density-lapse exponent m by engine type.
        %   α = σ^m,  σ = ρ/ρ_SL.  [Martins AE481 course notes (metabook)]
        %   m = 1.0: turbojet — thrust scales linearly with density  [Eq. 10.7]
        %   m = 0.6: turbofan — general low-to-high-BPR fit          [Eq. 10.9]
            switch engine_type
                case {'turbojet', 'turbojet_AB'}
                    m = 1.0;
                case {'low_bypass_turbofan_AB', 'low_bypass_turbofan', 'high_bypass_turbofan'}
                    m = 0.6;
                case 'turboprop'
                    m = 1.0;
                otherwise
                    error('PropL1:unknownEngineType', ...
                        'Unknown engine_type "%s". Add it to PropL1.lookup_lapse_exponent.', ...
                        engine_type);
            end
        end

        function tbl = lookup_TSFC_table(engine_type)
        %LOOKUP_TSFC_TABLE  Categorical cruise/loiter TSFC by engine type (1/hr).
        %   Source: Raymer 6th ed. Table 3.3.
        %   Returns struct with fields .cruise and .loiter (both in 1/hr).
        %   AB operation is NOT modelled here — see L2/L3 Mattingly Eq. 3.55.
        %   AB capability does not affect cruise/loiter TSFC; _AB variants share
        %   the same values as their dry counterparts.
            switch engine_type
                case {'turbojet', 'turbojet_AB'}
                    tbl = struct('cruise', 0.90, 'loiter', 0.80);
                case {'low_bypass_turbofan_AB', 'low_bypass_turbofan'}
                    tbl = struct('cruise', 0.80, 'loiter', 0.70);
                case 'high_bypass_turbofan'
                    tbl = struct('cruise', 0.50, 'loiter', 0.40);
                case 'turboprop'
                    tbl = struct('cruise', 0.90, 'loiter', 0.80);
                otherwise
                    error('PropL1:unknownEngineType', ...
                        'Unknown engine_type "%s". Add it to PropL1.lookup_TSFC_table.', ...
                        engine_type);
            end
        end

    end

end
