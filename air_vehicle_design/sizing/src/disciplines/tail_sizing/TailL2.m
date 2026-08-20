classdef TailL2
%TAILL2  Level-2 tail-sizing static toolbox -- NOT IMPLEMENTED.
%
%   NO EQUATIONS ARE IMPLEMENTED HERE. Level-2 tail sizing is reserved for a
%   future higher-fidelity method. size() throws until real, cited equations
%   are supplied. See docs/decision_log.md.
%
%   Companion doc: TailL2.md

    methods (Static)

        function result = size(obj) %#ok<INUSD>
        %SIZE  NOT IMPLEMENTED -- throws. L2 tail sizing has no equations yet.
            error('TailL2:notImplemented', ...
                ['Level-2 tail sizing is not implemented: no equations exist ' ...
                 'in this toolbox. Use the L1 volume-coefficient tail sizer ' ...
                 '(F16TailL1 / B777TailL1 / Aero481TailL1), or supply real, ' ...
                 'cited L2 equations. See docs/decision_log.md.']);
        end

    end
end
