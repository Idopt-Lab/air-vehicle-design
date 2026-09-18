function [W_fuel, fuel_fraction, fuel_burned, segment_weight, segment_wf] = mission_fuel(W_TO, obj)
%MISSION_FUEL  Total mission fuel at a candidate takeoff weight.
%
%   [W_fuel, fuel_fraction, fuel_burned, segment_weight, segment_wf] = ...
%       mission_fuel(W_TO, obj)
%
%   Inputs
%     W_TO   candidate takeoff gross weight [lbf]
%     obj    discipline bundle from ttpa_disciplines
%   Outputs
%     W_fuel         total fuel, including the reserve allowance [lbf]
%     fuel_fraction  W_fuel / W_TO [-]
%     fuel_burned    fuel burned in each segment [lbf], 1x8
%     segment_weight weight at each segment boundary [lbf], 1x9
%     segment_wf     weight fraction of each segment [-], 1x8
%
%   This is the two lines that used to live INSIDE the IHW1 iteration loop,
%   lifted out into a function of their own:
%
%       [fuel_burned, ...] = run_mission(W_TO, obj);
%       fuel_fraction = sum(fuel_burned) * 1.06 / W_TO;
%
%   The sizing loop calls this once per iteration, so it has to be a clean
%   function of W_TO with no state of its own. run_mission itself is the
%   IHW1 file, UNCHANGED - which is the point. Because TtpaAero.LD_max is
%   now a Dependent property that follows the geometry, the Breguet cruise
%   and loiter segments inside run_mission automatically use the drag of
%   the airplane the sizing loop has just laid out. Not one line of the
%   mission analysis had to be touched to make that happen.
%
%   THE 1.06 IS GONE. IHW1 typed the 6 percent reserve and trapped-fuel
%   allowance straight into the loop as a literal. It is a requirement, so
%   it belongs in the requirements file, and it is read from there now:
%   J.missions.std_mission.reserve_fuel_fraction. Change the requirement
%   and the analysis follows.

    arguments
        W_TO (1,1) double {mustBePositive}
        obj  (1,1) struct
    end

    [fuel_burned, segment_weight, segment_wf] = run_mission(W_TO, obj);

    % Reserve and trapped-fuel allowance, applied on top of the full
    % mission. Read from the mission profile, not typed in here.
    if isfield(obj.miss, 'reserve_fuel_fraction') && ~isempty(obj.miss.reserve_fuel_fraction)
        f_reserve = obj.miss.reserve_fuel_fraction;
    else
        error('mission_fuel:MissingReserveFraction', ...
            ['The mission profile has no reserve_fuel_fraction. Add it to ', ...
             'the missions block of the requirements JSON - it is a ', ...
             'requirement, not a constant to hide in the code.']);
    end

    W_fuel        = sum(fuel_burned) * (1 + f_reserve);
    fuel_fraction = W_fuel / W_TO;

end
