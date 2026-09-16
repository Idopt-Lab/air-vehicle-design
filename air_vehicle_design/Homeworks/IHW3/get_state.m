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

    atm = AircraftState(alt_ft, 0);
    sl  = AircraftState(0, 0);

    state.alt   = alt_ft;
    state.rho   = atm.rho;
    state.sigma = atm.rho / sl.rho;

end
