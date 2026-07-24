classdef (Abstract) AeroModelL3 < AerodynamicsBase
%AEROMODELL3  Tier-2 abstract enforcer for Level-3 aerodynamics.
%
%   Inherits AerodynamicsBase directly (NOT a subclass of AeroModelL1/L2).
%
%   LEVEL-3 = component drag build-up (Raymer 6th ed. Eq. 12.24). All component
%   geometry (per-component wetted area, reference length, diameter, t/c,
%   max-thickness-line sweep) is read live from an injected geometry object;
%   the aero class owns NO geometry numbers, only genuinely-aero constants
%   (interference Q, laminar fraction, surface roughness, body/surface flags,
%   airfoil data, wave-drag factor, misc-drag allowances).
%     CD0 = [sum_c (Cf_c*FF_c*Q_c*S_wet_c)]/S_ref + CD0_misc + CD0_LandP
%       per-component Cf : laminar Eq. 12.26 / turbulent Eq. 12.27
%       form factors     : surface Eq. 12.30 / body Eq. 12.31
%     + supersonic wave drag (M >= 1.2)                Raymer 6th ed. Eq. 12.41
%     K1/K2/CLmax        : same forms as L2 (Eq. 12.48-12.51, Eq. 12.15)
%
%   The base already declares drag_polar/get_CLmax abstract; this enforcer adds
%   no further abstract members. A concrete L3 class supplies the aero-only
%   constants (from the <aircraft> L3 JSON's .aerodynamics block), holds the
%   injected geometry object, and delegates the buildup to the AeroL3 static
%   toolbox (adding its own aircraft-specific wave-drag term on top).

end
