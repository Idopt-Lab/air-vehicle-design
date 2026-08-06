classdef BrandtPropAdapter < PropulsionBase
%BRANDTPROPADAPTER  Adapter exposing Brandt's own F-16A engine model
%   (VnV/BrandtF16A/BrandtEngine.m) through the generic PropulsionBase
%   contract, so "Brandt" can be selected as a fidelity LEVEL in the
%   mixed-fidelity sizing harness alongside F16PropL1/L2.
%
%   SELF-CONTAINED: the constructor builds a PRIVATE BrandtEngine and
%   analyzes it internally. BrandtEngine() ALWAYS loads its own hardcoded
%   VnV/BrandtF16A/GroundTruth/f16a_geometry.json -- this ignores whatever
%   f16a_L{1,2,3}.json spec the rest of a mixed combo points at
%   (COMPATIBILITY_NOTES.md item 5).
%
%   T_SL -- a PLAIN, MUTABLE property (NOT Dependent), seeded from
%   obj.brandt.T_sl_AB (23,770 lbf SLS afterburning thrust [Brandt
%   Engn(s)!T_AB_SLS = Main!D29]) at construction. This diverges from the
%   original mixed-fidelity design sketch, which proposed T_SL as read-only
%   Dependent; that would break BOTH SizingLoopL1 and SizingLoopL2, whose
%   run() bodies do `obj.prop.T_SL = T_SL_new` every iteration -- exactly
%   mirroring F16PropL2.T_SL, which is likewise a plain property the loop
%   overwrites in place even though its initial value is also a cited
%   Brandt/T.O. constant.
%   ! CONSEQUENCE, loudly documented: mutating obj.T_SL does NOT feed back
%   into obj.brandt, which keeps computing thrust_lapse/get_TSFC from its
%   OWN fixed internal T_sl_dry/T_sl_AB regardless of what this adapter's
%   T_SL currently holds. A sizing loop pairing Propulsion=Brandt will
%   therefore converge T_SL to some number while thrust_lapse/get_TSFC never
%   move -- an expected, structural artifact of wrapping Brandt's
%   self-contained engine model behind a mutable-state contract it was
%   never designed to have, not a bug to chase. Documented "weirdness",
%   consistent with this harness's tolerance for mixed-fidelity artifacts
%   (see COMPATIBILITY_NOTES.md).
%
%   thrust_lapse(obj, state) -- 100% afterburner (AB_p=1.0): calls
%   obj.brandt.run(state.altitude_ft, state.mach, 1.0) and returns
%   r.alpha_AB_ref, the lapse normalized on the T_SL_AB scale (Brandt's Miss
%   tab convention, BrandtEngine.m's own doc comment) -- exactly the ratio
%   PropulsionBase.thrust_lapse's contract documents (T(alt,M)/T_SL at
%   AB/max power).
%
%   get_TSFC(obj, state) -- dry/mil power (AB_p=0.0): calls
%   obj.brandt.run(state.altitude_ft, state.mach, 0.0) and returns r.TSFC.
%
%   thrust_lapse_mil_on_AB_scale is NOT overridden: PropulsionBase's default
%   (= thrust_lapse(state), i.e. the AB-basis lapse) applies here, same as
%   any concrete class with no separate mil-power model.

    properties
        T_SL   % lbf -- sea-level static AB thrust. Plain, mutable: see class header.
    end

    properties (Access = private)
        brandt   % BrandtEngine handle, built + analyzed in the constructor
    end

    methods

        function obj = BrandtPropAdapter()
        %BRANDTPROPADAPTER  Build and analyze a private BrandtEngine.
        %   No path argument: BrandtEngine() always loads its own hardcoded JSON.
            obj.brandt = BrandtEngine();
            obj.brandt.analyze();
            obj.T_SL = obj.brandt.T_sl_AB;   % [Brandt Engn(s)!T_AB_SLS = 23770]
        end

        function alpha = thrust_lapse(obj, state)
        %THRUST_LAPSE  100% AB thrust lapse T(alt,M)/T_SL_AB, from Brandt's OWN
        %   fixed engine data (see class header -- does not track obj.T_SL).
            arguments
                obj
                state (1,1) AircraftState
            end
            r = obj.brandt.run(state.altitude_ft, state.mach, 1.0);
            alpha = r.alpha_AB_ref;
        end

        function c_t = get_TSFC(obj, state)
        %GET_TSFC  Mil-power (dry, AB_p=0) installed TSFC [1/hr], from
        %   Brandt's OWN fixed engine data (see class header).
            arguments
                obj
                state (1,1) AircraftState
            end
            r = obj.brandt.run(state.altitude_ft, state.mach, 0.0);
            c_t = r.TSFC;
        end

    end

end
