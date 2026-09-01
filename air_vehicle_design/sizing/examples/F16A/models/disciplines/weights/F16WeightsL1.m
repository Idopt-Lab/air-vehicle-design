classdef F16WeightsL1 < WeightsModelL1
%F16WEIGHTSL1  F-16A Block 10/15 Level-1 weight estimation student class.
%
%   Inherits from WeightsModelL1. Its one abstract method delegates to the
%   WeightsL1 static toolbox. OEW is the Raymer empty-weight-FRACTION power law
%   on takeoff gross weight, multiplied out:
%     We/Wto = K_vs * A * W_TO^C,  jet_fighter A=2.34, C=-0.13, K_vs=1.00
%     [Raymer 6th ed. Table 3.1]
%   The Roskam Eq. 2.16 log-log minimum empty weight stays available in the
%   toolbox, as an independent lower bound, but this class does not use it.
%
%   Constructor: F16WeightsL1(json_path), the required unified L1 JSON
%   (f16a_spec_path(1)), no silent default. L1 has 5 inputs, 0 Dependent, and no
%   dependency injection; get_OEW stays a method that takes W_TO per call.
%
%   History and rationale: docs/decision_log.md
%
%   SOURCES:
%     [Brandt]  Brandt F-16A.xls, sheet "Wt" — validation targets only.
%     [Raymer]  D.P. Raymer, Aircraft Design 7th ed., AIAA, Table 3.1.
%     [Roskam]  J. Roskam, Airplane Design Part I, DARcorp., Eq. 2.16 + Table 2.15.

    % ======================================================================= %
    % INPUTS (5) — mutable spec data. Citations: F16WeightsL1.md §2.
    % ======================================================================= %
    properties
        aircraft_category = 'jet_fighter'  % selects the Raymer Tbl 3.1 row [f16a_L1.json top-level aircraft_category — ONE canonical class flag per aircraft]

        % ----- WeightsBase abstract properties -----
        W_TO               = NaN   % lbf  candidate gross takeoff weight; STATE, mutated by the sizing loop [WeightsBase contract]
        W_energy           = NaN   % lbf  internal fuel; STATE, set by mission analysis [WeightsBase contract]
        W_payload_expendable = 4400 % lbf  expendable payload (stores) [Brandt Wt!B5 = Main!O17]
        W_payload_fixed    = 700   % lbf  fixed equipment + crew [Brandt Wt!B4 = Main!O16]
        % The two payload values are inert (no WeightsL* static reads them); they
        % satisfy the WeightsBase closure contract for the sizing loop.
    end

    methods

        function obj = F16WeightsL1(json_path)
        %F16WEIGHTSL1  Construct from a required unified L1 input JSON path
        %   (f16a_spec_path(1)); reads its top-level aircraft_category and its
        %   .weights block. No silent default. Sets only input properties.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path));
            obj.aircraft_category    = char(J.aircraft_category);          % [f16a_L1.json top-level]
            obj.W_payload_fixed      = J.weights.W_payload_fixed;          % [Brandt Wt!B4]
            obj.W_payload_expendable = J.weights.W_payload_expendable;     % [Brandt Wt!B5]
            % W_TO and W_energy stay NaN: sizing-loop / mission-analysis state.
        end

        % ================================================================== %
        % Methods required by the abstract contract — each a single delegation
        % into the WeightsL1 static toolbox, which holds the cited equations.
        % ================================================================== %

        function oew = get_OEW_categorical(obj, W_TO)
        %GET_OEW_CATEGORICAL  Operating empty weight [lbf].
        %   [Raymer 6th ed. Table 3.1]  The power law gives a FRACTION, so the
        %   weight is that fraction times gross weight.
            % c   = WeightsL1.lookup_We_roskam_coeffs(obj.aircraft_category);
            % oew = WeightsL1.compute_We_roskam(c.A, c.B, W_TO);
            % K_vs is a DESIGN value, not a table value, so the caller supplies
            % it. The F-16A is fixed-sweep: K_vs = 1.00 [metabook_data.md:20-22].
            c        = WeightsL1.lookup_raymer_We_frac_coeffs(obj.aircraft_category);
            OEW_frac = WeightsL1.compute_We_frac_raymer(1.00, c.A, c.C, W_TO);
            oew      = OEW_frac * W_TO;
        end

        % Note (9/1/2026)(Casey): This serves no purpose.
        % function frac = compute_We_fraction(obj, W_TO, aircraft_category)
        % %COMPUTE_WE_FRACTION  Empty-weight fraction We/Wto.  [Raymer 6th ed. Table 3.1]
        % %   The optional third argument overrides obj.aircraft_category.
        %     if nargin < 3
        %         aircraft_category = obj.aircraft_category;
        %     end
        %     frac = WeightsL1.compute_We_fraction(obj, W_TO, aircraft_category);
        % end

        % Note (9/1/2026)(Casey): This serves no purpose.
        % function W_E = compute_We_roskam(obj, W_TO)
        % %COMPUTE_WE_ROSKAM  Minimum empty weight [lbf].  [Roskam Part I Eq. 2.16]
        % %   A LOWER BOUND, not an OEW estimate.
        %     W_E = WeightsL1.compute_We_roskam(obj, W_TO);
        % end

    end

end
