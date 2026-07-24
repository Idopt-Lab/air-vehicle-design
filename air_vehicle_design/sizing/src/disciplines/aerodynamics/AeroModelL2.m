classdef (Abstract) AeroModelL2 < AerodynamicsBase
%AEROMODELL2  Tier-2 abstract enforcer for Level-2 aerodynamics.
%
%   Inherits AerodynamicsBase directly (NOT a subclass of AeroModelL1/L3).
%
%   LEVEL-2 = geometry-DEPENDENT clean drag polar + finite-wing lift. All
%   geometry is read live from an injected geometry object (dependency
%   injection); the aero class owns NO geometry numbers.
%     CD0 (subsonic)   : Cfe*(S_wet/S_ref)                 Raymer 6th ed. Eq. 12.23 / Table 12.3
%     CD0 (supersonic) : Cf(Re,M)*(S_wet/S_ref), Cf Eq.12.27  Raymer 6th ed. Eq. 12.27
%     K1               : 1/(pi*AR*e)                       Raymer 6th ed. Eq. 12.50
%       official e     : Eq. 12.48 (Lambda_LE<30) / 12.49  Raymer 6th ed. Eq. 12.48/12.49
%     K2               : -2*K1*CL_minD (0 if uncambered)   Brandt Sec. 4.3 / Aero!G17
%     CLmax (clean)    : 0.9*cl_max_2D*cos(Lambda_c/4)     Raymer 6th ed. Eq. 12.15
%     CL_alpha         : finite-wing Datcom slope          Raymer 6th ed. Eq. 12.6
%
%   The base already declares drag_polar/get_CLmax abstract; this enforcer adds
%   no further abstract members. A concrete L2 class supplies the aero-only
%   inputs (Cfe, airfoil section data, e-method selector -- from
%   the <aircraft> L2 JSON's .aerodynamics block), holds the injected geometry
%   object, and delegates to the AeroL2 static toolbox.

end
