classdef PerformanceClass
     %PERFORMANCECLASS Summary of this class goes here
     %   This is a collection of performance equations.
     % Split between props, jets, and electric/unorthodox engines.

     methods (Static)


          %% TAKEOFF -----------------------------------------------





          %% GENERAL -----------------------------------------------
          % Weight rate of change as fuel burns
          % Raymer, 17.3, 6th ed
          function W_dot = compute_W_dot(SFC, T)
               % Where:
               % SFC = Specific fuel consumption
               % T = thrust
               % Outputs:
               % W_dot = Rate at which the aircraft weight changes (mass or weight
               % per unit time)
               W_dot = -SFC*T;
          end

          % Velocity for steady level flight
          % Raymer, eq 17.10, 6th ed
          function V_level = compute_V_steady_level(rho, CL, W_S)
               % Where:
               % rho = air density
               % CL = Lift coefficient
               % W_S = Instantaneous wing loading
               V_level = sqrt((2/(rho*CL)) * (W_S));
          end

          % TW for steady, level flight
          % Raymer, eq 17.11, 6th ed
          function TW_level = compute_TW_steady_level(q, CD0, W_S, K)
               % Where
               % q = dynamic pressure
               % CD0 = Zero-lift drag coefficient
               % W_S = Wing loading
               % K = 1/(pi*e_osw*AR)
               TW_level = (q*CD0)/(W_S) + (W_S)*(K/q);
          end

          % Compute minimum velocity corresponding to lowest thrust/drag
          % Raymer, eq 17.13, 6th ed
          function V_min_T = compute_V_minT(W, rho, S_ref, K, CD0)
               % Where:
               % W = Instantaneous aircraft weight
               % rho = Local medium density
               % S_ref = Planform reference area
               % K = 1/(pi*e_osw*AR)
               % CD0 = Zero-lift drag coefficient
               % You knew all that, didn't you?
               V_min_T = sqrt( (2*W)/(rho*S_ref) *sqrt((K/(CD0))));
          end

          % Compute minimum CL corresponding to lowest thrust/drag
          % Raymer, eq 17.14, 6th ed
          function CL_min_T = compute_CL_minT(CD0, K)
               CL_min_T = sqrt(CD0/K);
          end

          % Compute the minimum drag corresponding to lowest thrust/drag
          % Raymer, eq 17.15, 6th ed
          function D_min_T = compute_D_minT(q, S_ref, CD0)
               D_min_T = q*S_ref*2*CD0;
          end

          % Compute minimum power required for steady, level flight
          % Raymer, eq 17.17, 6th ed
          function P_min = compute_P_min(rho, V, S_ref, CD0, K, W)
               P_min = 0.5*rho*V^3*S_ref*CD0 + (K*W^2)/(0.5*rho*V*S_ref);
          end

          % Compute velocity at minimum power
          % Raymer, eq 17.19, 6th ed
          function V_min_P = compute_V_minP(W, rho, S_ref, K, CD0)
               V_min_P = sqrt( (2*W)/(rho*S_ref) * sqrt(K/(3*CD0)));
          end

          % Compute CL at minimum power
          % Raymer, eq 17.20, 6th ed
          function CL_min_P = compute_CL_minP(CD0, K)
               CL_min_P = sqrt(3*CD0/K);
          end

          % Compute D at minimum power
          % Raymer, eq 17.21, 6th ed
          function D_min_P = compute_D_minP(q, S_ref, CD0)
               D_min_P = q*S_ref*4*CD0;
          end

          % Range
          % Raymer, eq 17.23, 6th ed
          function R = compute_R(V, SFC, LD, W_i, W_f)
               % Where:
               % V = Instantaneous velocity
               % SFC = specific fuel consumption
               % LD = Lift-to-drag ratio
               % W_i = Initial weight
               % W_f = Final weight
               % Outputs:
               % R = Cruise range (distance units)
               R = (V/SFC)*LD*ln(W_i/W_f);
          end

          % Endurance/loiter
          % Raymer, eq 17.30, 6th ed
          function E = compute_E(LD, SFC, W_i, W_f)
               % Outputs:
               % E = Endurance/loiter time (units of time)
               E = LD*(1/SFC)*ln(W_i/W_f);
          end

          % Equivalent loiter time fro known cruise range and cruise
          % velocity
          % Raymer, eq 17.34, 6th ed
          function E_loiter = compute_equiv_loiter(R_cruise, V_cruise)
               % Where:
               % R_cruise = Cruise range
               % V_cruise = Cruise airspeed
               % Outputs:
               % E_loiter = Equivalent loiter time

               E_loiter = 1.14*(R_cruise/V_cruise);
          end

          % Groundspeed along desired flight direction, if there's
          % tailwind/headwind.
          % Raymer, eq 17.35, 6th ed
          function V_groundspeed = compute_V_groundspeed(V_airspeed, delta_tailwind_rad, V_wind)
               % Where:
               % V_airspeed = Airspeed velocity
               % delta_tailwind = 180 deg - angle between V_airspeed &
               % V_wind (RADIANS)
               % V_wind = Velocity of wind
               % Outputs:
               % V_groundspeed = Speed along the ground
               V_groundspeed = (V_airspeed * sin(pi - delta_tailwind_rad - asin(V_wind*(sin(delta_tailwind_rad)/V_airspeed))))/(sin(delta_tailwind_rad));
          end



          %% LEVEL TURNING FLIGHT -----------------------------------------------

          % Compute turn rate (rad/sec)
          % Raymer, eq 17.52, 6th ed
          function psi_dot = compute_turn_rate(g, n, V)
               % Where:
               % g = Local acceleration due to gravity
               % n = Load factor
               % V = Aircraft's velocity throughout the turn
               % Outputs:
               % psi_dot = turn rate (rad/sec)

               psi_dot = g*sqrt(n^2 - 1)/V;
          end

          % Compute maximum load factor for sustained turn rate at a given
          % flight condition
          % Raymer, eq 17.54
          function n_sus = compute_n_sus(q, K, W_S, T_W, CD0)
               n_sus = sqrt(q/(K*W_S) * (T_W - (q*CD0)/(W_S)));
          end







          %% GLIDING FLIGHT -----------------------------------------------

          % Determine glide angle for some LD
          % Raymer, eq 17.64, 6th ed
          function gamma = compute_glide_angle(LD)
               % Outputs:
               % gamma = climb angle (deg)
               gamma = atand(1/LD);
          end

          % Compute the maximum glide ratio (L/D)
          % Raymer, eq 17.67, 6th ed
          function LD_max = compute_max_glide_ratio(AR, e_osw, CD0)
               LD_max = 0.5*sqrt((pi*AR*e_osw)/CD0);
          end

          % Compute sink rate
          % Raymer, eq 17.70, 6th ed
          function V_v = compute_sink_rate(W_S, gamma_deg, CD, rho, CL)
               V_v = sqrt(W_S*(2*cosd(gamma_deg*CD^2)^3)/(rho*CL^3));
          end

          % Compute CL that gives the minimum sink rate
          % Raymer, eq 17.72, 6th ed
          function CL_min_sinkrate = compute_CL_min_sinkrate(CD0, K)
               CL_min_sinkrate = sqrt(3*CD0/K);
          end

          % Compute Velocity that yields minimum sink rate
          % Raymer, eq 17.73, 6th ed
          function V_min_sinkrate = compute_V_min_sinkrate(W, rho, S_ref, K, CD0)
               V_min_sinkrate = sqrt(2*W/(rho*S_ref) * sqrt(K/(3*CD0)));
          end

          % Compute minimum sink rate for some condition
          % Raymer, eq 17.74, 6th ed
          function sinkrate_min = compute_min_sinkrate(AR, e_osw, CD0)
               sinkrate_min = sqrt(3*pi*AR*e_osw/(16*CD0));
          end


          % TURNING GLIDING FLIGHT

          % Gliding turn radius
          % Raymer, eq 17.79, 6th ed
          function R_turn = compute_R_turn_gliding(V, g, phi_deg)
               % Where:
               % V = Aircraft velocity
               % g = Local acceleration due to gravity
               % phi = Bank angle (deg)
               % Output:
               % R_turn = Turn radius during the glide

               R_turn = V^2/(g * tand(phi_deg));
          end

          % Compute velocity of outer wing during a turn
          % Raymer, eq 17.82, 6th ed
          function V_w_out = compute_V_w_out(V_cg, Y, R, phi_deg)
               V_w_out = V_cg*(1 + Y/R*cosd(phi_deg));
          end

          % Compute velocity of innter wing during a turn
          % Raymer, eq 17.83, 6th ed
          function V_w_inner = compute_V_w_inner(V_cg, b, R, phi_deg)
               V_w_inner = V_cg*(1 - b/(2*R)*cosd(phi_deg));
          end













          %% CLIMBING AND DESCENDING FLIGHT -----------------------------------------------

          % Thrust for steady climb
          % Raymer, eq 17.36, 6th ed
          function T_climb = compute_T_steady_climb(D, W, gamma_deg)
               % Where:
               % D = Drag
               % W = Weight
               % gamma = Climb angle (deg)
               % Output:
               % T_climb = thrust for steady/unaccelerated climb
               T_climb = D + W*sind(gamma_deg);
          end

          % Lift for steady climb
          % Raymer, eq 17.37, 6th ed
          function L_climb = compute_L_steady_climb(W, gamma_deg)
               L_climb = W*cosd(gamma_deg);
          end

          % Climb angle for unaccelerated climb (thrust known, climb angle
          % isn't)
          % Raymer, eq 17.38, 6th ed.
          function gamma = compute_gamma(T_W, LD)
               % Outputs:
               % gamma = Climb angle (deg)
               gamma = asind(T_W - 1/LD);
          end

          % Vertical velocity during unaccelerated climb
          % Raymer, eq 17.39, 6th ed
          function V_v = compute_V_v(V, gamma_deg)
               V_v = V*sind(gamma_deg);
          end

          % Velocity required for steady climbing flight
          % Raymer, eq 17.40, 6th ed
          function V_climb = compute_V_climb(rho, CL, W_S, gamma_deg)
               V_climb = sqrt(2/(rho*CL) * W_S*cosd(gamma_deg));
          end

          % T/W ratio required for a steady, unaccelerated climb at some
          % climb angle, gamma.
          % Raymer, eq 17.41, 6th ed
          function TW_climb = compute_TW_climb_steady(gamma_deg, LD)
               TW_climb = cosd(gamma_deg)/LD + sind(gamma_deg);
          end

          % Time to climb
          % Raymer, eq 17.50, 6th ed
          % function t_next = compute_time_to_climb(t_










          %% PROPS -----------------------------------------------

          % Equivalent specific fuel consumption for piston-props
          % Raymer, eq 17.4, 6th ed
          function SFC_prop = compute_SFC_prop(C_bhp, V, eta_p)
               SFC_prop = C_bhp*V/(550*eta_p);
               % The 550 is in bhp unless explicitly stated otherwise
          end

          % Propeller thrust
          % Raymer, eq 17.5, 6th ed
          function T_prop = compute_T_prop(eta_p, V)
               T_prop = 550*eta_p/V;
          end


          % Range
          % Raymer, eq 17.28, 6th ed
          function R = compute_R_prop(eta_p, C_bhp, LD, W_i, W_f)
               % Where:
               % eta_p = Prop efficiency
               % C_bhp = SFC for prop? IDK
               % LD = Lift-to-drag ratio
               % W_i = Initial weight
               % W_f = final weight
               % Output:
               % R = Range (distance units)

               R = (550*eta_p)/(C_bhp) * LD * ln(W_i/W_f);
          end

          % Velocity that maximizes loiter time
          % Raymer, eq 17.33, 6th ed
          function V_max_E = compute_V_maxE_prop(W, rho, S_ref, K, CD0)
               V_max_E = sqrt((2*W)/(rho*S_ref) * sqrt((K/(3*CD0))));
          end

          % Best climb angle for prop
          % Raymer, 17.44, 6th ed
          function gamma = compute_gamma_best_prop(eta_p, V, W, D)
               gamma = asind(550*eta_p/(V*W) - D/W);
          end

          % Best climb velocity for prop
          % Raymer, 17.45, 6th ed
          function V_v = compute_V_v_best_prop(eta_p, V, W, D)
               V_v = 550*eta_p/W - D*V/W;
          end






          %% JETS -----------------------------------------------

          % Velocity for best range
          % Raymer, eq 17.25, 6th ed
          function V_best_R = compute_V_best_R_jet(W, rho, S_ref, K, CD0)
               V_best_R = sqrt((2*W)/(rho*S_ref) * sqrt((3*K)/(CD0)));
          end

          % CL for best range
          % Raymer, eq 17.26, 6th ed
          function CL_best_R = compute_CL_best_R_jet(CD0, K)
               CL_best_R = sqrt(CD0/(3*K));
          end

          % D for best range
          % Raymer, eq 17.27, 6th ed
          function D_best_R = compute_D_best_R_jet(q, S_ref, CD0)
               D_best_R = q*S_ref*(CD0 + CD0/3);
          end

          % Velocity for best climb rate at some altitude
          % Raymer, eq 17.42, 6th ed
          function V = compute_V_best_climb_jet(W_S, rho, CD0, T_W, K)
               V = sqrt( (W_S)/(3*rho*CD0) * (T_W + sqrt(T_W^2 + 12*CD0*K)));
          end




          %% ELECTRIC -----------------------------------------------
          % Runtime (hours)
          function runtime_electric = compute_runtime_electric(m_b, E_sb, eta_b2s, P_used)
               % Where:
               % m_b = Battery mass (total) (kg)
               % E_sb = Battery-specific energy (wh/kg)
               % eta_b2s = Total system efficiency from battery to motor output shaft
               % P_used = Average power used during that period of time (kW)

               runtime_electric = (m_b*E_sb*eta_b2s)/(1000*P_used);
          end

          % Power used
          function P_used = compute_P_used_electric(m, g, LD, V, eta_p)
               % Where
               % m = Vehicle mass (kg)
               % eta_p = Prop efficiency
               % g = Acceleration due to gravity (local) (m/s^2)
               % LD = Lift-to-drag ratio
               % V = Vehicle airspeed (m/s)

               P_used = (((m*g)/(LD))*V)/eta_p;
          end

          % Loiter time (hrs)
          function E_electric_hrs = compute_E_electric(LD, E_sb, eta_b2s, eta_p, m_b, g, V, m)
               % Where:
               % LD = Lift-to-drag ratio
               % E_sb = Battery-specific energy (wh/kg)
               % eta_b2s = Total system efficiency from battery to motor output shaft
               % eta_p = Prop efficiency
               % m_b = Total battery mass (kg)
               % g = Local acceleration due to gravity (m/s^2)
               % V = Aircraft speed (km/hr)
               % m = Aircraft mass (kg)

               E_electric_hrs = 3.6 * LD * ( (E_sb * eta_b2s * eta_p)/(g*V))*(m_b/m);
          end

          % Range (km)
          function R_electric_km = compute_R_electric(LD, E_sb, eta_b2s, eta_p, m_b, m, g)
               % Where:
               % LD = Lift-to-drag ratio
               % E_sb = Battery-specific energy (wh/kg)
               % eta_b2s = Total system efficiency from battery to motor
               % output shaft
               % eta_p = Prop efficiency
               % m_b = Total battery mass (kg)
               % m = Aircraft mass (kg)
               % g = local acceleration due to gravity (m/s^2)

               R_electric_km = 3.6*LD*( (E_sb*eta_b2s*eta_p)/g)*(m_b/m);
          end

          % Rate of climb (m/s)
          function V_v_electric = compute_climb_rate_electric(V, LD)
               % Where:
               % V = Velocity (km/h)
               % LD = Lift-to-drag ratio
               V_v_electric = V/(3.6*LD);
          end

          % Battery-Mass Fraction from known run time
          function BMF = compute_BMF_from_knownruntime(E, P_used, E_sb, eta_b2s, m)
               % Where:
               % E = Known Run-Time (hr)
               % E_sb = Battery specific energy (wh/kg)
               % eta_b2s = Total system efficiency from battery to motor
               % output shaft
               % P_used = Average power used during that period of time
               % (kW)
               % m = Aircraft mass (kg)
               BMF = 1000 * (E * P_used)/(E_sb*eta_b2s*m);
          end

          % Battery-Mass Fraction for loiter segments
          function BMF_loiter = compute_BMF_loiter(E, V, g, E_sb, eta_b2s, eta_p, LD)
               % Where:
               % E = Loiter time (hrs)
               % V = Velocity (km/h)
               % g = Local acceleration due to gravity (m/s^2)
               % E_sb = Battery specific energy (wh/kg)
               % eta_b2s = Total system efficiency from battery to motor
               % output shaft
               % eta_p = Propeller efficiency
               % LD = Lift-to-drag ratio
               BMF_loiter = (E*V*g)/(3.6*E_sb*eta_b2s*eta_p*LD);
          end

          % Battery-Mass Fraction for cruise segments
          function BMF_cruise = compute_BMF_cruise(R, g, E_sb, eta_b2s, eta_p, LD)
               % Where:
               % R = Range (km)
               % V = Velocity (km/h)
               % g = Local acceleration due to gravity (m/s^2)
               % E_sb = Battery specific energy (wh/kg)
               % eta_b2s = Total system efficiency from battery to motor
               % output shaft
               % eta_p = Propeller efficiency
               % LD = Lift-to-drag ratio
               BMF_cruise = (R*g)/(3.6*E_sb*eta_b2s*eta_p*LD);
          end

          % Battery-Mass Fraction for climb segment
          function BMF_climb = compute_BMF_climb(h, V_v, E_sb, eta_b2s, P_used, m)
               % Where:
               % h = Climb altitude required (m)
               % V_v = Vertical velocity (km/h)
               % E_sb = Battery specific energy (wh/kg)
               % eta_b2s = Total system efficiency from battery to motor
               % output shaft
               % P_used = Power used to climb (kW)
               % m = Aircraft mass (kg)
               BMF_climb = (h)/(3.6*V_v*E_sb*eta_b2s)*(P_used/m);
          end

          % Battery-Mass Fraction available
          function BMF_available = compute_BMF_available(W_0, W_e, W_payload)
               BMF_available = (W_0 - W_e - W_payload)/W_0;
          end

          % Electric aircraft sizing equation
          function W_electric = compute_W_electric(W_payload, BMF, W_e, W_0)
               W_electric = (W_payload)/(1-BMF-(W_e/W_0));
          end



          %% OTHER -----------------------------------------------
          % Hydrogen

          % Nuclear

     end
end