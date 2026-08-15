classdef F16PropL1 < PropulsionModelL1
%F16PROPL1  F-16A Block 10 Level-1 propulsion student class.
%
%   Inherits from PropulsionModelL1 (abstract enforcer).  Every abstract method
%   is satisfied by a single delegation line to PropL1 statics.
%
%   Level-1 model:
%     thrust_lapse — density-ratio law: α = σ^m, m=0.6 (engine-type table)
%                    [Martins AE481 course notes (metabook), Eq. 10.9]
%     TSFC         — categorical: cruise 0.80 1/hr (M >= 0.4) /
%                    loiter 0.70 1/hr (M < 0.4).  No AB, no Mach term, no
%                    supersonic value.  [Raymer 6th Table 3.3, low-bypass turbofan]
%
%   Constructor reads the .propulsion block of a required unified L1 input JSON
%   (see f16a_spec_path(1); the same file's .geometry/.aerodynamics blocks feed
%   F16GeomL1/F16AeroL1).  No silent default — the path must be supplied.
%
%   Validation target:
%     T_SL = 23,770 lbf  [Brandt D29; T.O. 1F-16A-1]
%     α at 36 kft M=0.87: σ^0.6 ≈ 0.484  (no Mach correction at L1)
%
%   SOURCES:
%     [Brandt] Brandt F-16A.xls, sheet "Main", cells C29/D29
%     [TO]     T.O. 1F-16A-1, Sec. I

    properties
        engine_type = "low_bypass_turbofan_AB"   % PropL1 TSFC/lapse table key [F100-PW-200 low-bypass AB turbofan; TO 1F-16A-1 Sec. I]
        T_SL     = 23770                         % lbf — AB (max) SLS thrust  [PropulsionBase contract; Brandt D29; TO]
        % (No stored TSFC property. It used to exist as a `TSFC = 0` placeholder
        % satisfying a PropulsionBase abstract property; that declaration was
        % removed 2026-07-25 because TSFC is state-dependent. Call
        % get_TSFC(obj, state).)
    end

    % ======================================================================= %
    % DERIVED — recomputed live on every read; read-only (no set-method).
    % ======================================================================= %
    properties (Dependent)
        %T_SL_WET  lbf — AB (max) SLS thrust; an ALIAS for T_SL, kept because
        %   call sites read the wet/AB name explicitly. Was a stored input
        %   duplicating T_SL in both the class and the JSON (Phase 3,
        %   2026-07-25) -- two independently-settable copies of one quantity, so
        %   an optimizer changing T_SL left T_SL_wet stale. Now they cannot
        %   diverge.
        T_SL_wet
    end

    methods

        function obj = F16PropL1(json_path)
        %F16PROPL1  Construct from a required unified L1 input JSON path
        %   (f16a_spec_path(1)); reads its .propulsion block. No silent
        %   default: the path must be supplied.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path)).propulsion;
            obj.engine_type = string(J.engine_type);
            obj.T_SL        = J.T_SL;
            % T_SL_wet is NOT read: it is Dependent on T_SL (see its comment).
        end

        function v = get.T_SL_wet(obj)
            v = obj.T_SL;   % wet/AB SLS thrust IS T_SL by the PropulsionBase convention
        end

        function alpha = thrust_lapse(obj, state, rating)
        %THRUST_LAPSE  L1 density-ratio lapse alpha = sigma^m [Eq. 10.9].
        %   L1 has NO mil/AB split (a single density-ratio law), so both the
        %   "mil" and "AB" ratings return the same lapse; the rating is still
        %   required and validated so a caller cannot silently pass a setting
        %   the F-16 engine does not have.
            arguments
                obj
                state  (1,1) AircraftState
                rating (1,1) string {mustBeMember(rating, ["mil","AB"])}
            end
            alpha = PropL1.get_thrust_lapse(obj, state);
        end

        function c_t = get_TSFC(obj, state)
            c_t = PropL1.get_TSFC(obj, state);
        end

        function alpha = get_thrust_lapse(obj, state)
            alpha = PropL1.get_thrust_lapse(obj, state);
        end

        function c_t = lookup_TSFC(obj, state)
            c_t = PropL1.get_TSFC(obj, state);
        end

    end

end
