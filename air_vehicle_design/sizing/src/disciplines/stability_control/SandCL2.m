classdef SandCL2
%SANDCL2  Level-2 stability & control static toolbox: the CG term only.
%
%   Call as SandCL2.method(...); never instantiated, not in the inheritance
%   chain. F16SandCL2 delegates here; F16SandCL3 also calls weighted_cg for
%   its own x_cg (the equation is level-agnostic, so it lives here once).
%
%   Companion doc: src/disciplines/stability_control/SandCL2.md

    methods (Static)

        function x_cg = weighted_cg(weights_vec, x_vec)
        %WEIGHTED_CG  Aircraft center-of-gravity x-station [ft].
        %   [no separate Raymer/Roskam equation number -- standard weighted-
        %   average CG identity; matches VnV/BrandtF16A/readme_bsc.md's own
        %   "CG closure" formula]:
        %     x_cg = Sum(W_i * x_i) / Sum(W_i)
        %
        %   No NaN-rejecting validator on weights_vec: a NaN component weight
        %   (e.g. the fuel group's W_energy before the mission/sizing loop
        %   sets it -- see WeightsBase.m) propagates through IEEE arithmetic
        %   into x_cg. This graceful NaN signal is by design, not an error.
            arguments
                weights_vec (1,:) double {mustBeReal}
                x_vec       (1,:) double {mustBeReal}
            end
            if numel(weights_vec) ~= numel(x_vec)
                error('SandCL2:sizeMismatch', ...
                    ['weights_vec (n=%d) and x_vec (n=%d) must have the same ' ...
                     'number of components.'], numel(weights_vec), numel(x_vec));
            end
            x_cg = sum(weights_vec .* x_vec) / sum(weights_vec);
        end

    end

end
