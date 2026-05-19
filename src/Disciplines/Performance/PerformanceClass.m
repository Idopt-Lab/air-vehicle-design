classdef PerformanceClass
     %PERFORMANCECLASS Summary of this class goes here
     %   This is a collection of performance equations.
     % Split between props, jets, and electric/unorthodox engines.

     methods (Static)

          %% PROPS


          %% JETS


          %% ELECTRIC
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



          %% OTHER
          % Hydrogen

          % Nuclear

     end
end