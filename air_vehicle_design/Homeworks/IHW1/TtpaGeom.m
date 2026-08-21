classdef TtpaGeom < GeometryBase
%TTPAGEOM  Tier-1 preliminary geometry model for a piston-prop aircraft.
%
%   Low-fidelity geometry model for preliminary aircraft sizing.
%   Geometry is intentionally minimal at this fidelity; most quantities
%   are determined by the sizing framework from aircraft requirements.
%
%   Inheritance:
%       GeometryBase -> TtpaGeom
%
%   Abstract interface implemented:
%       get_S_ref()
%       get_S_wet()

    properties

        S_ref = NaN
        % Wing reference area [ft^2].
        % Determined by the sizing framework.

        S_wet = NaN
        % Total aircraft wetted area [ft^2].
        % Not necessarily known at preliminary sizing.

    end

    methods

        %% Reference Area

        function val = get_S_ref(obj)
        %GET_S_REF  Wing reference area [ft^2].
            val = obj.S_ref;
        end


        %% Wetted Area

        function val = get_S_wet(obj, ~)
        %GET_S_WET  Total aircraft wetted area [ft^2].
        %
        %   Wetted area may remain unknown at preliminary sizing and is
        %   therefore initialized to NaN.

            val = obj.S_wet;
        end

    end

end