classdef TakeoffConstraint < Both_WbyS_TbyW
%TAKEOFFCONSTRAINT  Mattingly Master Equation, ground-roll (takeoff) case.
%
%   Generic Layer-1 constraint. Given a sea-level takeoff flight condition
%   (AircraftState), a required ground-roll distance S_G, and the
%   current-iteration aero/prop discipline objects, it returns the
%   thrust-to-weight ratio required to take off within S_G as a function of
%   wing loading W/S. Belongs to the Both_WbyS_TbyW category as a direct
%   sibling of the Master-Equation subtree: its required_TW is the ground-roll
%   affine relation below (the A=D=0 case where only B and C survive), not the
%   full Master Equation, so it implements required_TW itself.
%
%   CLmax_TO/CD0_TO are pulled fresh from the aero object each call.
%   get_CLmax_TO/get_Delta_CD0_TO are flapped-takeoff methods every F16AeroLN
%   class implements but which are NOT part of the abstract AerodynamicsBase
%   interface; any aero passed here must implement them (see compute_C for the
%   arity note).
%
%   EQUATION [Mattingly, Heiser, Pratt, "Aircraft Engine Design," 2nd ed.,
%   AIAA, 2002 -- the Master Equation specialized to the ground-roll segment
%   via T_SL >> (D+R) and dh/dt=0, which zero the A and D terms and leave a
%   B*(W/S) term plus a constant C (drag/rolling-friction correction). B term
%   matches NPTEL_Fighter_Aircraft_Sizing.ipynb (cells 32-33); full equation
%   matches Brandt F-16A.xls Consts row 32. NOT Raymer (ch. 5 gives only the
%   graphical Fig. 5.4 method). Reproduces Brandt's takeoff T/W to within 0.5%
%   at W/S=90 -- see TestTakeoffConstraint.m]:
%
%     T_SL/W_TO = (beta^2/alpha) * (k_TO^2 / (rho*g*CLmax_TO)) * (W_TO/S) / S_G
%                 + 0.7*CD0_TO/(beta*CLmax_TO) + mu
%
%   rho is sea-level density; g is standard gravity (included because this
%   framework's T/W is weight-based English lbf/lbf); CLmax_TO from
%   aero.get_CLmax_TO(); CD0_TO from drag_polar(state).CD0 +
%   get_Delta_CD0_TO(...) (flapped); alpha from thrust_lapse(state, "AB");
%   beta is the takeoff weight fraction (1.0); k_TO is the liftoff-speed
%   margin V_TO/V_stall (1.2); S_G is the ground-roll distance, ft; mu is the
%   rolling-friction coefficient (a runway property, not defaulted). Condition
%   values: examples/F16A/inputs/f16a_requirements.md.

    properties (SetAccess = protected)
        name    % string -- condition label, e.g. "Takeoff"
    end

    properties (SetAccess = private)
        state   % AircraftState -- sea-level takeoff flight condition
        aero    % AerodynamicsBase -- supplies CLmax_TO/CD0_TO via get_CLmax_TO()/(drag_polar(state).CD0 + get_Delta_CD0_TO(...))
        prop    % PropulsionBase -- supplies alpha via thrust_lapse(state, "AB")
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

        function TW = required_TW(obj, WS)
        %REQUIRED_TW  T/W required to take off within S_G at wing loading(s)
        %   WS [lbf/ft^2], per the ground-roll relation in the class header:
        %   TW = B*(W/S) + C. WS may be scalar or array; TW is returned the
        %   same size.
        %
        %   Fails loudly on a non-finite term: a NaN required_TW is silently
        %   dropped from ConstraintAnalysis's max() envelope. CLmax_TO, alpha,
        %   and the drag polar are fetched fresh each call so the constraint
        %   tracks the current iteration/fidelity.
            CLmax_TO = obj.aero.get_CLmax_TO();
            alpha    = obj.get_alpha();
            CD0_TO   = obj.aero.drag_polar(obj.state).CD0 + ...
                TakeoffConstraint.get_Delta_CD0_TO_dispatched(obj.aero, obj.state);

            B = obj.compute_B(CLmax_TO, alpha);
            C = obj.compute_C(CLmax_TO, CD0_TO);
            terms = [B, C];
            if ~all(isfinite(terms))
                names = ["B", "C"];
                bad   = names(~isfinite(terms));
                where = sprintf('This condition is at alt=%g ft, M=%.4f.', ...
                    obj.state.altitude_ft, obj.state.mach);
                error('TakeoffConstraint:nonFiniteTerm', ...
                    ['Constraint "%s": ground-roll term(s) %s are non-finite ', ...
                     '[B C] = %s. The usual cause is a flapped CLmax_TO/CD0_TO ', ...
                     'or thrust lapse that is not modeled at this flight ', ...
                     'condition. %s'], ...
                    obj.name, strjoin(bad, "/"), mat2str(terms, 6), where);
            end
            TW = B .* WS + C;
        end

    end

    methods (Access = protected)
        %COMPUTE_B/C  Ground-roll terms (T_SL>>D+R, dh/dt=0 zero the
        %   Master-Equation A and D -- see class header): B carries the
        %   W/S-linear term, C the drag/rolling-friction ground-roll
        %   correction. required_TW above assembles them into B*(W/S) + C.

        function B = compute_B(obj, CLmax_TO, alpha)
        %COMPUTE_B  See class header for the equation and citation. CLmax_TO is
        %   the flapped takeoff value (aero.get_CLmax_TO()), not the clean
        %   aero.get_CLmax(state). Takes the already-fetched CLmax_TO and
        %   thrust lapse alpha (required_TW fetches them once).
            rho = obj.state.rho;

            coeff = (obj.beta^2 / alpha) * (obj.k_TO^2 / (rho * TakeoffConstraint.G_FTS2 * CLmax_TO));
            B = coeff / obj.S_G;
        end

        function C = compute_C(obj, CLmax_TO, CD0_TO)
        %COMPUTE_C  Ground-roll drag/rolling-friction correction. See class
        %   header for the equation and citation. CLmax_TO/CD0_TO are the
        %   flapped takeoff values (required_TW fetches them once; its CD0_TO
        %   fetch handles get_Delta_CD0_TO's per-fidelity arity -- see
        %   get_Delta_CD0_TO_dispatched).
            C = TakeoffConstraint.DRAG_FACTOR * CD0_TO / (obj.beta * CLmax_TO) + obj.mu;
        end

        function alpha = get_alpha(obj)
        %GET_ALPHA  Thrust lapse at full takeoff power ("AB"). Takeoff is
        %   always flown at full power, so the rating is fixed here.
            alpha = obj.prop.thrust_lapse(obj.state, "AB");
        end

    end

    methods (Static, Access = private)

        function delta = get_Delta_CD0_TO_dispatched(aero, state)
        %GET_DELTA_CD0_TO_DISPATCHED  Calls aero.get_Delta_CD0_TO() with or
        %   without the flight state, matching the arity aero's fidelity level
        %   declares (F16AeroL1/L2 take none, F16AeroL3 takes state).
        %   Dispatches via metaclass reflection on InputNames, since nargin on
        %   a bound instance-method handle returns -1.
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

    methods (Static)

        function obj = fromCondition(cond, aero, prop)
        %FROMCONDITION  Build from a requirements-JSON condition struct + the
        %   injected aero/prop. Takeoff is modeled at the JSON liftoff Mach
        %   (mach_liftoff); rho at sea level is Mach-independent, so this only
        %   matches the modeled liftoff condition to Brandt. Uniform factory
        %   dispatched by ConstraintType; see ConstraintAnalysis.from_requirements.
            state = AircraftState(cond.altitude_ft, cond.mach_liftoff);
            obj = TakeoffConstraint(string(cond.name), state, aero, prop, ...
                cond.distance_ft, cond.mu, cond.beta, cond.k_factor);
        end

    end

end
