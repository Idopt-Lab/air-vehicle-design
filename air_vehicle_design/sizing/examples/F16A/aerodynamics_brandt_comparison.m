function T_all = aerodynamics_brandt_comparison()
%AERODYNAMICS_BRANDT_COMPARISON  F-16A aero at every fidelity vs ground truth.
%
%   Two jobs. (1) A one-stop comparison: run every aero tier over a Mach sweep
%   and put its output next to Brandt's workbook, the T.O. 1F-16A-1 and
%   published estimates. (2) A worked example of how to drive this framework —
%   read it top to bottom and you have seen the whole input and
%   dependency-injection story for aerodynamics.
%
%   ─── HOW TO RUN ─────────────────────────────────────────────────────────
%     >> cd air_vehicle_design/sizing
%     >> addpath(genpath('src')); addpath(genpath('examples'))
%     >> aerodynamics_brandt_comparison
%   Or non-interactively:
%     $ matlab -batch "addpath(genpath('src')); addpath(genpath('examples')); aerodynamics_brandt_comparison"
%
%   ─── WHERE THE INPUTS COME FROM ─────────────────────────────────────────
%     f16a_spec_path(N) -> examples/F16A/f16a_L{N}.json, the SPEC file. Aero
%                          reads its .aerodynamics block:
%                            L1  aircraft type + the folded Mattingly curves
%                            L2  airfoil section data + the Oswald-e selector
%                            L3  per-component buildup constants
%                          The SAME file's .geometry block builds the geometry
%                          object injected below — one file per fidelity level,
%                          read by two disciplines.
%   Ground truth is separate and lives under VnV/BrandtF16A/, read here as `gt`.
%   It is never an input — only a comparison target.
%
%   ─── HOW TO WIRE THE DEPENDENCIES ───────────────────────────────────────
%   Aero consumes geometry, and geometry consumes propulsion, so build outward:
%
%       a1   = F16AeroL1(f16a_spec_path(1));          % L1 is geometry-FREE
%       prop = F16PropL2(f16a_spec_path(2));
%       g2   = F16GeomL2(f16a_spec_path(2), prop);
%       g3   = F16GeomL3(f16a_spec_path(3), prop);
%       a2   = F16AeroL2(g2, f16a_spec_path(2), f16a_control_surfaces());
%       a3   = F16AeroL3(g3, f16a_spec_path(3), f16a_control_surfaces());      % NOTE: g3, not g2
%
%   Match the tiers. `F16AeroL3(g2, ...)` constructs happily — both geometry
%   tiers satisfy the aero contract — and then silently computes the entire L3
%   column on L2 geometry. That exact mistake shipped once and is invisible to
%   both the type guard and the tests, because the result is plausible rather
%   than wrong-looking. `Amax` in particular is tier-specific: area-ruled at L3
%   (what Raymer Eq. 12.44 wants), a fuselage-envelope ellipse at L2, so a
%   mismatched injection inflates supersonic CD0_wave by ~23 %.
%
%   L1 takes no geometry object at all: the Mattingly type-curve polar consumes
%   no geometry, so there is nothing to inject.
%
%   ─── OUTPUTS (written beside this script) ───────────────────────────────
%     aerodynamics_brandt_comparison.json  full table + metadata
%     aerodynamics_brandt_comparison.md    rendered markdown
%   Both via src/reporting/ComparisonReport.m, shared by all four discipline
%   reports so their columns cannot drift apart.
%
%   ─── SOURCES ────────────────────────────────────────────────────────────
%     [Brandt]    F-16A.xls workbook outputs + his tabulated actual polar
%     [AF manual] T.O. 1F-16A-1 — airfoil and operating limits ONLY; it carries
%                 no drag polar, CLmax or CD0 coefficients (those are in the
%                 absent T.O. 1F-16A-1-1)
%     [Internet]  published estimates (F-16C conceptual polar, textbook, NASA)
%     [Raymer]    Aircraft Design 6th ed., AIAA (Ch. 12)
%     [Mattingly] Aircraft Engine Design 2nd ed., AIAA, 2002
%     [Roskam]    Airplane Design Vol. I (CLmax / HLD delta tables)
%
%   The 0.95 <= M <= 1.05 transonic band is deliberately SKIPPED — L2/L3
%   drag_polar returns NaN there (Raymer Eq. 12.51 has a pole near M = 1). The
%   sweep uses subsonic M = 0.6/0.8/0.9 and supersonic M = 1.2/1.5/2.0.
%
%   NOT A TEST: informational only, never pass/fail, and no value here may
%   backfill a unit test's expected value (CLAUDE.md's two-tier rule).

