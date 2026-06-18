classdef TailSizingBase < handle
    % Abstract base class for tail sizing discipline.
    %
    % Tail sizing is called from SizingLoopL2 to determine horizontal and
    % vertical tail reference areas.  It is NOT called in SizingLoopL1.
    %
    % The simplest concrete implementation (TailSizingLevel1) uses the tail
    % volume coefficient method (Raymer Eq 6.28–6.29).

    methods (Abstract)
        % size  Returns horizontal and vertical tail reference areas (ft²).
        %   S_ref  — wing reference area (ft²)
        %   b      — wingspan (ft)
        %   cbar   — mean aerodynamic chord (ft)
        %   L_fus  — fuselage length (ft)
        %
        %   result.S_HT  — horizontal tail area (ft²)
        %   result.S_VT  — vertical tail area (ft²)
        result = size(obj, S_ref, b, cbar, L_fus)
    end
end
