classdef LandingFieldLengthConstraint < Only_WbyS
%LANDINGFIELDLENGTHCONSTRAINT  FAR-25 landing-field-length upper bound on
%   wing loading (the statistical field-length correlation).
%
%   Generic Layer-1 constraint. Given a required runway length, an
%   obstacle-clearance approach distance Sa, a landing-to-takeoff weight ratio,
%   a field air-density ratio sigma = rho/rho_SL, and a runway multiple, it
%   returns the UPPER BOUND this landing-field requirement imposes on wing
%   loading W/S -- not a required T/W. Braking landing has no thrust demand, so
%   it belongs to the Only_WbyS category: the aggregator reads WS_max() as a
%   vertical W/S wall.
%
%   This is the FAR-25 statistical field-length correlation (Roskam's
%   80*(W/S)/(sigma*CLmax) + Sa relation), NOT the Roskam Military
%   ground-roll-with-braking form that the sibling LandingConstraint.m uses.
%   Use this class for FAR-25 airliner / civil landing sizing.
%
%   CLmax_L is pulled fresh from the injected aero object each call (through
%   the HighLiftConfigBridge), not a constraint input, so the constraint tracks
%   the current sizing-loop iteration and fidelity level automatically.
%
%   EQUATION [Metabook (Aero 481 metabook), docs/reference_extracts/
%   metabook_data.md "§4.6 Landing Field Length," Eqs. 4.19 / 4.45; worked
%   Example 4.2, Eq. 4.46]:
%
%     sland = 80 * (W/S) / (sigma * CLmax_L) + Sa                      (4.19)
%   solved for W/S, with the FAR runway multiple and weight-ratio corrections:
%     W/S <= sigma * CLmax_L / 80
%              * (S_runway * runway_factor - Sa) / weight_ratio        (4.45/4.46)
%
%   FACTORS (see Example 4.2, Eq. 4.46, which evaluates this to 113.27*CLmax):
%     * 80           -- Eq. 4.19 Raymer/Roskam landing-field constant (English
%                       units; W/S in lb/ft^2, distances in ft).
%     * runway_factor = 0.6 -- FAR landing-field multiple. FAR-25 requires the
%                       demonstrated landing distance be at most 60% of the
%                       available runway (equivalently the field length is
%                       1.67x the landing distance, 0.6 = 1/1.67; Eq. 4.19's
%                       1.67 factor). Carried as a defaulted argument.
%     * Sa           -- obstacle-clearance approach distance [ft]: 1000 for an
%                       airliner, 600 for GA (Eq. 4.19 note).
%     * weight_ratio = MLW/MTOW -- converts the landing-weight W/S that this
%                       relation produces to the takeoff W_TO/S axis the
%                       constraint diagram plots (Example 4.2 uses 0.65 for the
%                       777-200LR).
%     * sigma = rho/rho_SL -- field air-density ratio (Example 4.2 uses 0.95,
%                       a hot day near sea level -- NOT an ISA AircraftState
%                       value, so it is an explicit input).
%
%   Example 4.2 hand-check (Eq. 4.46): sigma=0.95, S_runway=12,000 ft,
%   runway_factor=0.6, Sa=1000 ft, weight_ratio=0.65 gives
%   W/S = 0.95*CLmax/(80*0.65) * (12,000*0.6 - 1000) = 113.27 * CLmax.

    properties (SetAccess = protected)
        name           % string -- condition label, e.g. "Landing Field Length"
    end

    properties (SetAccess = private)
        aero           % AerodynamicsBase -- supplies CLmax_L via HighLiftConfigBridge.polar(aero,"landing_flaps_gear_down").CLmax
        S_runway_ft    % double, ft -- available runway length
        Sa_ft          % double, ft -- obstacle-clearance approach distance (1000 airliner / 600 GA)
        weight_ratio   % double -- MLW/MTOW, converts landing-weight W/S to takeoff W_TO/S axis
        sigma          % double -- field air-density ratio rho/rho_SL (explicit input, not an ISA state)
        runway_factor  % double -- FAR landing-field multiple (0.6 = 1/1.67, Eq. 4.19)
    end

    properties (Constant, Access = private)
        LANDING_CONSTANT = 80   % -- Eq. 4.19 Raymer/Roskam landing-field constant [Metabook Eq. 4.19]
    end

    methods

        function obj = LandingFieldLengthConstraint(name, aero, S_runway_ft, ...
                Sa_ft, weight_ratio, sigma, runway_factor)
            arguments
                name          (1,1) string
                aero          (1,1) AerodynamicsBase
                S_runway_ft   (1,1) double {mustBePositive}
                Sa_ft         (1,1) double {mustBeNonnegative}
                weight_ratio  (1,1) double {mustBePositive} = 1.0
                sigma         (1,1) double {mustBePositive} = 1.0
                runway_factor (1,1) double {mustBePositive} = 0.6
            end
            obj.name          = name;
            obj.aero          = aero;
            obj.S_runway_ft   = S_runway_ft;
            obj.Sa_ft         = Sa_ft;
            obj.weight_ratio  = weight_ratio;
            obj.sigma         = sigma;
            obj.runway_factor = runway_factor;
        end

        function WS = WS_max(obj)
        %WS_MAX  Upper bound on wing loading W/S [lbf/ft^2] this landing-field
        %   requirement imposes. See class header for the equation, factors,
        %   and citation. CLmax_L is the FLAPPED landing value pulled fresh from
        %   the aero high-lift config each call, so this tracks the
        %   current-iteration aerodynamics.
        %
        %   FAILS LOUDLY on a non-finite bound (a mis-injected discipline object
        %   or unmodeled config gives a non-finite CLmax_L). An Only_WbyS wall
        %   is read directly by the aggregator, so a NaN wall would silently
        %   drop the whole constraint -- error here instead.
        %
        %   [Metabook Eqs. 4.19/4.45; worked Ex. 4.2 Eq. 4.46.]
            CLmax_L = HighLiftConfigBridge.polar(obj.aero, "landing_flaps_gear_down").CLmax;

            % Eq. 4.45/4.46: solve the Eq. 4.19 field-length relation for W/S,
            % apply the FAR runway multiple, then convert to the takeoff axis.
            available_field = obj.S_runway_ft * obj.runway_factor - obj.Sa_ft;
            WS = obj.sigma * CLmax_L / LandingFieldLengthConstraint.LANDING_CONSTANT ...
                * available_field / obj.weight_ratio;

            if ~isfinite(WS)
                error('LandingFieldLengthConstraint:nonFiniteTerm', ...
                    ['Constraint "%s": landing-field W/S wall is non-finite ', ...
                     '(WS_max = %s) from sigma = %g, CLmax_L = %s, ', ...
                     'S_runway = %g ft, runway_factor = %g, Sa = %g ft, ', ...
                     'weight_ratio = %g. The usual cause is a flapped CLmax_L ', ...
                     'that is not modeled (HighLiftConfigBridge ', ...
                     'landing_flaps_gear_down).'], ...
                    obj.name, mat2str(WS, 6), obj.sigma, mat2str(CLmax_L, 6), ...
                    obj.S_runway_ft, obj.runway_factor, obj.Sa_ft, obj.weight_ratio);
            end
        end

    end

    methods (Static)

        function obj = fromCondition(cond, aero, ~)
        %FROMCONDITION  Build from a requirements-JSON condition struct + the
        %   injected aero. Reads cond.runway_ft, cond.Sa_ft, cond.weight_ratio,
        %   cond.sigma, and the optional cond.runway_factor (defaulted to 0.6
        %   when absent). prop is accepted for a uniform factory signature but
        %   unused -- landing is unpowered. Uniform factory dispatched by
        %   ConstraintType.
            if isfield(cond, 'runway_factor') && ~isempty(cond.runway_factor)
                obj = LandingFieldLengthConstraint(string(cond.name), aero, ...
                    cond.runway_ft, cond.Sa_ft, cond.weight_ratio, cond.sigma, ...
                    cond.runway_factor);
            else
                obj = LandingFieldLengthConstraint(string(cond.name), aero, ...
                    cond.runway_ft, cond.Sa_ft, cond.weight_ratio, cond.sigma);
            end
        end

    end

end
