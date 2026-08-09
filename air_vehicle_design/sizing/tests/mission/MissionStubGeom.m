classdef MissionStubGeom < GeometryBase
%MISSIONSTUBGEOM  Minimal GeometryBase stub for mission unit tests.
%   Fixed reference area, wetted area, and engine count. Mission analysis reads
%   get_S_ref() and n_engines; S_wet is here only to satisfy the GeometryBase
%   contract.

    properties
        S_ref     = 300      % ft^2
        S_wet     = 1400     % ft^2
        n_engines = 1
    end

    methods
        function val = get_S_ref(obj)
            val = obj.S_ref;
        end
        function val = get_S_wet(obj, ~)
            val = obj.S_wet;
        end
    end
end
