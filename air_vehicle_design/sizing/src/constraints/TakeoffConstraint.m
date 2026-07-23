classdef TakeoffConstraint < Both_WbyS_TbyW
%TAKEOFFCONSTRAINT  Mattingly Master Equation, ground-roll (takeoff) case.
%
%   Generic Layer-1 constraint: given a sea-level takeoff flight condition
%   (AircraftState), a required ground-roll distance S_G, and the
%   current-iteration aerodynamics/propulsion discipline objects, returns
%   the thrust-to-weight ratio required to take off within S_G as a
%   function of wing loading W/S. Belongs to the Both_WbyS_TbyW category
%   (see that class's header) -- it supplies the A/B/C/D terms below (A=C=D=0,
%   only B survives, see equation below); Both_WbyS_TbyW assembles them into
%   required_TW(WS). CLmax_TO is pulled fresh from aero.get_CLmax(state)
%   each call -- not a constraint input, per
%   sizing/docs/subplans/06_constraint_analysis.md ("CLmax is NOT a
%   constraint input. The constraint analysis calls aero.CLmax(state) at
%   the relevant flight condition."). Using the generic get_CLmax(state)
%   interface (clean CLmax) rather than F16AeroL3's ad-hoc get_CLmax_TO is
%   intentional here -- reconciling a first-class high-lift-config
%   argument into the AerodynamicsBase interface is flagged as an
%   explicit TODO in that subplan, out of scope for this generic class.
%
%   EQUATION [Mattingly, Heiser, Pratt, "Aircraft Engine Design," 2nd ed.,
%   AIAA, 2002 -- the same point-performance Master Equation ThrustConstraint
%   implements (see that class's header), specialized to the ground-roll
%   (takeoff) segment via T_SL >> (D+R) and dh/dt=0, which zero the Master
%   Equation's A, C, and D terms and leave only a B*(W_TO/S) term; matches
%   NPTEL_Fighter_Aircraft_Sizing.ipynb's Takeoff class (cells 32-33,
%   "### Takeoff" markdown + class Takeoff(Both_WbyS_TbyW)), the notebook
%   sizing/docs/subplans/06_constraint_analysis.md cites as the inspiration
%   for this class hierarchy -- NOT Raymer (Raymer's "Aircraft Design: A
%   Conceptual Approach," 6th ed., ch. 5, "Takeoff Distance" section, pp.
%   128-130, gives only the graphical Takeoff Parameter/Fig. 5.4 method,
%   confirmed by direct inspection of that chapter -- no closed-form W/S-
%   linear equation appears there; an earlier version of this header cited
%   Raymer ch. 5 in error). Cross-checked against temp_Casey's
%   takeoff_constraint.m (reference only, not reused): its term1 --
%     (V_TO/Vstall)^2 * beta^2 .* WS ./ (alpha*rho*CLmax*g*Distance)
%   -- is algebraically identical to the equation below with k_TO in place
%   of V_TO/Vstall and S_G in place of Distance; temp_Casey's term2
%   (0.7*CD0/(beta*CLmax) + mu) is the drag/rolling-friction correction
%   that survives in Brandt's own (less-simplified, T>>D not assumed)
%   F-16A.xls Consts-sheet takeoff row but that this class's T>>D-simplified
%   form omits -- see F16Baseline.m b.constraints.takeoff.TW_Takeoff and
%   TestTakeoffConstraint.m's diagnostic (not exact-match) comparison
%   against it]:
%
%     T_SL/W_TO = (beta^2/alpha) * (k_TO^2 / (rho*g*CLmax_TO)) * (W_TO/S) / S_G
%
%   where rho comes from the sea-level AircraftState; g is standard
%   gravity, included here (unlike the NPTEL notebook's SI form) because
%   this framework's AircraftState is weight-based (English lbf/lbf T/W),
%   not the notebook's mass-based T/mass (N/kg) convention -- rho (mass
%   density) must be converted to a weight density via g for the ratio to
%   come out dimensionless; CLmax_TO from aero.get_CLmax(state); alpha from
%   prop.thrust_lapse(state); beta is the takeoff weight fraction (1.0 for
%   field constraints, per subplans/06_constraint_analysis.md "Field
%   constraints" table -- takeoff burns negligible fuel before brake
%   release); k_TO is the liftoff-speed margin V_TO/V_stall (1.2, per the
%   NPTEL notebook and the F-16 field-constraint table's k_TO); S_G is the
%   required takeoff ground-roll distance, ft (4,000 ft for the F-16 per
%   the same table).

    properties (SetAccess = protected)
        name    % string -- condition label, e.g. "Takeoff"
    end

    properties (SetAccess = private)
        state   % AircraftState -- sea-level takeoff flight condition
        aero    % AerodynamicsBase -- supplies CLmax_TO via get_CLmax(state)
        prop    % PropulsionBase -- supplies alpha via thrust_lapse(state)
        S_G     % double, ft -- required takeoff ground-roll distance
        beta    % double -- takeoff weight fraction W/W_TO
        k_TO    % double -- liftoff speed margin V_TO/V_stall
    end

    properties (Constant, Access = private)
        G_FTS2 = 32.174   % ft/s^2 -- standard gravity
    end

    methods

        function obj = TakeoffConstraint(name, state, aero, prop, S_G, beta, k_TO)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                prop  (1,1) PropulsionBase
                S_G   (1,1) double {mustBePositive}
                beta  (1,1) double {mustBePositive} = 1.0
                k_TO  (1,1) double {mustBePositive} = 1.2
            end
            obj.name  = name;
            obj.state = state;
            obj.aero  = aero;
            obj.prop  = prop;
            obj.S_G   = S_G;
            obj.beta  = beta;
            obj.k_TO  = k_TO;
        end

    end

    methods (Access = protected)
        %COMPUTE_A/B/C/D  Master Equation terms specialized to the ground-roll
        %   case (T_SL>>D+R, dh/dt=0 zero A, C, D -- see class header): only B
        %   survives, carrying the equation below.

        function A = compute_A(~)
            A = 0;
        end

        function B = compute_B(obj)
        %COMPUTE_B  See class header for the equation and citation.
            CLmax_TO = obj.aero.get_CLmax(obj.state);
            alpha    = obj.prop.thrust_lapse(obj.state);
            rho      = obj.state.rho;

            coeff = (obj.beta^2 / alpha) * (obj.k_TO^2 / (rho * TakeoffConstraint.G_FTS2 * CLmax_TO));
            B = coeff / obj.S_G;
        end

        function C = compute_C(~)
            C = 0;
        end

        function D = compute_D(~)
            D = 0;
        end

    end

end
