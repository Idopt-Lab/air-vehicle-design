classdef F16AeroL1 < AeroModelL1
%F16AEROL1  F-16A Block 10 Level-1 aerodynamics student class.
%
%   Inherits AeroModelL1 (abstract enforcer).  L1 is GEOMETRY-FREE: the drag
%   polar is the Mattingly Fig. 2.10/2.11 fighter "Current" type-curve
%   (CD = CD0(M) + K1(M)*CL^2 + K2*CL, K2=0 for the uncambered fighter type,
%   Mattingly AED 2nd ed. Eq. 2.9), and CLmax is a Roskam type-based lookup.
%   Every abstract method delegates to the AeroL1 static toolbox.
%
%   NO GEOMETRY: the Mattingly type-curve polar consumes no geometry, so this
%   class takes NO geometry object (contrast F16AeroL2/L3, whose constructors
%   require an injected geometry object). Inputs come from the .aerodynamics
%   block of the unified L1 JSON (f16a_spec_path(1)): aircraft type / camber
%   class / technology-curve selector, plus the folded-in Mattingly Fig.
%   2.10 (CD0) / Fig. 2.11 (K1) "Current"/"Future" curve tables.
%
%   Inheritance: AerodynamicsBase -> AeroModelL1 -> F16AeroL1
%
%   Expected outputs (F-16A "Current" fighter curve, placeholder data):
%     drag_polar(M=0.6): CD0~0.016, K1~0.18, K2=0
%     get_CLmax        : 1.50  [Roskam Vol. I Table 3.1, fighter clean mean]
%     get_CLmax_TO     : 1.70  [Table 3.1 fighter TO mean]
%     get_CLmax_L      : 2.10  [Table 3.1 fighter landing mean]
%
%   TABLE 3.1 THROUGHOUT (2026-07-25). Clean CLmax and the takeoff/landing
%   increments all come from Roskam Table 3.1, so the totals equal that table's
%   own fighter means. Previously the clean base was Table 3.3's 0.90 while the
%   increments were Table 3.1 differences off a 1.50 base, giving totals
%   (1.10/1.50) that belonged to neither table. Note the resulting L1->L2
%   discontinuity is large and INTENTIONAL: 1.50 here vs. 0.913 at L2/L3
%   (Raymer Eq. 12.15, geometry-based) -- see AeroL1.get_CLmax's header.

    % ======================================================================= %
    % INPUTS -- aircraft-type / technology-curve spec data (from JSON;
    % mutable). L1 owns NO geometry, so there are no Dependent geometry getters
    % here (contrast F16AeroL2/L3).
    % ======================================================================= %
    properties
        aircraft_category % string; canonical class flag, read from the single top-level key. Selects the Roskam CLmax row (translated to that table's own "fighter" name by AeroL1.to_CLmax_table_row) and the Mattingly fighter curves.
        design_type       % string; "uncambered" -> K2=0 (Mattingly Sec. 2.3.1)
        curve             % string; Mattingly technology curve ("Current"/"Future")

        % Mattingly Fig. 2.10 (CD0) / Fig. 2.11 (K1) "Current"-curve breakpoints,
        % (mach, value) vectors read from the placeholder curve JSONs.
        cd0_curve_mach
        cd0_curve_value
        k1_curve_mach
        k1_curve_value
    end

    methods

        function obj = F16AeroL1(json_path)
        %F16AEROL1  Construct from a required unified L1 input JSON path
        %   (f16a_spec_path(1)); reads its .aerodynamics block (aircraft type,
        %   camber class, technology-curve selector, and the folded-in
        %   Mattingly Fig. 2.10/2.11 curve tables). No silent default: the path
        %   must be supplied. L1 is geometry-free -- it takes NO geometry object
        %   (contrast F16AeroL2/L3, whose constructors require an injected
        %   geometry object).
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path));
            A = J.aerodynamics;
            % ONE canonical top-level category key (Phase 3, 2026-07-25): it was
            % previously stored three times under two spellings, and the four
            % readers did not accept the same vocabulary.
            obj.aircraft_category = string(J.aircraft_category);

            obj.design_type   = string(A.design_type);
            obj.curve         = string(A.curve);

            cd0_curve = A.cd0_curve.(char(obj.curve));
            k1_curve  = A.k1_curve.(char(obj.curve));
            obj.cd0_curve_mach  = [cd0_curve.mach];
            obj.cd0_curve_value = [cd0_curve.value];
            obj.k1_curve_mach   = [k1_curve.mach];
            obj.k1_curve_value  = [k1_curve.value];
        end

        function polar = drag_polar(obj, state)
            polar = AeroL1.drag_polar(obj, state);
        end

        function CLmax = get_CLmax(obj, ~)
            CLmax = AeroL1.get_CLmax(obj);
        end

        % ================================================================ %
        % High-lift-device / gear deltas -- pure tabulation (Roskam Vol. I
        % Tables 3.1 and 3.6, "fighter" row). Type-based, NO geometry.
        % Reads AeroL1's Constant tables directly.
        % ================================================================ %

        function val = get_Delta_e_osw_TO(obj)
        %GET_DELTA_E_OSW_TO  Roskam Table 3.6: e(TO flaps) - e(clean).
            val = obj.roskam_e_osw("takeoff_flaps") - obj.roskam_e_osw("clean");
        end

        function val = get_Delta_e_osw_L(obj)
        %GET_DELTA_E_OSW_L  Roskam Table 3.6: e(landing flaps) - e(clean).
            val = obj.roskam_e_osw("landing_flaps") - obj.roskam_e_osw("clean");
        end

        function val = get_Delta_CD0_TO(obj)
        %GET_DELTA_CD0_TO  Roskam Table 3.6: Delta_CD0(TO flaps) + Delta_CD0(gear).
            val = obj.roskam_Delta_CD0("takeoff_flaps") + obj.roskam_Delta_CD0("landing_gear");
        end

        function val = get_Delta_CD0_L(obj)
        %GET_DELTA_CD0_L  Roskam Table 3.6: Delta_CD0(landing flaps) + Delta_CD0(gear).
            val = obj.roskam_Delta_CD0("landing_flaps") + obj.roskam_Delta_CD0("landing_gear");
        end

        function val = get_Delta_CLmax_TO(obj)
        %GET_DELTA_CLMAX_TO  Roskam Table 3.1: CLmax_TO(fighter) - CLmax_clean(fighter).
            val = obj.roskam_CLmax("CL_max_TO") - obj.roskam_CLmax("CL_max_clean");
        end

        function val = get_Delta_CLmax_L(obj)
        %GET_DELTA_CLMAX_L  Roskam Table 3.1: CLmax_L(fighter) - CLmax_clean(fighter).
            val = obj.roskam_CLmax("CL_max_L") - obj.roskam_CLmax("CL_max_clean");
        end

        function val = get_CLmax_TO(obj)
        %GET_CLMAX_TO  Clean CLmax + Delta_CLmax_TO.
            val = obj.get_CLmax([]) + obj.get_Delta_CLmax_TO();
        end

        function val = get_CLmax_L(obj)
        %GET_CLMAX_L  Clean CLmax + Delta_CLmax_L.
            val = obj.get_CLmax([]) + obj.get_Delta_CLmax_L();
        end

    end

    methods (Access = private)

        function val = roskam_e_osw(~, flapconfig)
        %ROSKAM_E_OSW  Mean of AeroL1.Delta_CD0's "e_osw" range for flapconfig.
            T   = AeroL1.Delta_CD0;
            row = T(T.FlapConfig == flapconfig, :);
            val = mean(row.e_osw{1});
        end

        function val = roskam_Delta_CD0(~, flapconfig)
        %ROSKAM_DELTA_CD0  Mean of AeroL1.Delta_CD0's "Delta_CD0" range for flapconfig.
            T   = AeroL1.Delta_CD0;
            row = T(T.FlapConfig == flapconfig, :);
            val = mean(row.Delta_CD0{1});
        end

        function val = roskam_CLmax(obj, column)
        %ROSKAM_CLMAX  Mean of AeroL1.CLmax_table's column for this aircraft type.
        %   Delegates to the AeroL1.roskam_CLmax_value low-level static, which
        %   AeroL1.get_CLmax also uses for the clean column -- so the clean base
        %   and these increments are guaranteed to come from the same table
        %   (Roskam Table 3.1). See AeroL1.get_CLmax's header.
            val = AeroL1.roskam_CLmax_value(obj.aircraft_category, column);
        end

    end
end
