classdef F16PropL2 < PropulsionModelL2
%F16PROPL2  F-16A Block 10 Level-2 propulsion student class.
%
%   Inherits from PropulsionModelL2 (abstract enforcer).  Every abstract method
%   is satisfied by a single delegation line to PropL2 statics.
%
%   Level-2 model (Mattingly analytical):
%     thrust_lapse — Eq. 2.54 (low-BPR mixed turbofan; TR = 1.0)
%     TSFC         — Eq. 3.12 + 3.55 coefficients (selected by engine_type
%                    inside the PropL2 toolbox via lookup_TSFC_coeffs)
%
%   The base-class method thrust_lapse(obj, state) returns the AB/max lapse
%   (for use with T_SL = T_max).  Call compute_thrust_lapse_mil for mil power.
%   The base-class TSFC(obj, state) returns mil-power TSFC for Breguet equations.
%
%   ============================================================================
%   INPUT vs DERIVED — the optimization-ready pattern (F16GeomL2 is the
%   reference implementation).  Inputs are a plain mutable properties block set
%   once by the constructor from the JSON (an optimizer may mutate them).
%   Derived quantities live in a properties (Dependent) block and recompute
%   live on every read from the inputs — no stored/cached copy, never stale.
%   TR is the only derived quantity here: its get.TR recomputes from T_t4_max_F.
%   ============================================================================
%
%   Constructor reads the .propulsion block of a required unified L2 input JSON
%   (see f16a_spec_path(2)).  No silent default — the path must be supplied.
%   The Mattingly TSFC coefficients (C1/C2 mil+AB) are NOT stored here: they are
%   engine-class constants selected by engine_type inside the PropL2 toolbox
%   (PropL2.lookup_TSFC_coeffs), mirroring PropL1's engine_type-keyed tables.
%
%   Validation targets:
%     T_SL     = 23,770 lbf  [Brandt D29; TO]
%     T_SL_mil = 15,000 lbf  [Brandt C29; TO]
%     TR       = 1.0         [Mattingly Eq. D.6; T_t4_max=2566°F (Table C.4); T_t4_SLS unknown]
%     α_AB at 36 kft M=0.87: ≈ δ₀ ≈ 0.37  (θ₀≈0.867 < TR=1.0, so α_AB = δ₀)
%     TSFC_mil at SLS M=0: (0.90 + 0.30·0)·√1 = 0.90 1/hr  (uninstalled)
%       installed = 0.90·1.08 = 0.972 1/hr
%       (vs. Brandt installed 0.70 1/hr — Mattingly over-predicts SLS static;
%        correct trend vs. alt/Mach)
%
%   SOURCES:
%     [Brandt]    Brandt F-16A.xls, sheet "Main", cells C29/D29/C30/D30; Miss!C25
%     [TO]        T.O. 1F-16A-1, Sec. I
%     [Mattingly] J.D. Mattingly, "Aircraft Engine Design," 2nd ed., AIAA, 2002

    % ======================================================================= %
    % INPUTS — engine-spec data (mutable; set once by the constructor from the
    % JSON .propulsion block, may be varied by an optimizer). The DERIVED
    % (Dependent) property below recomputes live from these on every read.
    % ======================================================================= %
    properties
        engine_type = "low_bypass_turbofan_AB"  % selects PropL2 TSFC coefficient set [F100-PW-200 low-bypass AB turbofan; TO 1F-16A-1 Sec. I]
        T_SL     = 23770   % lbf — AB (max) SLS thrust  [PropulsionBase contract; Brandt D29; TO]
        T_SL_mil = 15000   % lbf — mil SLS thrust        [Brandt C29; TO]
        T_t4_max_F = 2566  % °F  — burner-exit total temperature [Mattingly Table C.4]; feeds get.TR
        TSFC_install_factor = 1.08  % — installed = uninstalled × factor [Brandt Miss!C25]

        %BYPASS_RATIO  — engine bypass ratio (F100-PW-200 class). Consumed by
        %   Raymer Eq. 10.10's exp(-0.81*BPR) term in the weights engine-weight
        %   estimate, read off this object by dependency injection.
        %   [Nicolai & Carichner Table 14.3, F100-PW-100],
        %   docs/reference_extracts/14_propulsion_fundamentals.md:581 -- the
        %   direct predecessor of the F100-PW-200 this model otherwise uses.
        bypass_ratio = 0.71
        % No stored TSFC property -- TSFC is state-dependent; call get_TSFC(obj, state).
    end

    % DERIVED — computed live from the inputs above on every read (no cache,
    % never stale). Read-only: assigning errors (no set-method).
    properties (Dependent)
        TR   % — throttle ratio; get.TR = PropL2.compute_TR(T_t4_max °F→°R) [Mattingly Eq. D.6]

        %T_SL_WET  lbf — AB (max) SLS thrust. An ALIAS for T_SL, kept because
        %   several call sites read the wet/AB name explicitly (e.g.
        %   PropL2.thrust_lapse_mil_on_AB_scale's T_SL_mil/T_SL_wet ratio).
        %   Dependent so it cannot diverge from T_SL under mutation.
        T_SL_wet
    end

    methods

        function obj = F16PropL2(json_path)
        %F16PROPL2  Construct from a required unified L2 input JSON path
        %   (f16a_spec_path(2)); reads its .propulsion block. No silent
        %   default: the path must be supplied. Sets ONLY the input
        %   properties; TR is produced live by its Dependent getter.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path)).propulsion;
            obj.engine_type         = string(J.engine_type);
            obj.T_SL                = J.T_SL;
            obj.T_SL_mil            = J.T_SL_mil;
            % T_SL_wet is NOT read: it is Dependent on T_SL (see its comment).
            obj.T_t4_max_F          = J.T_t4_max_F;
            obj.TSFC_install_factor = J.TSFC_install_factor;
            obj.bypass_ratio        = J.bypass_ratio;
        end

        % ---- DERIVED-property getters (recompute live on every read) ------ %
        function v = get.T_SL_wet(obj)
            v = obj.T_SL;   % wet/AB SLS thrust IS T_SL by the PropulsionBase convention
        end

        function v = get.TR(obj)
            % Throttle ratio [Mattingly Eq. D.6]. °F → °R via +459.67.
            % T_t4_SLS is unknown → compute_TR defaults it to T_t4_max → TR = 1.0.
            v = PropL2.compute_TR(obj.T_t4_max_F + 459.67);
        end

        % ---- Thrust lapse (Mattingly Eq. 2.54) ---------------------------- %
        function alpha = thrust_lapse(obj, state, rating)
        %THRUST_LAPSE  Mattingly thrust lapse at the given rating [Eq. 2.54].
        %   "AB"  -> full afterburner lapse T_AB/T_SL_AB.
        %   "mil" -> military/dry lapse on the AB T_SL scale (T_mil/T_SL_AB,
        %            renormalized per Brandt F-16A.xls Consts col AU -- so a
        %            dry-power condition shares the AB T_SL diagram axis).
            arguments
                obj
                state  (1,1) AircraftState
                rating (1,1) string {mustBeMember(rating, ["mil","AB"])}
            end
            if rating == "mil"
                alpha = PropL2.get_thrust_lapse_mil_on_AB_scale(obj, state);
            else
                alpha = PropL2.get_thrust_lapse(obj, state);
            end
        end

        function alpha = compute_thrust_lapse_mil(obj, state)
            alpha = PropL2.get_thrust_lapse_mil(obj, state);
        end

        function alpha = compute_thrust_lapse_AB(obj, state)
            alpha = PropL2.get_thrust_lapse_AB(obj, state);
        end

        % ---- TSFC — uninstalled (Mattingly Eq. 3.12 + 3.55) --------------- %
        function c_t = get_TSFC(obj, state)
            c_t = PropL2.get_TSFC(obj, state);
        end

        function c_t = compute_TSFC_mil(obj, state)
            c_t = PropL2.get_TSFC_mil(obj, state);
        end

        function c_t = compute_TSFC_AB(obj, state)
            c_t = PropL2.get_TSFC_AB(obj, state);
        end

        % ---- TSFC — installed (uninstalled × TSFC_install_factor) --------- %
        function c_t = compute_TSFC_installed(obj, state)
        %COMPUTE_TSFC_INSTALLED  Installed mil-power TSFC in 1/hr.
        %   [Mattingly Eq. 3.12 + 3.55a; install factor Brandt Miss!C25]
            c_t = PropL2.get_TSFC_installed(obj, state);
        end

        function c_t = compute_TSFC_AB_installed(obj, state)
        %COMPUTE_TSFC_AB_INSTALLED  Installed afterburner TSFC in 1/hr.
        %   [Mattingly Eq. 3.12 + 3.55b; install factor Brandt Miss!C25]
            c_t = PropL2.get_TSFC_AB_installed(obj, state);
        end

    end

end
