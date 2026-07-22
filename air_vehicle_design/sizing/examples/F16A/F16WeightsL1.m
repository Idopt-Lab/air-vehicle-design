classdef F16WeightsL1 < WeightsModelL1
%F16WEIGHTSL1  F-16A Block 10 Level-1 weight estimation student class.
%
%   Inherits from WeightsModelL1 (abstract enforcer).  Every abstract method
%   is satisfied by a single delegation line to WeightsL1 statics.
%
%   METHODS:
%     (1) Raymer Table 3.1 power law:  We/Wto = Kvs × A × W_TO^C
%         Central estimate.  jet_fighter: A=2.34, C=-0.13, Kvs=1.00.
%     (2) Roskam Eq. 2.16 log-log:     W_E_min = 10^((log10(W_TO)−A)/B)
%         Minimum achievable W_E.  jet_fighter: A=0.5091, B=0.9505.
%
%   VALIDATION (at W_TO = 31,377 lbf):
%     Raymer: We/Wto = 1.00 × 2.34 × 31377^(−0.13) ≈ 0.609 → OEW ≈ 19,108 lbf
%     Roskam: W_E_min ≈ 15,660 lbf (lower bound)
%     Brandt actual: 19,148 lbf  [Brandt F-16A.xls, B12]
%
%   SOURCES:
%     [Brandt]  S. Brandt, F-16A.xls workbook.
%     [Raymer]  D.P. Raymer, Aircraft Design 6th ed., AIAA, 2018, Table 3.1.
%     [Roskam]  J. Roskam, Airplane Design Part I, DARcorp., 1985, Eq. 2.16 + Table 2.15.

    properties
        aircraft_category = 'jet_fighter'  % selects Raymer Table 3.1 / Roskam Table 2.15 row

        % ----- WeightsBase abstract properties -----
        W_TO               = NaN      % candidate gross takeoff weight [lbf]; set by sizing loop
        W_energy           = 6296.3   % internal fuel weight [lbf]  [Brandt B6]
        W_payload_expendable = 0      % expendable payload [lbf]; set by mission profile
        W_payload_fixed    = 220      % fixed equipment + crew [lbf; estimate: 1 pilot + survival gear]
    end

    methods

        function obj = F16WeightsL1()
            obj.aircraft_category = 'jet_fighter';
        end

        function oew = OEW(obj, W_TO)
            oew = WeightsL1.OEW(obj, W_TO);
        end

        function frac = compute_We_fraction(obj, W_TO, aircraft_category)
            if nargin < 3
                aircraft_category = obj.aircraft_category;
            end
            frac = WeightsL1.compute_We_fraction(obj, W_TO, aircraft_category);
        end

        function W_E = compute_We_roskam(obj, W_TO)
            W_E = WeightsL1.compute_We_roskam(obj, W_TO);
        end

    end

end
