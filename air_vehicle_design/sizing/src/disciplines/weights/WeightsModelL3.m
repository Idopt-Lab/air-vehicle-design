classdef (Abstract) WeightsModelL3 < WeightsBase
     %WEIGHTSMODELL3  Tier-2a abstract enforcer for Level-3 weight estimation.
     %
     %   Inherits WeightsBase directly (NOT WeightsModelL1 or L2).
     %
     %   Level-3 method: Raymer §15.3.1 Fighter/Attack statistical component
     %   buildup. Each group is declared as an abstract method; WeightsL3
     %   implements them. The concrete class supplies the aircraft-specific
     %   geometry and systems inputs — at L3 most of the geometry arrives by
     %   dependency injection from a geometry object rather than as literals.
     %
     %   OEW = structural group + landing gear + engine-section group
     %         + systems group.
     %
     %   SOURCE:
     %     Raymer, "Aircraft Design: A Conceptual Approach," 7th ed., AIAA,
     %     §15.3.1 — Fighter/Attack Statistical Weights (Eqs. 15.1–15.24),
     %     plus Raymer Eq. 10.10 for the dry engine weight, which is NOT a
     %     §15.3.1 equation.
     %     ! Every §15.3.1 exponent is a standing verify-against-the-book TO-DO;
     %       the full 62-row checklist is in WeightsL3.m's header and
     %       VnV/BrandtF16A/todo.md 2026-07-24 Weights §3a.
     %
     %   ! THE FIVE PROPERTIES BELOW ARE COMPUTED OUTPUTS, NOT STORED STATE.
     %   A concrete class MUST satisfy each with a `properties (Dependent)`
     %   getter recomputing live from its inputs on every read. Before
     %   2026-07-25 F16WeightsL3 satisfied all five with `= NaN` and no code ever
     %   assigned them, so a consumer reading the documented contract got NaN
     %   (review finding #12; todo 2026-07-24 §3c item 6). A property documented
     %   as computed must never be able to read NaN.
     %
     %   Inheritance: WeightsBase → WeightsModelL3 → F16WeightsL3
     %   (WeightsL3 is the static toolbox alongside, NOT in the chain.)

     properties (Abstract)
          W_wings            % DERIVED wing structural weight [lbf]  [Eq. 15.1]
          W_tail             % DERIVED tail weights, struct(HT, VT) [lbf]  [Eqs. 15.2-15.3]
          W_fuselage         % DERIVED fuselage structural weight [lbf]  [Eq. 15.4]
          W_installed_engine % DERIVED engine-section GROUP total [lbf] = dry engine [Eq. 10.10] + Eqs. 15.7-15.15
          W_subsystems       % DERIVED systems GROUP total [lbf]  [Eqs. 15.16-15.24]
          %                    ! Does NOT include the landing gear. The comment on
          %                    this property used to read "Includes landing gear",
          %                    which was false: WeightsL3.weight_systems contains no
          %                    landing-gear term, and WeightsL3.OEW adds
          %                    weight_landing_gear's .main + .nose SEPARATELY.
          %                    Corrected 2026-07-25 rather than adding a sixth
          %                    property, keeping the settled L3 derived-property
          %                    set at the documented 31. The gear total is reached
          %                    through weight_landing_gear(obj, W_TO).
          %                    todo 2026-07-25 Phase 4 §P4-10.
     end

     methods (Abstract)

          %WEIGHT_WING  Wing structural weight [lbf].  [Raymer 7th ed. Eq. 15.1]
          W = weight_wing(obj, W_TO)

          %WEIGHT_TAIL  Horizontal + vertical tail structural weight [lbf].
          %   [Raymer 7th ed. Eqs. 15.2-15.3]  Returns struct with fields HT and VT.
          W = weight_tail(obj, W_TO)

          %WEIGHT_FUSELAGE  Fuselage structural weight [lbf].  [Raymer 7th ed. Eq. 15.4]
          W = weight_fuselage(obj, W_TO)

          %WEIGHT_LANDING_GEAR  Main + nose landing-gear weight [lbf].
          %   [Raymer 7th ed. Eqs. 15.5-15.6]  Returns struct with fields main and nose.
          %   ! SIGNATURE CHANGED 2026-07-25 (Phase 4): W_TO is now REQUIRED. The
          %   landing weight W_l that Eqs. 15.5/15.6 take is derived from it
          %   (WeightsL3.landing_weight). It previously took no W_TO and read a
          %   frozen W_l = 20681 [Brandt Wt!B41, an OUTPUT], which made the whole
          %   gear group insensitive to gross weight — identical at W_TO =
          %   31,377 / 45,000 / 60,000. Both the frozen W_l AND the missing
          %   argument had to go or the group stayed dead.
          %   todo 2026-07-25 Phase 4 §P4-17.
          W = weight_landing_gear(obj, W_TO)

          %WEIGHT_ENGINE_SECTION  Total propulsion group weight [lbf].
          %   Includes: dry/UNINSTALLED engine weight (Raymer Eq. 10.10, supplied
          %   by the concrete class — not a §15.3.1 equation), engine mounts
          %   (15.7), firewall (15.8), engine section (15.9), air induction
          %   (15.10), tailpipe (15.11), engine cooling (15.12), oil cooling
          %   (15.13), engine controls (15.14), starter (15.15).
          %   Returns struct with one field per sub-component plus .total.
          %   ! The engine weight passed in must be UNINSTALLED at this level: the
          %   items above ARE the installation, so the metabook's ×1.3
          %   installed/bare factor would double-count them. ×1.3 is L2-only
          %   (settled decision 1, 2026-07-25; todo §P4-1b).
          W = weight_engine_section(obj, W_TO)

          %WEIGHT_SYSTEMS  Fuel, flight controls, avionics, furnishings group [lbf].
          %   Includes: fuel system (15.16), flight controls (15.17), instruments
          %   (15.18), hydraulics (15.19), electrical (15.20), avionics (15.21),
          %   furnishings (15.22), air cond/anti-ice (15.23), handling gear (15.24).
          %   Returns struct with one field per sub-component plus .total.
          %   Contains NO landing-gear term — see W_subsystems above.
          W = weight_systems(obj, W_TO)

     end

end
