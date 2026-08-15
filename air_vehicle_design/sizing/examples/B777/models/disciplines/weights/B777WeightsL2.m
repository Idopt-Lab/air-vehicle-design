classdef B777WeightsL2 < WeightsModelL2
%B777WEIGHTSL2  Boeing 777-200LR Level-2 weight estimation: the metabook
%   Chapter 7 component build-up (Algorithm 5, Example 7.1).
%
%   Inherits WeightsModelL2 -- the aircraft-agnostic Tier-2 enforcer whose whole
%   purpose is exactly this build-up ("L2 is surface density x area for the
%   structural groups, plus fractions of gross weight for landing gear,
%   installed engine and all-else-empty"). Every abstract member is satisfied by
%   a single delegation into the WeightsL2 static toolbox -- the SAME toolbox
%   F16WeightsL2 uses -- so no equation is duplicated here. The only per-aircraft
%   differences from the F-16 are the category (`jet_transport` -> Table 15.2
%   transport densities + the 0.043 landing-gear fraction), the engine-weight
%   model (Roskam Eqs. 7.13-7.19 vs the fighter's Raymer Eq. 10.10), and the
%   absence of a strake term.
%
%   OEW = W_wings + W_tail.HT + W_tail.VT + W_fuselage + W_landing_gear
%         + W_installed_engine + W_all_else_empty                [WeightsL2.OEW]
%       = 10·S_exp_wing + 5.5·S_exp_ht + 5.5·S_exp_vt + 5·S_wet_fus
%         + 0.043·W0 + 1.3·n·Wengine(T0) + 0.17·W0
%
%   Responds to all three sizing variables: W0 (gear + all-else fractions),
%   S_ref (via the injected geom's exposed wing area), T0 (via the injected
%   prop's thrust into the Roskam engine weight).
%
%   ============================================================================
%   TWO METABOOK NOTES (docs/reference_extracts/metabook_data.md §7.2):
%     * INSTALLED-ENGINE 1.3x (D8). Algorithm 5's pseudocode uses n*Wengine
%       (uninstalled), but Table 7.1/7.3 apply the 1.3x (47,476 = 1.3·36,520)
%       and the 323,778 total includes it. WeightsL2.weight_installed_engine
%       applies the 1.3, per the worked example.
%     * ENGINE THRUST (D9). Table 7.3 reproduces only at T0 = 89,000/engine, but
%       the constraint/T-S diagrams use 220,000 total (110k/engine). This class
%       feeds the SIZING prop.T_SL into the Roskam weight (USER decision
%       2026-08-15), so the engine responds to the real thrust. At 220k the
%       Roskam engine is ~10k heavier than Table 7.3, so OEW ~ 334k (+4% vs
%       actual 320k -- the Roskam regression over-predicts the modern GE90), NOT
%       Table 7.3's 323,778.
%   ============================================================================
%
%   DEPENDENCY INJECTION. geom (B777GeomL2) supplies the EXPOSED areas + fuselage
%   wetted area; prop (B777PropL1) supplies T_SL and n_engines. Never re-read
%   from JSON. INPUT vs DERIVED: only W_TO/W_energy/payload/category are stored;
%   every group/component weight and injected area is a Dependent getter that
%   recomputes live (no cache, never stale under a sizing mutation) -- the same
%   optimization-ready pattern as F16WeightsL2.
%
%   CONSTRUCTOR: B777WeightsL2(json_path, geom, prop) -- all three REQUIRED.
%
%   Inheritance: WeightsBase -> WeightsModelL2 -> B777WeightsL2
%
%   SOURCES: [metabook] §7.2 Algorithm 5 (Table 7.1/7.3); [Raymer] Table 15.2
%   areal densities; [Roskam] engine Eqs. 7.13-7.19. Companion: B777WeightsL2.md.

    % ======================================================================= %
    % INPUTS -- plain mutable properties set once by the constructor. Every
    % DERIVED property below recomputes live from these + the injected objects.
    % ======================================================================= %
    properties
        aircraft_category = 'jet_transport'  % selects the Table 15.2 transport densities + the 0.043 landing-gear fraction [top-level canonical key]

        % ----- WeightsBase abstract properties -----
        W_TO                 = NaN    % lbf  candidate gross takeoff weight; STATE, mutated by the sizing loop
        W_energy             = NaN    % lbf  internal fuel; STATE, set by mission analysis
        W_payload_expendable = 0      % lbf  a transport carries no expendable payload
        W_payload_fixed      = 78821  % lbf  crew + passengers = (14 + 314) x 109 kg [metabook Example 2.1]

        % ----- Injected collaborators (NOT numeric spec data) -----
        geom   % (1,1) GeometryModelL2 -- supplies the EXPOSED areas + fuselage wetted area (B777GeomL2)
        prop   % (1,1) PropulsionBase -- supplies T_SL and n_engines
    end

    % ======================================================================= %
    % DERIVED -- recomputed live on every read. Read-only (no set-methods).
    % ======================================================================= %
    properties (Dependent)
        % -- Geometry / propulsion, by DI ------------------------------------ %
        N_en        % --    engine count = prop.n_engines (WeightsL2 engine term reads obj.N_en)
        S_w         % ft^2  EXPOSED wing planform   = geom.S_exposed_wing
        S_ht        % ft^2  EXPOSED H-tail planform = geom.S_exposed_ht
        S_vt        % ft^2  EXPOSED V-tail planform = geom.S_exposed_vt
        S_wet_fus   % ft^2  fuselage WETTED area    = geom.get_S_wet_fuselage()
        W_en        % lbf   UNINSTALLED single-engine weight [Roskam Eqs. 7.13-7.19] at T0 = prop.T_SL/n

        % -- Component / group weights (6) -- WeightsModelL2's abstract set --- %
        W_wings            % lbf  10.0 · S_w        [Table 15.2 transport]
        W_tail             % struct(HT, VT) lbf  5.5·S_ht / 5.5·S_vt [Table 15.2]
        W_fuselage         % lbf  5.0 · S_wet_fus   [Table 15.2, on WETTED area]
        W_landing_gear     % lbf  0.043 · W_TO      [metabook Table 7.1 transport]
        W_installed_engine % lbf  1.3 · N_en · W_en [Table 7.1 installed 1.3x]
        W_all_else_empty   % lbf  0.17 · W_TO       [metabook Table 7.1]
    end

    methods

        function obj = B777WeightsL2(json_path, geom, prop)
            arguments
                json_path       {mustBeTextScalar, mustBeNonzeroLengthText}
                geom      (1,1) GeometryModelL2
                prop      (1,1) PropulsionBase
            end
            J = jsondecode(fileread(json_path));
            obj.geom = geom;
            obj.prop = prop;
            obj.aircraft_category = char(J.aircraft_category);
            obj.W_payload_fixed   = J.weights.W_payload;   % [metabook Example 2.1]
            % W_TO / W_energy stay NaN (sizing-loop / mission STATE).
        end

        % ================================================================== %
        % Abstract-contract methods -- single delegations to the WeightsL2
        % static toolbox (the same equations F16WeightsL2 uses).
        % ================================================================== %

        function oew = OEW(obj, W_TO)
        %OEW  Component build-up at the PASSED W_TO [metabook §7.2 Algorithm 5].
        %   Every W_TO-scaling term (landing gear, all-else) is recomputed inside
        %   WeightsL2.OEW at this argument, not read off obj.W_TO.
            arguments
                obj
                W_TO (1,1) double {mustBePositive, mustBeFinite}
            end
            oew = WeightsL2.OEW(obj, W_TO);
        end

        function W = weight_wing(obj, W_TO),        W = WeightsL2.weight_wing(obj, W_TO);        end
        function W = weight_tail(obj, W_TO),        W = WeightsL2.weight_tail(obj, W_TO);        end
        function W = weight_fuselage(obj, W_TO),    W = WeightsL2.weight_fuselage(obj, W_TO);    end
        function W = weight_landing_gear(obj, W_TO),W = WeightsL2.weight_landing_gear(obj, W_TO);end

        % ================================================================== %
        % DERIVED getters -- recompute live on every read.
        % ================================================================== %

        function v = get.N_en(obj),      v = obj.prop.n_engines;            end
        function v = get.S_w(obj),       v = obj.geom.S_exposed_wing;       end
        function v = get.S_ht(obj),      v = obj.geom.S_exposed_ht;         end
        function v = get.S_vt(obj),      v = obj.geom.S_exposed_vt;         end
        function v = get.S_wet_fus(obj), v = obj.geom.get_S_wet_fuselage(); end

        function v = get.W_en(obj)
            % UNINSTALLED single-engine Roskam weight at the sizing per-engine
            % thrust [metabook Eqs. 7.13-7.19]. The 1.3x installed factor is
            % applied in W_installed_engine, not here (this is the BARE weight).
            v = WeightsL1.engine_weight_roskam(obj.prop.T_SL / obj.N_en);
        end

        % Structural groups + engine are pure area·density / thrust correlations
        % (no W_TO dependence); the toolbox methods declare their W_TO arg as `~`.
        function v = get.W_wings(obj),            v = WeightsL2.weight_wing(obj, obj.W_TO);     end
        function v = get.W_tail(obj),             v = WeightsL2.weight_tail(obj, obj.W_TO);     end
        function v = get.W_fuselage(obj),         v = WeightsL2.weight_fuselage(obj, obj.W_TO); end
        function v = get.W_installed_engine(obj), v = WeightsL2.weight_installed_engine(obj);   end
        % Landing gear (0.043·W_TO) and all-else-empty (0.17·W_TO) GENUINELY
        % scale with W_TO, so a read before W_TO is set must fail loudly, not
        % return a silent NaN (mirrors F16WeightsL2.requireWTO).
        function v = get.W_landing_gear(obj)
            v = WeightsL2.weight_landing_gear(obj, obj.requireWTO('W_landing_gear'));
        end
        function v = get.W_all_else_empty(obj)
            v = WeightsL2.weight_all_else_empty(obj, obj.requireWTO('W_all_else_empty'));
        end

    end

    methods (Access = private)
        function W_TO = requireWTO(obj, whatFor)
        %REQUIREWTO  Return obj.W_TO, erroring if it is not a set positive value.
        %   Applied to the two genuinely W_TO-dependent group getters so they
        %   fail loudly instead of returning a silent NaN. OEW(W_TO) itself takes
        %   W_TO explicitly and does not use these getters.
            W_TO = obj.W_TO;
            if ~isfinite(W_TO) || W_TO <= 0
                error('B777WeightsL2:WTONotSet', ...
                    ['%s scales with gross weight, so obj.W_TO must be set to a ', ...
                     'positive value first (currently %g). Set it from the ', ...
                     'sizing loop, or call OEW(W_TO) with an explicit weight.'], ...
                     whatFor, W_TO);
            end
        end
    end
end
