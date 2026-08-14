classdef (Abstract) AeroModelL1 < AerodynamicsBase
%AEROMODELL1  Tier-2 abstract enforcer for Level-1 aerodynamics.
%
%   Inherits AerodynamicsBase directly, not another AeroModelLN.
%
%   Geometry-free is the TYPE-CURVE variant, not a tier invariant. The
%   F16AeroL1 path is geometry-FREE: it supplies the type-curve and
%   classification inputs from its .aerodynamics JSON block (Roskam-table CD0
%   and CLmax) and takes no geometry object. A concrete L1 aero class MAY,
%   however, inject a geometry object when its CD0 model needs a live wetted
%   area -- e.g. B777AeroL1 injects a geometry object to compute
%   CD0 = Cfe * S_wet / S_ref on every read (the metabook Eq. 4.58 / Eq. 4.8
%   wetted-area coupling, so CD0 tracks the wing area an optimizer mutates).
%   Either way the concrete class delegates to the AeroL1 toolbox.
%
%   The base already declares drag_polar and get_CLmax; this enforcer adds no
%   further abstract members.
%
%   Toolbox companion: src/disciplines/aerodynamics/AeroL1.md

end
