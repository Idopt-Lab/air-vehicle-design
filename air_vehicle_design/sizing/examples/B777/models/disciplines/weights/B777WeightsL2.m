classdef B777WeightsL2 < WeightsModelL2
%B777WEIGHTSL2  Boeing 777-200LR Level-2 weight estimation: the metabook
%   Chapter 7 component build-up (Algorithm 5, Example 7.1).
%
%   Inherits WeightsModelL2 -- the aircraft-agnostic Tier-2 enforcer for this
%   build-up (surface density x area for the structural groups, plus fractions of
%   gross weight for landing gear, installed engine and all-else-empty). Every
%   abstract member delegates to the WeightsL2 toolbox (same toolbox as
%   F16WeightsL2). The per-aircraft differences from the F-16 are the
%   `jet_transport` category (Table 15.2 transport densities + the 0.043
%   landing-gear fraction), the Roskam engine model (Eqs. 7.13-7.19 vs the
%   fighter's Raymer Eq. 10.10), and no strake term.
%
%   OEW = W_wings + W_tail.HT + W_tail.VT + W_fuselage + W_landing_gear
%         + W_installed_engine + W_all_else_empty
%       = 10·S_exp_wing + 5.5·S_exp_ht + 5.5·S_exp_vt + 5·S_wet_fus
%         + 0.043·W0 + 1.3·n·Wengine(T0) + 0.17·W0
%
%   Responds to all three sizing variables: W0 (gear + all-else fractions),
%   S_ref (injected geom's exposed wing area), T0 (injected prop's thrust into
%   the Roskam engine weight).
%
%   TWO METABOOK NOTES (docs/reference_extracts/metabook_data.md §7.2):
%     * INSTALLED-ENGINE 1.3x (D8): Table 7.1/7.3 apply the 1.3x, so
%       WeightsL2.compute_weight_installed_engine applies it too.
%     * ENGINE THRUST (D9): Table 7.3 reproduces at T0 = 89,000/engine, but the
%       constraint/T-S diagrams use 220,000 total. This class feeds the SIZING
%       prop.T_SL into the Roskam weight (USER decision), so OEW ~ 334k (+4% vs
%       actual 320k, the Roskam regression over-predicts the GE90).
%
%   DEPENDENCY INJECTION: geom (B777GeomL2) supplies exposed areas + fuselage
%   wetted area; prop (B777PropL1) supplies T_SL and n_engines. Only
%   W_TO/W_energy/payload/category are stored; every group/component weight is a
%   Dependent getter recomputed live (optimization-ready, as F16WeightsL2).
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

        function oew = get_OEW_major_component_buildup(obj, W_TO)
        %OEW  Component build-up at the PASSED W_TO [metabook §7.2 Algorithm 5].
        %   Landing gear and all-else scale with the PASSED W_TO, not obj.W_TO.
        %   No strake term: the 777 has none.
            arguments
                obj
                W_TO (1,1) double {mustBePositive, mustBeFinite}
            end
            cat = obj.aircraft_category;
            tail = obj.weight_tail(W_TO);
            oew = obj.get_wing_weight(W_TO) + tail.HT + tail.VT ...
                + obj.weight_fuselage(W_TO) + obj.weight_landing_gear(W_TO) ...
                + WeightsL2.compute_weight_installed_engine(cat, obj.N_en, obj.W_en) ...
                + WeightsL2.compute_weight_all_else_empty(cat, W_TO);
        end

        function W = get_wing_weight(obj, ~)
            W = WeightsL2.compute_weight_wing(obj.aircraft_category, obj.S_w);
        end
        function W = weight_tail(obj, ~)
            W = struct('HT', WeightsL2.compute_weight_HT(obj.aircraft_category, obj.S_ht), ...
                       'VT', WeightsL2.compute_weight_VT(obj.aircraft_category, obj.S_vt));
        end
        function W = weight_fuselage(obj, ~)
            W = WeightsL2.compute_weight_fuselage(obj.aircraft_category, obj.S_wet_fus);
        end
        function W = weight_landing_gear(obj, W_TO)
            W = WeightsL2.compute_weight_landing_gear(obj.aircraft_category, W_TO);
        end

        % ================================================================== %
        % DERIVED getters -- recompute live on every read.
        % ================================================================== %

        function v = get.N_en(obj),      v = obj.prop.n_engines;            end
        function v = get.S_w(obj),       v = obj.geom.S_exposed_wing;       end
        function v = get.S_ht(obj),      v = obj.geom.S_exposed_ht;         end
        function v = get.S_vt(obj),      v = obj.geom.S_exposed_vt;         end
        function v = get.S_wet_fus(obj), v = obj.geom.get_S_wet_fuselage(); end

        function v = get.W_en(obj)
            % UNINSTALLED single-engine Roskam weight at the per-engine thrust
            % [metabook Eqs. 7.13-7.19]; the 1.3x is applied in W_installed_engine.
            v = WeightsL2.jet_engine_weight_roskam(obj.prop.T_SL / obj.N_en);
        end

        % Structural groups + engine carry no W_TO dependence.
        function v = get.W_wings(obj),     v = obj.get_wing_weight([]);   end
        function v = get.W_tail(obj),      v = obj.weight_tail([]);       end
        function v = get.W_fuselage(obj),  v = obj.weight_fuselage([]);   end
        function v = get.W_installed_engine(obj)
            v = WeightsL2.compute_weight_installed_engine( ...
                    obj.aircraft_category, obj.N_en, obj.W_en);
        end
        % Landing gear and all-else-empty scale with W_TO, so a read before W_TO
        % is set fails loudly (mirrors F16WeightsL2.requireWTO).
        function v = get.W_landing_gear(obj)
            v = WeightsL2.compute_weight_landing_gear( ...
                    obj.aircraft_category, obj.requireWTO('W_landing_gear'));
        end
        function v = get.W_all_else_empty(obj)
            v = WeightsL2.compute_weight_all_else_empty( ...
                    obj.aircraft_category, obj.requireWTO('W_all_else_empty'));
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
