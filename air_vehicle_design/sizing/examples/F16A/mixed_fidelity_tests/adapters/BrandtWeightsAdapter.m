classdef BrandtWeightsAdapter < WeightsBase
%BRANDTWEIGHTSADAPTER  Adapter exposing Brandt's own F-16A weight buildup
%   (VnV/BrandtF16A/BrandtWeight.m) through the generic WeightsBase
%   contract, so "Brandt" can be selected as a fidelity LEVEL in the
%   mixed-fidelity sizing harness alongside F16WeightsL1/L2/L3.
%
%   SELF-CONTAINED, BY DESIGN (see BrandtGeomAdapter's header for the
%   rationale, which applies identically here): the constructor builds its
%   own PRIVATE BrandtGeometry -> BrandtWeight pair, calling geom.analyze()
%   and wt.analyze() internally (BrandtWeight.analyze() computes the
%   geometry-dependent structural weights and must run before .run(W_TO) --
%   see BrandtWeight.m:112-125). No external geometry object is injected --
%   Weights=Brandt always reflects Brandt's own airframe, independent of
%   whatever Geometry LEVEL the rest of a combo chose
%   (COMPATIBILITY_NOTES.md item 3).
%
%   OEW(obj, W_TO) calls r = obj.brandt.run(W_TO) and returns r.W_empty_lb
%   -- Brandt's own Wt!B12 = W_airframe + W_engine (BrandtWeight.m's class
%   header: "W_empty = W_airframe + W_engine"; confirmed as the exact
%   returned-struct field name at BrandtWeight.m's own Usage example,
%   "OEW = %.1f lb ... r.W_empty_lb").
%
%   W_TO / W_energy are left NaN, matching F16WeightsL1/L2/L3's OWN
%   treatment: both are STATE, only ever valid once the sizing loop sets
%   them (W_TO) or mission analysis sets them (W_energy); OEW itself never
%   reads obj.W_TO (it takes its own W_TO argument, per WeightsBase's
%   contract: "OEW stays a METHOD ... so it cannot go stale").
%
%   W_payload_fixed / W_payload_expendable are NOT left NaN (an earlier
%   version of this adapter did, reasoning that "no WeightsL{1,2,3} static
%   reads them" -- true, but SizingLoopL1.m/SizingLoopL2.m read
%   obj.wts.W_payload_fixed + obj.wts.W_payload_expendable directly every
%   iteration, so NaN here poisons W_TO on iteration 1 and the run never
%   converges). Brandt's own BrandtWeight already loads these exact
%   figures -- obj.brandt.inp.weight.perm_payload_lb (700 lbf, Wt!B4,
%   Main!O16) and .exp_payload_lb (4400 lbf, Wt!B5, Main!O17) -- the same
%   700/4400 lbf F16WeightsL1/L2/L3 read from f16a_L{1,2,3}.json. Reading
%   them off the already-constructed obj.brandt is not fabricating a
%   number: it is the exact input BrandtWeight.analyze()/run() themselves
%   consume for W_armament and W_fuel (BrandtWeight.m:214-215, 252-253,
%   267).

    properties
        W_TO                 = NaN   % lbf -- STATE; see class header
        W_energy             = NaN   % lbf -- STATE; see class header
        W_payload_expendable      % lbf -- set in constructor from Brandt's own inp
        W_payload_fixed           % lbf -- set in constructor from Brandt's own inp
    end

    properties (Access = private)
        brandt   % BrandtWeight handle, built + analyzed in the constructor
    end

    methods

        function obj = BrandtWeightsAdapter()
        %BRANDTWEIGHTSADAPTER  Build a private BrandtGeometry -> BrandtWeight
        %   pair and analyze both. Always Brandt's own hardcoded ground-truth
        %   JSON (VnV/BrandtF16A/GroundTruth/f16a_geometry.json).
            geom = BrandtGeometry();
            geom.analyze();
            obj.brandt = BrandtWeight(geom);
            obj.brandt.analyze();
            obj.W_payload_fixed      = obj.brandt.inp.weight.perm_payload_lb;
            obj.W_payload_expendable = obj.brandt.inp.weight.exp_payload_lb;
        end

        function oew = OEW(obj, W_TO)
        %OEW  Operating empty weight [lbf] at the PASSED W_TO -- Brandt's own
        %   Wt!B12 (W_airframe + W_engine), recomputed at this W_TO on every
        %   call via BrandtWeight.run (never cached), matching WeightsBase's
        %   "must recompute per call" contract.
            arguments
                obj
                W_TO (1,1) double {mustBePositive}
            end
            r = obj.brandt.run(W_TO);
            oew = r.W_empty_lb;
        end

    end

end
