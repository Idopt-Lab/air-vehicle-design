classdef WeightsL1
%WEIGHTSL1  Level-1 weights static toolbox: statistical empty-weight fraction.
%
%   Call as WeightsL1.method(...); never instantiated, not in the inheritance
%   chain. F16WeightsL1 inherits WeightsModelL1 and delegates to these statics.
%
%   Central estimate: [Raymer 6th ed. Table 3.1] empty-weight-fraction power
%   law. Independent lower bound: [Roskam Part I Eq. 2.16 with Table 2.15].
%   Both take only W_TO -- L1 has no geometry and no engine data.
%
%   Both coefficient sets come from secondary sources: the metabook cites
%   Raymer rather than being Raymer, and the Roskam rows were OCR-recovered
%   from an image-only table carrying its own verify-against-the-book warning.
%
%   TODO: docs/subplans/05_weights.md cites Raymer Table 6.1 for the same power
%   law, but Table 6.1's coefficients are NOT present in this repo -- the code
%   uses Table 3.1. Guarded by
%   TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo.
%
%   Companion doc: src/disciplines/weights/WeightsL1.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function oew = OEW(obj, W_TO)
        %OEW  Operating empty weight [lbf] via the Raymer Table 3.1 power law.
        %   [Raymer 6th ed. Table 3.1]  The OFFICIAL L1 answer — see the class
        %   header for why the Raymer central estimate is used here rather than
        %   the Roskam lower bound.
        %   W_TO — candidate gross weight [lbf].
            oew = WeightsL1.compute_We_fraction(obj, W_TO, obj.aircraft_category) * W_TO;
        end

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function frac = compute_We_fraction(obj, W_TO, aircraft_category)
        %COMPUTE_WE_FRACTION  Empty-weight fraction We/Wto.  [Raymer 6th ed. Table 3.1]
        %   aircraft_category defaults to obj.aircraft_category when omitted.
            if nargin < 3
                aircraft_category = obj.aircraft_category;
            end
            c = WeightsL1.lookup_coeffs(aircraft_category);
            frac = WeightsL1.We_fraction_power_law(c.Kvs, c.A, c.C, W_TO);
        end

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function W_E = compute_We_roskam(obj, W_TO)
        %COMPUTE_WE_ROSKAM  Minimum empty weight [lbf].  [Roskam Part I Eq. 2.16]
        %   A LOWER BOUND, not a central estimate — never summed into OEW.
        %   Uses obj.aircraft_category to look up the Roskam Table 2.15 row.
            c = WeightsL1.lookup_roskam_coeffs(obj.aircraft_category);
            W_E = WeightsL1.We_roskam(c.A, c.B, W_TO);
        end

        % ================================================================== %
        % LOW-LEVEL: pure math — scalars only.
        % ================================================================== %

        function frac = We_fraction_power_law(Kvs, A, C, W_TO)
        %WE_FRACTION_POWER_LAW  We/Wto = K_vs · A · W_TO^C.
        %   [Raymer 6th ed. Table 3.1; metabook_data.md:20-26]
        %   Kvs  — variable-sweep factor: 1.04 (VS) or 1.00 (fixed) [metabook_data.md:20-22].
        %   A, C — category constants from Raymer Table 3.1.
        %   W_TO — takeoff gross weight [lbf].
            frac = Kvs .* A .* W_TO .^ C;
        end

        function W_E = We_roskam(A, B, W_TO)
        %WE_ROSKAM  Roskam log-log minimum empty weight [lbf].
        %   [Roskam Part I Eq. 2.16, book p.47 / PDF p.59; roskam_vol1_data.md:47]
        %   Extract form:  W_E = inv.log10{ (log10(W_TO) − A) / B }
        %   i.e.  log10(W_E) = (log10(W_TO) − A) / B
        %   W_TO — gross weight [lbf].  Returns the MINIMUM W_E [lbf].
            W_E = 10 .^ ( (log10(W_TO) - A) ./ B );
        end

        function c = lookup_coeffs(aircraft_category)
        %LOOKUP_COEFFS  Return (Kvs, A, C) constants for Raymer Table 3.1.
        %   aircraft_category — char/string (e.g. 'jet_fighter').
        %   Every row below is transcribed from the named repo extract
        %   docs/reference_extracts/metabook_data.md, which
        %   is the AE481 metabook's copy of Raymer Table 3.1 (a SECONDARY
        %   source citing Raymer, not Raymer itself).
        %   [! verify all rows against the printed Raymer 6th ed. Table 3.1
        %      before citing as book-verified — todo §P4-8]
        %   A is the US-unit coefficient (the extract also lists A (SI), unused).
        %   K_vs = 1.00 fixed sweep / 1.04 variable sweep [metabook_data.md:20-22];
        %   the F-16 is fixed-sweep, so 1.04 is never exercised here.
        %   NOT CARRIED: the extract's 5th row, UAV-Tac Recce / UCAV
        %   (A = 1.67, C = -0.16, metabook_data.md:25) — no consumer, recorded
        %   for completeness rather than added speculatively.
            switch lower(aircraft_category)
                case 'jet_fighter'
                    c = struct('A', 2.34, 'C', -0.13, 'Kvs', 1.00); % [Raymer 6th ed. Tbl 3.1; metabook_data.md:22]
                case 'military_cargo_bomber'
                    c = struct('A', 0.93, 'C', -0.07, 'Kvs', 1.00); % [Raymer 6th ed. Tbl 3.1; metabook_data.md:23]
                case 'jet_transport'
                    c = struct('A', 1.02, 'C', -0.06, 'Kvs', 1.00); % [Raymer 6th ed. Tbl 3.1; metabook_data.md:24]
                case 'jet_trainer'
                    c = struct('A', 1.59, 'C', -0.10, 'Kvs', 1.00); % [Raymer 6th ed. Tbl 3.1; metabook_data.md:26]
                otherwise
                    error('WeightsL1:UnknownCategory', ...
                          'Unknown aircraft_category "%s". Add row to lookup_coeffs.', ...
                          aircraft_category);
            end
        end

        function c = lookup_roskam_coeffs(aircraft_category)
        %LOOKUP_ROSKAM_COEFFS  Return (A, B) constants for Roskam Table 2.15.
        %   [Roskam Part I Table 2.15, book p.47 / PDF p.59]
        %   All five rows transcribed from the named repo extract
        %   docs/reference_extracts/roskam_vol1_data.md:57-61.
        %   The extract's caveat (:63): the full 12-category table is image-only
        %   and these rows were OCR-recovered — traceable, not book-verified.
            switch lower(aircraft_category)
                case 'jet_fighter'
                    c = struct('A', 0.5091, 'B', 0.9505);  % Fighters — jets [roskam_vol1_data.md:57]
                case 'fighter_piston'
                    c = struct('A', 0.5647, 'B', 0.8761);  % Fighters — piston/props [roskam_vol1_data.md:58]
                case 'single_engine_prop'
                    c = struct('A', -0.1440, 'B', 1.1162); % Single-engine prop driven [roskam_vol1_data.md:59]
                case 'military_patrol_bomber'
                    c = struct('A', -0.2009, 'B', 1.1037); % Mil. patrol/bomb/transport — jets [roskam_vol1_data.md:60]
                case 'supersonic_cruise'
                    c = struct('A', 0.0833, 'B', 1.0335);  % Supersonic cruise — jets [roskam_vol1_data.md:61]
                otherwise
                    error('WeightsL1:UnknownRoskamCategory', ...
                          'Unknown aircraft_category "%s". Add row to lookup_roskam_coeffs.', ...
                          aircraft_category);
            end
        end

    end

end
