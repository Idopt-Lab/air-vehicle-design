classdef F16WeightsL1 < WeightsModelL1
%F16WEIGHTSL1  F-16A Block 10/15 Level-1 weight estimation student class.
%
%   Inherits from WeightsModelL1 (abstract enforcer).  Every abstract method is
%   satisfied by a single delegation line to WeightsL1 statics — no equations
%   are duplicated here.
%
%   METHODS (both statistical regressions on takeoff gross weight):
%     (1) Raymer Table 3.1 power law:  We/Wto = K_vs · A · W_TO^C
%         Central estimate.  jet_fighter: A = 2.34, C = -0.13, K_vs = 1.00.
%         [Raymer 6th ed. Table 3.1]  ** OEW delegates to this one. **
%     (2) Roskam Eq. 2.16 log-log:     W_E_min = 10^((log10(W_TO)-A)/B)
%         MINIMUM achievable W_E — a lower bound, never summed into OEW.
%         jet_fighter: A = 0.5091, B = 0.9505.
%         [Roskam Part I Eq. 2.16 + Table 2.15]
%
%   VALUES at W_TO = 31,377 lbf (computed live 2026-07-25):
%     Raymer: We/Wto = 1.00 · 2.34 · 31377^(-0.13) = 0.609055 -> OEW = 19110.31 lbf
%     Roskam: W_E_min = 15673.73 lbf  (correctly BELOW the Raymer estimate)
%   Ground truth for context — comparison only, never a calibration input:
%     Brandt OEW      = 19980.70 lbf  [Brandt Wt!B12 = 19980.700578, live-read
%                                      2026-07-25, formula =SUM(B10:B11)]  -> -4.36 %
%     corrections.xls = 19148.08 lbf  [Casey's revised-weight workbook,
%                                      docs/weights_parameter_usage.md §4]   -> -0.20 %
%     ! CORRECTED 2026-07-25: this header previously read "Brandt actual:
%     19,148 lbf [Brandt F-16A.xls, B12]" — WRONG CELL, WRONG WORKBOOK.
%     Wt!B12 is 19980.70; 19,148.08 is corrections.xls. The two are distinct
%     provenances ~4.3 % apart (review finding #14; todo §P4-0 / §E.4).
%
%   ============================================================================
%   INPUT vs DERIVED — the optimization-ready pattern (CLAUDE.md; reference
%   implementation examples/F16A/models/disciplines/geom/F16GeomL2.m).
%
%   L1 has 5 INPUTS and 0 DERIVED, and zero is the right answer:
%     * WeightsModelL1 declares no abstract properties, so there is no
%       "computed total" to expose (L1 carries none of review finding #12's NaN
%       placeholders).
%     * Nothing on this class is a frozen derived value — there is no L1 analog
%       of review finding #5.
%     * OEW(W_TO), compute_We_fraction(W_TO) and compute_We_roskam(W_TO) stay
%       METHODS: they take W_TO as an argument, so they recompute per call and
%       cannot go stale. The inputs-vs-Dependent rule governs *stored* derived
%       state.
%   Adding Dependent mirrors keyed off obj.W_TO would be a feature beyond what
%   this step requires and is deliberately out of scope — noted so a later
%   reader does not mistake the absence for an oversight (F16WeightsL1.md §3).
%   ============================================================================
%
%   CONSTRUCTOR (CHANGED 2026-07-25, Phase 4): F16WeightsL1(json_path).
%   Reads the top-level aircraft_category and the .weights block of a REQUIRED
%   unified L1 input JSON (f16a_spec_path(1)). No silent default — a no-argument
%   call errors, matching F16PropL2(json_path) / F16GeomL2(json_path, prop).
%
%   L1 does NOT read examples/F16A/inputs/f16a_requirements.json and injects nothing.
%   Both regressions take only W_TO and aircraft_category, so there is no design
%   Mach, no cruise condition, no geometry and no propulsion object to inject —
%   L1 is the only weights level with no dependency injection at all.
%
%   SOURCES:
%     [Brandt]  Brandt F-16A.xls, sheet "Wt" — validation targets only.
%     [Raymer]  D.P. Raymer, Aircraft Design 7th ed., AIAA, Table 3.1.
%     [Roskam]  J. Roskam, Airplane Design Part I, DARcorp., Eq. 2.16 + Table 2.15.

    % ======================================================================= %
    % INPUTS (5) — plain mutable properties. The constructor sets the three
    % spec/mission values once from the JSON; the two state variables are
    % mutated in place by the sizing / mission loops.
    % Authoritative table with all citations: F16WeightsL1.md §2.
    % ======================================================================= %
    properties
        aircraft_category = 'jet_fighter'  % selects the Raymer Tbl 3.1 row (WeightsL1.lookup_coeffs) and the Roskam Tbl 2.15 row (lookup_roskam_coeffs) [f16a_L1.json top-level aircraft_category — ONE canonical class flag per aircraft]

        % ----- WeightsBase abstract properties -----
        W_TO               = NaN   % lbf  candidate gross takeoff weight; STATE — the optimizer's variable, mutated in place by the sizing loop [WeightsBase contract]
        W_energy           = NaN   % lbf  internal fuel; STATE, set by mission analysis [WeightsBase contract]. ! Was 6296.3, which is Brandt Wt!B6 = =B3-B4-B5-B12 (live formula), i.e. W_TO - payload - OEW: a back-calculated Brandt OUTPUT, forbidden as an input by CLAUDE.md. Deleted from the JSON in Phase 3
        W_payload_expendable = 4400 % lbf  expendable payload (stores) [Brandt Wt!B5 = 4400.000000 (live), formula =Main!O17]
        W_payload_fixed    = 700   % lbf  fixed equipment + crew [Brandt Wt!B4 = 700.000000 (live), formula =Main!O16]
        % ! The two payload values are currently INERT: no WeightsL{1,2,3} static
        %   reads them (grepped 2026-07-25). They satisfy the WeightsBase closure
        %   contract and will be consumed by the future sizing loop. Setting them
        %   to 700/4400 changes no computed L1 number; it makes the closure
        %   identity 31377 - 19980.70 - 6296.30 = 5100 = 700 + 4400 correct for
        %   when the loop lands. docs/weights_parameter_usage.md §1.
    end

    methods

        function obj = F16WeightsL1(json_path)
        %F16WEIGHTSL1  Construct from a required unified L1 input JSON path
        %   (f16a_spec_path(1)); reads its top-level aircraft_category and its
        %   .weights block. NO silent default: the path must be supplied.
        %   Sets ONLY input properties — L1 has no derived quantity to compute,
        %   and in particular nothing is frozen here (contrast the constructor
        %   defect this pattern removed at L2, review finding #5).
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path));
            obj.aircraft_category    = char(J.aircraft_category);          % [f16a_L1.json top-level]
            obj.W_payload_fixed      = J.weights.W_payload_fixed;          % [Brandt Wt!B4]
            obj.W_payload_expendable = J.weights.W_payload_expendable;     % [Brandt Wt!B5]
            % W_TO and W_energy are deliberately NOT read: both are sizing-loop /
            % mission-analysis STATE and stay NaN until set. W_energy in
            % particular is a back-calculated Brandt output (Wt!B6).
        end

        % ================================================================== %
        % Methods required by the abstract contract — each a single delegation
        % into the WeightsL1 static toolbox, which holds the cited equations.
        % ================================================================== %

        function oew = OEW(obj, W_TO)
        %OEW  Operating empty weight [lbf].  [Raymer 6th ed. Table 3.1]
            oew = WeightsL1.OEW(obj, W_TO);
        end

        function frac = compute_We_fraction(obj, W_TO, aircraft_category)
        %COMPUTE_WE_FRACTION  Empty-weight fraction We/Wto.  [Raymer 6th ed. Table 3.1]
        %   The optional third argument overrides obj.aircraft_category.
            if nargin < 3
                aircraft_category = obj.aircraft_category;
            end
            frac = WeightsL1.compute_We_fraction(obj, W_TO, aircraft_category);
        end

        function W_E = compute_We_roskam(obj, W_TO)
        %COMPUTE_WE_ROSKAM  Minimum empty weight [lbf].  [Roskam Part I Eq. 2.16]
        %   A LOWER BOUND, not an OEW estimate.
            W_E = WeightsL1.compute_We_roskam(obj, W_TO);
        end

    end

end
