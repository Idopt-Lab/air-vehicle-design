classdef (Abstract) WeightsModelL3 < WeightsBase
     %WEIGHTSMODELL3  Tier-2a abstract enforcer for Level-3 weight estimation.
     %
     %   Inherits WeightsBase directly (NOT WeightsModelL1 or L2).
     %
     %   Level-3 method: Raymer §15.3.1 Fighter/Attack component-buildup.
     %   Each group is declared as an abstract method; WeightsL3 implements them.
     %   The student class provides all aircraft-specific geometry inputs.
     %
     %   OEW = sum of structural group + engine section group + systems group.
     %
     %   SOURCE:
     %     Raymer, "Aircraft Design: A Conceptual Approach," 6th ed., AIAA, 2018,
     %     §15.3.1 — Fighter/Attack Statistical Weights (Eqs. 15.1–15.24).
     %
     %   Inheritance: WeightsBase → WeightsModelL3 → F16WeightsL3

     properties (Abstract)
          W_wings
          W_tail
          W_fuselage
          W_installed_engine
          W_subsystems % Includes landing gear

     end

     methods (Abstract)

          %WEIGHT_WING  Wing structural weight [lbf].  [Raymer Eq. 15.1]
          W = weight_wing(obj, W_TO)

          %WEIGHT_TAIL  Horizontal + vertical tail structural weight [lbf].  [Raymer Eqs. 15.2-15.3]
          %   Returns struct with fields HT [lbf] and VT [lbf].
          W = weight_tail(obj, W_TO)

          %WEIGHT_FUSELAGE  Fuselage structural weight [lbf].  [Raymer Eq. 15.4]
          W = weight_fuselage(obj, W_TO)

          %WEIGHT_LANDING_GEAR  Main + nose landing-gear weight [lbf].  [Raymer Eqs. 15.5-15.6]
          %   Returns struct with fields main [lbf] and nose [lbf].
          W = weight_landing_gear(obj)

          %WEIGHT_ENGINE_SECTION  Engine support + propulsion systems group [lbf].
          %   Includes: engine mounts (15.7), firewall (15.8), engine section (15.9),
          %   air induction (15.10), tailpipe (15.11), engine cooling (15.12),
          %   oil cooling (15.13), engine controls (15.14), starter (15.15).
          %   Returns struct with one field per sub-component plus .total.
          W = weight_engine_section(obj, W_TO)

          %WEIGHT_SYSTEMS  Avionics, fuel, flight controls, and furnishings group [lbf].
          %   Includes: fuel system (15.16), flight controls (15.17), instruments (15.18),
          %   hydraulics (15.19), electrical (15.20), avionics (15.21),
          %   furnishings (15.22), air cond/anti-ice (15.23), handling gear (15.24).
          %   Returns struct with one field per sub-component plus .total.
          W = weight_systems(obj, W_TO)

     end

end
