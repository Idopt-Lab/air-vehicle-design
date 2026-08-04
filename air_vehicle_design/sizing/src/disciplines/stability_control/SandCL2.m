classdef SandCL2
%SANDCL2  Level-2 stability & control static toolbox: the CG term only.
%
%   Call as SandCL2.method(...); never instantiated, not in the inheritance
%   chain. F16SandCL2 inherits SandCModelL2 and delegates here. F16SandCL3
%   ALSO calls weighted_cg directly for its own x_cg (fidelity-collapse
%   rule: the equation is level-agnostic -- it lives here once, not
%   duplicated on SandCL3 -- exactly the cross-toolbox-reuse pattern already
%   used elsewhere in this repo, e.g. GeomL3.size_tail -> GeomL1.size_tail).
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
        %   Deliberately NO NaN-rejecting validator on weights_vec: if any
        %   component weight is NaN (in particular the 'fuel' group's
        %   W_energy, a mission-analysis STATE that reads NaN until the
        %   mission/sizing loop sets it -- see WeightsBase.m), ordinary IEEE
        %   arithmetic propagates that NaN straight into x_cg. This is the
        %   documented, GRACEFUL signal docs/subplans/10_stability_control.md
        %   asks for -- not an error. (mustBeNonnegative/mustBePositive would
        %   have rejected NaN outright -- e.g. NaN >= 0 is false -- so they
        %   are deliberately NOT applied here.)
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
