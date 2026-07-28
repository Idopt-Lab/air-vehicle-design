classdef TakeoffConstraint < Both_WbyS_TbyW
%TAKEOFFCONSTRAINT  Mattingly Master Equation, ground-roll (takeoff) case.
%
%   Generic Layer-1 constraint: given a sea-level takeoff flight condition
%   (AircraftState), a required ground-roll distance S_G, and the
%   current-iteration aerodynamics/propulsion discipline objects, returns
%   the thrust-to-weight ratio required to take off within S_G as a
%   function of wing loading W/S. Belongs to the Both_WbyS_TbyW category
%   (see that class's header) -- it supplies the A/B/C/D terms below (A=D=0;
%   B and C survive, see equation below); Both_WbyS_TbyW assembles them into
%   required_TW(WS). CLmax_TO/CD0_TO are pulled fresh from
%   aero.get_CLmax_TO()/(aero.drag_polar(state).CD0 + aero.get_Delta_CD0_TO(...))
%   each call -- not constraint inputs, per
%   sizing/docs/subplans/06_constraint_analysis.md ("CLmax is NOT a
%   constraint input. The constraint analysis calls aero.CLmax(state) at
%   the relevant flight condition."). get_CLmax_TO/get_Delta_CD0_TO are the
%   flapped-takeoff-configuration methods every F16AeroLN class implements
%   (cited Roskam/Raymer flap CLmax delta and CD0 increment) but which are
%   NOT part of the enforced AerodynamicsBase interface (only drag_polar and
%   get_CLmax are abstract there) -- reconciling a first-class high-lift-
%   config argument into that interface is still a TODO in that subplan, out
%   of scope for this generic class; any AerodynamicsBase subclass passed
%   here must implement get_CLmax_TO/get_Delta_CD0_TO itself (see
%   compute_C's header for the get_Delta_CD0_TO arity note).
%
%   EQUATION [Mattingly, Heiser, Pratt, "Aircraft Engine Design," 2nd ed.,
%   AIAA, 2002 -- the same point-performance Master Equation ThrustConstraint
%   implements (see that class's header), specialized to the ground-roll
%   (takeoff) segment via T_SL >> (D+R) and dh/dt=0, which zero the Master
%   Equation's A and D terms and leave a B*(W_TO/S) term plus a constant C
%   term (the drag/rolling-friction ground-roll correction below); matches
%   NPTEL_Fighter_Aircraft_Sizing.ipynb's Takeoff class (cells 32-33,
%   "### Takeoff" markdown + class Takeoff(Both_WbyS_TbyW)) for the B term,
%   and Brandt's own F-16A.xls Consts-sheet takeoff row (row 32) for the full
%   equation including C -- NOT Raymer (Raymer's "Aircraft Design: A
%   Conceptual Approach," 6th ed., ch. 5, "Takeoff Distance" section, pp.
%   128-130, gives only the graphical Takeoff Parameter/Fig. 5.4 method,
%   confirmed by direct inspection of that chapter -- no closed-form W/S-
%   linear equation appears there; an earlier version of this header cited
%   Raymer ch. 5 in error). Cross-checked against temp_Casey's
%   takeoff_constraint.m (reference only, not reused): its term1 --
%     (V_TO/Vstall)^2 * beta^2 .* WS ./ (alpha*rho*CLmax*g*Distance)
%   -- is algebraically identical to the B term below with k_TO in place of
%   V_TO/Vstall and S_G in place of Distance; its term2 --
%     0.7*CD0/(beta*CLmax) + mu
%   -- is the C term below: a drag/rolling-friction ground-roll correction
%   (the empirical first-order term Brandt's own, less-simplified, T>>D-not-
%   assumed takeoff row keeps, analogous in role to LandingConstraint.m's
%   DRAG_FACTOR term for the landing case). A prior version of this class
%   omitted C (T>>D taken literally, dropping this correction too); adding
%   it back reproduces F16Baseline.m's b.constraints.takeoff.TW_Takeoff to
%   well within 0.5% at W/S=90 when fed Brandt's own inputs (mu=0.03,
%   CD0=0.052, CLmax_TO=1.2785, alpha_AB=0.955053) -- see
%   TestTakeoffConstraint.m's testEquationReproducesBrandtTakeoffPoint]:
%
%     T_SL/W_TO = (beta^2/alpha) * (k_TO^2 / (rho*g*CLmax_TO)) * (W_TO/S) / S_G
%                 + 0.7*CD0_TO/(beta*CLmax_TO) + mu
%
%   where rho comes from the sea-level AircraftState; g is standard
%   gravity, included here (unlike the NPTEL notebook's SI form) because
%   this framework's AircraftState is weight-based (English lbf/lbf T/W),
%   not the notebook's mass-based T/mass (N/kg) convention -- rho (mass
%   density) must be converted to a weight density via g for the ratio to
%   come out dimensionless; CLmax_TO from aero.get_CLmax_TO(); CD0_TO from
%   aero.drag_polar(state).CD0 + aero.get_Delta_CD0_TO(...) (the flapped
%   takeoff configuration -- see class header and compute_C's header);
%   alpha from prop.thrust_lapse(state); beta is
%   the takeoff weight fraction (1.0 for field constraints, per
%   subplans/06_constraint_analysis.md "Field constraints" table -- takeoff
%   burns negligible fuel before brake release); k_TO is the liftoff-speed
%   margin V_TO/V_stall (1.2, per the NPTEL notebook and the F-16
%   field-constraint table's k_TO); S_G is the required takeoff ground-roll
%   distance, ft (4,000 ft for the F-16 per the same table); mu is the
%   ground-roll rolling-friction coefficient (0.03 for the F-16 takeoff
%   field constraint, per the same table -- not defaulted here since it is
%   a runway/surface property, not a universal margin, same reasoning as
%   LandingConstraint.m's mu).

    properties (SetAccess = protected)
        name    % string -- condition label, e.g. "Takeoff"
    end

    properties (SetAccess = private)
        state   % AircraftState -- sea-level takeoff flight condition
        aero    % AerodynamicsBase -- supplies CLmax_TO/CD0_TO via get_CLmax_TO()/(drag_polar(state).CD0 + get_Delta_CD0_TO(...))
        prop    % PropulsionBase -- supplies alpha via thrust_lapse(state)
        S_G     % double, ft -- required takeoff ground-roll distance
        mu      % double -- ground-roll rolling-friction coefficient
        beta    % double -- takeoff weight fraction W/W_TO
        k_TO    % double -- liftoff speed margin V_TO/V_stall
    end

    properties (Constant, Access = private)
        G_FTS2 = 32.174   % ft/s^2 -- standard gravity
        DRAG_FACTOR = 0.7   % -- ground-roll drag-correction factor on the CD0 term, see class header
    end

    methods

        function obj = TakeoffConstraint(name, state, aero, prop, S_G, mu, beta, k_TO)
            arguments
                name  (1,1) string
                state (1,1) AircraftState
                aero  (1,1) AerodynamicsBase
                prop  (1,1) PropulsionBase
                S_G   (1,1) double {mustBePositive}
                mu    (1,1) double {mustBePositive}
                beta  (1,1) double {mustBePositive} = 1.0
                k_TO  (1,1) double {mustBePositive} = 1.2
            end
            obj.name  = name;
            obj.state = state;
            obj.aero  = aero;
            obj.prop  = prop;
            obj.S_G   = S_G;
            obj.mu    = mu;
            obj.beta  = beta;
            obj.k_TO  = k_TO;
        end

    end

    methods (Access = protected)
        %COMPUTE_A/B/C/D  Master Equation terms specialized to the ground-roll
        %   case (T_SL>>D+R, dh/dt=0 zero A and D -- see class header): B
        %   carries the W/S-linear term, C the drag/rolling-friction
        %   ground-roll correction.

        function A = compute_A(~)
            A = 0;
        end

        function B = compute_B(obj)
        %COMPUTE_B  See class header for the equation and citation.
        %   CLmax_TO is the FLAPPED takeoff value (aero.get_CLmax_TO()), not
        %   the clean aero.get_CLmax(state) -- see the class header's
        %   discussion of get_CLmax_TO/get_Delta_CD0_TO above.
            CLmax_TO = obj.aero.get_CLmax_TO();
            alpha    = obj.get_alpha();
            rho      = obj.state.rho;

            coeff = (obj.beta^2 / alpha) * (obj.k_TO^2 / (rho * TakeoffConstraint.G_FTS2 * CLmax_TO));
            B = coeff / obj.S_G;
        end

        function C = compute_C(obj)
        %COMPUTE_C  Ground-roll drag/rolling-friction correction. See class
        %   header for the equation and citation. CLmax_TO/CD0_TO are the
        %   FLAPPED takeoff values (aero.get_CLmax_TO(),
        %   aero.drag_polar(state).CD0 + aero.get_Delta_CD0_TO(...)), pulled
        %   fresh from the aero discipline object each call, same convention
        %   as compute_B. get_Delta_CD0_TO's signature is not uniform across
        %   fidelity levels: F16AeroL1/L2 take no argument, F16AeroL3 takes
        %   the flight state (gear-strut Reynolds-number lookup) -- dispatched
        %   via metaclass reflection on aero's declared InputNames (see
        %   TakeoffConstraint.get_Delta_CD0_TO_dispatched), since neither
        %   nargin(@obj.aero.get_Delta_CD0_TO) (returns -1 for bound
        %   instance-method handles) nor a try/catch is a reliable arity check.
            CLmax_TO       = obj.aero.get_CLmax_TO();
            Delta_CD0_TO   = TakeoffConstraint.get_Delta_CD0_TO_dispatched(obj.aero, obj.state);
            CD0_TO         = obj.aero.drag_polar(obj.state).CD0 + Delta_CD0_TO;

            C = TakeoffConstraint.DRAG_FACTOR * CD0_TO / (obj.beta * CLmax_TO) + obj.mu;
        end

        function D = compute_D(~)
            D = 0;
        end

        function alpha = get_alpha(obj)
        %GET_ALPHA  Thrust lapse (AB/max power, PropulsionBase convention --
        %   TakeoffConstraint has no mil/AB distinction to select between,
        %   unlike ThrustConstraint.m's get_alpha). Exposed as its own
        %   method, rather than computed inline only inside compute_B, so
        %   Both_WbyS_TbyW.TW_margin uses this exact same alpha -- never an
        %   independently-supplied value that could disagree with it.
            alpha = obj.prop.thrust_lapse(obj.state);
        end

    end

    methods (Static, Access = private)

        function delta = get_Delta_CD0_TO_dispatched(aero, state)
        %GET_DELTA_CD0_TO_DISPATCHED  Calls aero.get_Delta_CD0_TO() with or
        %   without the flight state, matching whichever arity aero's
        %   fidelity level declares (F16AeroL1/L2 take none, F16AeroL3 takes
        %   state for a gear-strut Reynolds-number lookup -- see compute_C's
        %   header). Dispatches via metaclass reflection on the method's
        %   declared InputNames, since nargin(@aero.get_Delta_CD0_TO)
        %   returns -1 for bound instance-method handles and is not a
        %   reliable arity check.
            mc = metaclass(aero);
            m  = findobj(mc.MethodList, 'Name', 'get_Delta_CD0_TO');
            if isempty(m)
                error('TakeoffConstraint:missingGetDeltaCD0TO', ...
                    ['aero (class %s) has no get_Delta_CD0_TO method -- every ', ...
                     'AerodynamicsBase subclass passed to TakeoffConstraint must ', ...
                     'implement the flapped-takeoff get_CLmax_TO/get_Delta_CD0_TO ', ...
                     'methods (see class header).'], class(aero));
            end
            if numel(m.InputNames) >= 2
                delta = aero.get_Delta_CD0_TO(state);
            else
                delta = aero.get_Delta_CD0_TO();
            end
        end

    end

end
