classdef (Abstract) WeightsModelL3 < WeightsBase
%WEIGHTSMODELL3  Tier-2 abstract enforcer for Level-3 weights: the
%   [Raymer 6th ed. Sec. 15.3.1] fighter/attack component buildup, Eqs.
%   15.1-15.24, plus [Raymer 7th ed. Eq. 10.10] for the dry engine weight.
%   Inherits WeightsBase; declares the abstract members a concrete L3 class
%   must supply. Most geometry arrives by dependency injection.
%
%     OEW = structural + landing gear + engine section + systems
%
%   The DERIVED properties below must be Dependent getters on the concrete
%   class, never stored values.
%   History and rationale: docs/decision_log.md.
%   Toolbox companion: src/disciplines/weights/WeightsL3.md

     properties (Abstract)
          W_wings            % DERIVED [lbf]  [Eq. 15.1]
          W_tail             % DERIVED struct(HT, VT) [lbf]  [Eq. 15.2, 15.3]
          W_fuselage         % DERIVED [lbf]  [Eq. 15.4]
          W_installed_engine % DERIVED group total [lbf]  [Eq. 15.7-15.15]
          W_subsystems       % DERIVED group total [lbf]  [Eq. 15.16-15.24]
          %                    Does NOT include the landing gear: OEW adds
          %                    weight_landing_gear's .main + .nose separately.
     end

     methods (Abstract)

          %WEIGHT_WING  [Raymer 6th ed. Eq. 15.1]
          W = weight_wing(obj, W_TO)

          %WEIGHT_TAIL  Struct with fields HT and VT.
          %   [Raymer 6th ed. Eq. 15.2 and 15.3]
          W = weight_tail(obj, W_TO)

          %WEIGHT_FUSELAGE  [Raymer 6th ed. Eq. 15.4]
          W = weight_fuselage(obj, W_TO)

          %WEIGHT_LANDING_GEAR  Struct with fields main and nose.
          %   [Raymer 6th ed. Eq. 15.5 and 15.6]
          %   W_TO is REQUIRED: the landing weight the equations take is derived
          %   from it, so the group scales with gross weight.
          W = weight_landing_gear(obj, W_TO)

          %WEIGHT_ENGINE_SECTION  Propulsion group [lbf], struct of members plus
          %   .total.  Dry engine [Raymer 7th ed. Eq. 10.10] plus mounts (15.7),
          %   firewall (15.8), section (15.9), induction (15.10), tailpipe
          %   (15.11), cooling (15.12), oil (15.13), controls (15.14), starter
          %   (15.15).
          %   The engine weight passed in must be UNINSTALLED: those items ARE
          %   the installation, so a lumped x1.3 factor would double-count them.
          W = weight_engine_section(obj, W_TO)

          %WEIGHT_SYSTEMS  Systems group [lbf], struct of members plus .total.
          %   [Raymer 6th ed. Eq. 15.16-15.24]. Contains no landing-gear term.
          W = weight_systems(obj, W_TO)

     end

end
