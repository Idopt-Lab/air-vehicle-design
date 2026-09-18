classdef SizingSteps
%SIZINGSTEPS  Static toolbox of the two numerical steps a sizing loop uses.
%
%   Never instantiated; call as SizingSteps.togw_update(...) and
%   SizingSteps.relax(...). Exactly the same pattern, and the same two
%   equations, as src/sizing/SizingSteps.m in the sizing framework, so the
%   homework loop and the framework loop iterate identically.
%
%     togw_update -- one step of the takeoff-gross-weight fixed point
%                    [metabook Ch. 2, TOGW Iteration Algorithm (Algorithm
%                    1); same form as Raymer 6th ed. Eq. 3.4]
%     relax       -- successive-substitution under-relaxation. A numerical
%                    method, not textbook physics, and therefore uncited.
%
%   These two lines are the WHOLE sizing loop. Everything else in IHW3a -
%   the geometry, the drag build-up, the weight build-up, the mission, the
%   constraint analysis - exists only to supply the three numbers
%   togw_update takes.

    methods (Static)

        function [W0_new, denom] = togw_update(W_payload, W_OEW, W_fuel, W_TO)
        %TOGW_UPDATE  One takeoff-gross-weight fixed-point step [lbf].
        %
        %   Everything must add up: payload + fuel + empty = takeoff. Divide
        %   by W_TO and solve for the takeoff weight,
        %
        %       W_TO = W_payload / ( 1 - W_fuel/W_TO - W_OEW/W_TO )
        %
        %   [metabook Ch. 2, Algorithm 1; Raymer 6th ed. Eq. 3.4]
        %
        %   The two fractions are evaluated at the CURRENT guess W_TO, not
        %   at the answer - that is exactly why the loop has to iterate. The
        %   denominator is the USEFUL-LOAD FRACTION: the share of the
        %   takeoff weight that is left for payload once the structure and
        %   the fuel have taken theirs.
        %
        %   When denom <= 0 the empty and fuel fractions consume the whole
        %   takeoff weight and no positive W_TO closes the payload. W0_new
        %   is returned as NaN and the CALLER decides what that means - the
        %   sizing loop raises an error, because it is a design result, not
        %   a coding mistake: the airplane as specified cannot carry its
        %   payload.
        %
        %   W_payload -- lbf, fixed plus expendable payload; must be > 0,
        %                the closure has no fixed point at zero payload.
        %   W_OEW     -- lbf, operating empty weight at W_TO.
        %   W_fuel    -- lbf, mission fuel including reserve at W_TO.
        %   W_TO      -- lbf, current takeoff-gross-weight guess.
            arguments
                W_payload (1,1) double {mustBePositive}
                W_OEW     (1,1) double {mustBeNonnegative}
                W_fuel    (1,1) double {mustBeNonnegative}
                W_TO      (1,1) double {mustBePositive}
            end

            denom = 1 - W_fuel/W_TO - W_OEW/W_TO;

            if denom <= 0
                W0_new = NaN;
            else
                W0_new = W_payload / denom;
            end
        end


        function x = relax(x_old, x_new, w)
        %RELAX  Under-relaxed update  x = x_old + w (x_new - x_old).
        %
        %   Successive-substitution damping for a fixed-point iteration. A
        %   numerical method, so there is no physics citation. w in (0,1]:
        %   w = 1 takes the full step to x_new, smaller w stabilises the
        %   iteration.
        %
        %   For the TTPA this is NOT optional. A full step taken from a
        %   guess far from the answer overshoots into the region where the
        %   empty and fuel fractions consume the whole takeoff weight, the
        %   closure denominator goes negative, and the loop stops. At
        %   w = 0.5 the loop converges from every starting guess between
        %   about 2500 and 10000 lbf.
            arguments
                x_old (1,1) double
                x_new (1,1) double
                w     (1,1) double {mustBeInRange(w, 0, 1, "exclude-lower")}
            end

            x = x_old + w * (x_new - x_old);
        end

    end

end
