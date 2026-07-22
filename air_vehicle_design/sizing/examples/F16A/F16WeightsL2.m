classdef F16WeightsL2 < WeightsModelL2
%F16WEIGHTSL2  F-16A Block 10 Level-2 weight estimation student class.
%
%   Inherits from WeightsModelL2 (abstract enforcer).  Each abstract method
%   is satisfied by a single delegation line to WeightsL2 statics.
%
%   METHODS:
%     Structural group: Raymer Table 15.2 surface-density estimates.
%       Wing 9 lbf/ft², HT 4 lbf/ft², VT 5.3 lbf/ft², Fus 4.8 lbf/ft²,
%       LG 3.3% of W_TO.
%     Engine + all-else: AE481 metabook §7 fraction-based estimates,
%       computed in the constructor (see properties below) — NOT
%       calibrated against Brandt's OEW, and NOT the L3 Raymer §15.3.1
%       component buildup (a separate, independent, higher-fidelity method).
%
%   OEW = W_wings + W_HT + W_VT + W_fuselage + W_LG
%         + W_installed_engine + W_all_else_empty
%
%   For comparison, call WeightsL1.compute_We_roskam(obj, W_TO) to get
%   the Roskam lower-bound estimate at any W_TO.
%
%   SOURCES:
%     [Brandt]  S. Brandt, F-16A.xls workbook. Used only as a validation
%               target (see tests) — never as a calibration input here.
%     [Raymer]  D.P. Raymer, Aircraft Design 6th ed., AIAA, 2018,
%               Table 15.2 (structural group).
%     [AE481]   AE481 Aircraft Design Metabook §7, Fraction-Based Weight
%               Estimates table (installed engine, all-else-empty).
%     [TO]      T.O. 1F-16A-1, Flight Manual, USAF/EPAF F-16A/B Blocks 10/15.

    properties
        aircraft_category = 'jet_fighter'  % selects Raymer Table 15.2 row

        % ----- Geometry inputs for Raymer Table 15.2 component estimates -----
        % S_w/S_ht/S_vt are EXPOSED planform areas (fuselage-excluded), per
        % Raymer Table 15.2's definition -- NOT the full trapezoidal
        % reference areas (b.geom.S_ref/S_ht/S_vt = 300/63.70/54.75).
        S_w       = 196.23   % ft²  exposed wing planform area       [Brandt Geom sheet, "Exposed S", Wing row; F16Baseline b.geom.S_exposed_wing]
        S_ht      = 49.85    % ft²  exposed horizontal tail area     [Brandt Geom sheet, "Exposed S", Pitch Control Surface row; F16Baseline b.geom.S_exposed_ht]
        S_vt      = 40.89    % ft²  exposed vertical tail area       [Brandt Geom sheet, "Exposed S", Vertical Tail row; F16Baseline b.geom.S_exposed_vt]
        S_wet_fus = 750      % ft²  fuselage wetted area             [estimate; verify TO 1F-16A-1]

        % ----- Inputs for AE481 §7 installed-engine fraction estimate -----
        N_en      = 1        % --   number of engines                [TO 1F-16A-1]
        W_en      = 3030     % lbf  bare/dry engine weight            [estimate; verify TO 1F-16A-1 or Jane's All the World's Aircraft]

        % ----- WeightsBase abstract properties -----
        W_TO               = NaN      % candidate gross takeoff weight [lbf]; set by sizing loop
        W_energy           = 6296.3   % internal fuel weight [lbf]           [Brandt B6]
        W_payload_expendable = 0      % expendable payload [lbf]; set by mission profile
        W_payload_fixed    = 220      % fixed equipment + crew [lbf; estimate]

        % ----- WeightsModelL2 abstract properties (populated by compute methods) -----
        W_wings        = NaN  % wing structural weight [lbf]
        W_landing_gear = NaN  % total LG weight [lbf]
        W_tail         = NaN  % tail weights struct; set by weight_tail [lbf]
        W_fuselage     = NaN  % fuselage structural weight [lbf]

        % ----- Component weights not computable from Table 15.2 (set in constructor) -----
        % Both are AE481 metabook §7 fraction-based estimates (installed
        % engine = 1.3 x bare engine weight; all-else-empty = 0.17 x W_TO) —
        % NOT back-calculated from Brandt's OEW (Brandt B12 is a validation
        % target only; per PLAN.md it must never be a calibration input),
        % and NOT the L3 Raymer §15.3.1 component buildup, which is a
        % separate, independent, higher-fidelity method.
        W_installed_engine = NaN  % [lbf] AE481 §7: 1.3 x N_en x W_en
        W_all_else_empty = NaN   % [lbf] AE481 §7: 0.17 x W_TO
    end

    methods

        function obj = F16WeightsL2()
            obj.W_installed_engine = WeightsL2.weight_installed_engine(obj);
            % Nominal F-16A Block 10/15 baseline TOGW [T.O. 1F-16A-1 / Brandt B38]
            % used as the W_TO input to the 0.17xW_TO all-else-empty fraction.
            obj.W_all_else_empty = WeightsL2.weight_all_else_empty(obj, 31377);
        end

        function oew = OEW(obj, W_TO)
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

    end

end
