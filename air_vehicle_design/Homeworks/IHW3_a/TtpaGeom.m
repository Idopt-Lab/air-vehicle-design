classdef TtpaGeom < GeometryBase
%TTPAGEOM  Test Twin Propeller Aircraft Level-2 geometry model.
%
%   IHW3a UPDATE
%   In IHW1 and IHW2 this class held two numbers, S_ref and S_wet, and both
%   were NaN. It could afford to: the mission analysis never needed a wing,
%   and the constraint analysis works entirely in RATIOS - W/S and W/P - so
%   it never needed one either. size_from_design_point wrote S_ref in at the
%   very end, once, and nothing ever read it back.
%
%   A sizing loop cannot work that way. It rebuilds the airplane from the
%   takeoff weight on every iteration, so every span, chord, area and wetted
%   area has to follow S_ref the instant the loop writes it. This version
%   therefore carries the whole Level-2 planform:
%
%       wing        span, root and tip chord, MAC, y_MAC, exposed area
%       tails       sized by the volume-coefficient method, then their own
%                   spans and chords
%       fuselage    fixed by the cabin layout, so constant through the loop
%       nacelles    length tracks the engine, which tracks P_SL
%       wetted      every component, and the total
%
%   INPUTS vs DERIVED
%   S_ref is the ONLY mutable property. Everything else is Dependent and is
%   recomputed from S_ref on every read, so nothing can go stale when the
%   sizing loop mutates the object. There is no cached copy of any derived
%   quantity anywhere in this class and no set method on any of them:
%   assigning to a Dependent property errors, which is correct - they are
%   outputs, not inputs.
%
%   INJECTED PROPULSION
%   The constructor takes the propulsion object, TtpaGeom(json_path, prop),
%   because the nacelle is sized around the engine and the engine size is
%   engine data, not airframe data. The nacelle length is therefore
%   Dependent on prop.P_SL, exactly as the wing is Dependent on S_ref.
%
%   Inheritance:
%       GeometryBase -> TtpaGeom
%
%   Abstract interface implemented:
%       get_S_ref()
%       get_S_wet()
%
%   Equations
%       Root chord, tip chord, MAC      Raymer Eqs. 7.6, 7.7, 7.8, through
%                                       the GeometryBase statics
%       Span                            AR = b^2/S_ref, definitional
%       y_MAC                           b(1+2*lambda)/(6(1+lambda))
%       Tail areas                      volume-coefficient method: Raymer
%                                       Sec. 6.5, Roskam Part II Ch. 8,
%                                       Nicolai and Carichner Ch. 11
%       Lifting-surface wetted area     Raymer Eqs. 7.11 and 7.12
%       Fuselage wetted area            Raymer Eq. 7.13
%       Wing fuel volume                Torenbeek, in wing_fuel_volume()

    properties
        S_ref = NaN
        % Wing reference area [ft^2]. THE design variable of the sizing
        % loop: written on every iteration as W_TO / (W/S). Stays NaN until
        % the loop, or the caller, sets it.
    end

    properties (SetAccess = immutable)
        prop                        % injected TtpaProp, for the nacelle

        % --- wing shape, read from J.geometry ---
        AR                          % <- J.geometry.AR
        taper                       % <- J.geometry.taper_ratio
        sweep_qc_deg                % <- J.geometry.sweep_quarter_chord_deg
        tc_root                     % <- J.geometry.thickness_ratio_root
        tc_tip                      % <- J.geometry.thickness_ratio_tip
        twist_deg                   % <- J.geometry.twist_deg
        incidence_deg               % <- J.geometry.incidence_deg
        dihedral_deg                % <- J.geometry.dihedral_deg

        % --- horizontal tail, read from J.geometry.horizontal_tail ---
        V_ht                        % volume coefficient [-]
        L_ht                        % moment arm [ft]
        AR_ht
        taper_ht
        tc_ht
        sweep_qc_ht_deg

        % --- vertical tail, read from J.geometry.vertical_tail ---
        V_vt
        L_vt
        AR_vt
        taper_vt
        tc_vt
        sweep_qc_vt_deg

        % --- fuselage, read from J.geometry.fuselage, all fixed ---
        w_fus                       % width [ft]
        h_fus                       % height [ft]
        l_nose                      % [ft]
        l_cabin                     % constant section [ft]
        l_cone                      % tail cone [ft]
        w_cone_end                  % [ft]
        h_cone_end                  % [ft]

        % --- nacelle, read from J.geometry.nacelle ---
        d_nacelle                   % diameter [ft]
        k_nacelle_length            % nacelle length / bare engine length

        % --- landing gear geometry, read from J.geometry.landing_gear ---
        l_n_over_l_d
        l_m_over_l_d
    end

    properties (Dependent)
        % --- wing planform ---
        b                           % span [ft]
        c_root                      % root chord [ft]
        c_tip                       % tip chord [ft]
        MAC                         % mean aerodynamic chord [ft]
        y_MAC                       % spanwise station of the MAC [ft]
        tc_mean                     % mean thickness ratio [-]
        S_exposed_wing              % planform outside the fuselage [ft^2]

        % --- horizontal tail ---
        S_ht                        % area [ft^2]
        b_ht
        c_root_ht
        c_tip_ht
        MAC_ht
        y_MAC_ht

        % --- vertical tail ---
        S_vt                        % area [ft^2]
        b_vt
        c_root_vt
        c_tip_vt
        MAC_vt
        y_MAC_vt

        % --- fuselage: constant, but Dependent so it stays derived ---
        l_fus                       % total length [ft]
        fineness_ratio              % l_fus / max diameter [-]
        S_wet_fuselage              % [ft^2]

        % --- nacelle ---
        l_nacelle                   % ONE nacelle [ft]
        S_wet_nacelle               % ALL nacelles [ft^2]

        % --- wetted areas ---
        S_wet_wing
        S_wet_ht
        S_wet_vt
        S_wet                       % total [ft^2]
        S_wet_over_S_ref            % [-], drives CD0 through Raymer 12.23
    end

    methods

        %% Constructor
        function obj = TtpaGeom(json_path, prop)
        %TTPAGEOM  Build the geometry from the requirements JSON.
        %
        %   obj = TtpaGeom(json_path, prop)
        %
        %   prop is the TtpaProp object. It is injected, not built here,
        %   because the nacelle length follows the engine and the engine is
        %   propulsion data. Build prop FIRST - see ttpa_disciplines.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
                prop (1,1) PropulsionBase2
            end

            obj.prop = prop;

            J = jsondecode(fileread(json_path));
            G = J.geometry;

            % Wing shape
            obj.AR            = G.AR;
            obj.taper         = G.taper_ratio;
            obj.sweep_qc_deg  = G.sweep_quarter_chord_deg;
            obj.tc_root       = G.thickness_ratio_root;
            obj.tc_tip        = G.thickness_ratio_tip;
            obj.twist_deg     = G.twist_deg;
            obj.incidence_deg = G.incidence_deg;
            obj.dihedral_deg  = G.dihedral_deg;

            % Horizontal tail
            H = G.horizontal_tail;
            obj.V_ht            = H.volume_coefficient;
            obj.L_ht            = H.arm_ft;
            obj.AR_ht           = H.AR;
            obj.taper_ht        = H.taper_ratio;
            obj.tc_ht           = H.thickness_ratio;
            obj.sweep_qc_ht_deg = H.sweep_quarter_chord_deg;

            % Vertical tail
            V = G.vertical_tail;
            obj.V_vt            = V.volume_coefficient;
            obj.L_vt            = V.arm_ft;
            obj.AR_vt           = V.AR;
            obj.taper_vt        = V.taper_ratio;
            obj.tc_vt           = V.thickness_ratio;
            obj.sweep_qc_vt_deg = V.sweep_quarter_chord_deg;

            % Fuselage
            F = G.fuselage;
            obj.w_fus      = F.width_ft;
            obj.h_fus      = F.height_ft;
            obj.l_nose     = F.nose_length_ft;
            obj.l_cabin    = F.constant_length_ft;
            obj.l_cone     = F.tailcone_length_ft;
            obj.w_cone_end = F.tailcone_end_width_ft;
            obj.h_cone_end = F.tailcone_end_height_ft;

            % Nacelle
            N = G.nacelle;
            obj.d_nacelle        = N.diameter_ft;
            obj.k_nacelle_length = N.length_over_engine_length;

            % Landing gear geometry
            L = G.landing_gear;
            obj.l_n_over_l_d = L.l_n_over_l_d;
            obj.l_m_over_l_d = L.l_m_over_l_d;
        end


        %% ---------------- Abstract interface ----------------

        function val = get_S_ref(obj)
        %GET_S_REF  Wing reference area [ft^2].
            val = obj.S_ref;
        end

        function val = get_S_wet(obj, ~)
        %GET_S_WET  Total aircraft wetted area [ft^2].
        %
        %   The second argument is the takeoff weight. A Level-1 geometry
        %   needs it, because it gets the wetted area from a regression on
        %   gross weight. This one does not: it has real geometry and adds
        %   the components up. The argument stays in the signature so that
        %   the GeometryBase contract is still met.
            val = obj.S_wet;
        end


        %% ---------------- Wing planform ----------------

        function val = get.b(obj)
            val = GeometryBase.compute_span(obj.AR, obj.S_ref);
        end

        function val = get.c_root(obj)
            val = GeometryBase.compute_root_chord(obj.S_ref, obj.b, obj.taper);
        end

        function val = get.c_tip(obj)
            val = GeometryBase.compute_tip_chord(obj.c_root, obj.taper);
        end

        function val = get.MAC(obj)
            val = GeometryBase.compute_mac(obj.c_root, obj.taper);
        end

        function val = get.y_MAC(obj)
            val = TtpaGeom.compute_y_mac(obj.b, obj.taper);
        end

        function val = get.tc_mean(obj)
            val = 0.5 * (obj.tc_root + obj.tc_tip);
        end

        function val = get.S_exposed_wing(obj)
        %GET.S_EXPOSED_WING  Wing planform outside the fuselage [ft^2].
        %
        %   The reference area is the trapezoid carried through to the
        %   centreline. The part of it buried in the fuselage is neither
        %   built nor wetted, so Raymer Table 15.2 and Raymer Eq. 7.12 both
        %   want the EXPOSED area. Integrating the chord from the
        %   centreline out to the fuselage side, on both sides,
        %
        %       S_covered = c_root * w_fus * ( 1 - (1-lambda) w_fus/(2b) )
        %
        %   which is exact for a straight-tapered wing.
            S_covered = obj.c_root * obj.w_fus * ...
                (1 - (1 - obj.taper) * obj.w_fus / (2 * obj.b));
            val = obj.S_ref - S_covered;
        end


        %% ---------------- Horizontal tail ----------------

        function val = get.S_ht(obj)
        %GET.S_HT  Horizontal tail area by the volume-coefficient method.
        %
        %       V_h  = S_ht * L_ht / ( S_ref * MAC )     so
        %       S_ht = V_h * S_ref * MAC / L_ht
        %
        %   [Raymer Sec. 6.5; Roskam Part II Ch. 8; Nicolai and Carichner
        %   Ch. 11]. Both S_ref and MAC follow the wing, so the tail grows
        %   with the wing on every iteration of the sizing loop.
            val = obj.V_ht * obj.S_ref * obj.MAC / obj.L_ht;
        end

        function val = get.b_ht(obj)
            val = GeometryBase.compute_span(obj.AR_ht, obj.S_ht);
        end

        function val = get.c_root_ht(obj)
            val = GeometryBase.compute_root_chord(obj.S_ht, obj.b_ht, obj.taper_ht);
        end

        function val = get.c_tip_ht(obj)
            val = GeometryBase.compute_tip_chord(obj.c_root_ht, obj.taper_ht);
        end

        function val = get.MAC_ht(obj)
            val = GeometryBase.compute_mac(obj.c_root_ht, obj.taper_ht);
        end

        function val = get.y_MAC_ht(obj)
            val = TtpaGeom.compute_y_mac(obj.b_ht, obj.taper_ht);
        end


        %% ---------------- Vertical tail ----------------

        function val = get.S_vt(obj)
        %GET.S_VT  Vertical tail area by the volume-coefficient method.
        %
        %       V_v  = S_vt * L_vt / ( S_ref * b )       so
        %       S_vt = V_v * S_ref * b / L_vt
        %
        %   The length scale is the wing SPAN, not the MAC. That is the one
        %   difference between the two tail-volume definitions.
            val = obj.V_vt * obj.S_ref * obj.b / obj.L_vt;
        end

        function val = get.b_vt(obj)
            val = GeometryBase.compute_span(obj.AR_vt, obj.S_vt);
        end

        function val = get.c_root_vt(obj)
            val = GeometryBase.compute_root_chord(obj.S_vt, obj.b_vt, obj.taper_vt);
        end

        function val = get.c_tip_vt(obj)
            val = GeometryBase.compute_tip_chord(obj.c_root_vt, obj.taper_vt);
        end

        function val = get.MAC_vt(obj)
            val = GeometryBase.compute_mac(obj.c_root_vt, obj.taper_vt);
        end

        function val = get.y_MAC_vt(obj)
        %GET.Y_MAC_VT  Spanwise MAC station of the vertical tail [ft].
        %   The vertical tail is a SINGLE panel, so the mirrored-surface
        %   result is doubled - see the note in the tail-sizing reference.
            val = 2 * TtpaGeom.compute_y_mac(obj.b_vt, obj.taper_vt);
        end


        %% ---------------- Fuselage, fixed ----------------

        function val = get.l_fus(obj)
            val = obj.l_nose + obj.l_cabin + obj.l_cone;
        end

        function val = get.fineness_ratio(obj)
            val = obj.l_fus / max(obj.w_fus, obj.h_fus);
        end

        function val = get.S_wet_fuselage(obj)
        %GET.S_WET_FUSELAGE  Fuselage wetted area [ft^2].
        %
        %   [Raymer Eq. 7.13]   S_wet ~= 3.4 * (A_top + A_side) / 2
        %
        %   with A_top and A_side the projected plan and side areas. The
        %   fuselage is taken as three segments - a linearly tapered nose, a
        %   constant section, and a linearly tapered tail cone closing to a
        %   small but non-zero end area. A rounded nose would add a few
        %   percent, which at this fidelity is inside the noise of the 3.4.
        %
        %   NOTHING here depends on S_ref or on P_SL. The fuselage is sized
        %   by the cabin, so it is CONSTANT through the sizing loop.
            A_top = 0.5 * obj.w_fus * obj.l_nose ...
                  +       obj.w_fus * obj.l_cabin ...
                  + 0.5 * (obj.w_fus + obj.w_cone_end) * obj.l_cone;

            A_side = 0.5 * obj.h_fus * obj.l_nose ...
                   +       obj.h_fus * obj.l_cabin ...
                   + 0.5 * (obj.h_fus + obj.h_cone_end) * obj.l_cone;

            val = 3.4 * (A_top + A_side) / 2;
        end


        %% ---------------- Nacelles ----------------

        function val = get.l_nacelle(obj)
        %GET.L_NACELLE  Length of ONE nacelle [ft].
        %   The bare engine length comes from the propulsion model, which
        %   scales it from the rated power per engine. The cowl runs from
        %   the spinner bulkhead to the aft fairing, so the nacelle is
        %   longer than the engine by k_nacelle_length.
            val = obj.k_nacelle_length * obj.prop.engine_length();
        end

        function val = get.S_wet_nacelle(obj)
        %GET.S_WET_NACELLE  Wetted area of ALL nacelles [ft^2].
        %   Each nacelle is taken as a cylinder of diameter d_nacelle. The
        %   end faces are not wetted: the front is the propeller disc and
        %   the back fairs into the wing.
            val = obj.prop.n_engines * pi * obj.d_nacelle * obj.l_nacelle;
        end


        %% ---------------- Wetted areas ----------------

        function val = get.S_wet_wing(obj)
            val = TtpaGeom.wetted_from_exposed(obj.S_exposed_wing, obj.tc_mean);
        end

        function val = get.S_wet_ht(obj)
        %   The horizontal tail area from the volume coefficient is the
        %   theoretical planform. The strip inside the fuselage is not
        %   wetted, but it is small on a conventional tail, so the
        %   theoretical area is used and the result is slightly
        %   conservative.
            val = TtpaGeom.wetted_from_exposed(obj.S_ht, obj.tc_ht);
        end

        function val = get.S_wet_vt(obj)
            val = TtpaGeom.wetted_from_exposed(obj.S_vt, obj.tc_vt);
        end

        function val = get.S_wet(obj)
        %GET.S_WET  Total wetted area [ft^2].
            val = obj.S_wet_wing + obj.S_wet_ht + obj.S_wet_vt ...
                + obj.S_wet_fuselage + obj.S_wet_nacelle;
        end

        function val = get.S_wet_over_S_ref(obj)
        %GET.S_WET_OVER_S_REF  Wetted-area ratio [-].
        %   The one number TtpaAero needs to turn geometry into drag,
        %   through Raymer Eq. 12.23.
            val = obj.S_wet / obj.S_ref;
        end


        %% ---------------- Post-sizing check ----------------

        function [V_ft3] = wing_fuel_volume(obj)
        %WING_FUEL_VOLUME  Usable fuel volume inside the wing [ft^3].
        %
        %   Torenbeek empirical relation:
        %
        %       V_wf = 0.54 (S^2/b) (t/c)_root
        %              * (1 + lambda sqrt(tau) + lambda^2 tau) / (1+lambda)^2
        %
        %   with tau = (t/c)_tip / (t/c)_root. Run this AFTER the sizing
        %   loop converges and compare the fuel weight the wing can hold
        %   with the fuel weight the mission needs. A shortfall of more than
        %   15 to 20 percent means the planform has to change.
            tau = obj.tc_tip / obj.tc_root;
            V_ft3 = 0.54 * obj.S_ref^2 / obj.b * obj.tc_root ...
                * (1 + obj.taper * sqrt(tau) + tau * obj.taper^2) ...
                / (1 + obj.taper)^2;
        end

    end


    methods (Static)

        function y = compute_y_mac(b, lambda)
        %COMPUTE_Y_MAC  Spanwise station of the MAC [ft].
        %       y_mac = b (1 + 2 lambda) / ( 6 (1 + lambda) )
        %   Standard straight-tapered-planform identity. For a vertical
        %   tail, which is a single panel, double the result - see
        %   get.y_MAC_vt.
            arguments
                b      (1,1) double {mustBePositive}
                lambda (1,1) double {mustBeNonnegative}
            end
            y = b * (1 + 2*lambda) / (6 * (1 + lambda));
        end

        function S_wet = wetted_from_exposed(S_exposed, tc)
        %WETTED_FROM_EXPOSED  Wetted area of a lifting surface [ft^2].
        %       [Raymer Eq. 7.11]  t/c < 0.05 :  S_wet = 2.003 S_exposed
        %       [Raymer Eq. 7.12]  t/c > 0.05 :  S_wet = S_exposed
        %                                                * (1.977 + 0.52 t/c)
            arguments
                S_exposed (1,1) double
                tc        (1,1) double {mustBeNonnegative}
            end
            if tc < 0.05
                S_wet = 2.003 * S_exposed;
            else
                S_wet = S_exposed * (1.977 + 0.52 * tc);
            end
        end

    end

end