script_dir  = fileparts(mfilename('fullpath'));
sizing_root = fileparts(fileparts(script_dir));
gt_path     = fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth', 'f16a_ground_truth.json');
gt          = jsondecode(fileread(gt_path)).aerodynamics;

% Flight condition for the polar sweep (L3's component CD0 is Reynolds- and
% therefore altitude-sensitive; CLmax/e are not). 36,000 ft is a
% representative cruise/combat altitude.
ALT   = 36000;   % ft
M_SUB = 0.6;     % subsonic representative point (< 0.95)
M_SUP = 1.6;     % supersonic representative point (matches Brandt actual-polar M=1.6 row)
M_SWEEP = [0.6 0.8 0.9 1.2 1.5 2.0];   % full sweep, avoiding the transonic band

% Brandt's tabulated ACTUAL (reference) polar rows, indexed by Mach.
ap        = gt.brandt_actual_polar_vs_mach.rows;   % struct array: mach/CDmin/CDo/k1/k2
ap_mach   = [ap.mach];
brandt_CDo = @(M) ap(nearestIdx(ap_mach, M)).CDo;   % nearest tabulated CDo
brandt_k1a = @(M) ap(nearestIdx(ap_mach, M)).k1;    % nearest tabulated k1

% L1 is geometry-free (Mattingly type-curve) -> takes no geometry object.
% L2 and L3 now inject their OWN geometry tier (Phase 2, 2026-07-25): L3 was
% previously handed an F16GeomL2, which made f16a_L3.json's entire .geometry
% block dead input. Geometry also takes the propulsion object, because the
% nacelle diameter -- and so duct wetted area and CD0 -- is sized from thrust.
% L3 geometry is INTENTIONALLY divergent from L2 (physical/T.O. values: VT LE
% sweep 47.5 vs 40, L_fus 47.5 vs 46.5, HT span 18.5 primary), so L2-vs-L3
% differences below are expected, not errors -- see examples/F16A/F16GeomL3.md.
a1   = F16AeroL1(f16a_spec_path(1));
prop = F16PropL2(f16a_spec_path(2));
g2   = F16GeomL2(f16a_spec_path(2), prop);
g3   = F16GeomL3(f16a_spec_path(3), prop);
a2 = F16AeroL2(g2, f16a_spec_path(2), f16a_control_surfaces());
a3 = F16AeroL3(g3, f16a_spec_path(3), f16a_control_surfaces());

st_sub = AircraftState(ALT, M_SUB);
st_sup = AircraftState(ALT, M_SUP);

p1s = a1.drag_polar(st_sub);  p2s = a2.drag_polar(st_sub);  p3s = a3.drag_polar(st_sub);
p1u = a1.drag_polar(st_sup);  p2u = a2.drag_polar(st_sup);  p3u = a3.drag_polar(st_sup);

% ════════════════════════════════════════════════════════════════════════ %
%  BUILD TABLE
% ════════════════════════════════════════════════════════════════════════ %
T = table();

af_air = gt.af_manual.airfoil.value;
af_ML  = gt.af_manual.Mach_limit.value;

T = [T; srow('[AF MANUAL CONTEXT -- T.O. 1F-16A-1 has NO drag polar / CLmax / CD0 coefficients]')];
T = [T; arow('Wing airfoil', 'spec', NaN, NaN, af_air, NaN, '%s', 'T.O. 1F-16A-1 Fig. 1-2', ...
        'AF-manual ground truth is limited to airfoil + operating limits; coefficients are in the (absent) T.O. 1F-16A-1-1.')];
