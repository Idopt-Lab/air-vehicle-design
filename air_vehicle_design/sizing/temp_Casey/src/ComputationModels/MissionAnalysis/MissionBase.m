classdef (Abstract) MissionBase < handle
     %MISSIONBASE Discipline-wide contract for mission-analysis classes.
     %   Estimates mission fuel (not MTOW, though mission fuel feeds MTOW).
     %   Common to every fidelity level; shared IO helpers live in the
     %   MissionAnalysisModel intermediate.

     properties (Abstract)
          missiondata
          mission_fuel
     end

     methods (Abstract)
          [total_fuel_used, fuel_fraction] = get_mission_fuel(mission_obj, constraint_obj, design, geometry_obj, propulsion_obj, weight_obj)
     end
end
