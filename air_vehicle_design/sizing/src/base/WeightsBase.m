classdef (Abstract) WeightsBase < handle
     %WEIGHTSBASE  Tier-1 base enforcer for all weight estimation discipline classes.
     %
     %   Declares OEW(obj, W_TO) -> scalar lbf as the top-level method, plus
     %   the four sizing-loop weight properties that all student classes must expose.
     %
     %   Sizing-loop closure:  W_TO = OEW + W_energy + W_payload_fixed + W_payload_expendable
     %
     %   Closure sanity against the ground truth, at Brandt's converged point:
     %     31377 - 19980.70 - 6296.30 = 5100.00 = 700 + 4400
     %     [Brandt Wt!B3 / Wt!B12 / Wt!B6 / Wt!B4 / Wt!B5, live-read 2026-07-25;
     %      docs/weights_parameter_usage.md Part A]
     %
     %   ! DOCUMENTED GAP (flagged, not fixed this phase): no WeightsL{1,2,3}
     %   static reads W_energy, W_payload_fixed or W_payload_expendable, so the
     %   closure identity above is NOT enforced anywhere yet. That is correct for
     %   now -- the sizing loop does not exist -- but it means those three
     %   properties are currently inert. See docs/weights_parameter_usage.md
     %   Part A ("AS-IS gap").
     %
     %   Inheritance chain per fidelity level:
     %     WeightsBase -> WeightsModelLN (abstract) -> F16WeightsLN (student class)
     %
     %   WeightsL1/L2/L3 are standalone static toolboxes -- NOT in this chain.
     %   Student classes call them via WeightsL1.method(obj, W_TO) etc.
     %
     %   CONSTRUCTOR SIGNATURES of the F-16A concretes (Phase 4, 2026-07-25) --
     %   every argument required, no silent default:
     %     F16WeightsL1(json_path)                       % no DI at all
     %     F16WeightsL2(json_path, req_path, geom, prop) % geom = F16GeomL2
     %     F16WeightsL3(json_path, req_path, geom, prop) % geom = F16GeomL3
     %   json_path  = f16a_spec_path(N)         -> the level's .weights block
     %   req_path   = f16a_requirements_path()  -> design_mach, cruise condition

     properties (Abstract)
          W_TO               % candidate gross takeoff weight [lbf]; NaN until the sizing loop sets it
          W_energy           % total internal fuel/battery weight [lbf]; NaN until mission analysis sets it
          W_payload_expendable % expendable payload (stores) weight [lbf]
          W_payload_fixed    % fixed equipment weight [lbf] (includes crew)
     end

     methods (Abstract)

          %OEW  Operating empty weight [lbf] at a candidate takeoff weight.
          %   W_TO - candidate gross takeoff weight [lbf].
          %   Returns OEW [lbf].  Must satisfy OEW < W_TO for all physical designs.
          %
          %   OEW stays a METHOD at every fidelity level, deliberately: it takes
          %   W_TO as an ARGUMENT, so it recomputes on every call and can never
          %   go stale. The inputs-vs-Dependent rule (CLAUDE.md, "Optimization-
          %   ready property design") governs *stored* derived state; a method
          %   whose result is a pure function of its arguments is already
          %   correct-by-construction. Concrete classes must therefore never
          %   cache an OEW value, and every W_TO-dependent term inside OEW must
          %   be evaluated at the PASSED W_TO -- not at obj.W_TO (that confusion
          %   was review finding #5, docs/weights_parameter_usage.md F.2).
          oew = OEW(obj, W_TO)

     end

end
