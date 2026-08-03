classdef WeightsL2
%WEIGHTSL2  Level-2 weights static toolbox: surface density x area, plus fractions.
%
%   Call as WeightsL2.method(...); never instantiated, not in the inheritance
%   chain. F16WeightsL2 inherits WeightsModelL2 and delegates to these statics.
%
%   Structural groups: [Raymer 6th ed. Table 15.2] psf surface densities on
%   real areas. Landing gear, installed engine and all-else-empty: the AE481
%   metabook Sec. 7 fraction table -- a SEPARATE, unnumbered table, not
%   Table 15.2, which in the repo extract carries only the psf densities.
%
%   OEW(W_TO) must evaluate both fraction terms at the PASSED W_TO and must not
%   read the W_all_else_empty / W_installed_engine properties, which are pinned
%   to the object's own W_TO.
%
%   Companion doc: src/disciplines/weights/WeightsL2.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function oew = OEW(obj, W_TO)
            W_w   = WeightsL2.weight_wing(obj, W_TO);
            W_t   = WeightsL2.weight_tail(obj, W_TO);
            W_f   = WeightsL2.weight_fuselage(obj, W_TO);
            W_lg  = WeightsL2.weight_landing_gear(obj, W_TO);
            W_ie  = WeightsL2.weight_installed_engine(obj);
            W_ale = WeightsL2.weight_all_else_empty(obj, W_TO);
            oew   = W_w + W_t.HT + W_t.VT + W_f + W_lg + W_ie + W_ale;
        end

        function W = weight_wing(obj, ~)
            rho = WeightsL2.wing_unit_weight(obj.aircraft_category);
            W   = rho * obj.S_w;
        end

        function W = weight_tail(obj, ~)
            rho_ht = WeightsL2.HT_unit_weight(obj.aircraft_category);
            rho_vt = WeightsL2.VT_unit_weight(obj.aircraft_category);
            W.HT = rho_ht * obj.S_ht;
            W.VT = rho_vt * obj.S_vt;
        end

        function W = weight_fuselage(obj, ~)
            rho = WeightsL2.fus_unit_weight(obj.aircraft_category);
            W   = rho * obj.S_wet_fus;
        end

        function W = weight_landing_gear(obj, W_TO)
            f = WeightsL2.LG_fraction(obj.aircraft_category);
            W = f * W_TO;
        end

        function W = weight_installed_engine(obj)
            W = 1.3 * obj.N_en * obj.W_en;
        end

        function W = weight_all_else_empty(~, W_TO)
            W = 0.17 * W_TO;
        end

        % ================================================================== %
        % LOW-LEVEL: unit-weight / fraction lookups, and the Brandt engine
        % alternate. Pure scalars in, scalar out.
        % ================================================================== %

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
                    % TODO (todo 2026-07-25 Phase 4 §P4-7, OPEN): 0.057 is
                    % UNCITED. The metabook fraction table (metabook_data.md:328-334)
                    % has NO general-aviation landing-gear row — only fighter
                    % 0.033 (:330), Navy fighter 0.045 (:331) and transport
                    % 0.043 (:332). This value has no source anywhere in the
                    % repo; it is retained unchanged rather than deleted or
                    % re-derived, and must not be cited to the metabook until the
                    % user supplies a source. It does not affect the F-16A
                    % (jet_fighter), so this is a citation-integrity item.
                    f = 0.057;  % [UNCITED — see the TODO above]
                otherwise
                    % NOTE: the extract carries a Navy-fighter row, 0.045 *W0
                    % [metabook_data.md:331], that this lookup deliberately does
                    % NOT add — no consumer exists and adding it would be a
                    % feature beyond this phase. Recorded so its absence reads as
                    % a decision, not an oversight. todo §P4-7 (open).
                    error('WeightsL2:UnknownCategory', ...
                          'No LG fraction for "%s".', aircraft_category);
            end
        end

        function W = engine_weight_brandt(T_AB_SLS)
            W = 0.199 * T_AB_SLS;
        end

    end

end
