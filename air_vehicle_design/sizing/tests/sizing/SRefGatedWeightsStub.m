classdef SRefGatedWeightsStub < WeightsBase
%SREFGATEDWEIGHTSSTUB  Weights stub whose feasibility depends on the current
%   wing area. Used only by TestTSDiagram.m's fuel_grid NaN-masking test.
%
%   Rationale: FixedWeightsStub's OEW fraction is constant, so a TOGW-closure
%   grid over (T, S) is either ALL feasible or ALL infeasible with it.
%   TSDiagram.fuel_grid's NaN-masking contract needs a MIX of feasible and
%   infeasible cells in one grid. This stub reads the injected geometry
%   stub's S_ref live (converge_W0 writes geom.S_ref = S before iterating)
%   and gates the OEW fraction on it:
%
%     S_ref <= S_ref_limit:  OEW = 0.60*W_TO
%         with FixedMissionStub's fuel fraction 0.15 the TOGW denominator is
%         1 - 0.15 - 0.60 = 0.25 > 0  ->  W0 = 800/0.25 = 3200 lbf (the same
%         hand-computed toy fixed point as TestSizingLoopL1.m).
%     S_ref >  S_ref_limit:  OEW = 0.95*W_TO
%         denominator = 1 - 0.15 - 0.95 = -0.10 <= 0  ->
%         SizingSteps.togw_update returns NaN and TSDiagram.converge_W0 must
%         mark the cell NaN (never error).
%
%   Same payload split as FixedWeightsStub (500 + 300 = 800 lbf) so the
%   feasible-cell fixed point stays 3200.

    properties
        W_TO = NaN
        W_energy = NaN
        W_payload_expendable = 300
        W_payload_fixed = 500
        geom                                   % handle -- geometry stub whose S_ref gates OEW
        S_ref_limit      (1,1) double = 50     % ft^2 -- feasibility gate
        oew_fraction_ok  (1,1) double = 0.60   % feasible branch
        oew_fraction_bad (1,1) double = 0.95   % infeasible branch (denom <= 0)
    end

    methods

        function obj = SRefGatedWeightsStub(geom, S_ref_limit)
            arguments
                geom        (1,1) GeometryBase
                S_ref_limit (1,1) double {mustBePositive}
            end
            obj.geom = geom;
            obj.S_ref_limit = S_ref_limit;
        end

        function oew = OEW(obj, W_TO)
        %OEW  0.60*W_TO while geom.S_ref <= S_ref_limit, else 0.95*W_TO
        %   (see class header for the resulting feasible/infeasible split).
            if obj.geom.S_ref <= obj.S_ref_limit
                oew = obj.oew_fraction_ok * W_TO;
            else
                oew = obj.oew_fraction_bad * W_TO;
            end
        end

    end

end
