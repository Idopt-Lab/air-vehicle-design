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
        %   Successive-substitution damping for a fixed-point iteration
        %   (numerical method, no physics citation). w in (0, 1]: w = 1 is
        %   the full step to x_new; smaller w stabilizes convergence.
        %
        %   Choose w per stack: aircraft with a large fixed-OEW content have
        %   a steep closure-map slope and need a smaller w (Brandt F-16A
        %   slope ~= -2.9 -> w ~= 0.25).
        %   History and rationale: docs/decision_log.md
            arguments
                x_old (1,1) double
                x_new (1,1) double
                w     (1,1) double {mustBeInRange(w, 0, 1, "exclude-lower")}
            end
            x = x_old + w * (x_new - x_old);
        end

    end

end
