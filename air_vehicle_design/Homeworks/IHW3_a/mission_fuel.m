function [W_fuel, fuel_fraction, fuel_burned, segment_weight, segment_wf, detail] = mission_fuel(W_TO, obj)
%MISSION_FUEL  Total mission fuel at a candidate takeoff weight.
%
%   [W_fuel, fuel_fraction, fuel_burned, segment_weight, segment_wf, detail] = ...
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
%     detail         per-segment C_L, L/D, speed, time  (L2 method only;
%                    empty for L1, which does not compute them)
%
%   This is the "Fuel fraction" box of the preliminary design framework. The
%   sizing loop calls it once per iteration, so it has to be a clean function
%   of W_TO with no state of its own.
%
%   TWO METHODS, selected by missions.std_mission.method in the requirements
%   file:
%
%     "L1"  run_mission      - the IHW1 file, UNCHANGED. Roskam Table 2.2
%                              fractions, cruise at L/D_max, loiter at
%                              0.866 L/D_max.
%     "L2"  run_mission_L2   - the improved fuel fractions of the
%                              sizing-refinement lecture. The lift
%                              coefficient is computed from the ACTUAL wing
%                              loading at each condition, so the fuel
%                              responds to the wing.
%
%   The lecture draws the difference as an arrow: W_0/S_ref feeds the Fuel
%   fraction box. Under L1 that arrow does not exist - the fuel fraction is
%   the same number whatever wing the airplane has. That is the defect, and
%   on this airplane it is worth 27 percent of the cruise L/D. Run both and
%   compare; run_ttpa_sizing prints the pair.
%
%   THE RESERVE IS READ, NOT TYPED. IHW1 hardcoded a 6 percent reserve and
%   trapped-fuel allowance as a literal 1.06 inside its loop. It is a
%   requirement, so it lives in the requirements file:
%   J.missions.std_mission.reserve_fuel_fraction. Both methods apply it the
%   same way.

    arguments
        W_TO (1,1) double {mustBePositive}
        obj  (1,1) struct
    end

    if isfield(obj.miss, 'method') && ~isempty(obj.miss.method)
        method = string(obj.miss.method);
    else
        method = "L1";     % the IHW1 behaviour, if the file does not say
    end

    detail = struct([]);

    switch method

        case "L1"
            [fuel_burned, segment_weight, segment_wf] = run_mission(W_TO, obj);

        case "L2"
            [fuel_burned, segment_weight, segment_wf, detail] = run_mission_L2(W_TO, obj);

        otherwise
            error('mission_fuel:UndefinedMethod', ...
                ['Mission method "%s" is not defined. Use "L1" (the IHW1 ', ...
                 'fixed-fraction mission) or "L2" (the improved fuel ', ...
                 'fractions).'], method);
    end

    % Reserve and trapped-fuel allowance, applied on top of the full mission.
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
