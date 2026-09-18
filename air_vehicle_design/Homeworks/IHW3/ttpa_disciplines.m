function [obj] = ttpa_disciplines()
%TTPA_DISCIPLINES  Build the TTPA discipline bundle for the constraint analysis.
%
%   obj = ttpa_disciplines() returns the same struct of discipline objects
%   the mission analysis of IHW1 uses, with the constraint set added:
%
%       obj.aero   TtpaAero      clean polar, CLmax and configuration polars
%       obj.geom   TtpaGeom      areas; receives S_ref from the sizing
%       obj.prop   TtpaProp      propeller efficiency, power lapse, power ratio
%       obj.wts    TtpaWeights   empty weight and payload
%       obj.miss   struct        mission profile, from MissionProfileReader
%       obj.cons   struct array  constraint conditions, from ConstraintSetImporter
%
%   Every constraint-analysis function takes this bundle, so building it in
%   one place keeps the analysis and the tests consistent.
%
%   The discipline objects are HANDLE objects: a function that writes into
%   them (size_from_design_point writes S_ref and P_SL) changes the objects
%   the caller holds.

    json_path = ttpa_requirements_path();

    aero = TtpaAero(json_path);
    geom = TtpaGeom();
    prop = TtpaProp(json_path);
    wts  = TtpaWeights();
    miss = MissionProfileReader.read_profile(json_path, 'std_mission');
    cons = ConstraintSetImporter.read_conditions(json_path);

    obj = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
        'miss', miss, 'cons', cons);

end