T = [T; arow('Mach limit', 'spec', NaN, NaN, sprintf('%.2f', af_ML), NaN, '%.2f', 'T.O. 1F-16A-1 limits', ...
        'Structural/operational limit, not an aero coefficient.')];

% ── Subsonic clean polar (M=0.6, 36 kft) ────────────────────────────────── %
T = [T; srow(sprintf('[SUBSONIC CLEAN DRAG POLAR -- M=%.1f, %d kft]', M_SUB, ALT/1000))];
T = [T; arow('CD0 subsonic (L1 Mattingly type-curve)', 'L1', p1s.CD0, gt.CDmin_sub.brandt.value, 'N/A', gt.CD0_cruise.internet.value, '%.5f', 'Brandt Aero!G3 (skin-friction CDmin)', ...
        'L1 CD0(M) from Mattingly Fig.2.10 (placeholder). Brandt skin-friction basis 0.01691; his MISSION CD0=0.0270 folds in form/interference/wave (a different basis).')];
T = [T; arow('CD0 subsonic (L2 Cfe*Swet/Sref)', 'L2', p2s.CD0, gt.CDmin_sub.brandt.value, 'N/A', gt.CD0_cruise.internet.value, '%.5f', 'Brandt Aero!G3 (skin-friction CDmin)', ...
        'Raymer Eq.12.23 with Cfe=0.0035 (AF fighter). Closest to Brandt skin-friction 0.01691; below his mission 0.0270 (no form/wave drag at L2) -- not a bug.')];
T = [T; arow('CD0 subsonic (L3 component buildup)', 'L3', p3s.CD0, gt.CDmin_sub.brandt.value, 'N/A', gt.CD0_cruise.internet.value, '%.5f', 'Brandt Aero!G3 (skin-friction CDmin)', ...
        'Raymer Eq.12.24 per-component sum. Same skin-friction basis as Brandt Aero!G3; below mission 0.0270 (no excrescence calibration) -- not a bug.')];
T = [T; arow('K1 subsonic (L1)', 'L1', p1s.K1, gt.k1.brandt.value, 'N/A', gt.k1.internet.value, '%.4f', 'Brandt Miss!k1', ...
        'L1 K1(M) from Mattingly Fig.2.11 (placeholder, ~0.18); higher than the geometry-based L2/L3 K1.')];
T = [T; arow('K1 subsonic (L2/L3, 1/(pi*AR*e))', 'L2', p2s.K1, gt.k1.brandt.value, 'N/A', gt.k1.internet.value, '%.4f', 'Brandt Miss!k1', ...
        'Raymer Eq.12.50 with official Oswald e (Eq.12.49). L2 and L3 share this K1; excellent agreement with Brandt 0.1160.')];
T = [T; arow('K2 subsonic (L1, uncambered)', 'L1', p1s.K2, gt.k2.brandt.value, 'N/A', gt.k2.internet.value, '%.5f', 'Brandt Aero!G17', ...
        'L1 treats the fighter as uncambered -> K2=0 (Mattingly Sec.2.3.1). Brandt uses a small negative camber term -0.0063.')];
T = [T; arow('K2 subsonic (L2, -2*K1*CL_minD)', 'L2', p2s.K2, gt.k2.brandt.value, 'N/A', gt.k2.internet.value, '%.5f', 'Brandt Aero!G17', ...
        'Raymer Eq.12.6 CL_alpha + Brandt Sec.4.3. Cambered 64A204 (alpha_L0=-1.01) -> negative K2, close to Brandt.')];
T = [T; arow('K2 subsonic (L3, -2*K1*CL_minD)', 'L3', p3s.K2, gt.k2.brandt.value, 'N/A', gt.k2.internet.value, '%.5f', 'Brandt Aero!G17', ...
        'Same form as L2; L3 CL_alpha omits the 2-D-slope eta term (default 0.95), giving a slightly larger magnitude.')];

