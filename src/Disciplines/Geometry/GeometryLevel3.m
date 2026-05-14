classdef GeometryLevel3
     %F16GEOMETRYSTUFF Summary of this class goes here
     %   Detailed explanation goes here

     properties
          % Organize by physical object; separate into tail (horizontal,
          % vertical), fuselage, etc?
          % I should definitely use structs for this. Organize into wings,
          % tails, fuselage.
     end

     methods (Static)

          % Compute wingspan from planform area
          function b = compute_b(AR, S_ref)
               b = sqrt(AR*S_ref);
          end

          % Compute c_root from wingspan, S_ref, and taper ratio
          function c_root = compute_c_root(S_ref, b, lambda)
               c_root = (2 * S_ref)/(b*(1 + lambda));
          end

          % Compute c_tip from taper ratio, and c_root
          function c_tip = compute_c_tip(lambda, c_root)
               c_tip = lambda*c_root;
          end

          % size control surfaces
          function S_control = size_control_surface_raymer( ...
                    deltaCL_req, ...
                    S_ref, ...
                    K_f, ...
                    dcl_ddelta_airfoil, ...
                    delta_max_deg, ...
                    Lambda_HL_deg)

               % Raymer-style plain-flap/control-surface sizing.
               % deltaCL_req: required section/surface lift coefficient increment
               % S_ref: parent reference area, e.g. S_h for elevator, S_v for rudder, S_w for flap/aileron
               % K_f: empirical correction factor
               % dcl_ddelta_airfoil: 2D lift increment per radian of deflection
               % delta_max_deg: maximum control deflection in degrees
               % Lambda_HL_deg: hinge-line sweep angle in degrees

               delta_max_rad = deg2rad(delta_max_deg);

               S_control = (deltaCL_req * S_ref) / ...
                    (0.9 * K_f * dcl_ddelta_airfoil * delta_max_rad * cosd(Lambda_HL_deg));
          end

          function L_hinge = compute_hinge_length_from_stations(y_in, y_out, Lambda_h_deg)
               % Computes hinge length from projected span and hinge-line sweep.
               %
               % y_in: inboard span station [ft]
               % y_out: outboard span station [ft]
               % Lambda_h_deg: hinge-line sweep angle [deg]

               b_control = abs(y_out - y_in);
               L_hinge = b_control / cosd(Lambda_h_deg);
          end

          % Estimate the wetted area of the aircraft
          function S_wet = get_design_S_wet(W_TO)
               c = -0.1289; % Coefficient for fighter aircraft, given for S_wetrest equation, provided by Roskam's Aircraft Design Volume 1 (1985), Table 3.5.
               d = 0.7506; % Coefficient for fighter aicraft, given for S_wetrest equation, provided by Roskam's Aircraf Design Volume 1 (1985), Table 3.5.
               S_wet = 10^(c) * W_TO^(d); % ft^2
          end

          % Estimate exposed surface area (lifting surface)
          % Source: Brandt, "F16A", "Geom" sheet, cell H7.
          function S_exposed = get_S_exposed(tip_length, exposed_rc, exposed_halfspan)
               S_exposed = exposed_halfspan*(exposed_rc + tip_length);
          end

          % Estimate exposed wetted areas (lifting surfaces)
          function S_exposed = get_S_wet_wing(S_exposed, tc)
               S_exposed = S_exposed*(1.977 + 0.52*tc); % Brandt, "Geom" sheet, cell B13
          end

          % Estimate wetted area (fuselage) (Brandt's 2/3 cylinder + 1/3
          % cone approximation)
          function S_wet_fuselage = get_S_wet_fuselage(fuselage_length, fuselage_max_width, max_height)
               S_wet_fuselage = (5/6) * fuselage_length * (fuselage_max_width + max_height)*2*pi/4;
          end

          % Estimate wing sweep at quarter-chord (deg)
          function qc_sweep = get_sweep_qc(b, LE_sweep_deg, root_chord, tip_chord)
               qc_sweep = atand(tand(LE_sweep_deg) - (root_chord - tip_chord)/(2*b));
          end

          % Size the tail
          function [S_HT, S_VT] = Tail_Sizing(c_VT, c_HT, b_W, Sref_w, L_fus, Cbar_W)

               % NOTE: S_REF IS USED BUT ITS SUPPOSED TO BE S_REF OF THE
               % MAIN WINGS
               % Assuming tail located 80% down fuselage
               L_VT = L_fus*0.8;
               L_HT = L_fus*0.8; % Allow operator to adjust this, later.

               obj.VT.L = L_VT;
               obj.HT.L = L_HT;

               S_VT = c_VT*b_W*Sref_w/obj.VT.L; % eq 6.28, 2nd edition

               S_HT = c_HT*Cbar_W*Sref_w/obj.HT.L; % eq 6.29, 2nd edition

               obj.VT.S_ref = S_VT;
               obj.HT.S_ref = S_HT;

          end
     end

     methods (Access = private)
     end
end