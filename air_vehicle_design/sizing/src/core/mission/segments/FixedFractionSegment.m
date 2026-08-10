classdef FixedFractionSegment < MissionSegment
%FIXEDFRACTIONSEGMENT  A segment whose fuel burn is a historical constant
%   weight fraction, not a physics calculation.
%
%   fuel = W_before * (1 - WF), with WF from Roskam Airplane Design Part I,
%   Table 2.1 (fighter row), selected by mission phase (the segment_type:
%   startup / taxi / takeoff / climb / descent / landing). Used for the phases
%   where no closed-form fuel equation applies -- at L1 for startup / taxi /
%   takeoff / climb / descent / landing, and at L2 as the Roskam fallback so
%   that startup / taxi / descent / landing still burn fuel rather than reading
%   zero (every segment must yield a fuel burn).
%
%   Discipline-independent: reads only ctx.aircraft_category (spec data from the
%   injected aero object) to pick the table row -- never the aero drag polar or
%   the prop TSFC. That is deliberate: these phases have no L/D or TSFC
%   dependence at this fidelity, so the same fraction holds for every discipline
%   stack.

    methods
        function fuel = fuel_burn(obj, ctx)
            wf   = MissionEquations.roskam_fixed_fraction(ctx.aircraft_category, obj.segment_type);
            fuel = obj.W_before * (1 - wf);
            obj.debug = struct('method', "roskam_fixed_fraction", ...
                               'weight_fraction', wf);
        end
    end

end
