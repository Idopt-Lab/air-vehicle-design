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
%     Engine + all-else: computed in the constructor from the WeightsL3
%       Raymer §15.3.1 component equations (see properties below) — NOT
%       calibrated against Brandt's OEW.
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
%               Table 15.2 and §15.3.1 (Eqs. 15.7-15.24).
%     [TO]      T.O. 1F-16A-1, Flight Manual, USAF/EPAF F-16A/B Blocks 10/15.

    properties
        aircraft_category = 'jet_fighter'  % selects Raymer Table 15.2 row

        % ----- Geometry inputs for Raymer Table 15.2 component estimates -----
        S_w       = 300      % ft²  wing trapezoidal reference area  [TO 1F-16A-1]
        S_ht      = 63.70    % ft²  horizontal tail area             [TO 1F-16A-1]
        S_vt      = 54.75    % ft²  vertical tail area               [TO 1F-16A-1]
        S_wet_fus = 750      % ft²  fuselage wetted area             [estimate; verify TO 1F-16A-1]

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
        % Both are evaluated from the WeightsL3 Raymer §15.3.1 component
        % equations at the F-16A Block 10/15 spec inputs in F16WeightsL3 —
        % NOT back-calculated from Brandt's OEW. (Brandt B12 is a validation
        % target only; per PLAN.md it must never be a calibration input.)
        W_installed_engine = NaN  % [lbf] bare engine + installation hardware; WeightsL3 Eqs. 15.7-15.15
        W_all_else_empty = NaN   % [lbf] avionics/fuel/FCS/hydraulics/electrical/furnishings; WeightsL3 Eqs. 15.16-15.24
    end

    methods

        function obj = F16WeightsL2()
            l3 = F16WeightsL3();
            W_eng = WeightsL3.weight_engine_section(l3, NaN);
            obj.W_installed_engine = W_eng.total;
            % Nominal F-16A Block 10/15 baseline TOGW [T.O. 1F-16A-1 / Brandt B38]
            % used only as the W_TO input to handling_gear (Eq. 15.24), which
            % contributes < 0.05% of the systems-group total.
            W_sys = WeightsL3.weight_systems(l3, 31377);
            obj.W_all_else_empty = W_sys.total;
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
