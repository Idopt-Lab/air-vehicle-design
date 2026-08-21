classdef F16GeomBrandtAlt
%F16GEOMBRANDTALT  Brandt's own fuselage wetted-area methods, F-16A only.
%   Call as F16GeomBrandtAlt.method(...); never instantiated.
%
%   Brandt verifies the framework. He does not supply its equations. So his own
%   constructions live here, not in a toolbox.
%
%   The comparison report and TestGeomL2 are the only consumers. No sizing path
%   calls this. The official fuselage method is GeomL2.compute_s_wet_fus_cyl
%   [Roskam Vol. II Eq. 12.3].
%
%   Mod (08/19/2026) (Claude) -- compute_s_wet_from_control_stations and
%   compute_frame_perimeter moved to the GeomL3 toolbox on 2026-08-19, Casey's
%   decision. Bodies unchanged. Change record: src/disciplines/geometry/GeomL3.md.

% Note (8/18/2026)(Casey): Honestly, this may be removed. The functions for
% estimating the strakes' wetted areas may be useful though, so  I'd like
% to keep that.

    methods (Static)

        % Mod (08/18/2026) (Claude) -- moved from GeomL2, unchanged.
        function val = compute_s_wet_fus_brandt_lowfi(max_width, max_height, L_fuse)
        %COMPUTE_S_WET_FUS_BRANDT_LOWFI  Fuselage wetted area [ft^2], Brandt's
        %   "1/3-cone + 2/3-cylinder" approximation.  [Brandt F-16A.xls, Geom!B3]
            arguments
                max_width  (1,1) double {mustBePositive}
                max_height (1,1) double {mustBePositive}
                L_fuse     (1,1) double {mustBePositive}
            end
            D_avg = (max_width + max_height) / 2;
            val   = (5/6) * pi * D_avg * L_fuse;
        end

    end
end
