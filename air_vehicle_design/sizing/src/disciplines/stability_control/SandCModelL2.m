classdef (Abstract) SandCModelL2 < StabControlBase
%SANDCMODELL2  Tier-2 abstract enforcer for Level-2 stability & control.
%
%   Inherits StabControlBase directly (the normal three-tier pattern: each
%   fidelity level satisfies the Tier-1 contract independently, not by
%   inheriting SandCModelL(N-1)).
%
%   Adds NOTHING beyond the inherited x_cg. Per
%   docs/subplans/10_stability_control.md's "DECIDED (Casey, 2026-08-03):
%   F16SandCL2 is limited to the CG term only" note: F16GeomL2 exposes NO
%   x-station properties at all (no x_apex_wing/x_le_ht/x_le_vt/x_inlet/tail-
%   arm equivalent -- confirmed by direct inspection of F16GeomL2.m; only
%   F16GeomL3 has these), so every other Ch. 16 quantity (Eqs. 16.4/16.5/
%   16.7/16.8/16.9/16.11/16.12 and 16.13/16.14/16.15) genuinely cannot run at
%   L2 -- it is not a scope choice, it is what the injected geometry object
%   can supply. F16SandCL2 computes ONLY
%     x_cg = Sum(W_i * x_i) / Sum(W_i)
%   over the 10 WeightsL2-matched component groups in
%   examples/F16A/inputs/f16a_L2.json
%   .stability_control.component_x_stations.groups (wing, horizontal_tail,
%   vertical_tail, fuselage, landing_gear, installed_engine, subsystems_lump,
%   strake, payload, fuel), with each group's WEIGHT read live by DI from an
%   injected F16WeightsL2 object and each group's cg_x_ft STATION read once
%   from the JSON at construction (static spec data, not a live-recomputed
%   quantity).
%
%   DEPENDENCY INJECTION: the concrete class injects ONLY a weights object
%   (no Geom/Aero/Prop DI at all at this tier -- the CG-only scope needs
%   none) -- see F16SandCL2.m's own header for the exact constructor
%   signature.
%
%   Toolbox companion: src/disciplines/stability_control/SandCL2.md

end

