classdef (Abstract) AeroModelL1 < AerodynamicsBase
%AEROMODELL1  Tier-2 abstract enforcer for Level-1 aerodynamics.
%
%   Inherits AerodynamicsBase directly (NOT a subclass of AeroModelL2/L3 --
%   each fidelity enforcer independently inherits the base).
%
%   LEVEL-1 = aircraft-type only, NO geometry (Mattingly type-curves):
%     drag_polar : CD = CD0(M) + K1(M)*CL^2 + K2*CL   Mattingly AED 2nd ed. Eq. 2.9
%                  CD0(M) from Fig. 2.10, K1(M) from Fig. 2.11 ("Current"
%                  fighter curve), interpolated by Mach; fighters set K2 = 0
%                  (uncambered, Mattingly Sec. 2.3.1).
%     get_CLmax  : type-based lookup                  Roskam Vol. I Table 3.1/3.3
%
%   The base already declares drag_polar/get_CLmax abstract; this enforcer adds
%   no further abstract members -- L1 owns no geometry-dependent contract. A
%   concrete L1 class supplies the aircraft-type / technology-curve inputs
%   (from the <aircraft> L1 JSON's .aerodynamics block, incl. the Mattingly Fig.
%   2.10/2.11 curve tables, then delegates drag_polar/get_CLmax to the AeroL1
%   static toolbox.

end
