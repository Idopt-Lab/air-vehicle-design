function [ok, V_ft3, W_capacity, margin] = wing_fuel_check(W_fuel_required, obj)
%WING_FUEL_CHECK  Does the sized wing hold the fuel the mission needs?
%
%   [ok, V_ft3, W_capacity, margin] = wing_fuel_check(W_fuel_required, obj)
%
%   Inputs
%     W_fuel_required  mission fuel from the converged loop [lbf]
%     obj              discipline bundle, AFTER sizing_loop has run
%   Outputs
%     ok          true when the wing holds at least the required fuel
%     V_ft3       usable wing fuel volume [ft^3]
%     W_capacity  fuel weight that volume holds [lbf]
%     margin      (W_capacity - W_fuel_required) / W_fuel_required [-]
%
%   A POST-CONVERGENCE CHECK, not part of the loop. The sizing loop closes
%   the airplane on WEIGHT; it never asks whether the fuel physically fits
%   inside the wing it has sized. That is a separate question and it has to
%   be asked, because the answer can be no.
%
%   The volume comes from the Torenbeek relation in
%   TtpaGeom.wing_fuel_volume, and the density is the 100LL figure in the
%   weights block. A shortfall of more than 15 to 20 percent means the
%   planform has to change - a thicker root, less taper, or more area.
%
%   Run this AFTER sizing_loop, when obj.geom.S_ref holds the converged
%   wing.

    arguments
        W_fuel_required (1,1) double {mustBePositive}
        obj             (1,1) struct
    end

    V_ft3      = obj.geom.wing_fuel_volume();
    W_capacity = V_ft3 * obj.wts.rho_fuel;

    margin = (W_capacity - W_fuel_required) / W_fuel_required;
    ok     = W_capacity >= W_fuel_required;

end
