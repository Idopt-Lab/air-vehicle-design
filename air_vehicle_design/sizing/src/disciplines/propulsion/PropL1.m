classdef PropL1
%PROPL1  Level-1 propulsion static toolbox: density-ratio lapse, table TSFC.
%
%   Call as PropL1.method(...); never instantiated, not in the inheritance
%   chain. F16PropL1 inherits PropulsionModelL1 and delegates to these statics.
%
%   Thrust lapse: [Martins AE481 metabook Eq. 10.9], exponent by engine type
%   per Eq. 10.7. TSFC: [Raymer 6th ed. Table 3.3] for jet engines, [Table
%   3.4] for 'turboprop' (a different, power-specific quantity) -- a
%   two-value table with no Mach or afterburner dependence.
%
%   Companion doc: src/disciplines/propulsion/PropL1.md

    properties (Constant, Access = private)
        RHO_SL = 0.002377;   % slug/ft³ — ISA sea-level density [Mattingly App. B]
        % TODO (7/13/2026): Standard atmospheric conditions at sea level should be its own class.
        % TODO (8/14/2026): Standard atmospheric conditions at sea-level should be its own class. This is still true, today.
    end

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        % TODO (8/14/2026): This appears to be an artefact from when the toolboxes were subclasses of the enforcers.
        % These wrappers are no longer necessary and should be replaced with the "compute" functions that actually do the math.
        function alpha = get_thrust_lapse(obj, state)
        %GET_THRUST_LAPSE  Density-ratio lapse: α = σ^m, m from engine-type table.
        %   [Martins AE481 course notes (metabook), Eqs. 10.7 / 10.9]
            m = PropL1.lookup_lapse_exponent(obj.engine_type);
            alpha = PropL1.sigma_lapse(state.rho, m);
        end

        % TODO (8/14/2026): This appears to be in the same boat as the "get_thrust_lapse" function. Same problem, same solution.
        % These wrappers should be moved into the F16 example, if they aren't already.
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
        % >>>>>>>>>>    N.B: "m" IS NOT MACH NUMBER, IT'S A COEFFICIENT!    <<<<<<<<<<<<<
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
        %LOOKUP_TSFC_TABLE  Categorical cruise/loiter TSFC by engine type.
        %   Source: Raymer 6th ed. Table 3.3 (jet engines, thrust-specific,
        %   1/hr) and Table 3.4 (propeller engines, power-specific Cbhp,
        %   lb/hr/bhp -- a DIFFERENT physical quantity, not interchangeable
        %   with the jet rows without a power/thrust relation).
        %   Returns struct with fields .cruise and .loiter.
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
                    % Table 3.4 Cbhp [lb/hr/bhp], NOT Table 3.3's 1/hr basis.
                    % Fixed 2026-07-30 (previously duplicated the turbojet
                    % row, 0.90/0.80, which was a mis-transcription).
                    warning('PropL1:turbopropIsPowerBasis', ...
                        ['turboprop TSFC is Raymer Table 3.4 Cbhp [lb/hr/bhp], a ' ...
                         'power-specific fuel consumption -- not the thrust-specific ' ...
                         '1/hr basis every other engine_type here returns. Do not feed ' ...
                         'this value into a thrust-basis TSFC equation without converting.']);
                    tbl = struct('cruise', 0.50, 'loiter', 0.60);
                otherwise
                    error('PropL1:unknownEngineType', ...
                        'Unknown engine_type "%s". Add it to PropL1.lookup_TSFC_table.', ...
                        engine_type);
            end
        end

    end

end
