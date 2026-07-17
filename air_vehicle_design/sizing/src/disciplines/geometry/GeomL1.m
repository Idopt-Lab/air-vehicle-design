classdef GeomL1
%GEOML1  Level-1 geometry static toolbox: statistical regression from TOGW.
%
%   Call as GeomL1.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16GeomL1, etc.) inherit
%   from GeometryModelL1 and call these statics to implement each abstract method.
%
%   EQUATIONS:
%     Total S_wet:
%       S_wet = 10^c * W_TO^d
%       Roskam, Airplane Design Vol. I, Table 3.5 [Jan Roskam, 1997]
%       Jet fighter: c = -0.1289, d = 0.7506
%
%     Fuselage length:
%       L_fus = a * W_TO^C
%       Raymer, Aircraft Design: A Conceptual Approach, 6th ed., Table 6.3
%       [Daniel P. Raymer, AIAA, 2018]
%       Jet fighter: a = 0.93, C = 0.39

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function val = get_S_wet_statistical(obj, W_TO)
        %GET_S_WET_STATISTICAL  Total S_wet from Roskam Vol. I Table 3.5 regression.
        %   Reads obj.aircraft_category.
            val = GeomL1.compute_s_wet_regression(obj.aircraft_category, W_TO);
        end

        function val = get_L_fus(obj, W_TO)
        %GET_L_FUS  Fuselage length from Raymer 6th ed. Table 6.3 regression.
        %   Reads obj.aircraft_category.
            val = GeomL1.compute_l_fus_regression(obj.aircraft_category, W_TO);
        end

        % ================================================================== %
        % LOW-LEVEL: pure math — take only scalars/strings, no object access.
        % ================================================================== %

        function val = compute_s_wet_regression(aircraft_category, W_TO)
        %COMPUTE_S_WET_REGRESSION  S_wet = 10^c * W_TO^d  (Roskam Vol. I Table 3.5).
            [c, d] = GeomL1.lookup_swet(aircraft_category);
            val = 10^c * W_TO^d;
        end

        function val = compute_l_fus_regression(aircraft_category, W_TO)
        %COMPUTE_L_FUS_REGRESSION  L_fus = a * W_TO^C  (Raymer 6th ed. Table 6.3).
            [a, C] = GeomL1.lookup_lfus(aircraft_category);
            val = a * W_TO^C;
        end

        function [c, d] = lookup_swet(cat)
        %LOOKUP_SWET  Roskam Vol. I Table 3.5: S_wet = 10^c * W_TO^d.
            switch cat
                case 'jet_fighter',    c = -0.1289; d = 0.7506;
                case 'jet_bomber',     c =  0.1213; d = 0.7306;
                case 'transport_jet',  c =  0.0199; d = 0.7351;
                case 'business_jet',   c =  0.2263; d = 0.6977;
                case 'military_cargo', c = -0.0866; d = 0.8099;
                otherwise
                    error('GeomL1:unknownCategory', ...
                        'Unknown aircraft_category "%s". Add it to GeomL1.lookup_swet.', cat);
            end
        end

        function [a, C] = lookup_lfus(cat)
        %LOOKUP_LFUS  Raymer 6th ed. Table 6.3: L_fus = a * W_TO^C  (ft, lbf).
            switch cat
                case 'jet_fighter',    a = 0.93; C = 0.39;
                case 'jet_trainer',    a = 0.79; C = 0.41;
                case 'transport_jet',  a = 0.67; C = 0.43;
                case 'military_cargo', a = 0.23; C = 0.50;
                otherwise
                    error('GeomL1:unknownCategory', ...
                        'Unknown aircraft_category "%s". Add it to GeomL1.lookup_lfus.', cat);
            end
        end

    end
end
