classdef TtpaWeights < WeightsBase

    properties
        W_TO                 = NaN   % lbf — candidate gross takeoff weight; NaN until the sizing loop sets it
        W_energy             = NaN   % lbf — total internal fuel/battery weight; NaN until mission analysis sets it
        W_payload_expendable = 0     % lbf — expendable payload (stores)
        W_payload_fixed      = 1200  % lbf — fixed equipment, including crew
    end

    methods
        function oew = OEW(obj, W_TO)
            % Empty Weight
            oew = 0.911 * W_TO^0.947;
        end
    end
end