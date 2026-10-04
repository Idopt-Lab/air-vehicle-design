classdef landinggearL2
%LANDINGGEARL2  Level-2 landing-gear static toolbox: statistical tire sizing.
%
%   Call as landinggearL2.method(...).
%
%   Methods (Static):
%       tire_diameter: tire outside diameter (in) from the load on one wheel (lbf).
%       tire_width: tire width (in) from the load on one wheel (lbf).
%       lookup_tire_sizing_coeffs: the four Table 11.1 coefficients for one
%           aircraft category.
%
%   A design with no landing gear does not call this toolbox.
%
%   Source: Raymer 6th ed. Table 11.1 "Statistical Tire Sizing", p.344.
%
%   Companion doc: src/disciplines/landing_gear/landinggearL2.md

    methods (Static)

        function d = tire_diameter(A, B, W_w)
            %TIRE_DIAMETER  Static tire diameter [in].
            %   [Raymer 6th ed. Table 11.1, p.344]  D = A * W_w^B.
            arguments
                A   (1,1) double {mustBePositive}
                B   (1,1) double {mustBePositive}
                W_w (1,1) double {mustBePositive}
            end
            d = A * W_w^B;
        end

        function w = tire_width(A, B, W_w)
            %TIRE_WIDTH  Static tire width [in].
            %   [Raymer 6th ed. Table 11.1, p.344]  Width = A * W_w^B.
            arguments
                A   (1,1) double {mustBePositive}
                B   (1,1) double {mustBePositive}
                W_w (1,1) double {mustBePositive}
            end
            w = A * W_w^B;
        end

        function c = lookup_tire_sizing_coeffs(table_row)
        %LOOKUP_TIRE_SIZING_COEFFS  Diameter/width coefficient pairs by
        %   aircraft category. [Raymer 6th ed. Table 11.1 "Statistical Tire
        %   Sizing," p.344]. Full 4-row table, reproduced verbatim -- do not
        %   read A_d/A_w from a mismatched row (each row's diameter and
        %   width coefficients must travel together).
            switch table_row
                case 'General aviation'
                    c = struct('A_d', 1.51, 'B_d', 0.349, 'A_w', 0.7150, 'B_w', 0.312);
                case 'Business twin'
                    c = struct('A_d', 2.69, 'B_d', 0.251, 'A_w', 1.170,  'B_w', 0.216);
                case 'Transport/bomber'
                    c = struct('A_d', 1.63, 'B_d', 0.315, 'A_w', 0.1043, 'B_w', 0.480);
                case 'Jet fighter/trainer'
                    c = struct('A_d', 1.59, 'B_d', 0.302, 'A_w', 0.0980, 'B_w', 0.467);
                otherwise
                    error('F16LandingGearL2:unknownTireCategory', ...
                        ['Unknown tire-sizing table row "%s". Known rows ' ...
                         '(Raymer 6th ed. Table 11.1): General aviation, ' ...
                         'Business twin, Transport/bomber, Jet fighter/trainer.'], ...
                        table_row);
            end
        end

        function tipback_angle = compute_tipback_angle(cg_loc, main_wheel_loc)
            % Computes tipback angle.
            %
            % ARGS:
            %   cg_loc (array): x, y location of CG measured downstream from the nose (ft)
            %   main_wheel_loc (array): x,y location of main wheel measured downstream from nose (ft)
            %
            % RETURNS:
            %   tipback_angle (double): angle between the vertical intersecting the main wheel and ray drawn from CG to main wheel (deg)

            % Assume the vertical line acts through the main wheel, down
            r_down_mainwheel = [0, main_wheel_loc(2)];

            % Draw the ray from cg to main wheel
            r_mainwheel_cg = (cg_loc - main_wheel_loc);

            % Take the dot product
            r_dot_cg_mw_vert = dot(r_down_mainwheel, r_mainwheel_cg);

            % Get the magnitudes
            r_down_mainwheel_mag = sqrt(r_down_mainwheel(1)^2 + r_down_mainwheel(2)^2);
            r_mainwheel_cg_mag = sqrt(r_mainwheel_cg(1)^2 + r_mainwheel_cg(2)^2);

            % Compute the angle in rad
            tipback_angle = acos(r_dot_cg_mw_vert/(r_down_mainwheel_mag*r_mainwheel_cg_mag));

            % Convert to deg
            tipback_angle = 180 - rad2deg(tipback_angle);
        end

        function val = check_tipback_angle(tipback_angle)
            % Checks if tipback angle is between 15-25 deg.
            %
            % ARGS:
            %   tipback_angle (double): literally the tipback angle (deg)
            %
            % RETURNS:
            %   val (bool): true/false. If 15<tipback_angle<25, then true.
            % Code begins here

            if (15<tipback_angle) && (tipback_angle<25)
                val = true;
            else
                val = false;
            end
        end


    end

end