% ── Supersonic clean polar (M=1.6, 36 kft) ──────────────────────────────── %
T = [T; srow(sprintf('[SUPERSONIC CLEAN DRAG POLAR -- M=%.1f, %d kft]', M_SUP, ALT/1000))];
T = [T; arow('CD0 supersonic (L1)', 'L1', p1u.CD0, brandt_CDo(M_SUP), 'N/A', gt.CD0_supersonic_M1p05.internet.value, '%.5f', 'Brandt Aero!O9 (actual polar, M=1.6)', ...
        'L1 Mattingly supersonic CD0 plateau (~0.028, placeholder). Internet band ~0.0425 is at M~1.05.')];
T = [T; arow('CD0 supersonic (L2, skin friction only)', 'L2', p2u.CD0, brandt_CDo(M_SUP), 'N/A', gt.CD0_supersonic_M1p05.internet.value, '%.5f', 'Brandt Aero!O9 (actual polar, M=1.6)', ...
        'EXPECTED LOW, NOT A BUG: L2 supersonic CD0 is Cf(Re,M)*Swet/Sref with NO wave drag (that is added only at L3). Grossly under Brandt 0.0461.')];
T = [T; arow('CD0 supersonic (L3, buildup + wave drag)', 'L3', p3u.CD0, brandt_CDo(M_SUP), 'N/A', gt.CD0_supersonic_M1p05.internet.value, '%.5f', 'Brandt Aero!O9 (actual polar, M=1.6)', ...
        'L3 adds the Raymer Eq.12.41 fuselage wave-drag term (M>=1.2); much closer to Brandt 0.0461. Residual gap = no wing/canopy/boat-tail wave drag -- not a bug.')];
T = [T; arow('K1 supersonic (L1)', 'L1', p1u.K1, brandt_k1a(M_SUP), 'N/A', NaN, '%.4f', 'Brandt Aero!P9 (actual polar, M=1.6)', ...
        'L1 Mattingly Fig.2.11 supersonic K1 (~0.29, placeholder).')];
T = [T; arow('K1 supersonic (L2/L3, Eq.12.51)', 'L2', p2u.K1, brandt_k1a(M_SUP), 'N/A', NaN, '%.4f', 'Brandt Aero!P9 (actual polar, M=1.6)', ...
        'Raymer Eq.12.51 linearized supersonic K1 (shared L2/L3). Under Brandt 0.340 -- linear theory under-predicts real supersonic induced drag; expected.')];

% ── CD0 Mach-sweep for L2 and L3 (drag rise) ────────────────────────────── %
T = [T; srow(sprintf('[CD0 vs MACH SWEEP -- L2 & L3, %d kft (subsonic 0.6/0.8/0.9, supersonic 1.2/1.5/2.0)]', ALT/1000))];
for M = M_SWEEP
    stM = AircraftState(ALT, M);
    cd2 = a2.drag_polar(stM).CD0;
    cd3 = a3.drag_polar(stM).CD0;
    br  = brandt_CDo(M);
    if M < 1
        note2 = 'L2 skin-friction CD0 (flat/slightly falling with M); Brandt = nearest tabulated actual-polar CDo.';
        note3 = 'L3 buildup CD0 falls slightly with M (compressible Cf); Brandt = nearest tabulated actual-polar CDo.';
    else
        note2 = 'L2 has NO wave drag -> far below Brandt supersonic CDo (not a bug); Brandt = nearest actual-polar CDo.';
        note3 = 'L3 includes Eq.12.41 wave drag (M>=1.2); tracks the Brandt supersonic drag-rise trend; Brandt = nearest actual-polar CDo.';
    end
    T = [T; arow(sprintf('CD0 @ M=%.1f (L2)', M), 'L2', cd2, br, 'N/A', NaN, '%.5f', sprintf('Brandt actual polar (M~%.3g)', ap_mach(nearestIdx(ap_mach, M))), note2)]; %#ok<AGROW>
    T = [T; arow(sprintf('CD0 @ M=%.1f (L3)', M), 'L3', cd3, br, 'N/A', NaN, '%.5f', sprintf('Brandt actual polar (M~%.3g)', ap_mach(nearestIdx(ap_mach, M))), note3)]; %#ok<AGROW>
end

