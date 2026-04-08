classdef (Abstract) MissionAnalysisModel < handle
     %MISSIONANALYSISMODEL Summary of this class goes here
     %   Detailed explanation goes here
     % THIS IS FOR ESTIMATING MISSION FUEL
     % MISSION FUEL, NOT MTOW
     % BUT MISSION FUEL IS IMPORTANT FOR ESTIMATING MTOW

     properties (Abstract)
          % What the heck do I put here?
          % MTOW
          mission_fuel
          eps
     end

     methods (Abstract)
          mission_fuel = run_mission_analysis(input)
          % [W_out, fuel_used] = segment_climb(W_TO, W_in, Mach, S, CD0, e, AR, TSFC, h, T0)
          % [W_out, fuel_used] = segment_combat(W_in, time, TSFC, payload, CD0, e, AR, W_TO, q,  S_ref)
          % [W_out, fuel_used] = segment_cruise(W_in, W_S, TSFC, Distance, Mach, a, q, CD0, e, AR, W_TO, S)
          % [W_out, fuel_used] = segment_dash(W_in, S_ref, W_TO, q, CD0, e, AR, TSFC, Distance, V)
          % [W_out, fuel_used] = segment_landing(W_in, W_TO)
          % [W_out, fuel_used] = segment_loiter(W_TO, W_in, S_ref, q, CD0, e, AR, time, TSFC)
          % [W_out, fuel_used] = segment_startup(W_in)
          % [W_out, fuel_used] = segment_takeoff(W_in)
          % [W_out, fuel_used] = segment_taxi(W_in)
     end
end