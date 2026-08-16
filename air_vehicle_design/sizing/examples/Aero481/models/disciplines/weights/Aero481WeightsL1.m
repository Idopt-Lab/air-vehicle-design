classdef Aero481WeightsL1 < WeightsModelL1
%Aero481WEIGHTSL1  F-35A (Aero 481 Design01/A02 provenance) Level-1 weight class.
%
%   Inherits WeightsModelL1 (abstract enforcer). Every equation body reuses a
%   shared src/ static -- no equation is re-derived here.
%
%   OEW = the Aero 481 A02 empty-weight DELTA model [+Algorithms/A02.m:37-63]:
%   the Sainristil empty-weight FRACTION plus two DELTA terms measuring how far
%   the current design sits from the fixed A481 design point (W/S = 92.17 psf,
%   T/W = 1.2):
%
%     OEW(W_TO) = We_frac(W_TO) * W_TO                              [FRACTION]
%               + rho_w * ( geom.S_ref - W_TO / design_WS_psf )    [WING  delta]
%               + ( engine_weight_roskam( prop.T_SL )
%                 - engine_weight_roskam( design_TW * W_TO ) )      [ENGINE delta]
%
%   where
%     We_frac(W_TO) = 0.882 * W_TO[lbm]^-0.055  [A481 Design01.m:26 Sainristil]
%     rho_w         = 9 lbf/ft^2 jet_fighter    [Raymer 6th ed. Table 15.2;
%                     = A481 A02 WingDensity 44 kg/m^2]
%     design_WS_psf = 92.17 psf, design_TW = 1.2 [A481 Design01 PointPerformance]
%
%   Both delta baselines (W_TO/design_WS_psf, design_TW*W_TO) SELF-SCALE with
%   W_TO, so each delta stays bounded and OEW does not run away. Verified:
%   A02(Design01, T_SL = 43000, S = 50 m^2) sizes the F-35 to 62,399 lb. The
%   F-35 sizes small because the ENGINE delta is strongly negative (the real
%   F135 is far below the design-T/W thrust), pulling the effective OEW fraction
%   from ~0.486 to ~0.37. lbm basis passes through as lbf at standard gravity.
%
%   FRAMEWORK-CITED ALTERNATIVE. compute_We_fraction_raymer is the cited fighter
%   curve We/W0 = 2.34*W0^-0.13 [Raymer 6th ed. Table 3.1 jet_fighter] -- exposed
%   for the comparison report, NOT the design baseline. compute_We_roskam is the
%   [Roskam Part I Eq. 2.16 + Table 2.15] jet_fighter log-log MINIMUM empty
%   weight -- a lower bound, never summed into OEW.
%
%   OEW(W_TO) etc. stay METHODS taking W_TO (recompute per call, read geom.S_ref
%   and prop.T_SL LIVE, no cache). CONSTRUCTOR:
%   Aero481WeightsL1(json_path, geom, prop) -- three args, all required.
%
%   Inheritance: WeightsBase -> WeightsModelL1 -> Aero481WeightsL1
%   History and rationale: docs/decision_log.md; companion .md.
%
%   SOURCES:
%     [A481]    University of Michigan AEROSP 481 (Fall 2024) starter code by
%               Max Arnson (Design01 / +Algorithms/A02.m) -- design PROVENANCE,
%               not a primary source. docs/reference_extracts/aero481_data.md Part II.
%     [Raymer]  D.P. Raymer, Aircraft Design, AIAA -- Table 3.1 empty-weight
%               fraction and Table 15.2 areal densities (6th ed.).
%     [Roskam]  J. Roskam, Airplane Design Part I -- Eq. 2.16 + Table 2.15
%               (empty-weight lower bound); Eqs. 7.13-7.19 (engine weight).
%     [disc]    examples/Aero481/aero481_discrepancies.md (A7, A9).

    % ======================================================================= %
    % INPUTS -- plain mutable properties set once by the constructor; W_TO /
    % W_energy are sizing/mission state; geom / prop are injected, read LIVE
    % inside OEW. Citations table: companion .md section 2.
    % ======================================================================= %
    properties
        aircraft_category = 'jet_fighter'  % selects the Raymer Table 15.2 wing areal density (WeightsL2.wing_unit_weight), the Raymer Table 3.1 jet_fighter fraction row, and the Roskam Table 2.15 row [aero481_L1.json top-level -- ONE canonical class flag per aircraft]

        %OEW_COEFF_A, OEW_COEFF_C  Sainristil OEW-fraction power-law coefficients:
        %   We/W0 = oew_coeff_a * W0[lbm]^oew_coeff_c = 0.882 * W0^-0.055
        %   [A481 Design01.m:26]. _TODO -- UNCITED (A7). USER APPROVED baseline.
        oew_coeff_a = 0.882   % --   Sainristil OEW-fraction leading coefficient [A481 Design01.m:26]. _TODO -- UNCITED (A7)
        oew_coeff_c = -0.055  % --   Sainristil OEW-fraction exponent           [A481 Design01.m:26]. _TODO -- UNCITED (A7)

        %DESIGN_WS_PSF, DESIGN_TW  A481 design-point targets, the self-scaling
        %   baselines of the two A02 delta terms [A481 Design01.m:20-21].
        %   _TODO -- UNCITED (student design choices).
        design_WS_psf = 92.17 % psf  design wing loading; wing-delta baseline [A481 Design01.m PointPerformance]. _TODO -- UNCITED
        design_TW     = 1.2   % --   design thrust-to-weight; engine-delta baseline [A481 Design01.m PointPerformance]. _TODO -- UNCITED

        %GEOM, PROP  Injected discipline objects (DI); read LIVE inside OEW.
        geom   % (1,1) GeometryModelL1 -- supplies S_ref via get_S_ref() (wing delta actual area)
        prop   % (1,1) PropulsionBase  -- supplies T_SL (engine delta actual thrust)

        % ----- WeightsBase abstract properties -----
        W_TO                 = NaN     % lbf  candidate gross takeoff weight; STATE, mutated by the sizing loop [WeightsBase contract]
        W_energy             = NaN     % lbf  internal fuel; STATE, set by mission analysis [WeightsBase contract]
        W_payload_expendable = 18000   % lbf  expendable payload (missiles). [A481 WMissile = 18000 lbm, Design01.m:41-49]. _TODO -- UNCITED (student choice)
        W_payload_fixed      = 441     % lbf  fixed payload (200 kg crew). [A481 WCrew, Design01.m]. _TODO -- UNCITED (student choice)
        % ! Both payload values are INERT for the OEW build-up; they satisfy the
        %   WeightsBase closure W_TO = OEW + W_energy + payloads.
    end

    methods

        function obj = Aero481WeightsL1(json_path, geom, prop)
        %Aero481WEIGHTSL1  Construct from a required spec JSON path
        %   (aero481_spec_path(1)) plus an injected L1 geometry object (supplies
        %   S_ref via get_S_ref) and propulsion object (supplies T_SL). No silent
        %   default. Reads the top-level aircraft_category and the .weights block
        %   (OEW coefficients, design_WS_psf, design_TW, payload).
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
                geom (1,1) GeometryModelL1
                prop (1,1) PropulsionBase
            end
            J = jsondecode(fileread(json_path));
            obj.geom = geom;   % injected: supplies the wing-delta actual area
            obj.prop = prop;   % injected: supplies the engine-delta actual thrust

            obj.aircraft_category    = char(J.aircraft_category);          % [aero481_L1.json top-level]
            obj.oew_coeff_a          = J.weights.oew_coeff_a;              % [A481 Design01.m:26]  _TODO A7
            obj.oew_coeff_c          = J.weights.oew_coeff_c;              % [A481 Design01.m:26]  _TODO A7
            obj.design_WS_psf        = J.weights.design_WS_psf;           % [A481 Design01 PointPerformance] _TODO
            obj.design_TW            = J.weights.design_TW;               % [A481 Design01 PointPerformance] _TODO
            obj.W_payload_expendable = J.weights.W_payload_expendable;     % [A481 WMissile]       _TODO
            obj.W_payload_fixed      = J.weights.W_payload_fixed;          % [A481 WCrew]          _TODO
            % W_TO / W_energy stay NaN (sizing-loop / mission STATE).
        end

        % ================================================================== %
        % WeightsModelL1 / WeightsBase abstract contract.
        % ================================================================== %

        function oew = OEW(obj, W_TO)
        %OEW  Operating empty weight [lbf] -- the Aero 481 A02 delta model.
        %   [A481 +Algorithms/A02.m:37-63]
        %
        %     OEW(W_TO) = We_frac(W_TO)*W_TO                         [FRACTION]
        %               + rho_w*( S_ref - W_TO/design_WS_psf )       [WING  delta]
        %               + ( Weng(T_SL) - Weng(design_TW*W_TO) )      [ENGINE delta]
        %
        %   rho_w  = WeightsL2.wing_unit_weight(aircraft_category)
        %            = 9 lbf/ft^2 jet_fighter [Raymer 6th ed. Table 15.2]
        %   S_ref  = geom.get_S_ref()   [ft^2, read LIVE]
        %   T_SL   = prop.T_SL          [lbf, read LIVE]
        %   Weng   = WeightsL1.engine_weight_roskam  [Roskam Eqs. 7.13-7.19]
        %   Single engine (n = 1): the engine delta has no division by an engine
        %   count. Every W_TO-dependent term uses the PASSED W_TO.
            arguments
                obj
                W_TO (1,1) double {mustBePositive, mustBeFinite}
            end
            % FRACTION term -- the bare Sainristil empty weight.
            oew_fraction = obj.compute_We_fraction(W_TO) * W_TO;

            % WING delta -- rho_w * (actual S_ref - design-W/S baseline area).
            % [A481 A02.m:37-63; Raymer 6th ed. Table 15.2 rho_w = 9]
            rho_w        = WeightsL2.wing_unit_weight(obj.aircraft_category);
            S_ref        = obj.geom.get_S_ref();                 % live
            wing_delta   = rho_w * (S_ref - W_TO / obj.design_WS_psf);

            % ENGINE delta -- actual installed engine minus the design-T/W engine.
            % Single engine, no division by count.
            % [A481 A02.m:37-63; Roskam Eqs. 7.13-7.19 via engine_weight_roskam]
            T_SL         = obj.prop.T_SL;                        % live
            T_baseline   = obj.design_TW * W_TO;
            engine_delta = WeightsL1.engine_weight_roskam(T_SL) ...
                         - WeightsL1.engine_weight_roskam(T_baseline);

            oew = oew_fraction + wing_delta + engine_delta;
        end

        function frac = compute_We_fraction(obj, W_TO)
        %COMPUTE_WE_FRACTION  Sainristil empty-weight fraction We/W0 [--].
        %   We/W0 = oew_coeff_a * W0[lbm]^oew_coeff_c = 0.882 * W0^-0.055, the
        %   FRACTION term of the A02 model. Delegates to
        %   WeightsL1.We_fraction_power_law (Kvs = 1). _TODO -- UNCITED (A7).
        %   [A481 Design01.m:26]
            frac = WeightsL1.We_fraction_power_law(1.0, obj.oew_coeff_a, obj.oew_coeff_c, W_TO);
        end

        function frac = compute_We_fraction_raymer(obj, W_TO, aircraft_category)
        %COMPUTE_WE_FRACTION_RAYMER  Framework-cited ALTERNATIVE We/W0 [--].
        %   [Raymer 6th ed. Table 3.1 jet_fighter]  We/W0 = 2.34 * W_TO^-0.13.
        %   NOT the design baseline -- exposed only so the comparison report can
        %   show the Sainristil-vs-Raymer delta. The optional third argument
        %   overrides obj.aircraft_category.
            if nargin < 3
                aircraft_category = obj.aircraft_category;
            end
            frac = WeightsL1.compute_We_fraction(obj, W_TO, aircraft_category);
        end

        function W_E = compute_We_roskam(obj, W_TO)
        %COMPUTE_WE_ROSKAM  Minimum empty weight [lbf].  [Roskam Part I Eq. 2.16]
        %   jet_fighter log-log lower bound -- never summed into OEW.
            W_E = WeightsL1.compute_We_roskam(obj, W_TO);
        end

    end

end
