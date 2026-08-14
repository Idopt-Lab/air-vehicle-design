classdef SizingSteps
%SIZINGSTEPS  Static toolbox of sizing-loop update steps.
%
%   Never instantiated. Holds the two numerical steps every sizing loop
%   shares, so SizingLoopL1, SizingLoopL2, and TSDiagram all iterate with
%   the SAME closure equation and the SAME relaxation convention:
%     togw_update -- one step of the TOGW fixed-point iteration
%                    [docs/reference_extracts/metabook_data.md -- Ch. 2,
%                    "TOGW Iteration Algorithm (Algorithm 1)"; Raymer 6th
%                    ed. Eq. 3.4].
%     relax       -- standard successive-substitution under-relaxation
%                    (numerical damping, not textbook physics).
%
%   Same pattern as the discipline static toolboxes (AeroL1, GeomL2, ...):
%   methods (Static) only, not in any inheritance chain.

    methods (Static)

        function [W0_new, denom] = togw_update(W_payload, W_OEW, W_fuel, W_TO)
        %TOGW_UPDATE  One TOGW fixed-point step.
        %   [docs/reference_extracts/metabook_data.md -- Ch. 2, "TOGW
        %   Iteration Algorithm (Algorithm 1)":
        %     W0_new = (Wcrew + Wpayload) / (1 - Wf/W0 - We/W0);
        %   same form as Raymer 6th ed. Eq. 3.4.]
        %
        %   The empty and fuel fractions are evaluated at the CURRENT guess
        %   W_TO. When denom <= 0 the empty + fuel fractions consume the
        %   whole takeoff weight: no positive W0 closes the payload, so
        %   W0_new = NaN is returned and the CALLER decides between an
        %   error (sizing loops) and a NaN infeasibility marker (TSDiagram
        %   grid scans).
        %
        %   W_payload -- lbf, fixed + expendable payload (must be > 0: the
        %                closure form has no fixed point at zero payload).
        %   W_OEW     -- lbf, operating empty weight at W_TO.
        %   W_fuel    -- lbf, mission fuel at W_TO.
        %   W_TO      -- lbf, current takeoff-gross-weight guess.
            arguments
                W_payload (1,1) double {mustBePositive}
                W_OEW     (1,1) double {mustBeNonnegative}
                W_fuel    (1,1) double {mustBeNonnegative}
                W_TO      (1,1) double {mustBePositive}
            end
            % [metabook Algorithm 1; Raymer 6th ed. Eq. 3.4]
            denom = 1 - W_fuel/W_TO - W_OEW/W_TO;
            if denom <= 0
                W0_new = NaN;
            else
                W0_new = W_payload / denom;
            end
        end

        function x = relax(x_old, x_new, w)
        %RELAX  Under-relaxed update x = x_old + w*(x_new - x_old).
        %   Standard successive-substitution damping for a fixed-point
        %   iteration (numerical method, no physics citation applies).
        %   w in (0, 1]: w = 1 is the full step to x_new; smaller w damps
        %   the update to stabilize convergence.
        %
        %   RELAXATION CHOICE (added 2026-08-14). If the unrelaxed map has
        %   slope m = d(x_new)/d(x_old) at the fixed point, the relaxed
        %   slope is (1 - w) + w*m; the iteration converges only when its
        %   magnitude is < 1, and w = 1/(1 - m) nulls it (fastest). For
        %   the TOGW closure, m ~= -W_payload*|d(ef)/dW0|/denom^2 with
        %   ef = OEW/W0 -- aircraft with a large fixed-OEW content have
        %   steep m. Measured on the Brandt F-16A stack: m ~= -2.9, so
        %   the 0.5 default leaves |slope| ~= 0.95 (very slow, oscillating)
        %   while w ~= 0.25 converges in a handful of iterations. Callers
        %   should tune the loops' relaxation opts per stack; the Aero 481
        %   reference code used w = 0.2 on a 777-class closure for the
        %   same reason.
            arguments
                x_old (1,1) double
                x_new (1,1) double
                w     (1,1) double {mustBeInRange(w, 0, 1, "exclude-lower")}
            end
            x = x_old + w * (x_new - x_old);
        end

    end

end
