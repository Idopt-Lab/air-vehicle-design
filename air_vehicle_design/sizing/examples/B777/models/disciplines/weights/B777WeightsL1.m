classdef B777WeightsL1 < WeightsModelL1
%B777WEIGHTSL1  Boeing 777-200LR Level-1 weight estimation (metabook §4.12.1).
%
%   Inherits WeightsModelL1 (abstract enforcer). The empty-weight-fraction and
%   Roskam-lower-bound methods delegate to WeightsL1 statics; OEW implements the
%   metabook §4.12.1 Algorithm 2 DELTA-WEIGHT model directly (it is a B777-example
%   composition of toolbox statics, not a single toolbox equation).
%
%   OEW DELTA MODEL [metabook §4.12.1 Algorithm 2] -- recomputed every call, no
%   cache. Empty weight is the Raymer Table 3.1 regression at W_TO, plus linear
%   corrections for how far the current wing area, tail areas and engine thrust
%   sit from the baseline 777-200LR design point:
%
%     OEW(W_TO) = (We/W0)(W_TO) * W_TO                                   [Raymer Table 3.1]
%               + dens_wing * (geom.S_ref - S_ref_baseline)             [Table 15.2 wing 10]
%               + dens_HT   * (geom.S_ht  - S_ht_baseline)              [Table 15.2 HT 5.5]
%               + dens_VT   * (geom.S_vt  - S_vt_baseline)              [Table 15.2 VT 5.5]
%               + n_eng * ( Weng_roskam(prop.T_SL/n_eng)
%                         - Weng_roskam(T_baseline_per_engine) )        [Roskam Eqs. 7.13-7.19]
%
%   with (We/W0)(W_TO) = Kvs*A*W_TO^C, jet_transport row A=1.02, C=-0.06,
%   Kvs=1.00 [Raymer Table 3.1; WeightsL1.lookup_coeffs]. At the BASELINE design
%   point (W_TO = 766800, geom at S_ref=4605 / baseline tail areas, prop.T_SL =
%   220000 -> 110000/engine = T_baseline) ALL FOUR deltas are zero, so
%   OEW(766800) collapses to the pure regression We = A*W_TO^C * W_TO ~ 346862 lbf.
%
%   ============================================================================
%   DEPENDENCY INJECTION. Geometry and propulsion are INJECTED, not re-read from
%   JSON -- the CURRENT wing/tail areas come from geom, the CURRENT thrust from
%   prop.T_SL (mirroring F16WeightsL2, which reads prop.T_SL rather than a JSON
%   thrust). The .weights block's T_baseline_per_engine is the BASELINE ONLY (the
%   fixed reference point of the delta model), never the current thrust.
%
%   INPUT vs DERIVED. OEW is a METHOD taking W_TO (WeightsBase contract), so it
%   recomputes on every call and cannot go stale -- there is nothing to cache and
%   no Dependent block is needed (same as WeightsModelL1's note). The WeightsBase
%   abstract weight properties are bare (no size/type validators): they are
%   inherited abstract properties, and an abstract property cannot carry
%   validation, so the concrete override declares them plainly (W_TO = NaN etc.),
%   matching BrandtWeightAdapter.
%   ============================================================================
%
%   CONSTRUCTOR: B777WeightsL1(json_path, geom, prop) -- all three REQUIRED, no
%   silent default. Reads the top-level aircraft_category + the .weights baseline
%   block; the baseline tail areas are computed ONCE here (see below).
%
%   BASELINE TAIL AREAS ARE SELF-CONSISTENT. S_ht_baseline / S_vt_baseline are
%   NOT JSON inputs -- they are computed in the constructor from a baseline
%   B777GeomL1-equivalent geometry (S_ref/AR/S_wet_rest/L_fus at the actual
%   777-200LR design point) sized through B777TailL1. This guarantees the
%   baseline tail delta is exactly zero when geom's tail areas equal the baseline
%   sizing, rather than depending on a hand-entered baseline that could drift from
%   the tail toolbox.
%
%   Inheritance: WeightsBase -> WeightsModelL1 -> B777WeightsL1
%
%   FIDELITY CAVEAT (BY DESIGN). engine_weight_roskam and tsfc_mattingly_hibpr
%   are metabook-method regressions; both OVERESTIMATE the real GE90 (the Roskam
%   sum vs. the ~17300 lb metabook Table 10.1 uninstalled figure). That is a
%   metabook-fidelity choice, not an error -- the comparison report annotates it.
%
%   SOURCES:
%     [metabook] AE481 metabook Example 4.2 §4.12.1 Algorithm 2,
%       docs/reference_extracts/metabook_data.md. Baseline W0/S/T [Table 4.3 /
%       Fig. 4.7]. [Raymer] Table 3.1 (We/W0), Table 15.2 (areal densities).
%       [Roskam] engine-weight regression Eqs. 7.13-7.19.

    % ======================================================================= %
    % INPUTS -- baseline design-point spec + payload + injected collaborators.
    % Plain mutable properties, set once by the constructor. OEW recomputes from
    % these (and the live injected geom/prop) on every call.
    % ======================================================================= %
    properties
        aircraft_category = "jet_transport"  % WeightsModelL1 contract; selects the Raymer Table 3.1 We/W0 row + the Table 15.2 areal densities [top-level canonical key]

        % ----- Baseline design point (fixed reference of the delta model) ----- %
        W0_baseline           = 766800   % lbf  design-point MTOW  [metabook Table 4.3 / Fig. 4.7]
        S_ref_baseline        = 4605     % ft^2 design-point wing area [metabook Table 4.3]
        T_baseline_per_engine = 110000   % lbf  design-point per-engine SLS thrust [_TODO stand-in; metabook Fig. 4.7 caption total 220000 / 2]
        S_ht_baseline         = NaN      % ft^2 baseline HT area -- computed SELF-CONSISTENTLY in the constructor (B777GeomL1 baseline -> B777TailL1), not a JSON input
        S_vt_baseline         = NaN      % ft^2 baseline VT area -- computed SELF-CONSISTENTLY in the constructor

        % ----- WeightsBase abstract properties (bare; see class header) ----- %
        W_TO                 = NaN       % lbf  candidate gross takeoff weight; STATE, mutated by the sizing loop [WeightsBase contract]
        W_energy             = NaN       % lbf  internal fuel; STATE, set by mission analysis [WeightsBase contract]
        W_payload_expendable = 0         % lbf  expendable payload -- a transport carries none in this model (all payload is fixed) [b777_L1.md §5.3]
        W_payload_fixed      = 145000    % lbf  design payload at the range point (realistic 2-class 777-200LR; _TODO not pinned to a Boeing payload-range chart; b777_L1.md §5.3)

        % ----- Injected collaborators (NOT numeric spec data) ----- %
        geom   % (1,1) GeometryBase -- supplies the CURRENT S_ref / S_ht / S_vt (tail write-back slots) live
        prop   % (1,1) PropulsionBase -- supplies the CURRENT T_SL and n_engines for the engine-weight delta
    end

    methods

        function obj = B777WeightsL1(json_path, geom, prop)
        %B777WEIGHTSL1  Construct from a required spec JSON path, a required
        %   injected geometry object and a required injected propulsion object.
        %   No silent default on any of the three. Sets the baseline / payload
        %   inputs from the .weights block and computes the SELF-CONSISTENT
        %   baseline tail areas once (baseline B777GeomL1 -> B777TailL1). W_TO and
        %   W_energy stay NaN (sizing-loop / mission STATE).
            arguments
                json_path       {mustBeTextScalar, mustBeNonzeroLengthText}
                geom      (1,1) GeometryBase
                prop      (1,1) PropulsionBase
            end
            J = jsondecode(fileread(json_path));

            obj.geom = geom;   % injected: current S_ref / S_ht / S_vt
            obj.prop = prop;   % injected: current T_SL / n_engines

            obj.aircraft_category     = string(J.aircraft_category);        % [top-level canonical key]
            obj.W0_baseline           = J.weights.W0_baseline;              % [metabook Table 4.3]
            obj.S_ref_baseline        = J.weights.S_baseline;               % [metabook Table 4.3]
            obj.T_baseline_per_engine = J.weights.T_baseline_per_engine;    % [_TODO; metabook Fig. 4.7]
            obj.W_payload_fixed       = J.weights.W_payload;                % [_TODO; b777_L1.md §5.3]

            % Baseline tail areas, computed SELF-CONSISTENTLY (see class header):
            % a baseline geometry at the actual 777-200LR design point, sized
            % through the same B777TailL1 the live geometry uses. So the baseline
            % tail delta is exactly zero when geom's tail equals this sizing.
            base_geom = B777GeomL1(json_path);        % baseline S_ref/AR/S_wet_rest/L_fus from the same spec
            base_tail = B777TailL1().size(base_geom.S_ref, base_geom.b_wing, ...
                                          base_geom.cbar_wing, base_geom.L_fus);
            obj.S_ht_baseline = base_tail.S_ht;
            obj.S_vt_baseline = base_tail.S_vt;

            % W_TO and W_energy are deliberately NOT read: both are sizing-loop /
            % mission STATE and stay NaN until set.
        end

        % ================================================================== %
        % WeightsModelL1 abstract methods -- single delegations to WeightsL1.
        % ================================================================== %

        function frac = compute_We_fraction(obj, W_TO, aircraft_category)
        %COMPUTE_WE_FRACTION  We/W_TO = Kvs*A*W_TO^C [Raymer Table 3.1].
        %   aircraft_category defaults to obj.aircraft_category when omitted.
            if nargin < 3
                aircraft_category = obj.aircraft_category;
            end
            frac = WeightsL1.compute_We_fraction(obj, W_TO, aircraft_category);
        end

        function W_E = compute_We_roskam(obj, W_TO)
        %COMPUTE_WE_ROSKAM  Roskam log-log minimum empty weight [lbf] -- a LOWER
        %   BOUND, never summed into OEW. [Roskam Part I Eq. 2.16]
            W_E = WeightsL1.compute_We_roskam(obj, W_TO);
        end

        % ================================================================== %
        % OEW -- metabook §4.12.1 Algorithm 2 delta-weight model. Recomputed on
        % every call at the PASSED W_TO (WeightsBase contract); the We/W0 term
        % uses the passed W_TO, the four deltas use the live injected geom/prop.
        % ================================================================== %

        function oew = OEW(obj, W_TO)
        %OEW  Operating empty weight [lbf] at the PASSED W_TO.
        %   [metabook §4.12.1 Algorithm 2] -- see the class header for the full
        %   equation. Every W_TO-dependent term (the regression) is evaluated at
        %   the PASSED W_TO, not obj.W_TO. The area/thrust deltas read the live
        %   injected geom/prop, so an optimizer mutating geom.S_ref or prop.T_SL
        %   flows straight through here.
            arguments
                obj
                W_TO (1,1) double {mustBePositive, mustBeFinite}
            end

            % 1. Empty-weight-fraction regression at the passed W_TO.
            We_regression = obj.compute_We_fraction(W_TO) * W_TO;   % [Raymer Table 3.1]

            % 2. Areal-density deltas from the baseline design point.
            dens_wing = WeightsL2.wing_unit_weight(char(obj.aircraft_category)); % 10 [Table 15.2]
            dens_HT   = WeightsL2.HT_unit_weight(char(obj.aircraft_category));   % 5.5 [Table 15.2]
            dens_VT   = WeightsL2.VT_unit_weight(char(obj.aircraft_category));   % 5.5 [Table 15.2]

            dWing = dens_wing * (obj.geom.S_ref - obj.S_ref_baseline);
            dHT   = dens_HT   * (obj.geom.S_ht  - obj.S_ht_baseline);
            dVT   = dens_VT   * (obj.geom.S_vt  - obj.S_vt_baseline);

            % 3. Engine-weight delta: current per-engine thrust vs. baseline,
            %    scaled by engine count. Current thrust from the injected prop
            %    (NOT the JSON baseline). [Roskam Eqs. 7.13-7.19]
            n_eng = obj.prop.n_engines;
            T_per_engine_now = obj.prop.T_SL / n_eng;
            dEngine = n_eng * ( WeightsL1.engine_weight_roskam(T_per_engine_now) ...
                              - WeightsL1.engine_weight_roskam(obj.T_baseline_per_engine) );

            oew = We_regression + dWing + dHT + dVT + dEngine;
        end

    end

end
