classdef WeightsL1
%WEIGHTSL1  Level-1 weights static toolbox: statistical empty-weight fraction.
%
%   Call as WeightsL1.method(...); never instantiated. F16WeightsL1 inherits
%   WeightsModelL1 and delegates here.
%
%   Two regressions, both on W_TO alone. The design class picks one:
%     [Raymer 6th ed. Table 3.1] empty-weight FRACTION power law.
%     [Roskam Part I Eq. 2.16 with Table 2.15] empty WEIGHT, which Roskam
%     presents as the minimum achievable value.
%   Both coefficient sets are secondary-source extracts.
%
%   TODO: the original step-5 design cites Raymer Table 6.1 for the same power
%   law, but Table 6.1's coefficients are NOT present in this repo -- the code
%   uses Table 3.1. Guarded by TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo.
%
%   Companion doc: src/disciplines/weights/WeightsL1.md

    methods (Static)

        % ================================================================== %
        % LOW-LEVEL: pure math — scalars only.
        % ================================================================== %

        function frac = compute_We_frac_raymer(Kvs, A, C, W_TO)
        %WE_FRACTION_POWER_LAW  We/Wto = K_vs · A · W_TO^C.
        %   [Raymer 6th ed. Table 3.1; metabook_data.md:20-26]
        %   Kvs  — variable-sweep factor: 1.04 (VS) or 1.00 (fixed) [metabook_data.md:20-22].
        %   A, C — category constants from Raymer Table 3.1.
        %   W_TO — takeoff gross weight [lbf].
            frac = Kvs .* A .* W_TO .^ C;
        end

        function W_E = compute_We_roskam(A, B, W_TO)
        %WE_ROSKAM  Roskam log-log minimum empty weight [lbf].
        %   [Roskam Part I Eq. 2.16, book p.47 / PDF p.59; roskam_vol1_data.md:47]
        %   Extract form:  W_E = inv.log10{ (log10(W_TO) − A) / B }
        %   i.e.  log10(W_E) = (log10(W_TO) − A) / B
        %   W_TO — gross weight [lbf].  Returns the MINIMUM W_E [lbf].
            W_E = 10 .^ ( (log10(W_TO) - A) ./ B );
        end

        % Note (9/1/2026)(Casey): Kvs does not come from a table, it comes from the design.
        % Kvs should not be tabulated.
        function c = lookup_raymer_We_frac_coeffs(aircraft_category)
        %LOOKUP_COEFFS  Return (Kvs, A, C) constants for Raymer Table 3.1.
        %   aircraft_category — char/string (e.g. 'jet_fighter').
        %   Rows transcribed from docs/reference_extracts/metabook_data.md (the
        %   AE481 metabook's copy of Raymer Table 3.1, a secondary source).
        %   [! verify all rows against the printed Raymer 6th ed. Table 3.1
        %      before citing as book-verified — todo §P4-8]
        %   A is the US-unit coefficient. K_vs = 1.00 fixed / 1.04 variable
        %   sweep [metabook_data.md:20-22]; the F-16 is fixed-sweep.
        %   NOT CARRIED: the extract's 5th row, UAV-Tac Recce / UCAV
        %   (A = 1.67, C = -0.16, metabook_data.md:25) — no consumer.
            switch lower(aircraft_category)
                case 'jet_fighter'
                    c = struct('A', 2.34, 'C', -0.13); % [Raymer 6th ed. Tbl 3.1; metabook_data.md:22]
                case 'military_cargo_bomber'
                    c = struct('A', 0.93, 'C', -0.07); % [Raymer 6th ed. Tbl 3.1; metabook_data.md:23]
                case 'jet_transport'
                    c = struct('A', 1.02, 'C', -0.06); % [Raymer 6th ed. Tbl 3.1; metabook_data.md:24]
                case 'jet_trainer'
                    c = struct('A', 1.59, 'C', -0.10); % [Raymer 6th ed. Tbl 3.1; metabook_data.md:26]
                otherwise
                    error('WeightsL1:UnknownCategory', ...
                          'Unknown aircraft_category "%s". Add row to lookup_coeffs.', ...
                          aircraft_category);
            end
        end

        function c = lookup_We_roskam_coeffs(aircraft_category)
        %LOOKUP_ROSKAM_COEFFS  Return (A, B) constants for Roskam Table 2.15.
        %   [Roskam Part I Table 2.15, book p.47 / PDF p.59]
        %   Five rows transcribed from
        %   docs/reference_extracts/roskam_vol1_data.md:57-61. The extract's
        %   caveat (:63): image-only table, OCR-recovered, not book-verified.
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
