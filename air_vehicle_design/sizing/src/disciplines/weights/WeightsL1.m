classdef WeightsL1
%WEIGHTSL1  Level-1 weight estimation static toolbox.
%
%   Call as WeightsL1.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16WeightsL1, etc.)
%   inherit from WeightsModelL1 and call these statics to implement each
%   abstract method.
%
%   TWO INDEPENDENT L1 STATISTICAL METHODS, both implemented, separately
%   named and separately citable:
%
%   (1) Raymer Table 3.1 — empty-weight power law (the CENTRAL estimate):
%         We/Wto = K_vs · A · W_TO^C
%       A, C, K_vs are aircraft-category constants.
%       K_vs = 1.04 for variable-sweep wings, 1.00 otherwise.
%       OEW = (We/Wto) · W_TO  [lbf]
%       [Raymer 7th ed. Table 3.1]
%
%   (2) Roskam Eq. 2.16 — log-log MINIMUM bound:
%         log10(W_E) = (log10(W_TO) − A) / B
%       Gives the MINIMUM historically achievable W_E for that aircraft class.
%       An actual OEW will exceed this minimum.  Useful for design margin.
%       [Roskam Part I Eq. 2.16 + Table 2.15]
%
%   *** WHICH ONE IS THE CLASS'S OFFICIAL ANSWER ***
%   WeightsL1.OEW — the WeightsBase contract method every downstream consumer
%   calls — delegates to (1), the Raymer power law. Reason: (1) is a central
%   regression through historical fighters and is therefore the right thing to
%   put into a sizing loop; (2) is by construction a LOWER BOUND (the
%   state-of-the-art efficiency frontier), so using it as an OEW estimate would
%   systematically under-predict. (2) is exposed separately as
%   compute_We_roskam / We_roskam for margin checks and comparison reporting,
%   and is never summed into OEW.
%
%   Comparison at W_TO = 31,377 lbf for a jet fighter (computed live 2026-07-25):
%     Raymer (1): We/Wto = 0.609055 -> OEW = 19110.31 lbf  (central estimate)
%     Roskam (2): W_E    = 15673.73 lbf                    (minimum achievable)
%   Ground truth for context — NOT a calibration input:
%     Brandt OEW = 19980.70 lbf  [Brandt Wt!B12 = 19980.700578, live-read
%       2026-07-25, formula =SUM(B10:B11)]  -> Raymer (1) is -4.36 %
%     corrections.xls OEW = 19148.08 lbf  [Casey's revised-weight workbook,
%       F16Baseline.m:136] -> Raymer (1) is -0.20 %
%     ! 19,148 is corrections.xls, NOT Brandt Wt!B12. The two are distinct
%     provenances ~4.3 % apart and must never be conflated (review finding #14;
%     VnV/BrandtF16A/todo.md 2026-07-25 Phase 4 §P4-0, docs/weights_parameter_usage.md E.4).
%
%   STANDING TO-DO — Raymer Table 6.1 (locked, user 2026-07-24).
%     docs/subplans/05_weights.md:81,88 cites Raymer **Table 6.1** for the same
%     power law that this file cites as **Table 3.1**. Locked decision: KEEP
%     Table 3.1 plus the Roskam bound; Table 6.1's coefficients are NOT present
%     anywhere in this repo, so the user must supply them. Do not silently adopt
%     Table 6.1 numbers, and do not invent them.
%     todo 2026-07-25 Phase 4 §P4-8; guard test
%     TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo.
%
%   SOURCES (edition unified to Raymer 7th ed. across the weights discipline,
%   Phase 4; no coefficient value changes — todo 2026-07-24 §3c item 4):
%     Raymer, "Aircraft Design: A Conceptual Approach," 7th ed., AIAA —
%       Table 3.1, empty-weight fraction regression constants. Transcribed from
%       the secondary extract temp_AI/docs/disciplines/reference_extracts/
%       metabook_data.md:20-26 (the AE481 metabook's copy, which cites Raymer).
%       [! SECONDARY SOURCE — verify every row against the printed table.]
%     Roskam, "Airplane Design, Part I," DARcorporation — Eq. 2.16 (book p.47 /
%       PDF p.59) + Table 2.15. Transcribed from
%       temp_AI/docs/disciplines/reference_extracts/roskam_vol1_data.md:47
%       (equation) and :53-63 (table). The extract's own caveat (:63): the full
%       12-category table is image-only and these rows were OCR-recovered —
%       "Verify against the book before locking into code." So the Roskam
%       constants are traceable-but-not-book-verified. This is explicitly NOT a
%       standing TO-DO (todo §P4-8 withdrew that item); only Table 6.1 is.

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function oew = OEW(obj, W_TO)
        %OEW  Operating empty weight [lbf] via the Raymer Table 3.1 power law.
        %   [Raymer 7th ed. Table 3.1]  The OFFICIAL L1 answer — see the class
        %   header for why the Raymer central estimate is used here rather than
        %   the Roskam lower bound.
        %   W_TO — candidate gross weight [lbf].
            oew = WeightsL1.compute_We_fraction(obj, W_TO, obj.aircraft_category) * W_TO;
        end

        function frac = compute_We_fraction(obj, W_TO, aircraft_category)
        %COMPUTE_WE_FRACTION  Empty-weight fraction We/Wto.  [Raymer 7th ed. Table 3.1]
        %   aircraft_category defaults to obj.aircraft_category when omitted.
            if nargin < 3
                aircraft_category = obj.aircraft_category;
            end
            c = WeightsL1.lookup_coeffs(aircraft_category);
            frac = WeightsL1.We_fraction_power_law(c.Kvs, c.A, c.C, W_TO);
        end

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
        %   [Raymer 7th ed. Table 3.1; metabook_data.md:20-26]
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
        %   temp_AI/docs/disciplines/reference_extracts/metabook_data.md, which
        %   is the AE481 metabook's copy of Raymer Table 3.1 (a SECONDARY
        %   source citing Raymer, not Raymer itself).
        %   [! verify all rows against the printed Raymer 7th ed. Table 3.1
        %      before citing as book-verified — todo §P4-8]
        %   A is the US-unit coefficient (the extract also lists A (SI), unused).
        %   K_vs = 1.00 fixed sweep / 1.04 variable sweep [metabook_data.md:20-22];
        %   the F-16 is fixed-sweep, so 1.04 is never exercised here.
        %   NOT CARRIED: the extract's 5th row, UAV-Tac Recce / UCAV
        %   (A = 1.67, C = -0.16, metabook_data.md:25) — no consumer, recorded
        %   for completeness rather than added speculatively.
            switch lower(aircraft_category)
                case 'jet_fighter'
                    c = struct('A', 2.34, 'C', -0.13, 'Kvs', 1.00); % [Raymer 7th ed. Tbl 3.1; metabook_data.md:22]
                case 'military_cargo_bomber'
                    c = struct('A', 0.93, 'C', -0.07, 'Kvs', 1.00); % [Raymer 7th ed. Tbl 3.1; metabook_data.md:23]
                case 'jet_transport'
                    c = struct('A', 1.02, 'C', -0.06, 'Kvs', 1.00); % [Raymer 7th ed. Tbl 3.1; metabook_data.md:24]
                case 'jet_trainer'
                    c = struct('A', 1.59, 'C', -0.10, 'Kvs', 1.00); % [Raymer 7th ed. Tbl 3.1; metabook_data.md:26]
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
        %   temp_AI/docs/disciplines/reference_extracts/roskam_vol1_data.md:57-61.
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