% ── Oswald span efficiency ──────────────────────────────────────────────── %
T = [T; srow('[OSWALD SPAN EFFICIENCY -- two implementation options]')];
T = [T; arow('e, official Raymer Eq.12.48/12.49 (L2)', 'L2', a2.get_e_osw(), gt.e0.brandt.value, 'N/A', gt.e0.internet.value, '%.4f', 'Brandt Aero!G12 (e0)', ...
        'OFFICIAL drag_polar value (Eq.12.49, Lambda_LE=40). ~0.6% under Brandt e0 (Brandt uses a different formula).')];
T = [T; arow('e, official Raymer Eq.12.48/12.49 (L3)', 'L3', a3.get_e_osw(), gt.e0.brandt.value, 'N/A', gt.e0.internet.value, '%.4f', 'Brandt Aero!G12 (e0)', ...
        'Same official formula as L2.')];
T = [T; arow('e, Brandt Aero!G12 alternate (L2)', 'L2', a2.get_e_osw_brandt(), gt.e0.brandt.value, 'N/A', gt.e0.internet.value, '%.4f', 'Brandt Aero!G12 (e0)', ...
        'POSITIVE CONTROL: this is Brandt''s own formula fed Brandt''s inputs, so it reproduces e0=0.9144 near-exactly. Comparison-report ONLY -- never what drag_polar returns.')];
T = [T; arow('e, Brandt Aero!G12 alternate (L3)', 'L3', a3.get_e_osw_brandt(), gt.e0.brandt.value, 'N/A', gt.e0.internet.value, '%.4f', 'Brandt Aero!G12 (e0)', ...
        'Same Brandt alternate as L2 (positive control).')];

% ── CLmax (clean / takeoff / landing) ───────────────────────────────────── %
T = [T; srow('[MAXIMUM LIFT COEFFICIENT -- clean / takeoff / landing]')];
T = [T; arow('CLmax clean (L1 Roskam lookup)', 'L1', a1.get_CLmax([]), gt.CLmax_clean.brandt.value, 'N/A', gt.CLmax_clean.internet.value, '%.4f', 'Brandt Aero!H25', ...
        'Roskam Vol.I Table 3.3 fighter clean = 0.90. Both L1 and Brandt (0.984) badly under the ~1.6 whole-aircraft value: NO LEX/strake vortex lift modeled -- not a bug.')];
T = [T; arow('CLmax clean (L2 Eq.12.15)', 'L2', a2.get_CLmax([]), gt.CLmax_clean.brandt.value, 'N/A', gt.CLmax_clean.internet.value, '%.4f', 'Brandt Aero!H25', ...
        '0.9*cl_max_2D*cos(Lambda_c/4). Near Brandt 0.984; far below internet ~1.6 (no vortex lift) -- expected underprediction, not a bug.')];
T = [T; arow('CLmax clean (L3 Eq.12.15)', 'L3', a3.get_CLmax([]), gt.CLmax_clean.brandt.value, 'N/A', gt.CLmax_clean.internet.value, '%.4f', 'Brandt Aero!H25', ...
        'Same Eq.12.15 basis as L2; same LEX vortex-lift limitation.')];
T = [T; arow('CLmax takeoff (L1)', 'L1', a1.get_CLmax_TO(), gt.CLmax_takeoff.brandt.value, 'N/A', gt.CLmax_takeoff.internet.value, '%.4f', 'Brandt Aero!H27', ...
        'L1 clean + Roskam Table 3.1 fighter TO-delta (category mean).')];
T = [T; arow('CLmax takeoff (L2 flap+slat)', 'L2', a2.get_CLmax_TO(), gt.CLmax_takeoff.brandt.value, 'N/A', gt.CLmax_takeoff.internet.value, '%.4f', 'Brandt Aero!H27', ...
        'Clean + TE-flap + LE-flap deltas (Eq.12.21). LEF ADDED 2026-08-10 -- L2 previously modeled the flap only; see VnV/BrandtF16A/todo.md. Internet 1.35 is a rough band center (F-16 has no conventional TE flaps).')];
