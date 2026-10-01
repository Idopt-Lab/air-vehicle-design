function [obj] = ttpa_disciplines()
%TTPA_DISCIPLINES  Build the TTPA discipline bundle for the sizing loop.
%
%   obj = ttpa_disciplines() returns the same struct of discipline objects
%   IHW1 and IHW2 used:
%
%       obj.aero   TtpaAero      drag polar, CLmax, configuration polars.
%                                CD0 now follows the geometry.
%       obj.geom   TtpaGeom      the whole Level-2 planform. Receives S_ref
%                                from the sizing loop.
%       obj.prop   TtpaProp      power lapse, power ratio, and now engine
%                                weight and length. Receives P_SL.
%       obj.wts    TtpaWeights   component weight build-up and payload
%       obj.miss   struct        mission profile, from MissionProfileReader
%       obj.cons   struct array  constraint conditions, from
%                                ConstraintSetImporter
%
%   BUILD ORDER MATTERS. The disciplines are injected into one another, and
%   a constructor cannot take an object that has not been built yet:
%
%       prop                 depends on nothing
%       geom(json, prop)     the nacelle is sized around the engine
%       aero(json, geom)     CD0 = Cfe * S_wet/S_ref needs the geometry
%       wts (json, geom, prop)  the weight build-up needs areas and the
%                               engine weight
%
%   This is the same dependency order the sizing framework uses for the
%   F-16 and the 777. It is not arbitrary: it follows the direction the
%   physical information travels.
%
%   IN IHW2 there was no injection at all - every class read the JSON and
%   nothing else, because nothing in the constraint analysis depended on
%   how big the airplane was. The injection appears now because the sizing
%   loop makes the airplane's size the thing that changes.
%
%   EVERY DISCIPLINE OBJECT IS A HANDLE OBJECT. The sizing loop writes
%   obj.geom.S_ref and obj.prop.P_SL; the caller sees those writes, and so
%   does every other discipline holding a reference. That is what lets the
%   loop change the airplane in one place and have the drag, the weight and
%   the mission all notice.

    json_path = ttpa_requirements_path();

    prop = TtpaProp(json_path);
    geom = TtpaGeom(json_path, prop);
    aero = TtpaAero(json_path, geom);
    wts  = TtpaWeights(json_path, geom, prop);

    miss = MissionProfileReader.read_profile(json_path, 'std_mission');
    cons = ConstraintSetImporter.read_conditions(json_path);

    obj = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
        'miss', miss, 'cons', cons);

end
