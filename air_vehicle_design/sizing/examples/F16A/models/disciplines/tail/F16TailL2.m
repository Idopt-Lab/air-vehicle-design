classdef F16TailL2 < TailSizingModelL2
%F16TAILL2  F-16A Level-2 tail sizing -- NOT IMPLEMENTED (stub).
%
%   Constructible so the TailSizingBase/TailSizingModelL2 type contract holds,
%   but size() throws 'TailL2:notImplemented'. Level-2 tail sizing is reserved
%   for a future higher-fidelity method with real, cited equations.
%   See docs/decision_log.md.

    methods

        function obj = F16TailL2()
        %F16TAILL2  No-argument constructor -- stub, nothing to configure.
        end

        function result = size(obj, varargin) %#ok<INUSD>
        %SIZE  NOT IMPLEMENTED -- delegates to TailL2.size, which throws.
        %   Accepts and ignores any arguments so any caller gets the same clear
        %   not-implemented error.
            result = TailL2.size(obj);
        end

    end

end
