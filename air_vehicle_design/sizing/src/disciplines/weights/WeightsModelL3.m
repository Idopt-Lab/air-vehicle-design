classdef (Abstract) WeightsModelL3 < WeightsBase
%WEIGHTSMODELL3  Tier-2 abstract enforcer for Level-3 weights: the
%   [Raymer 6th ed. Sec. 15.3.1] fighter/attack component buildup, Eqs.
%   15.1-15.24 and Table 15.3, plus [Raymer 7th ed. Eq. 10.10] for the
%   dry engine weight.
%   Inherits WeightsBase; declares the abstract members a concrete L3 class
%   must supply. Most geometry arrives by dependency injection.
%
%     OEW = structural + landing gear + engine group + systems + misc
%
%   The DERIVED properties below must be Dependent getters on the concrete
%   class, never stored values.
%   History and rationale: docs/decision_log.md.
%   Toolbox companion: src/disciplines/weights/WeightsL3.md

     properties (Abstract)
          W_wings            % DERIVED [lbf]  [Eq. 15.1]
          W_installed_engine % DERIVED group total [lbf]  [Eq. 15.7-15.15 + Eq. 10.10]
          W_subsystems       % DERIVED group total [lbf]  [Eq. 15.16-15.21, 15.23]
          %                    Does NOT include the landing gear: OEW adds
          %                    the gear group separately.
          W_landing          % Design weight at landing segment [lbf]. The
          %                    sizing loop writes it from the mission.
     end

     methods (Abstract)

          % Get OEW of design
          OEW = get_OEW_component_buildup(obj, W_TO)

          %WEIGHT_WING  [Raymer 6th ed. Eq. 15.1]
          W = get_weight_wing(obj, W_TO)

          %GET_WEIGHT_ENGINE  Propulsion group [lbf]. Dry engine [Raymer 7th
          %   ed. Eq. 10.10] plus mounts (15.7), firewall (15.8), section
          %   (15.9), induction (15.10), tailpipe (15.11), cooling (15.12),
          %   oil (15.13), controls (15.14), starter (15.15).
          %   The dry engine must be UNINSTALLED: those items ARE the
          %   installation, so a lumped x1.3 factor would double-count them.
          W = get_weight_engine(obj)

          %GET_WEIGHT_SUBSYSTEMS  Systems group [lbf].
          %   [Raymer 6th ed. Eq. 15.16-15.21 and 15.23]. Contains no
          %   landing-gear term, and no furnishings or handling gear: those
          %   two are Eqs. 15.22/15.24 and belong to the misc group.
          W = get_weight_subsystems(obj)

     end

     methods
          function v = get_OEW(obj, W_TO)
               v = obj.get_OEW_component_buildup(W_TO);
          end
     end

end
