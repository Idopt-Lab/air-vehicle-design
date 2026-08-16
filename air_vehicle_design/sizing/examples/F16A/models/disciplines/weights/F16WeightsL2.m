classdef F16WeightsL2 < WeightsModelL2
%F16WEIGHTSL2  F-16A Block 10/15 Level-2 weight estimation student class.
%
%   Inherits from WeightsModelL2. Every abstract method delegates to a WeightsL2
%   static. L2 is surface density × area plus fractions:
%     Structural group — Raymer 6th ed. Table 15.2 surface density (psf × area):
%       wing 9, HT 4, VT 5.3 lbf/ft^2 on the EXPOSED planform areas;
%       fuselage 4.8 lbf/ft^2 on the WETTED area.
%     Engine + all-else — AE481 metabook Sec. 7 "Fraction-Based Weight
%       Estimates" table: LG 0.033·W_TO, installed engine 1.3 × bare,
%       all-else-empty 0.17·W_TO. These three are NOT Raymer Table 15.2 (that
%       table is the psf table only).
%
%   OEW = W_wings + W_tail.HT + W_tail.VT + W_fuselage + W_landing_gear
%         + W_installed_engine + W_all_else_empty + W_strake
%
%   The strake (LERX) term is k_strake·S_strake = 90.00 lbf [Brandt Main!D18 /
%   Wt!H7]; see the S_strake/k_strake property comment for the cross-model borrow
%   (Raymer Table 15.2 has no strake row).
%
%   Inputs are mutable spec/requirement data; Dependent getters recompute on
%   read (no stored copy, read-only). 7 inputs + 2 injected objects; 13 Dependent.
%
%   Constructor: F16WeightsL2(json_path, req_path, geom, prop) — all four
%   required, no silent default.
%       json_path — f16a_spec_path(2): aircraft_category + .weights.
%       req_path  — f16a_requirements_path(): design_mach.
%       geom      — GeometryModelL2 or GeometryModelL3 (both declare the four
%                   members read: S_exposed_wing/_ht/_vt, get_S_wet_fuselage).
%       prop      — PropulsionBase; supplies T_SL and bypass_ratio.
%
%   History and rationale: docs/decision_log.md
%
%   SOURCES:
%     [Brandt]  Brandt F-16A.xls, sheet "Wt" — validation targets ONLY, never a
%               calibration input.
%     [Raymer]  D.P. Raymer, Aircraft Design 7th ed., AIAA, Table 15.2.
%     [AE481]   AE481 Aircraft Design Metabook Sec. 7, Fraction-Based Weight
%               Estimates table (installed engine, all-else-empty, LG fraction).
%     [TO]      T.O. 1F-16A-1, USAF/EPAF F-16A/B Blocks 10/15.

    % ======================================================================= %
    % INPUTS (6 numeric + 1 string) + 2 injected objects — mutable spec data.
    % Citations: F16WeightsL2.md §2.
    % ======================================================================= %
    properties
        aircraft_category = 'jet_fighter'  % selects the Raymer Tbl 15.2 psf row and the metabook Sec. 7 LG fraction [f16a_L2.json top-level aircraft_category — ONE canonical class flag per aircraft]

        N_en        = 1     % --   number of engines [T.O. 1F-16A-1 Sec. I]. Not derivable: no propulsion class exposes an engine count

        design_mach = 2.0   % --   design maximum Mach; feeds Raymer 7th ed. Eq. 10.10's M^0.25 for W_en. From f16a_requirements.json (a REQUIREMENT, not weights spec data). [Brandt Main! aircraft.Mmax = 2.0]. NOT the T.O. operating Mach limit 2.05

        % ----- WeightsBase abstract properties -----
        W_TO               = NaN   % lbf  candidate gross takeoff weight; STATE, mutated by the sizing loop [WeightsBase contract]
        W_energy           = NaN   % lbf  internal fuel; STATE, set by mission analysis [WeightsBase contract]
        W_payload_expendable = 4400 % lbf  expendable payload (stores) [Brandt Wt!B5 = Main!O17]
        W_payload_fixed    = 700   % lbf  fixed equipment + crew [Brandt Wt!B4 = Main!O16]
        % Both payload values are inert; they satisfy the WeightsBase closure
        % contract for the sizing loop.

        %S_STRAKE, K_STRAKE  Strake (LERX) structural weight inputs. [Brandt
        %   Main!D18 = 20 ft^2 / Wt!H7 = 4.5 lbf/ft^2]. Cross-model borrow:
        %   Raymer Table 15.2 has no strake row, so Brandt's own coefficient is
        %   the only source; it is a genuine input in his worksheet, not a
        %   back-calculated output. History and rationale: docs/decision_log.md
        S_strake  % ft^2   strake planform reference area   [Brandt Main!D18]
        k_strake  % lbf/ft^2  strake structural surface density [Brandt Wt!H7]

        % ----- Injected collaborators (NOT numeric spec data) -----
        geom   % (1,1) GeometryModelL2 OR GeometryModelL3 — supplies the four EXPOSED/WETTED areas below by DI
        prop   % (1,1) PropulsionBase  — supplies T_SL and bypass_ratio for Raymer Eq. 10.10
    end

    % ======================================================================= %
    % DERIVED (13) — recomputed live on read; read-only.
    % Citations: F16WeightsL2.md §3.
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
        W_wings            % lbf  [Raymer 6th ed. Tbl 15.2]  9.0 · S_w        = 1766.03
        W_tail             % struct(HT, VT) lbf [Tbl 15.2]  4.0·S_ht / 5.3·S_vt = 199.39 / 216.72
        W_fuselage         % lbf  [Raymer 6th ed. Tbl 15.2]  4.8 · S_wet_fus  = 3505.45
        W_landing_gear     % lbf  [AE481 metabook Sec. 7]    0.033 · W_TO     = 1035.44 at 31377
        W_installed_engine % lbf  [AE481 metabook Sec. 7]    1.3 · N_en · W_en = 3607.53
        W_all_else_empty   % lbf  [AE481 metabook Sec. 7]    0.17 · W_TO      = 5334.09 at 31377 / 7650.00 at 45000
        W_strake           % lbf  [Brandt Main!D18 / Wt!H7]  k_strake · S_strake = 90.00 (see S_strake/k_strake property comment)
    end

    methods

        function obj = F16WeightsL2(json_path, req_path, geom, prop)
        %F16WEIGHTSL2  Construct from a required spec JSON path, requirements
        %   JSON path, injected L2/L3 geometry object and injected propulsion
        %   object. No silent default. Sets only input properties.
        %
        %   geom reads S_exposed_wing/_ht/_vt and get_S_wet_fuselage(); prop
        %   reads T_SL and bypass_ratio for Raymer Eq. 10.10.
            arguments
                json_path       {mustBeTextScalar, mustBeNonzeroLengthText}
                req_path        {mustBeTextScalar, mustBeNonzeroLengthText}
                geom      (1,1) {mustBeA(geom, ["GeometryModelL2", "GeometryModelL3"])}
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
            obj.S_strake             = J.weights.S_strake_ft2;          % [Brandt Main!D18]
            obj.k_strake             = J.weights.k_strake_psf;          % [Brandt Wt!H7]

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
        %   [Raymer 6th ed. Table 15.2 + AE481 metabook Sec. 7] + the strake term
        %   (Brandt Main!D18/Wt!H7). Every W_TO-scaling term (landing gear,
        %   all-else-empty) is recomputed inside WeightsL2.OEW at this argument,
        %   not read off obj.W_TO. W_strake is pure area x density, added on top.
            oew = WeightsL2.OEW(obj, W_TO) + obj.W_strake;
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
            v = obj.geom.S_exposed_wing;
        end
        function v = get.S_ht(obj)
            % ★ NAME TRAP: geom.S_exposed_ht (49.8473), NOT geom.S_ht = 108.
            % Raymer Table 15.2 wants the EXPOSED planform; wiring geom.S_ht is
            % silent — no error, a plausible wrong number.
            v = obj.geom.S_exposed_ht;
        end
        function v = get.S_vt(obj)
            % ★ NAME TRAP: geom.S_exposed_vt (40.8897), NOT geom.S_vt = 60.
            v = obj.geom.S_exposed_vt;
        end
        function v = get.S_wet_fus(obj)
            % Fuselage WETTED area [Roskam Vol. II Eq. 12.3] = 730.3023 ft^2.
            % This term alone takes WETTED area; the three surfaces above take
            % PLANFORM.
            v = obj.geom.get_S_wet_fuselage();
        end

        % ---- Engine weight, by DI ---------------------------------------- %
        function v = get.W_en(obj)
            % OFFICIAL: Raymer 7th ed. Eq. 10.10, UNINSTALLED —
            %   W = 0.0637·T^1.1·M^0.25·exp(-0.81·BPR) = 2775.0210 lbf
            % [coefficient at raymer_data.md:38], in PropL2.engine_weight_AB.
            % BARE weight; the ×1.3 installed factor is applied in
            % W_installed_engine.
            v = PropL2.engine_weight_AB(obj.prop.T_SL, obj.design_mach, obj.prop.bypass_ratio);
        end
        function v = get.W_en_brandt(obj)
            % ALTERNATE, comparison report ONLY — never summed into OEW.
            % 0.199·T_AB = 4730.2300 lbf [Brandt Wt!B11; the 0.199 literal is
            % 'Engn(s)'!D22, readme_wt.md:230 attributes it to Brandt 1997
            % Table 6.2 as the INSTALLED formula, so no ×1.3]. Positive control
            % on the propulsion DI.
            v = WeightsL2.engine_weight_brandt(obj.prop.T_SL);
        end

        % ---- Component / group weights ----------------------------------- %
        % The three structural groups are pure area x density (Raymer Table 15.2
        % psf) and carry no W_TO dependence, so they are NOT guarded on W_TO;
        % only the genuinely W_TO-dependent getters below use requireWTO.
        function v = get.W_wings(obj)
            v = WeightsL2.weight_wing(obj, obj.W_TO);
        end
        function v = get.W_tail(obj)
            v = WeightsL2.weight_tail(obj, obj.W_TO);
        end
        function v = get.W_fuselage(obj)
            v = WeightsL2.weight_fuselage(obj, obj.W_TO);
        end
        function v = get.W_landing_gear(obj)
            % Genuinely W_TO-dependent (0.033·W_TO).
            v = WeightsL2.weight_landing_gear(obj, obj.requireWTO('W_landing_gear'));
        end
        function v = get.W_installed_engine(obj)
            % 1.3 · N_en · W_en = 3607.5273 lbf [AE481 metabook Sec. 7,
            % metabook_data.md:333]. The ×1.3 is L2-ONLY: L3 sums Raymer's
            % installation items individually.
            v = WeightsL2.weight_installed_engine(obj);
        end
        function v = get.W_all_else_empty(obj)
            % 0.17 · obj.W_TO [AE481 metabook Sec. 7, metabook_data.md:334],
            % recomputed live on every read.
            v = WeightsL2.weight_all_else_empty(obj, obj.requireWTO('W_all_else_empty'));
        end

        function v = get.W_strake(obj)
            % k_strake * S_strake = 4.5 * 20 = 90.00 lbf [Brandt Wt!H9 = 4.5*20].
            % Pure area x density, no W_TO dependence.
            v = obj.k_strake * obj.S_strake;
        end

    end

    methods (Access = private)

        function W_TO = requireWTO(obj, whatFor)
        %REQUIREWTO  Return obj.W_TO, erroring if it has not been set.
        %   Applied to exactly the getters that depend on W_TO: W_landing_gear
        %   (0.033·W_TO) and W_all_else_empty (0.17·W_TO). Not applied to the
        %   structural groups or the engine group, which carry no W_TO term.
        %   Per-component weights are also reachable via the toolbox statics
        %   (WeightsL2.weight_wing(obj, W_TO) etc.), which OEW(W_TO) uses.
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
