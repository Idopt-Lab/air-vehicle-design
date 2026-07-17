classdef (Abstract) AeroModelL1 < AerodynamicsBase
%AEROMODELL1  Tier-2a abstract enforcer for Level-1 aerodynamics.
%
%   Inherits AerodynamicsBase directly (NOT a subclass of AeroModelL2 or
%   AeroModelL3 — each fidelity enforcer independently inherits the base).
%
%   At Level 1 the drag polar is assembled from:
%     CD0  : Cf * (S_wet / S_ref)            Raymer 6th ed. §12.3
%     K1   : 1/(pi*AR*e_osw)   subsonic      Raymer 6th ed. Eq. 12.50
%            AR*beta*cos(LE)/(4*AR*beta-2)   supersonic   Raymer 6th ed. Eq. 12.51
%     K2   : -2*K1_sub*CL_minD subsonic      Brandt et al. §4.3
%            0                 M >= 1
%     CLmax: historical lookup by aircraft category   Roskam Vol. I, Table 3.3
%
%   Concrete utility methods (compute_CD, compute_CL, compute_CD0, get_CDi) are
%   inherited from AerodynamicsBase and do not need to be re-declared here.

    properties (Abstract)
        % --- Aircraft-specific inputs
        LD_max          % double; — maximum lift-to-drag ratio
        AR_wet          % double; — wetted aspect ratio b^2/S_wet
    end

    methods (Abstract)

        %GET_E_OSW  Oswald span efficiency factor.
        val = get_e_osw(obj)

        %GET_K1  Induced-drag factor K1 at Mach number M.
        val = get_K1(obj, M)

        %GET_K2  Polar-offset term K2 at Mach number M (zero for M >= 1).
        val = get_K2(obj, K1_sub, M)

        %GET_CD0  Zero-lift drag coefficient: CD0 = Cf * S_wet / S_ref.
        val = get_CD0(obj)

        %COMPUTE_LD_MAX  Statistical LD_max = K_LD * sqrt(AR_wet).  Raymer Eq. 3.12.
        val = compute_LD_max(obj, K_LD, AR_wet)

        %COMPUTE_AR_WET  Wetted aspect ratio: AR_wet = b^2 / S_wet.  Raymer Eq. 3.11.
        val = compute_AR_wet(obj, b, S_wet)

        %COMPUTE_CL_MIND  CL at minimum drag (airfoil-type and polar based).
        val = compute_CL_minD(obj, airfoil_type, CL_min, CD0)

        %LOOKUP_CF  Equivalent skin-friction coefficient from aircraft-type table.
        val = lookup_Cf(obj, aircraft_type, n_engines)

        %LOOKUP_CLMAX  CLmax for clean, take-off, and landing configurations.
        val = lookup_CLmax(obj, aircraft_type, config, rangeMode)

    end

end
