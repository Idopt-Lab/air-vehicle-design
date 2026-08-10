function ctrl = f16a_control_surfaces()
%F16A_CONTROL_SURFACES  The F-16A's canonical ControlSurfaceSizer.
%   ctrl = f16a_control_surfaces() returns the one configured
%   ControlSurfaceSizer every F-16A consumer should use -- the design studies,
%   the aero classes (injected), F16SandCL3, the mixed-fidelity builder and the
%   comparison reports. Same role as f16a_spec_path / f16a_requirements_path:
%   one place for the aircraft's own data, so nobody re-types it.
%
%   ADDED 2026-08-10. Before this, the six-argument call
%   ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30, 0.90) was typed out at five
%   separate sites (design_study_02_L2, design_study_03_L3,
%   build_fidelity_combo, sandc_brandt_comparison and several tests), each with
%   its own copy of the justification comment. Widening the sizer's argument
%   list would have meant editing all of them, which is exactly the smell that
%   says the wiring belongs in one function.
%
%   THE F-16A's CONTROL SURFACES [configuration confirmed 2026-08-10 against a
%   summary the user supplied, sourced from F-16.net / StackExchange /
%   ryanporto.com -- secondary web references, adequate for "which surfaces
%   exist and how far they move", NOT for areas or fractions]:
%     1. FLAPERONS on the wing trailing edge, serving as both ailerons and
%        flaps; 20 deg down, 23 deg up.
%     2. LEADING-EDGE FLAPS, auto-scheduled on angle of attack and Mach;
%        20 deg maximum.
%     3. ALL-MOVING HORIZONTAL TAILS (stabilators) for pitch.
%     4. A RUDDER for yaw.
%   Hence: no separate aileron, no separate elevator -- both fractions are 0
%   and ControlSurfaceSizer's constructor would reject them alongside the
%   flaperon / all-moving flag anyway.
%
%   ★ ONLY THREE OF THE FOUR ARE CONTROL EFFECTORS. The flaperons, the
%   stabilators and the rudder fly the aeroplane. The LEADING-EDGE FLAP DOES
%   NOT: it is functionally a SLAT -- an automatic stall-prevention / manoeuvre
%   device the flight control system schedules to keep the flow over the wing
%   attached, with no response to pitch, roll or yaw commands (user
%   clarification, 2026-08-10). It is sized here anyway, and counted in
%   geom.S_csw / geom.S_cs, because it is an actuated surface with real
%   planform area that Raymer Eqs. 15.1 and 15.17 must see -- the retired
%   S_cs = 190 estimate counted it too. Do not read its presence in this
%   function's output as making it an effector. Its dynamic AoA/Mach schedule
%   is OUT OF SCOPE here (user decision, 2026-08-10): this framework has no
%   time domain, and the mission segments carry fixed per-segment slat
%   deflections (F16AeroL3.delta_slat_TO_deg/delta_slat_L_deg) instead.
%
%   ═══ EVERY NUMBER BELOW IS A TEXTBOOK ESTIMATE, NOT MEASURED F-16 DATA ═══
%   This is the distinction to hold onto (user, 2026-08-10). The fractions here
%   are Raymer/Roskam conceptual-design estimates; the real aircraft's measured
%   areas are GROUND TRUTH used to judge how good those estimates are. The two
%   directions must not be mixed: no fraction below is back-solved from a
%   measured area, because that would turn the accuracy check into a tautology
%   (and is the "back-calculated value as input" pattern docs/PLAN.md forbids).
%   Accuracy at the JSON baseline (S_ref = 300 ft^2, taper = 0.2275,
%   S_ht = 108, S_vt = 60), computed here vs. T.O. 1F-16A-1 Fig. 1-2:
%
%     Flaperon    28.11 ft^2  vs  31.32   -10.2 %
%     LE flap     44.66 ft^2  vs  36.71   +21.6 %
%     Wing total  72.77 ft^2  vs  68.03    +7.0 %   (S_csw -- errors partly cancel)
%     Rudder      16.20 ft^2  vs  11.65   +39.1 %   (the worst; see below)
%     Stabilator 108.00 ft^2  vs 108.00     0.0 %   (= S_ht by definition)
%
%   examples/F16A/tail_sizing_brandt_comparison.m reports this table live.
%
%   ── Fraction provenance, one line each ────────────────────────────────────
%   FLAPERON c = 0.25 [Raymer 6th ed. p.162 text, "ailerons and flaps are
%     typically 15-25% of wing chord" -- top of the band]. Carried over
%     unchanged from the value F16AeroL2/L3 already used for the high-lift
%     deltas, which is the point: one flaperon, one chord fraction.
%   FLAPERON span eta = 0.35 to 0.75 of semispan. Extent 0.40 is the
%     previously-approved b_ail_frac (user, 2026-07-27) read off Raymer
%     Fig. 6.3's historical-guidelines band -- "the band's typical/lower value
%     at that chord, consistent with a fighter's relatively compact" roll
%     surface. Fig. 6.3 gives only the EXTENT, so the stations are placed
%     outboard of the wing-root/strake region where a fighter's TE surface
%     actually sits. NOTE this REPLACES the eta = 0.10-0.90 pair F16AeroL2/L3
%     carried as an admitted-unverified estimate: 0.10-0.90 implies a 60 ft^2
%     flaperon, nearly double the measured 31.32, and was flagged in-code as
%     needing T.O. verification. Logged in VnV/BrandtF16A/todo.md.
%   LEF c = 0.15, eta = 0.0 to 0.98 [F16AeroL3's existing c_slat_over_c /
%     eta_slat_* estimates, carried over unchanged]. eta_in = 0 is known to be
%     physically generous (the real LEF starts outboard of the strake) and is
%     the main reason this device reads +21.6 % high; kept rather than adjusted,
%     because adjusting it to close the gap is exactly the fitting this file
%     must not do. Logged in todo.md.
%   RUDDER c = 0.30 [Raymer 6th ed. Table 6.5, Fighter/attack row, Cr/C],
%     span = 0.90 [Raymer 6th ed. p.161, "extend to the tip of the tail or to
%     about 90% of the tail span"]. ★ This is the framework's largest
%     control-surface error, +39.1 % against the measured 11.65 ft^2, and it
%     MATTERS: geom.S_r aliases this area into Raymer Eq. 15.3's
%     (1 + S_r/S_vt)^0.348 vertical-tail weight term. Deliberately NOT
%     calibrated to 11.65 -- Raymer's own printed fractions are what a
%     conceptual design has available, and the gap is the finding. Note also
%     that GeomL1.lookup_control_surface_fraction returns 0.33 for the same
%     row out of Raymer's 7th ed.; two editions disagree, logged in todo.md.
%   ALL-MOVING TAIL: true [Raymer 6th ed. Table 6.5's footnote to the
%     Fighter/attack row, "Supersonic usually all-moving tail without separate
%     elevator"]. Sets S_stab = S_ht and keeps S_elev = 0 -- which F16SandCL3
%     relies on, since its Delta_alpha_L0 (Raymer Eqs. 16.16/16.18) describes a
%     hinged-flap deflection that a stabilator does not have.
%
%   See also F16A_SPEC_PATH, F16A_REQUIREMENTS_PATH, CONTROLSURFACESIZER.

    ctrl = ControlSurfaceSizer( ...
        0,    0,    ...   % aileron  c, b   -- none; the flaperon serves the roll role
        0,    0,    ...   % elevator c, b   -- none; all-moving stabilator
        0.30, 0.90, ...   % rudder   c, b   [Raymer 6th ed. Table 6.5 / p.161]
        'c_flaperon_frac',  0.25, ...   [Raymer 6th ed. p.162, 15-25% band]
        'eta_flaperon_in',  0.35, ...   [Raymer 6th ed. Fig. 6.3, 0.40 extent]
        'eta_flaperon_out', 0.75, ...
        'c_lef_frac',       0.15, ...   [F16AeroL3's existing LE-device estimate]
        'eta_lef_in',       0.0,  ...
        'eta_lef_out',      0.98, ...
        'ht_all_moving',    true);      % [Raymer 6th ed. Table 6.5 footnote]
end
