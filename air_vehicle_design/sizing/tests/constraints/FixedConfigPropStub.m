classdef FixedConfigPropStub < PropulsionBase
%FIXEDCONFIGPROPSTUB  A deterministic propulsion stand-in with engine count, tests only.
%
%   WHY THIS EXISTS. FixedPropStub covers the point-performance constraints
%   (Takeoff/Thrust), whose only propulsion input is a fixed thrust lapse. The
%   ClimbGradient constraint needs MORE: it reads prop.n_engines to apply the
%   one-engine-inoperative (OEI) climb factor and to reject a single-engine
%   aircraft, and it uses sea-level thrust. FixedConfigPropStub is the
%   deterministic propulsion object for the FAR-25 field-length/climb-gradient
%   constraint tests: settable n_engines and T_SL, plus constant thrust lapse
%   and TSFC.
%
%   It subclasses PropulsionBase only because that is the type the constraint
%   constructors require. thrust_lapse / thrust_lapse_mil_on_AB_scale / get_TSFC
%   return constructor-supplied constants, no matter what state is passed in.

    properties
        T_SL      = 1     % lbf -- sea-level static thrust (mutable; some constraints read it)
        n_engines = 2     % engine count (ClimbGradient reads this for the OEI factor)
        alpha     = 1     % constant thrust lapse returned by thrust_lapse(state)
        TSFC      = 0     % 1/hr -- constant TSFC returned by get_TSFC(state)
    end

    methods

        function obj = FixedConfigPropStub(alpha, n_engines, T_SL, TSFC)
        %FIXEDCONFIGPROPSTUB  Build the stub.
        %   FixedConfigPropStub() -> alpha=1, n_engines=2, T_SL=1, TSFC=0.
        %   Any argument may be supplied to override its default; the defaults
        %   match a twin-engine transport, which is what the metabook Example
        %   4.2 climb-gradient case assumes.
            arguments
                alpha     (1,1) double {mustBePositive}     = 1
                n_engines (1,1) double {mustBeInteger, mustBePositive} = 2
                T_SL      (1,1) double {mustBePositive}     = 1
                TSFC      (1,1) double {mustBeNonnegative}  = 0
            end
            obj.alpha     = alpha;
            obj.n_engines = n_engines;
            obj.T_SL      = T_SL;
            obj.TSFC      = TSFC;
        end

        function a = thrust_lapse(obj, ~)
        %THRUST_LAPSE  Constant lapse, state-independent.
            a = obj.alpha;
        end

        function a = thrust_lapse_mil_on_AB_scale(obj, ~)
        %THRUST_LAPSE_MIL_ON_AB_SCALE  Same constant lapse (no mil/AB split in
        %   a stub); overrides the PropulsionBase default only to stay
        %   explicitly state-independent.
            a = obj.alpha;
        end

        function c_t = get_TSFC(obj, ~)
        %GET_TSFC  Constant TSFC, state-independent.
            c_t = obj.TSFC;
        end

    end

end
