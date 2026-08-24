classdef TtpaAero < AerodynamicsBase
%TTPAAERO  Test Twin Propeller Aircraft Level-1 aerodynamic model.
%
%   Geometry/design inputs are read from the requirements JSON.
%   Derived aerodynamic quantities are calculated here.

    properties
        AR              % Wing aspect ratio, read from requirements JSON
        CD0 = 0.028     % Parasitic drag coefficient
    end

    properties (Dependent)
        e               % Oswald efficiency factor
        K               % Induced drag factor
        LD_max          % Maximum lift-to-drag ratio
    end

    methods

        %% Constructor
        function obj = TtpaAero(json_path)
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            % Read requirements JSON
            J = jsondecode(fileread(json_path));

            % Read geometry-owned requirement
            obj.AR = J.geometry.AR;
        end


        %% Oswald Efficiency
        function e = get.e(obj)
            e = 1.78 * (1 - 0.045 * obj.AR^0.68) - 0.64;
        end


        %% Induced Drag Factor
        function K = get.K(obj)

            if isnan(obj.e) || obj.e <= 0 || obj.e > 1
                error('TtpaAero:InvalidOswaldEfficiency', ...
                    'Computed Oswald efficiency e = %.4f is invalid.', obj.e);
            end

            K = 1 / (pi * obj.AR * obj.e);
        end


        %% Drag Polar
        function polar = drag_polar(obj, ~)

            polar.CD0 = obj.CD0;
            polar.K1  = obj.K;
            polar.K2  = 0;

        end


        %% Maximum Lift Coefficient
        function CLmax = get_CLmax(~, ~)

            % Placeholder until CLmax model is implemented
            CLmax = NaN;

        end


        %% Maximum L/D
        function LD_max = get.LD_max(obj)

            LD_max = 1 / (2 * sqrt(obj.CD0 * obj.K));

        end

    end

end