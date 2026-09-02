classdef WeightsL2
%WEIGHTSL2  Level-2 weights static toolbox: surface density x area, plus fractions.
%
%   Call as WeightsL2.method(...); never instantiated. F16WeightsL2 inherits
%   WeightsModelL2 and delegates here.
%
%   Structural groups: [Raymer 6th ed. Table 15.2] psf surface densities on
%   real areas. Landing gear, installed engine and all-else-empty: the AE481
%   metabook Sec. 7 fraction table (a separate, unnumbered table).
%
%   OEW(W_TO) evaluates both fraction terms at the PASSED W_TO. It must not
%   read the W_all_else_empty / W_installed_engine properties, which are pinned
%   to the object's own W_TO.
%
%   Companion doc: src/disciplines/weights/WeightsL2.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function oew = OEW(obj, W_TO)
            W_w   = WeightsL2.weight_wing(obj, W_TO);
            W_t   = WeightsL2.weight_tail(obj, W_TO);
            W_f   = WeightsL2.weight_fuselage(obj, W_TO);
            W_lg  = WeightsL2.weight_landing_gear(obj, W_TO);
            W_ie  = WeightsL2.weight_installed_engine(obj);
            W_ale = WeightsL2.weight_all_else_empty(obj, W_TO);
            oew   = W_w + W_t.HT + W_t.VT + W_f + W_lg + W_ie + W_ale;
        end

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function W = weight_wing(obj, ~)
            rho = WeightsL2.wing_unit_weight(obj.aircraft_category);
            W   = rho * obj.S_w;
        end

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function W = weight_tail(obj, ~)
            rho_ht = WeightsL2.HT_unit_weight(obj.aircraft_category);
            rho_vt = WeightsL2.VT_unit_weight(obj.aircraft_category);
            W.HT = rho_ht * obj.S_ht;
            W.VT = rho_vt * obj.S_vt;
        end

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function W = weight_fuselage(obj, ~)
            rho = WeightsL2.fus_unit_weight(obj.aircraft_category);
            W   = rho * obj.S_wet_fus;
        end

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function W = weight_landing_gear(obj, W_TO)
            f = WeightsL2.LG_fraction(obj.aircraft_category);
            W = f * W_TO;
        end

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function W = weight_installed_engine(obj)
            W = 1.3 * obj.N_en * obj.W_en;
        end

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function W = weight_all_else_empty(~, W_TO)
            W = 0.17 * W_TO;
        end

        % ================================================================== %
        % LOW-LEVEL: unit-weight / fraction lookups, and the Brandt engine
        % alternate. Pure scalars in, scalar out.
        % ================================================================== %

        function W = jet_engine_weight_roskam(T0_lbf)
        %JET_ENGINE_WEIGHT_ROSKAM  Uninstalled weight [lbf] of ONE jet engine
        %   from its SLS thrust, via the Roskam multi-term regression.
        %   TURBOJET / TURBOFAN ONLY -- see the applicability note above.
        %   Turboprops take turboprop_engine_weight_roskam instead.
        %   [Roskam Airplane Design Part V, Eqs. 7.13-7.19, via
        %    docs/reference_extracts/metabook_data.md:607-612. Part V is NOT in
        %    the repo, so these coefficients are secondary-source only.]
        %
        %     Weng_dry     = 0.521 * T0^0.9                 (7.13)
        %     Weng_oil     = 0.082 * T0^0.65                (7.14)
        %     Weng_rev     = 0.034 * T0   [thrust reverser] (7.15)
        %     Weng_control = 0.26  * T0^0.5                 (7.16)
        %     Weng_start   = 9.33  * (Weng_dry/1000)^1.078  (7.18)
        %     Wengine_total = sum of the above              (7.19)
        %
        %   Turboprops take a different equation entirely:
        %     Weng = P^0.9306 * 10^-0.1205, P in shp        (7.20)
        %
        %   T0_lbf -- max SLS thrust per engine [lbf]. Returns the total weight
        %   of ONE engine [lbf]. No Eq. 7.17 term is listed; sum is Eq. 7.19.
            arguments
                T0_lbf (1,1) double {mustBePositive}
            end
            W_dry     = 0.521 * T0_lbf.^0.9;
            W_oil     = 0.082 * T0_lbf.^0.65;
            W_rev     = 0.034 * T0_lbf;
            W_control = 0.26  * T0_lbf.^0.5;
            W_start   = 9.33  * (W_dry / 1000).^1.078;
            W = W_dry + W_oil + W_rev + W_control + W_start;
        end

        function W = turboprop_engine_weight_roskam(P_shp)
        %TURBOPROP_ENGINE_WEIGHT_ROSKAM  Uninstalled weight [lbf] of ONE
        %   turboprop engine from its rated shaft power.
        %   ARGS:
        %       P_shp = Shaft horsepower (hp)
        %   RETURNS:
        %       W = Engine weight (lbf)
        %   CITATION:
        %       Roskam Airplane Design Part V, Eq. 7.20
        %
        %   P_shp -- rated shaft power per engine [shp]. ONE engine's weight.
        %   Unlike the jet form this is a SINGLE term, so it carries no oil,
        %   controls or starter contribution. Do not compare the two totals
        %   term-by-term. _TODO -- does Eq. 7.20 include the propeller and
        %   gearbox? The extract does not say, and Part V is not in the repo.
            arguments
                P_shp (1,1) double {mustBePositive}
            end
            W = P_shp.^0.9306 .* 10.^-0.1205;
        end

        function rho = wing_unit_weight(aircraft_category)
        %WING_UNIT_WEIGHT  Wing structural surface density [lbf/ft^2].
        %   [Raymer 6th ed. Table 15.2; metabook_data.md:321 — all three rows]
            switch lower(aircraft_category)
                case 'jet_fighter',      rho = 9.0;   % fighters [metabook_data.md:321]
                case 'jet_transport',    rho = 10.0;  % transport/bomber [metabook_data.md:321]
                case 'general_aviation', rho = 2.5;   % GA [metabook_data.md:321]
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No wing unit weight for "%s".', aircraft_category);
            end
        end

        function rho = HT_unit_weight(aircraft_category)
        %HT_UNIT_WEIGHT  Horizontal tail structural surface density [lbf/ft^2].
        %   [Raymer 6th ed. Table 15.2; metabook_data.md:322 — all three rows]
            switch lower(aircraft_category)
                case 'jet_fighter',      rho = 4.0;   % fighters [metabook_data.md:322]
                case 'jet_transport',    rho = 5.5;   % transport/bomber [metabook_data.md:322]
                case 'general_aviation', rho = 2.0;   % GA [metabook_data.md:322]
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No HT unit weight for "%s".', aircraft_category);
            end
        end

        function rho = VT_unit_weight(aircraft_category)
        %VT_UNIT_WEIGHT  Vertical tail structural surface density [lbf/ft^2].
        %   [Raymer 6th ed. Table 15.2; metabook_data.md:323 — all three rows]
            switch lower(aircraft_category)
                case 'jet_fighter',      rho = 5.3;   % fighters [metabook_data.md:323]
                case 'jet_transport',    rho = 5.5;   % transport/bomber [metabook_data.md:323]
                case 'general_aviation', rho = 2.0;   % GA [metabook_data.md:323]
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No VT unit weight for "%s".', aircraft_category);
            end
        end

        function rho = fus_unit_weight(aircraft_category)
        %FUS_UNIT_WEIGHT  Fuselage structural surface density [lbf/ft^2].
        %   [Raymer 6th ed. Table 15.2; metabook_data.md:324 — all three rows]
            switch lower(aircraft_category)
                case 'jet_fighter',      rho = 4.8;   % fighters [metabook_data.md:324]
                case 'jet_transport',    rho = 5.0;   % transport/bomber [metabook_data.md:324]
                case 'general_aviation', rho = 1.4;   % GA [metabook_data.md:324]
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No fuselage unit weight for "%s".', aircraft_category);
            end
        end

        function f = LG_fraction(aircraft_category)
            switch lower(aircraft_category)
                case 'jet_fighter',      f = 0.033;  % non-Navy fighter [metabook_data.md:330]
                case 'jet_transport',    f = 0.043;  % transport [metabook_data.md:332]
                case 'general_aviation'
                    % TODO (todo Phase 4 §P4-7, OPEN): 0.057 is UNCITED. The
                    % metabook fraction table (metabook_data.md:328-334) has no
                    % general-aviation row. Do not cite to the metabook until
                    % the user supplies a source. Does not affect the F-16A.
                    f = 0.057;  % [UNCITED — see the TODO above]
                otherwise
                    % NOTE: the extract's Navy-fighter row, 0.045 *W0
                    % [metabook_data.md:331], is deliberately not added — no
                    % consumer. todo §P4-7 (open).
                    error('WeightsL2:UnknownCategory', ...
                          'No LG fraction for "%s".', aircraft_category);
            end
        end

        function W = engine_weight_brandt(T_AB_SLS)
            W = 0.199 * T_AB_SLS;
        end

    end

end
