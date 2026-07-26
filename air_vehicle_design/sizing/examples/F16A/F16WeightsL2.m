classdef F16WeightsL2 < WeightsModelL2
%F16WEIGHTSL2  F-16A Block 10/15 Level-2 weight estimation student class.
%
%   Inherits from WeightsModelL2 (abstract enforcer).  Every abstract method is
%   satisfied by a single delegation line to WeightsL2 statics — no equations
%   are duplicated here.
%
%   METHOD:
%     Structural group — Raymer 7th ed. Table 15.2 surface density (psf × area):
%       wing 9, HT 4, VT 5.3 lbf/ft^2 on the EXPOSED planform areas;
%       fuselage 4.8 lbf/ft^2 on the WETTED area.
%     Engine + all-else — AE481 metabook Sec. 7 "Fraction-Based Weight
%       Estimates" table: LG 0.033·W_TO, installed engine 1.3 × bare,
%       all-else-empty 0.17·W_TO. ! These three are NOT Raymer Table 15.2
%       (settled 2026-07-25, todo §P4-7) — Table 15.2 is the psf table only.
%
%   OEW = W_wings + W_tail.HT + W_tail.VT + W_fuselage + W_landing_gear
%         + W_installed_engine + W_all_else_empty
%
%   Call WeightsL1.compute_We_roskam(obj, W_TO) for the L1 Roskam lower bound to
%   compare this buildup against.
%
%   VALUES at W_TO = 31,377 lbf (computed live 2026-07-25):
%     wing 1766.03 | HT 199.39 | VT 216.72 | fuselage 3505.45
%     LG 1035.44 | installed engine 3607.53 | all-else 5334.09
%     OEW = 15664.65 lbf   (-21.60 % vs Brandt Wt!B12 = 19980.70;
%                           -18.19 % vs corrections.xls 19148.08)
%     OEW(45000) = 18430.12 lbf — and it MOVES, which it did not before
%                           (review finding #5, see below).
%   With the Brandt engine-weight alternate instead: OEW = 16787.35 (-15.98 %).
%
%   ============================================================================
%   INPUT vs DERIVED — the optimization-ready pattern (CLAUDE.md; reference
%   implementation examples/F16A/F16GeomL2.m, whose header carries the full
%   rationale).  7 INPUTS (6 numeric + 1 string) + 2 injected objects; 12 DERIVED.
%
%     (1) INPUTS — a plain, mutable `properties` block: the genuine spec /
%         requirement / mission numbers, set once by the constructor (the two
%         state variables are mutated by the sizing and mission loops).
%     (2) DERIVED — a `properties (Dependent)` block: the four geometry
%         quantities and two engine weights that arrive by dependency injection,
%         plus the six component/group weights. Each `get.<name>` recomputes
%         live on every read; there is NO stored copy, so nothing can go stale.
%         Read-only (no set-methods) — assigning errors, which is correct: they
%         are outputs.
%
%   ★ TWO DEFECTS THIS CONVERSION REMOVES — both were in this file:
%
%   REVIEW FINDING #5 — W_all_else_empty was FROZEN at a Brandt output.
%     The old constructor read, verbatim:
%         obj.W_all_else_empty = WeightsL2.weight_all_else_empty(obj, 31377);
%     Two separate defects in one line:
%       (a) Stale under mutation. OEW(45000) carried an all-else group of
%           0.17·31377 = 5334.09 where 0.17·45000 = 7650.00 is required —
%           UNDERSTATED BY 2315.91 lbf (reproduced live 2026-07-25). Every
%           TestWeightsL2 case called OEW(31377), the single argument at which
%           the bug is invisible, which is why no test caught it.
%       (b) 31,377 is Brandt Wt!B3 = 31377.000000 (live, formula =Main!O15) — a
%           sizing OUTPUT, explicitly forbidden as an input by CLAUDE.md ("do not
%           hardcode Brandt's back-calculated calibration values"). The old
%           comment even labelled it "Brandt B38".
%     W_all_else_empty is now Dependent = 0.17·obj.W_TO, and WeightsL2.OEW
%     recomputes the term at its own W_TO argument.
%
%   REVIEW FINDING #12 — four "computed total" properties could read NaN.
%     W_wings / W_landing_gear / W_tail / W_fuselage were satisfied with `= NaN`
%     and NO code ever assigned them (WeightsL2.OEW computed locally and
%     discarded), so a consumer reading the documented contract got NaN. All four
%     are now Dependent. A property documented as computed can no longer read NaN.
%   todo 2026-07-24 §3c items 1 and 6; docs/weights_parameter_usage.md F.2.
%   ============================================================================
%
%   CONSTRUCTOR (CHANGED 2026-07-25, Phase 4):
%     F16WeightsL2(json_path, req_path, geom, prop)  — all four REQUIRED.
%       json_path — f16a_spec_path(2): top-level aircraft_category + .weights.
%       req_path  — f16a_requirements_path(): design_mach (a REQUIREMENT, not
%                   spec data, hence the separate fidelity-independent file).
%       geom      — (1,1) GeometryModelL2. The type guard is deliberately at the
%                   L2 ENFORCER, not GeometryBase: GeometryModelL2 abstractly
%                   declares all four members this class reads (S_exposed_wing,
%                   S_exposed_ht, S_exposed_vt, get_S_wet_fuselage), so a wrong
%                   tier fails at CONSTRUCTION rather than resolving property
%                   names to different physical quantities mid-run — the
%                   finding-#10 lesson from the Phase-2d aero pass.
%       prop      — (1,1) PropulsionBase; supplies T_SL and bypass_ratio.
%     No silent default anywhere: a defaulted injection would silently re-freeze
%     engine or geometry data, which is the defect class Phase 4 removes.
%
%   SOURCES:
%     [Brandt]  Brandt F-16A.xls, sheet "Wt" — validation targets ONLY, never a
%               calibration input. Brandt's own psf coefficients (wing 6.75,
%               fuselage 5.0, pitch 6.0, VT 6.0, live-read Wt!C7:H7) are a
%               DIFFERENT model and are never used here.
%     [Raymer]  D.P. Raymer, Aircraft Design 7th ed., AIAA, Table 15.2.
%     [AE481]   AE481 Aircraft Design Metabook Sec. 7, Fraction-Based Weight
%               Estimates table (installed engine, all-else-empty, LG fraction).
%     [TO]      T.O. 1F-16A-1, USAF/EPAF F-16A/B Blocks 10/15.

    % ======================================================================= %
    % INPUTS (6 numeric + 1 string) + 2 injected objects — plain mutable
    % properties, set once by the constructor. Every DERIVED property below
    % recomputes live from these (and from the injected objects) on every read.
    % Authoritative table with all citations: F16WeightsL2.md §B.1.
    % ======================================================================= %
    properties
        aircraft_category = 'jet_fighter'  % selects the Raymer Tbl 15.2 psf row and the metabook Sec. 7 LG fraction [f16a_L2.json top-level aircraft_category — ONE canonical class flag per aircraft]

        N_en        = 1     % --   number of engines [T.O. 1F-16A-1 Sec. I]. Not derivable: no propulsion class exposes an engine count (geom.n_engines exists only as a .geometry stopgap, todo 2026-07-25 Phase 2 §22)

        design_mach = 2.0   % --   design maximum Mach; feeds Raymer 7th ed. Eq. 10.10's M^0.25 for W_en. From f16a_requirements.json, NOT the .weights block: it is an aircraft REQUIREMENT, not weights spec data. [Brandt Main! aircraft.Mmax = 2.0; GroundTruth/f16a_geometry.json:9 "Mmax": 2.0] ★ NOT the T.O. 1F-16A-1 operating Mach LIMIT, which is a DIFFERENT number, 2.05 [GroundTruth/f16a_ground_truth.json:228]. 2.0 != 2.05 (-2.44 %); live W_en sensitivity 2775.0210 -> 2792.2046 (+0.62 %). Citing 2.0 to the T.O. would attribute a Brandt input to a primary document that says otherwise — todo 2026-07-25 Phase 4 §P4-13

        % ----- WeightsBase abstract properties -----
        W_TO               = NaN   % lbf  candidate gross takeoff weight; STATE — the optimizer's variable, mutated in place by the sizing loop [WeightsBase contract]
        W_energy           = NaN   % lbf  internal fuel; STATE, set by mission analysis [WeightsBase contract]. ! Was 6296.3 = Brandt Wt!B6 (=B3-B4-B5-B12, live formula), a back-calculated OUTPUT — forbidden as an input. Deleted from the JSON in Phase 3
        W_payload_expendable = 4400 % lbf  expendable payload (stores) [Brandt Wt!B5 = 4400.000000 (live), =Main!O17]
        W_payload_fixed    = 700   % lbf  fixed equipment + crew [Brandt Wt!B4 = 700.000000 (live), =Main!O16]
        % ! Both payload values are currently INERT — no WeightsL* static reads
        %   them (grepped 2026-07-25). They satisfy the WeightsBase closure
        %   contract for the future sizing loop.

        % ----- Injected collaborators (NOT numeric spec data) -----
        geom   % (1,1) GeometryModelL2 — supplies the four EXPOSED/WETTED areas below by DI, replacing four hardcoded literals (review finding #11's L2 half)
        prop   % (1,1) PropulsionBase  — supplies T_SL and bypass_ratio for Raymer Eq. 10.10, replacing a hardcoded W_en = 3030 [estimate]
    end

    % ======================================================================= %
    % DERIVED (12) — recomputed live from the inputs / injected objects on every
    % read. No cache, never stale. Read-only: assigning to any of these errors
    % (there are no set-methods), which is correct — they are outputs.
    % Authoritative table with all citations: F16WeightsL2.md §B.2.
    % ======================================================================= %
    properties (Dependent)
        % -- Geometry, by DI from the injected geom (4) -------------------- %
        S_w         % ft^2  EXPOSED wing planform area   = geom.S_exposed_wing (196.2261)
        S_ht        % ft^2  EXPOSED HT planform area      = geom.S_exposed_ht  (49.8473) — NOT geom.S_ht = 108 (FULL)
        S_vt        % ft^2  EXPOSED VT planform area      = geom.S_exposed_vt  (40.8897) — NOT geom.S_vt = 60 (FULL)
        S_wet_fus   % ft^2  fuselage WETTED area          = geom.get_S_wet_fuselage() (730.3023)

        % -- Engine weight, by DI from the injected prop (2) --------------- %
        W_en        % lbf  OFFICIAL, UNINSTALLED [Raymer 7th ed. Eq. 10.10] = 2775.0210
        W_en_brandt % lbf  ALTERNATE, already installed [Brandt Wt!B11] = 4730.2300 — comparison report only, NEVER summed into OEW

        % -- Component / group weights (6) — WeightsModelL2's abstract set -- %
        W_wings            % lbf  [Raymer 7th ed. Tbl 15.2]  9.0 · S_w        = 1766.03
        W_tail             % struct(HT, VT) lbf [Tbl 15.2]  4.0·S_ht / 5.3·S_vt = 199.39 / 216.72
        W_fuselage         % lbf  [Raymer 7th ed. Tbl 15.2]  4.8 · S_wet_fus  = 3505.45
        W_landing_gear     % lbf  [AE481 metabook Sec. 7]    0.033 · W_TO     = 1035.44 at 31377
        W_installed_engine % lbf  [AE481 metabook Sec. 7]    1.3 · N_en · W_en = 3607.53
        W_all_else_empty   % lbf  [AE481 metabook Sec. 7]    0.17 · W_TO      = 5334.09 at 31377 / 7650.00 at 45000 — ★ this is review finding #5
    end

    methods

        function obj = F16WeightsL2(json_path, req_path, geom, prop)
        %F16WEIGHTSL2  Construct from a required spec JSON path, a required
        %   requirements JSON path, a required injected L2 geometry object and a
        %   required injected propulsion object. NO silent default on any of the
        %   four. Sets ONLY input properties; every derived quantity is produced
        %   live by its Dependent getter — nothing is computed and frozen here
        %   (that was review finding #5).
        %
        %   geom must be a GeometryModelL2 subclass: only S_exposed_wing,
        %   S_exposed_ht, S_exposed_vt and get_S_wet_fuselage() are read.
        %   prop must be a PropulsionBase subclass: only T_SL and bypass_ratio
        %   are read, both for Raymer Eq. 10.10.
            arguments
                json_path       {mustBeTextScalar, mustBeNonzeroLengthText}
                req_path        {mustBeTextScalar, mustBeNonzeroLengthText}
                geom      (1,1) GeometryModelL2
                prop      (1,1) PropulsionBase
            end
            J = jsondecode(fileread(json_path));
            R = jsondecode(fileread(req_path));

            obj.geom = geom;   % injected: supplies the four Dependent areas
            obj.prop = prop;   % injected: supplies Eq. 10.10's T and BPR

            % ---- spec / mission (f16a_L2.json) --------------------------- %
            obj.aircraft_category    = char(J.aircraft_category);       % [f16a_L2.json top-level]
            obj.N_en                 = J.weights.N_en;                  % [T.O. 1F-16A-1 Sec. I]
            obj.W_payload_fixed      = J.weights.W_payload_fixed;       % [Brandt Wt!B4]
            obj.W_payload_expendable = J.weights.W_payload_expendable;  % [Brandt Wt!B5]

            % ---- requirements (f16a_requirements.json) ------------------- %
            %      Cited to BRANDT, not to the T.O. — see the property comment.
            obj.design_mach = R.design_mach;                            % 2.0 [Brandt Main! aircraft.Mmax]

            % W_TO and W_energy are deliberately NOT read: both are sizing-loop /
            % mission-analysis STATE and stay NaN until set.
        end

        % ================================================================== %
        % Methods required by the abstract contract — each a single delegation
        % into the WeightsL2 static toolbox, which holds the cited equations and
        % reads the Dependent properties above live.
        % ================================================================== %

        function oew = OEW(obj, W_TO)
        %OEW  Operating empty weight [lbf] at the PASSED W_TO.
        %   [Raymer 7th ed. Table 15.2 + AE481 metabook Sec. 7]
        %   Every W_TO-scaling term (landing gear, all-else-empty) is recomputed
        %   inside WeightsL2.OEW at this argument, NOT read off obj.W_TO.
            oew = WeightsL2.OEW(obj, W_TO);
        end

        function W = weight_wing(obj, W_TO)
            W = WeightsL2.weight_wing(obj, W_TO);
        end

        function W = weight_tail(obj, W_TO)
            W = WeightsL2.weight_tail(obj, W_TO);
        end

        function W = weight_fuselage(obj, W_TO)
            W = WeightsL2.weight_fuselage(obj, W_TO);
        end

        function W = weight_landing_gear(obj, W_TO)
            W = WeightsL2.weight_landing_gear(obj, W_TO);
        end

        % ================================================================== %
        % DERIVED-property getters — recompute live on every read.
        % ================================================================== %

        % ---- Geometry, by DI (the exposed-vs-FULL name trap) -------------- %
        function v = get.S_w(obj)
            % Raymer Table 15.2 takes the EXPOSED planform area.
            % [Brandt Geom!7 exposed-S wing row; readme_geom.md §4.3] via
            % GeomL2.compute_S_exposed_horizontal. Replaces a stored 196.23.
            v = obj.geom.S_exposed_wing;
        end
        function v = get.S_ht(obj)
            % ★ NAME TRAP: geom.S_exposed_ht (49.8473), NOT geom.S_ht = 108.
            % After the Phase-2 geometry rename, S_ht/S_vt/AR_ht/lambda_ht mean
            % FULL planform on BOTH geometry tiers; Raymer Table 15.2 wants the
            % EXPOSED planform. Wiring geom.S_ht here is silent — no error, a
            % plausible wrong number (docs/weights_parameter_usage.md §B.3).
            v = obj.geom.S_exposed_ht;
        end
        function v = get.S_vt(obj)
            % ★ NAME TRAP: geom.S_exposed_vt (40.8897), NOT geom.S_vt = 60.
            v = obj.geom.S_exposed_vt;
        end
        function v = get.S_wet_fus(obj)
            % Fuselage WETTED area, [Roskam Vol. II Eq. 12.3] via
            % GeomL2.compute_s_wet_fus_cyl = 730.3023 ft^2. Replaces a stored
            % 750 [estimate; verify TO], i.e. -2.627 %: the geometry DI removes
            % an unpinned estimate. Note this term alone takes WETTED area — the
            % three lifting surfaces above take PLANFORM.
            v = obj.geom.get_S_wet_fuselage();
        end

        % ---- Engine weight, by DI ---------------------------------------- %
        function v = get.W_en(obj)
            % OFFICIAL: Raymer 7th ed. Eq. 10.10, UNINSTALLED —
            %   W = 0.0637·T^1.1·M^0.25·exp(-0.81·BPR) = 2775.0210 lbf
            % [coefficient confirmed at raymer_data.md:38]. Implemented once, in
            % PropL2.engine_weight_AB; not duplicated here.
            % Replaces a stored W_en = 3030 [estimate; verify TO/Jane's] that was
            % pinned to nothing. T and BPR arrive from the injected prop, M from
            % the requirements file, so mutating prop.T_SL now flows all the way
            % through to W_installed_engine.
            % The metabook's ×1.3 installed factor is applied in
            % W_installed_engine, not here: this property is the BARE weight.
            v = PropL2.engine_weight_AB(obj.prop.T_SL, obj.design_mach, obj.prop.bypass_ratio);
        end
        function v = get.W_en_brandt(obj)
            % ALTERNATE, comparison report ONLY — never summed into OEW.
            % 0.199·T_AB = 4730.2300 lbf [Brandt Wt!B11 = 4730.230000 (live);
            % the 0.199 literal is 'Engn(s)'!D22 (live), label 'Engn(s) Old'!C22
            % = "Engine with AB:  Weng = "; readme_wt.md:230 attributes it to
            % Brandt 1997 Table 6.2 and states it is the INSTALLED formula, so it
            % gets NO ×1.3 — settled decision 1, todo §P4-1a].
            % Brandt's coefficient is never ported into the framework equation;
            % this exists so the report can show his model fed his own thrust as
            % a positive control on the propulsion DI.
            v = WeightsL2.engine_weight_brandt(obj.prop.T_SL);
        end

        % ---- Component / group weights ----------------------------------- %
        % The three structural groups below are NOT guarded on W_TO. Each
        % toolbox method declares its second argument as `~` -- they are pure
        % area x density (Raymer Table 15.2 psf) and carry no W_TO dependence.
        % An earlier version guarded them anyway "for uniformity", which
        % asserted a dependency that does not exist; only the genuinely
        % W_TO-dependent getters below use requireWTO.
        function v = get.W_wings(obj)
            % Was `= NaN`, never assigned (review finding #12).
            v = WeightsL2.weight_wing(obj, obj.W_TO);
        end
        function v = get.W_tail(obj)
            % Was `= NaN`, never assigned (review finding #12).
            v = WeightsL2.weight_tail(obj, obj.W_TO);
        end
        function v = get.W_fuselage(obj)
            % Was `= NaN`, never assigned (review finding #12).
            v = WeightsL2.weight_fuselage(obj, obj.W_TO);
        end
        function v = get.W_landing_gear(obj)
            % Was `= NaN`, never assigned (review finding #12). Genuinely
            % W_TO-dependent (0.033·W_TO), so freezing it was never an option.
            v = WeightsL2.weight_landing_gear(obj, obj.requireWTO('W_landing_gear'));
        end
        function v = get.W_installed_engine(obj)
            % 1.3 · N_en · W_en = 3607.5273 lbf [AE481 metabook Sec. 7,
            % metabook_data.md:333]. The ×1.3 is L2-ONLY (settled decision 1):
            % L3 sums Raymer's installation items individually, so applying it
            % there would double-count.
            % Was computed in the constructor and frozen. That freeze was
            % numerically harmless (this term is W_TO-independent), but it hid
            % W_en behind a literal — now that W_en is Eq. 10.10 on the injected
            % thrust, a frozen copy would go stale the moment prop.T_SL moved.
            v = WeightsL2.weight_installed_engine(obj);
        end
        function v = get.W_all_else_empty(obj)
            % ★ REVIEW FINDING #5, FIXED. 0.17 · obj.W_TO [AE481 metabook Sec. 7,
            % metabook_data.md:334], recomputed live on every read.
            % Previously: WeightsL2.weight_all_else_empty(obj, 31377) evaluated
            % ONCE in the constructor and frozen into a plain property, so
            % OEW(45000) understated by 2315.91 lbf and 31,377 — Brandt Wt!B3, an
            % OUTPUT — had become a calibration input.
            v = WeightsL2.weight_all_else_empty(obj, obj.requireWTO('W_all_else_empty'));
        end

    end

    methods (Access = private)

        function W_TO = requireWTO(obj, whatFor)
        %REQUIREWTO  Return obj.W_TO, erroring if it has not been set.
        %   Applied to EXACTLY the getters that genuinely depend on W_TO:
        %   W_landing_gear (0.033·W_TO) and W_all_else_empty (0.17·W_TO). Both
        %   would otherwise return a silent NaN — the failure mode Phase 1e was
        %   written to eliminate (Phase-1f precedent: F16GeomL1.requireWTO).
        %
        %   NOT applied to W_wings / W_tail / W_fuselage / W_installed_engine.
        %   Those toolbox methods declare their W_TO argument as `~`: the
        %   structural groups are pure area × density (Raymer Table 15.2 psf) and
        %   the engine group is a thrust correlation. An earlier version guarded
        %   all of them "for uniformity", justified as "there is no design point
        %   until a gross weight is chosen". That was wrong on two counts — it
        %   asserted a dependency the formulas do not have, and it was not even
        %   uniform (W_installed_engine was never guarded), so the stated
        %   rationale did not describe the code. A guard should encode a real
        %   dependency, not a house style; if a formula later gains a W_TO term,
        %   add the guard then.
        %   Per-component weights are also reachable through the toolbox statics
        %   (WeightsL2.weight_wing(obj, W_TO) etc.), which is what OEW(W_TO) uses.
            W_TO = obj.W_TO;
            if ~isfinite(W_TO) || W_TO <= 0
                error('F16WeightsL2:WTONotSet', ...
                    ['%s is a weight-statement quantity at the current design ', ...
                     'point, so obj.W_TO must be set to a positive value first ', ...
                     '(currently %g). Assign it from the sizing loop''s current ', ...
                     'TOGW iterate, e.g. w2.W_TO = 31377; or call ', ...
                     'OEW(W_TO)/weight_*(W_TO) with an explicit weight.'], ...
                     whatFor, W_TO);
            end
        end

    end

end
