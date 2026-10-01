function [state] = get_state(alt_ft)
%GET_STATE  Standard-atmosphere flight state at an altitude.
%
%   state = get_state(alt_ft) returns
%       state.alt     altitude [ft]
%       state.rho     density [slug/ft^3]
%       state.sigma   density ratio rho/rho_sealevel [-]
%
%   This is the state argument the discipline models of IHW1 already
%   accepted but never used: run_mission passes state = [] because the
%   Breguet segments need no atmosphere. Every constraint needs one, so
%   IHW2 fills it in.
%
%   The atmosphere comes from AircraftState, which wraps the MATLAB
%   atmosisa function and converts to English units. The sea-level density
%   is taken from AircraftState as well, not typed in, so that sigma comes
%   out exactly 1.0 at sea level.
%
%   MEMOIZED IN IHW3a. The returned values are unchanged to the last bit -
%   the ISA is a pure function of altitude, so calling it twice at the same
%   altitude must give the same answer, and this just stops it being
%   recomputed. The reason is speed, and the speed matters:
%
%     * IHW2 called this a handful of times per constraint diagram.
%     * The IHW3a L2 mission calls it once per flight condition and once per
%       climb sub-segment, the sizing loop calls the whole mission ~30 times,
%       and the P-S diagram runs a whole sizing loop in every one of a
%       thousand grid cells.
%
%   Unmemoized that is roughly a million atmosphere evaluations for one P-S
%   diagram, at 0.66 ms each. The cache turns the L2 mission from 10.5 ms
%   into about 1 ms and makes the diagram tractable.
%
%   The cache is keyed on the altitude and never invalidated, which is
%   correct because nothing about the standard atmosphere can change at run
%   time. Call clear('get_state') to drop it.

    persistent cache rho_SL

    if isempty(cache)
        cache  = containers.Map('KeyType', 'double', 'ValueType', 'any');
        % Sea-level density, read from AircraftState once rather than typed
        % in, so sigma is exactly 1.0 at sea level.
        rho_SL = AircraftState(0, 0).rho;
    end

    if isKey(cache, alt_ft)
        state = cache(alt_ft);
        return;
    end

    atm = AircraftState(alt_ft, 0);

    state.alt   = alt_ft;
    state.rho   = atm.rho;
    state.sigma = atm.rho / rho_SL;

    cache(alt_ft) = state;

end
