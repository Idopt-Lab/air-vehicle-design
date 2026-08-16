classdef Aero481WeightsL1 < WeightsModelL1
%Aero481WEIGHTSL1  F-35A (Aero 481 Design01/A02 provenance) Level-1 weight class.
%
%   Inherits WeightsModelL1 (abstract enforcer). Every equation body reuses a
%   shared src/ static -- no equation is re-derived here.
%
%   ==========================================================================
%   OEW = AERO 481 A02 DELTA MODEL (RESTORED 2026-08-15).
%
%   This is the University of Michigan AEROSP 481 (Fall 2024) A02 empty-weight
%   model [+Algorithms/A02.m:37-63]: the Sainristil empty-weight FRACTION plus
%   two DELTA terms that measure how far the current design sits from the fixed
%   A481 design point (W/S = 92.17 psf, T/W = 1.2):
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
%   SELF-SCALING BASELINES -- WHY A02 IS STABLE. Both delta baselines scale WITH
%   W_TO, so each delta stays BOUNDED and OEW never runs away in the sizing loop:
%     * WING baseline W_TO/design_WS_psf is the wing area the CURRENT W_TO wants
%       at the design wing loading. As W_TO grows this baseline grows with it,
%       so the wing delta rho_w*(S_ref - W_TO/design_WS_psf) tracks only the
%       deviation of the ACTUAL S_ref from the design-wing-loading area, not W_TO
%       itself.
%     * ENGINE baseline design_TW*W_TO is the design-T/W-implied thrust. It too
%       grows with W_TO, so the engine delta measures only how far the ACTUAL
%       installed thrust prop.T_SL sits from the design-T/W thrust.
%   An earlier build ran away because SizingLoopL1 froze a FIXED (non-scaling)
%   baseline (S_ref_baseline / T_baseline constants), turning each delta into a
%   second W_TO-proportional term. That was a SizingLoopL1 fixed-baseline BUG,
%   NOT a defect of the A02 model. With A02's own self-scaling baselines the
%   model is stable; this is verified: A02(Design01, T_SL = 43000, S = 50 m^2)
%   sizes the F-35 to 62,399 lb.
%
%   WHY THE F-35 SIZES SMALL (~62.4 klb). At the F-35 design point the ENGINE
%   delta is strongly NEGATIVE: the real F135 (prop.T_SL = 43,000 lbf) is far
%   below the design-T/W-implied thrust design_TW*W_TO (~74,880 lbf at
%   W_TO ~ 62k), so engine_weight_roskam(43000) - engine_weight_roskam(74880) is
%   a large negative number. That credit pulls the EFFECTIVE OEW fraction from
%   the bare Sainristil ~0.486 down to ~0.37, which is exactly why Aero 481
%   converges the F-35 to ~62,400 lb rather than a much heavier point.
%
%   lbm-vs-lbf: the Sainristil coefficient basis is lbm, numerically equal to
%   lbf at standard gravity, so W_TO[lbf] passes straight through.
%   ==========================================================================
%
%   FRAMEWORK-CITED ALTERNATIVE. The cited fighter curve
%   [Raymer 6th ed. Table 3.1 jet_fighter] is We/W0 = 2.34 * W0^-0.13
%   (WeightsL1.lookup_coeffs) -- a DIFFERENT curve, exposed as
%   compute_We_fraction_raymer so the comparison report can show the
%   Sainristil-vs-Raymer delta. It is NOT the design baseline.
%
%   ROSKAM LOWER BOUND. compute_We_roskam is the [Roskam Part I Eq. 2.16 +
%   Table 2.15] jet_fighter log-log MINIMUM empty weight -- a lower bound, never
%   summed into OEW; carried to satisfy the WeightsModelL1 contract.
%
%   INPUT vs DERIVED. OEW(W_TO), compute_We_fraction(W_TO) etc. stay METHODS
%   taking W_TO, so they recompute per call and cannot go stale. OEW reads
%   geom.S_ref and prop.T_SL LIVE on every call (no cache), so a sizing-loop or
%   optimizer change to either injected object is reflected on the next read.
%
%   CONSTRUCTOR: Aero481WeightsL1(json_path, geom, prop) -- THREE args, all required,
%   no silent default. Injects the L1 geometry object (supplies S_ref via
%   get_S_ref) and the propulsion object (supplies T_SL). Reads the top-level
%   aircraft_category and the .weights block (OEW coefficients, design_WS_psf,
%   design_TW, payload).
%
%   Inheritance: WeightsBase -> WeightsModelL1 -> Aero481WeightsL1
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
    % INPUTS -- plain mutable properties, set once by the constructor; W_TO /
    % W_energy are state, mutated by the sizing / mission loops. geom / prop are
    % injected discipline objects read LIVE inside OEW. Authoritative table with
    % citations: Aero481WeightsL1.md section 2.
    % ======================================================================= %
    properties
        aircraft_category = 'jet_fighter'  % selects the Raymer Table 15.2 wing areal density (WeightsL2.wing_unit_weight), the Raymer Table 3.1 jet_fighter fraction row, and the Roskam Table 2.15 row [aero481_L1.json top-level -- ONE canonical class flag per aircraft]

        %OEW_COEFF_A, OEW_COEFF_C  Sainristil empty-weight-fraction power-law
        %   coefficients: We/W0 = oew_coeff_a * W0[lbm]^oew_coeff_c = 0.882 *
        %   W0^-0.055 [A481 Design01.m:26]. _TODO -- UNCITED (student-team fit;
        %   discrepancy A7). USER APPROVED as the F-35 DESIGN BASELINE.
        oew_coeff_a = 0.882   % --   Sainristil OEW-fraction leading coefficient [A481 Design01.m:26]. _TODO -- UNCITED (A7)
        oew_coeff_c = -0.055  % --   Sainristil OEW-fraction exponent           [A481 Design01.m:26]. _TODO -- UNCITED (A7)

        %DESIGN_WS_PSF, DESIGN_TW  A481 fixed design-point performance targets,
        %   the SELF-SCALING baselines of the two A02 delta terms. design_WS_psf
        %   (= 450 kgf/m^2) fixes the wing-delta baseline area W_TO/design_WS_psf;
        %   design_TW fixes the engine-delta baseline thrust design_TW*W_TO.
        %   [A481 Design01 PointPerformance, Design01.m:20-21]. _TODO -- UNCITED
        %   (student design choices).
        design_WS_psf = 92.17 % psf  design wing loading; wing-delta baseline [A481 Design01.m PointPerformance]. _TODO -- UNCITED
        design_TW     = 1.2   % --   design thrust-to-weight; engine-delta baseline [A481 Design01.m PointPerformance]. _TODO -- UNCITED

        %GEOM, PROP  Injected discipline objects (DI). OEW reads geom.get_S_ref()
        %   for the wing-delta actual area and prop.T_SL for the engine-delta
        %   actual thrust, LIVE on every call -- never cached here.
        geom   % (1,1) GeometryModelL1 -- supplies S_ref via get_S_ref() (wing delta actual area)
        prop   % (1,1) PropulsionBase  -- supplies T_SL (engine delta actual thrust)

        % ----- WeightsBase abstract properties -----
        W_TO                 = NaN     % lbf  candidate gross takeoff weight; STATE, mutated by the sizing loop [WeightsBase contract]
        W_energy             = NaN     % lbf  internal fuel; STATE, set by mission analysis [WeightsBase contract]
        W_payload_expendable = 18000   % lbf  expendable payload (missiles). [A481 WMissile = 18000 lbm, Design01.m:41-49]. _TODO -- UNCITED (student choice)
        W_payload_fixed      = 441     % lbf  fixed payload (200 kg crew). [A481 WCrew, Design01.m]. _TODO -- UNCITED (student choice)
        % ! Both payload values are INERT for the OEW build-up (no term reads
        %   them). They satisfy the WeightsBase closure
        %   W_TO = OEW + W_energy + W_payload_fixed + W_payload_expendable used by
        %   the sizing loop.
    end

    methods

        function obj = Aero481WeightsL1(json_path, geom, prop)
        %Aero481WEIGHTSL1  Construct from a required spec JSON path (aero481_spec_path(1))
        %   plus an injected L1 geometry object and propulsion object. NO silent
        %   default on any of the three. Reads the top-level aircraft_category
        %   and the .weights block (OEW coefficients, design_WS_psf, design_TW,
        %   payload). Sets ONLY input properties -- OEW recomputes per call and
        %   reads geom.S_ref / prop.T_SL live, so nothing is frozen here.
        %
        %   geom -- (1,1) GeometryModelL1 subclass; supplies S_ref (get_S_ref).
        %   prop -- (1,1) PropulsionBase subclass; supplies T_SL.
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
        %
        %   Single engine (n = 1), so the engine delta has NO division by an
        %   engine count. Every W_TO-dependent term uses the PASSED W_TO, not
        %   obj.W_TO.
            arguments
                obj
                W_TO (1,1) double {mustBePositive, mustBeFinite}
            end
            % FRACTION term -- the bare Sainristil empty weight.
            oew_fraction = obj.compute_We_fraction(W_TO) * W_TO;

            % WING delta -- rho_w * (actual S_ref - design-W/S baseline area).
            % Baseline area W_TO/design_WS_psf SELF-SCALES with W_TO.
            % [A481 A02.m:37-63; Raymer 6th ed. Table 15.2 rho_w = 9]
            rho_w        = WeightsL2.wing_unit_weight(obj.aircraft_category);
            S_ref        = obj.geom.get_S_ref();                 % live
            wing_delta   = rho_w * (S_ref - W_TO / obj.design_WS_psf);

            % ENGINE delta -- actual installed engine minus the design-T/W engine.
            % Baseline thrust design_TW*W_TO SELF-SCALES with W_TO. Single engine,
            % so no division by an engine count.
            % [A481 A02.m:37-63; Roskam Eqs. 7.13-7.19 via engine_weight_roskam]
            T_SL         = obj.prop.T_SL;                        % live
            T_baseline   = obj.design_TW * W_TO;
            engine_delta = WeightsL1.engine_weight_roskam(T_SL) ...
                         - WeightsL1.engine_weight_roskam(T_baseline);

            oew = oew_fraction + wing_delta + engine_delta;
        end

        function frac = compute_We_fraction(obj, W_TO)
        %COMPUTE_WE_FRACTION  Sainristil empty-weight fraction We/W0 [--].
        %   We/W0 = oew_coeff_a * W0[lbm]^oew_coeff_c = 0.882 * W0^-0.055.
        %   The FRACTION term of the A02 model (USER APPROVED baseline). A power
        %   law of exactly the WeightsL1.We_fraction_power_law shape, so it
        %   delegates to that shared static with Kvs = 1. _TODO -- UNCITED (A7).
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
