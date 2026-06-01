classdef SensitivityStudiesL1
     %TRADESTUDIES Breguet partial derivatives for preliminary trade studies.
     %
     % Source: Roskam, Airplane Design Part I, Table 2.20
     %
     % Notes from table:
     %   Propeller-driven:
     %       R in statute miles
     %       V in mph
     %
     %   Jet:
     %       R in nautical miles or statute miles
     %       V in knots or mph
     %
     % Inputs:
     %   R     = range
     %   E     = endurance
     %   V     = velocity
     %   LD    = lift-to-drag ratio, L/D
     %   c_j   = jet TSFC, lb/lb/hr
     %   c_p   = propeller TSFC, lb/hp/hr
     %   eta_p = propeller efficiency

     methods (Static)

          %% ============================================================
          %  PROPELLER-DRIVEN AIRPLANES
          %  ============================================================

          % Range case, y = R
          function output = prop_dRbar_dR(c_p, eta_p, LD)
               output = c_p ./ (375 .* eta_p .* LD);
          end

          % Endurance case, y = E
          function output = prop_dEbar_dE(V, c_p, eta_p, LD)
               output = V .* c_p ./ (375 .* eta_p .* LD);
          end

          % Range case, y = c_p
          function output = prop_dRbar_dcp(R, eta_p, LD)
               output = R ./ (375 .* eta_p .* LD);
          end

          % Endurance case, y = c_p
          function output = prop_dEbar_dcp(E, V, eta_p, LD)
               output = E .* V ./ (375 .* eta_p .* LD);
          end

          % Range case, y = eta_p
          function output = prop_dRbar_deta(R, c_p, eta_p, LD)
               output = -R .* c_p ./ (375 .* eta_p.^2 .* LD);
          end

          % Endurance case, y = eta_p
          function output = prop_dEbar_deta(E, V, c_p, eta_p, LD)
               output = -E .* V .* c_p ./ (375 .* eta_p.^2 .* LD);
          end

          % Endurance case, y = V
          % Range case for y = V is not applicable for propeller-driven aircraft.
          function output = prop_dEbar_dV(E, c_p, eta_p, LD)
               output = E .* c_p ./ (375 .* eta_p .* LD);
          end

          % Range case, y = L/D
          function output = prop_dRbar_dLD(R, c_p, eta_p, LD)
               output = -R .* c_p ./ (375 .* eta_p .* LD.^2);
          end

          % Endurance case, y = L/D
          function output = prop_dEbar_dLD(E, V, c_p, eta_p, LD)
               output = -E .* V .* c_p ./ (375 .* eta_p .* LD.^2);
          end


          %% ============================================================
          %  JET AIRPLANES
          %  ============================================================

          % Range case, y = R
          function output = jet_dRbar_dR(c_j, V, LD)
               output = c_j ./ (V .* LD);
          end

          % Endurance case, y = E
          function output = jet_dEbar_dE(c_j, LD)
               output = c_j ./ LD;
          end

          % Range case, y = c_j
          function output = jet_dRbar_dcj(R, V, LD)
               output = R ./ (V .* LD);
          end

          % Endurance case, y = c_j
          function output = jet_dEbar_dcj(E, LD)
               output = E ./ LD;
          end

          % Range case, y = V
          % Endurance case for y = V is not applicable for jet aircraft.
          function output = jet_dRbar_dV(R, c_j, V, LD)
               output = -R .* c_j ./ (V.^2 .* LD);
          end

          % Range case, y = L/D
          function output = jet_dRbar_dLD(R, c_j, V, LD)
               output = -R .* c_j ./ (V .* LD.^2);
          end

          % Endurance case, y = L/D
          function output = jet_dEbar_dLD(E, c_j, LD)
               output = -E .* c_j ./ (LD.^2);
          end

     end
end