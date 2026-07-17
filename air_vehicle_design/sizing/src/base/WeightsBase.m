classdef (Abstract) WeightsBase < handle
     %WEIGHTSBASE  Tier-1 base enforcer for all weight estimation discipline classes.
     %
     %   Declares OEW(obj, W_TO) → scalar lbf as the top-level method, plus
     %   the five sizing-loop weight properties that all student classes must expose.
     %
     %   Sizing-loop closure:  W_TO = OEW + W_energy + W_payload_fixed + W_payload_expendable
     %
     %   Inheritance chain per fidelity level:
     %     WeightsBase → WeightsModelLN (abstract) → F16WeightsLN (student class)
     %
     %   WeightsL1/L2/L3 are standalone static toolboxes — NOT in this chain.
     %   Student classes call them via WeightsL1.method(obj, W_TO) etc.

     properties (Abstract)
          W_TO               % candidate gross takeoff weight [lbf]; set by sizing loop
          W_energy           % total internal fuel/battery weight [lbf]
          W_payload_expendable % payload weight [lbf]
          W_payload_fixed    % fixed equipment weight [lbf] (includes crew)
     end

     methods (Abstract)

          %OEW  Operating empty weight [lbf] at a candidate takeoff weight.
          %   W_TO — candidate gross takeoff weight [lbf].
          %   Returns OEW [lbf].  Must satisfy OEW < W_TO for all physical designs.
          oew = OEW(obj, W_TO)

     end

end
