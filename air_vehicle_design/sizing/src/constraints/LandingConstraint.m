classdef LandingConstraint < Only_WbyS
%LANDINGCONSTRAINT  Landing ground-roll upper bound on wing loading.
%
%   Generic Layer-1 constraint: given a sea-level landing flight condition
%   (AircraftState), a required free-roll/braking ground-roll distance S_FR,
%   a braking-surface friction coefficient mu, a touchdown-speed margin k_L,
%   and the current-iteration aerodynamics discipline object, returns the
%   upper bound this landing requirement imposes on wing loading W/S --
%   NOT a required T/W. CLmax_land and CD0_land are pulled fresh from
%   aero.get_CLmax(state)/aero.drag_polar(state) each call -- not constraint
%   inputs, same convention as TakeoffConstraint (see that class's header
%   and sizing/docs/subplans/06_constraint_analysis.md, "CLmax is NOT a
%   constraint input").
%
%   Unlike ThrustConstraint/TakeoffConstraint (Both_WbyS_TbyW category),
%   this condition constrains W/S directly and has no thrust dependence at
%   all (idle/braking, not powered flight) -- there is no "required T/W" to
%   derive. It belongs to the Only_WbyS category (see that class's header,
%   and sizing/docs/subplans/06_constraint_analysis.md's Design Notes):
%   Only_WbyS supplies the required_TW(WS) interface every
%   PointPerformanceBase condition must expose, encoding this class's
%   WS_max() as a hard vertical wall -- required_TW returns 0 (no additional
%   thrust demanded) for W/S at or below the landing limit, and Inf
%   (infeasible -- no finite thrust satisfies it) above it. Under
%   ConstraintAnalysis's max-envelope combination (TW_envelope(WS) =
%   max_i TW_table(i,WS)), this correctly excludes W/S values beyond the
%   landing bound from the feasible region while adding no spurious thrust
%   requirement below it.
%
%   EQUATION [landing ground-roll-with-braking sizing relation: touchdown
%   speed V_TD = k_L*V_stall decelerates to a stop under braking friction
%   PLUS aerodynamic drag, a_avg = g*(mu + 0.83*CD0/CLmax_land), giving
%   S_FR = V_TD^2 / (2*a_avg); substituting V_stall^2 = 2*(W/S)/(rho*CLmax_land)
%   and solving for W/S -- the "0.83" coefficient is a ground-roll velocity-
%   averaging factor applying the drag contribution over the braking run,
%   analogous in role to TakeoffConstraint.m's "0.7*CD0/(beta*CLmax)" term
%   that Brandt's own (unsimplified) takeoff row retains but this framework's
%   TakeoffConstraint.m omits -- except here the drag term is INCLUDED,
%   because dropping it (a pure mu-only kinematic form, k_L^2 substituted
%   literally as 1.69) undershoots Brandt's F-16A.xls Consts-sheet landing
%   row (b.constraints.landing.WS_land = 138.742) by ~7% (129.3 vs 138.742),
%   while this fuller form matches it to <0.1% (138.62 vs 138.742, using
%   Brandt's own flapped CLmax_land=1.4288 and CD0=0.062) -- confirmed
%   against temp_Casey's landing_constraint.m (reference only, not reused):
%     Wto_S = (Distance*rho*g*(mu*CLmax + 0.83*CD0)) / (1.69*beta)
%   is algebraically identical to the equation below with k_L^2 in place of
%   the literal 1.69 (1.3^2 = 1.69, so temp_Casey's constant already bakes
%   in k_L=1.3 rather than keeping it symbolic) and S_FR in place of
%   Distance. Matches Roskam, "Airplane Design, Part I: Preliminary Sizing
%   of Airplanes," DARcorporation -- Ch. 3 landing-distance sizing, Military
%   method (~p.115, per temp_AI/docs/disciplines/reference_extracts/
%   roskam_vol1_data.md's chapter outline) -- ground-roll-with-braking form,
%   not the FAR23/25 statistical field-length correlations from the same
%   chapter. NOT Raymer -- Raymer's "Aircraft Design: A Conceptual
%   Approach," 6th ed., ch. 5 ("Landing," Sec. 5.4) landing-distance
%   treatment is the statistical FAR field-length correlation (e.g.
%   S_FAR23 = 80*(W/S)/(sigma*CLmax), no explicit mu/CD0/k_L term) --
%   sizing/docs/subplans/06_constraint_analysis.md's "Raymer 6th ed (confirm
%   exact eq at implementation)" note appears to be the same kind of
%   citation slip TakeoffConstraint.m's header corrected for the takeoff
%   case]:
%
%     W_TO/S <= rho * g * S_FR * (mu * CLmax_land + 0.83 * CD0_land) / (k_L^2 * beta)
%
%   where rho comes from the sea-level AircraftState; g is standard gravity,
%   included for the same English lbf/lbf-basis reason as TakeoffConstraint.m;
%   CLmax_land from aero.get_CLmax(state), CD0_land from
%   aero.drag_polar(state).CD0; mu is the braking-surface friction
%   coefficient (0.50 for the F-16 landing field constraint, per
%   subplans/06_constraint_analysis.md's "Field constraints" table -- not
%   defaulted here since it is a runway/braking-system property, not a
%   universal margin, same reasoning as TakeoffConstraint.m's S_G); k_L is
%   the touchdown-speed margin V_TD/V_stall (1.3, the FAR-style approach-
%   speed-margin convention, playing the same role as k_TO=1.2 at takeoff);
%   beta is the landing weight fraction W_land/W_TO (1.0, per the same
%   "Field constraints" table -- landing, like takeoff, is treated at full
%   W_TO in this simplified framework, ignoring fuel burned before
%   touchdown).
%
%   NOTE ON CLmax/CD0 BASIS: aero.get_CLmax(state)/aero.drag_polar(state)
%   return the CLEAN (no high-lift-device) values -- the generic
%   AerodynamicsBase interface has no flapped-landing-config argument yet
%   (same documented gap as TakeoffConstraint.m's header and the subplan's
%   "TODO (high-lift configuration)" note). So even with the corrected
%   equation above, this class's WS_max will read well below Brandt's
%   138.742 when driven by clean CLmax/CD0 -- see
%   TestLandingConstraint.m's F-16 diagnostic, which is not an
%   exact-match assertion for that reason.

    properties (SetAccess = protected)
        name    % string -- condition label, e.g. "Landing"
    end

    properties (SetAccess = private)
        state   % AircraftState -- sea-level landing flight condition
        aero    % AerodynamicsBase -- supplies CLmax_land/CD0_land
        S_FR    % double, ft -- required landing free-roll/braking ground-roll distance
        mu      % double -- braking-surface friction coefficient
        beta    % double -- landing weight fraction W_land/W_TO
        k_L     % double -- touchdown speed margin V_TD/V_stall
    end

    properties (Constant, Access = private)
        G_FTS2 = 32.174   % ft/s^2 -- standard gravity
        DRAG_FACTOR = 0.83   % -- ground-roll velocity-averaging factor on the CD0 term, see class header
    end

    methods

        function obj = LandingConstraint(name, state, aero, S_FR, mu, beta, k_L)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                S_FR  (1,1) double {mustBePositive}
                mu    (1,1) double {mustBePositive}
                beta  (1,1) double {mustBePositive} = 1.0
                k_L   (1,1) double {mustBePositive} = 1.3
            end
            obj.name  = name;
            obj.state = state;
            obj.aero  = aero;
            obj.S_FR  = S_FR;
            obj.mu    = mu;
            obj.beta  = beta;
            obj.k_L   = k_L;
        end

        function WS = WS_max(obj)
        %WS_MAX  Upper bound on wing loading W/S [lbf/ft^2] this landing
        %   requirement imposes. See class header for the equation and
        %   citation. CLmax_land/CD0_land are pulled fresh from the aero
        %   discipline object each call, so this tracks the current-
        %   iteration aerodynamics.
            CLmax_land = obj.aero.get_CLmax(obj.state);
            CD0_land   = obj.aero.drag_polar(obj.state).CD0;
            rho        = obj.state.rho;
            g          = LandingConstraint.G_FTS2;

            WS = (rho * g * obj.S_FR * (obj.mu * CLmax_land + LandingConstraint.DRAG_FACTOR * CD0_land)) ...
                / (obj.k_L^2 * obj.beta);
        end

    end

end