T = [T; arow('CLmax takeoff (L3 flap+slat)', 'L3', a3.get_CLmax_TO(), gt.CLmax_takeoff.brandt.value, 'N/A', gt.CLmax_takeoff.internet.value, '%.4f', 'Brandt Aero!H27', ...
        'Clean + TE-flap + LE-slat deltas -- same fractions/deflections as L2 now (f16a_control_surfaces()); L2/L3 agree exactly here.')];
T = [T; arow('CLmax landing (L1)', 'L1', a1.get_CLmax_L(), gt.CLmax_landing.brandt.value, 'N/A', gt.CLmax_landing.internet.value, '%.4f', 'Brandt Aero!H29', ...
        'L1 clean + Roskam Table 3.1 fighter landing-delta -- generic large-flap category mean overshoots the F-16.')];
T = [T; arow('CLmax landing (L2 flap+slat)', 'L2', a2.get_CLmax_L(), gt.CLmax_landing.brandt.value, 'N/A', gt.CLmax_landing.internet.value, '%.4f', 'Brandt Aero!H29', ...
        'Clean + TE-flap + LE-flap deltas. LEF ADDED 2026-08-10, closing a real fidelity gap (L2 previously omitted it entirely, which left SizingLoopL2''s landing wall ~5.3 psf too tight vs. L3 -- VnV/BrandtF16A/todo.md).')];
T = [T; arow('CLmax landing (L3 flap+slat)', 'L3', a3.get_CLmax_L(), gt.CLmax_landing.brandt.value, 'N/A', gt.CLmax_landing.internet.value, '%.4f', 'Brandt Aero!H29', ...
        'Clean + TE-flap + LE-slat deltas -- same fractions/deflections as L2 now; L2/L3 agree exactly here.')];

% ── CL_alpha: the finite-wing lift slope. L1 has no such method (geometry-free,
%    so no finite-wing correction exists at that tier) -- reported N/A rather
%    than omitted, so the ladder shows where the capability starts.
%    Compared against Brandt's WING slope (Aero!A15), not his whole-aircraft
%    one (Aero!A32 = 0.0615/deg), because get_CL_alpha is a finite-WING method
%    with no strake or tail contribution. Both are stored per DEGREE.
gt_CLalpha = gt.CL_alpha_wing_per_deg.brandt.value * 180/pi;   % 3.1117 /rad
T = [T; srow('[LIFT-CURVE SLOPE CL_alpha -- Raymer Eq.12.6, M=0]')];
T = [T; arow('CL_alpha, M=0 [1/rad]', 'L1', NaN, gt_CLalpha, 'N/A', NaN, '%.4f', 'Brandt Aero!A15', ...
        'L1 is geometry-free (Mattingly type-curve), so no finite-wing lift slope exists at this tier -- not an omission.')];
T = [T; arow('CL_alpha, M=0 [1/rad]', 'L2', a2.get_CL_alpha(0), gt_CLalpha, 'N/A', NaN, '%.4f', 'Brandt Aero!A15', ...
        'Raymer Eq.12.6 with the injected quarter-chord sweep (~32.2 deg) and the real NACA 64A204 2-D slope.')];
T = [T; arow('CL_alpha, M=0 [1/rad]', 'L3', a3.get_CL_alpha(0), gt_CLalpha, 'N/A', NaN, '%.4f', 'Brandt Aero!A15', ...
        'L3 delegates to AeroL2.get_CL_alpha, so it MUST equal the L2 row exactly for identical injected geometry -- a positive control on the delegation.')];

% ════════════════════════════════════════════════════════════════════════ %
%  DISPLAY + EXPORT — all four discipline reports share one renderer
%  (src/reporting/ComparisonReport.m), so their columns cannot drift apart.
% ════════════════════════════════════════════════════════════════════════ %

