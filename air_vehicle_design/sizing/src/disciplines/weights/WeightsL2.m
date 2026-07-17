classdef WeightsL2
%WEIGHTSL2  Level-2 weight estimation static toolbox — component/surface-density buildup.
%
%   Call as WeightsL2.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16WeightsL2, etc.)
%   inherit from WeightsModelL2 and call these statics to implement each
%   abstract method.
%
%   METHOD — Raymer Table 15.2 surface-density component estimates:
%     W_wing     = rho_w   × S_w        (rho_w = 9 lbf/ft² for fighters)
%     W_HT       = rho_ht  × S_ht       (rho_ht = 4 lbf/ft²)
%     W_VT       = rho_vt  × S_vt       (rho_vt = 5.3 lbf/ft²)
%     W_fuselage = rho_fus × S_wet_fus  (rho_fus = 4.8 lbf/ft²)
%     W_LG       = f_lg    × W_TO       (f_lg = 0.033 for non-Navy fighters)
%   OEW = W_wing + W_HT + W_VT + W_fus + W_LG
%         + obj.W_installed_engine + obj.W_all_else_empty
%
%   The last two terms are set directly by the student class.  They capture
%   installed engine weight and the systems/equipment group (avionics,
%   fuel system, FCS, hydraulics, electrical, furnishings).  Computing these
%   from first principles requires the L3 Raymer §15.3.1 equations.
%
%   The Roskam statistical method (minimum-bound regression) has moved to
%   WeightsL1.compute_We_roskam / WeightsL1.We_roskam.  Call it there for
%   a lower-bound comparison against this component estimate.
%
%   SOURCE:
%     Raymer, "Aircraft Design: A Conceptual Approach," 6th ed., AIAA, 2018,
%     Table 15.2 — Typical Component Weights per Unit Area.
%     [AE481 Aircraft Design Metabook §7, Table 7.1]

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function oew = OEW(obj, W_TO)
        %OEW  Component-buildup operating empty weight [lbf].  [Raymer Table 15.2]
        %   Sums structural components + student-specified engine and all-else-empty.
        %   W_TO — candidate gross weight [lbf].
            W_w  = WeightsL2.weight_wing(obj, W_TO);
            W_t  = WeightsL2.weight_tail(obj, W_TO);
            W_f  = WeightsL2.weight_fuselage(obj, W_TO);
            W_lg = WeightsL2.weight_landing_gear(obj, W_TO);
            oew  = W_w + W_t.HT + W_t.VT + W_f + W_lg ...
                 + obj.W_installed_engine + obj.W_all_else_empty;
        end

        function W = weight_wing(obj, ~)
        %WEIGHT_WING  Wing structural weight [lbf].  [Raymer Table 15.2]
        %   Surface-density method: W = rho_w × S_w.
        %   rho_w = 9 lbf/ft² for fighters  [Raymer Table 15.2, AE481 metabook §7].
            rho = WeightsL2.wing_unit_weight(obj.aircraft_category);
            W   = rho * obj.S_w;
        end

        function W = weight_tail(obj, ~)
        %WEIGHT_TAIL  HT and VT structural weights [lbf].  [Raymer Table 15.2]
        %   Returns struct with fields HT and VT.
        %   rho_ht = 4 lbf/ft², rho_vt = 5.3 lbf/ft² for fighters
        %   [Raymer Table 15.2, AE481 metabook §7].
            rho_ht = WeightsL2.HT_unit_weight(obj.aircraft_category);
            rho_vt = WeightsL2.VT_unit_weight(obj.aircraft_category);
            W.HT = rho_ht * obj.S_ht;
            W.VT = rho_vt * obj.S_vt;
        end

        function W = weight_fuselage(obj, ~)
        %WEIGHT_FUSELAGE  Fuselage structural weight [lbf].  [Raymer Table 15.2]
        %   Surface-density method: W = rho_f × S_wet_fus.
        %   rho_f = 4.8 lbf/ft² for fighters  [Raymer Table 15.2, AE481 metabook §7].
            rho = WeightsL2.fus_unit_weight(obj.aircraft_category);
            W   = rho * obj.S_wet_fus;
        end

        function W = weight_landing_gear(obj, W_TO)
        %WEIGHT_LANDING_GEAR  Total landing gear weight [lbf].  [AE481 metabook §7]
        %   Fraction-based: W = f_lg × W_TO.
        %   f_lg = 0.033 for non-Navy fighters; 0.045 for Navy fighters
        %   [AE481 metabook §7 / Raymer Table 15.2 fractions].
            f = WeightsL2.LG_fraction(obj.aircraft_category);
            W = f * W_TO;
        end

        % ================================================================== %
        % LOW-LEVEL: unit weight / fraction lookups  [Raymer Table 15.2]
        % ================================================================== %

        function rho = wing_unit_weight(aircraft_category)
        %WING_UNIT_WEIGHT  Wing structural surface density [lbf/ft²].
        %   Source: Raymer, Aircraft Design 6th ed., Table 15.2.
            switch lower(aircraft_category)
                case 'jet_fighter',      rho = 9.0;   % [Raymer Table 15.2]
                case 'jet_transport',    rho = 10.0;  % [Raymer Table 15.2]
                case 'general_aviation', rho = 2.5;   % [Raymer Table 15.2]
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No wing unit weight for "%s".', aircraft_category);
            end
        end

        function rho = HT_unit_weight(aircraft_category)
        %HT_UNIT_WEIGHT  Horizontal tail structural surface density [lbf/ft²].
        %   Source: Raymer Table 15.2.
            switch lower(aircraft_category)
                case 'jet_fighter',      rho = 4.0;   % [Raymer Table 15.2]
                case 'jet_transport',    rho = 5.5;   % [Raymer Table 15.2]
                case 'general_aviation', rho = 2.0;   % [Raymer Table 15.2]
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No HT unit weight for "%s".', aircraft_category);
            end
        end

        function rho = VT_unit_weight(aircraft_category)
        %VT_UNIT_WEIGHT  Vertical tail structural surface density [lbf/ft²].
        %   Source: Raymer Table 15.2.
            switch lower(aircraft_category)
                case 'jet_fighter',      rho = 5.3;   % [Raymer Table 15.2]
                case 'jet_transport',    rho = 5.5;   % [Raymer Table 15.2]
                case 'general_aviation', rho = 2.0;   % [Raymer Table 15.2]
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No VT unit weight for "%s".', aircraft_category);
            end
        end

        function rho = fus_unit_weight(aircraft_category)
        %FUS_UNIT_WEIGHT  Fuselage structural surface density [lbf/ft²].
        %   Source: Raymer Table 15.2.
            switch lower(aircraft_category)
                case 'jet_fighter',      rho = 4.8;   % [Raymer Table 15.2]
                case 'jet_transport',    rho = 5.0;   % [Raymer Table 15.2]
                case 'general_aviation', rho = 1.4;   % [Raymer Table 15.2]
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No fuselage unit weight for "%s".', aircraft_category);
            end
        end

        function f = LG_fraction(aircraft_category)
        %LG_FRACTION  Landing gear weight as fraction of W_TO.
        %   Source: AE481 metabook §7 / Raymer statistical fractions.
            switch lower(aircraft_category)
                case 'jet_fighter',      f = 0.033;  % non-Navy fighter [AE481 metabook §7]
                case 'jet_transport',    f = 0.043;  % transport/bomber [AE481 metabook §7]
                case 'general_aviation', f = 0.057;  % GA [AE481 metabook §7]
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No LG fraction for "%s".', aircraft_category);
            end
        end

    end

end