meta = struct( ...
    'title',         'F-16A Block 10/15 — Aerodynamics vs Ground Truth', ...
    'aircraft',      'F-16A Block 10/15', ...
    'generated',     char(datetime('now', 'Format', 'yyyy-MM-dd')), ...
    'condition',     sprintf('Flight condition: %d ft, subsonic M = %.1f / supersonic M = %.1f.', ALT, M_SUB, M_SUP), ...
    'referenceDesc', ['Brandt F-16A.xls workbook outputs and his tabulated actual polar, via ' ...
                      '`VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` [`.aerodynamics`].'], ...
    'secondDesc',    ['whichever independent source exists for that row, tagged inline — `[AF]` = ' ...
                      'T.O. 1F-16A-1 (which carries the airfoil and operating limits **only**; it has ' ...
                      'no drag polar, CLmax or CD0 coefficients — those live in the absent ' ...
                      'T.O. 1F-16A-1-1), `[pub]` = a published estimate (F-16C conceptual polar, ' ...
                      'textbook, NASA). Most aero rows have neither, and show `N/A`.'] );

meta.preamble = { ...
    ['**The transonic band 0.95 ≤ M ≤ 1.05 is deliberately skipped.** L2/L3 `drag_polar` returns NaN ' ...
     'there — Raymer Eq. 12.51 has a pole near M = 1 — so the sweep uses subsonic M = 0.6/0.8/0.9 and ' ...
     'supersonic M = 1.2/1.5/2.0. That NaN is a modelled gap, not a failure: `Both_WbyS_TbyW` and ' ...
     '`ConstraintAnalysis` both refuse to evaluate a constraint there rather than returning a number.'], ...
    ['**Two expected large gaps that are not defects.** L2 supersonic CD0 carries no wave-drag term at ' ...
     'all (that arrives only at L3), so it sits far below Brandt. And Brandt''s skin-friction CDmin ' ...
     '(`Aero!G3`) is a different basis from his *mission* CD0 of 0.0270, which folds in form, ' ...
     'interference and wave drag — compare like with like before concluding anything.'] };

meta.footer = { ...
    ['**CLmax is the largest step in the fidelity ladder, and it is intentional.** L1 returns the ' ...
     'Roskam Table 3.1 fighter-column mean (1.50); L2/L3 return Raymer Eq. 12.15''s geometry-based ' ...
     '0.914. A type-only statistical mean over a column dominated by straight wings is simply a ' ...
     'different estimator from one that penalises a thin 40°-swept wing. Neither is calibrated to ' ...
     'the other.'], ...
    ['**Vortex lift from the LEX/strake is not modelled at any tier**, so every CLmax row ' ...
     'underpredicts the ~1.6 real whole-aircraft value.'] };

ComparisonReport.show(T, meta);

out_json = fullfile(script_dir, 'jsons', 'aerodynamics_brandt_comparison.json');
out_md   = fullfile(script_dir, 'mds', 'aerodynamics_brandt_comparison.md');
ComparisonReport.writeJson(T, out_json, meta);
ComparisonReport.writeMarkdown(T, out_md, meta);
fprintf('  JSON     -> %s\n', out_json);
fprintf('  Markdown -> %s\n\n', out_md);

T_all = T;

end

% ─── local helpers: thin wrappers over the shared renderer ───────────────── %

function T = arow(name, fidelity, computed, brandt, afman, internet, numfmt, cite, notes)
%AROW  One comparison row. See ComparisonReport.row for the column semantics.
%   This report has TWO candidate second sources -- the AF manual and a
%   published estimate -- but the shared scheme carries ONE `2nd Source`
%   column, so whichever exists is passed through tagged inline ([AF] / [pub]).
%   Rows with both are not expected and would need a Notes mention.
    if nargin < 9; notes = ''; end
    second = 'N/A';
    if (ischar(afman) || isstring(afman)) && ~strcmpi(char(afman), 'N/A')
        second = sprintf('%s [AF]', char(afman));
    elseif isnumeric(afman) && ~isnan(afman)
        second = sprintf([numfmt ' [AF]'], afman);
    elseif isnumeric(internet) && ~isnan(internet)
        second = sprintf([numfmt ' [pub]'], internet);
    end
    T = ComparisonReport.row(name, fidelity, computed, brandt, cite, numfmt, notes, second, '');
end

function T = srow(label)
%SROW  Section separator row.
    T = ComparisonReport.section(label);
end

function idx = nearestIdx(vec, x)
%NEARESTIDX  Index of the element of vec closest to x.
    [~, idx] = min(abs(vec - x));
end
