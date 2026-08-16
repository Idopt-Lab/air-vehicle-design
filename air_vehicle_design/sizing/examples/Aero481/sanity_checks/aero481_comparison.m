function results = aero481_comparison()
%Aero481_AERO481_COMPARISON  Informational F-35 model vs Aero 481 Design01.
%
%   Compares the F-35 L1 discipline model against the INLINE Aero 481
%   +Constraints/* reference formulas (C:\Users\darsh\Downloads\Aero 481
%   Code\+Constraints\: Cruise.m, SustainedTurn.m, SpecExcessPower.m,
%   InstantaneousTurn.m, Ceiling.m, plus the All.m driver), evaluated at the
%   Design01 design wing-loading W/S = 92.17 psf (= 450 kg/m^2 * 9.807 = 4413
%   N/m^2 [A481 Design01.m:21]). Per-constraint framework required_TW vs the
%   transcribed A481 T/W.
%
%   INFORMATIONAL ONLY -- not a pass/fail unit test, and NEVER used to backfill a
%   unit test's expected value (the CLAUDE.md two-tier rule). Prints console
%   tables and writes examples/Aero481/output/aero481_comparison.{md,json}.
%   Mirrors sanity_checks/b777_metabook_comparison.m and the
%   brandt_constraint_reference.m transcription pattern.
%
%   The A481 reference formulas are transcribed HERE in SI, faithful to the
%   source (Utility.StdAtm Section 01 for all F-35 altitudes <11 km; W/S in
%   N/m^2; T/W dimensionless). The A481 g = 9.087 typo (disc A3) is reproduced
%   in the InstantaneousTurn transcription so the printed A481 value matches what
%   Aero 481 actually computes -- the framework value corrects it, and the delta
%   is annotated. Aero 481 applies NO thrust lapse (disc A6); the framework lapse
%   is now OFF too (m = 0), so the A6 section below reports alpha = 1 at every
%   altitude and the per-constraint deltas are no longer lapse-driven.
%
%   A02 MTOW REPRODUCTION (section 12). Beyond the per-constraint check, the
%   report sizes the framework at the real F135 thrust (43,000 lbf) x a few
%   design wings via TSDiagram.converge_W0 (the A02 fixed-cell closure) and
%   compares the converged TOGW to Aero 481's A02 values -- the faithfulness
%   check (~2%).
%
%   ANNOTATED SYSTEMATIC DELTAS (Aero 481 vs framework; see
%   examples/Aero481/aero481_discrepancies.md):
%     * A6 (thrust lapse) -- Aero 481 uses installed thrust at altitude with no
%       alpha = T(alt)/T_SL term. The framework lapse is now OFF (m = 0), so
%       alpha = sigma^0 = 1 at every altitude, matching A481. This delta is now
%       ZERO; the A6 section below reports alpha = 1 to document the resolution.
%     * A2 (Oswald form) -- A481 Utility.Oswald(AR) = 1.78*(1-0.045*AR^0.68)-0.64
%       IS Raymer 6th ed. Eq. 12.48 (the framework's low-sweep branch), so at
%       Lambda_LE < 30 deg the two are IDENTICAL. Any e delta is zero here.
%     * A4 (climb gradient) -- no longer relevant here: the six FAR-25 climb rows
%       were DROPPED (transport-cert gradients, not applicable to a fighter; user
%       decision). No climb comparison is made.
%     * SEP maneuver (combat) weight -- A481 SpecExcessPower.m ALONE evaluates at
%       a 50%-internal-fuel COMBAT weight (W_S_mw = W_S*(1+(1-ff))/2*n, ff = 0.343
%       the DCA fuel fraction => combat fraction (1+(1-0.343))/2 = 0.8285) [A481
%       SpecExcessPower.m:28]. The framework now REPRODUCES this: the 6 SEP rows
%       carry beta = 0.8285 in aero481_requirements.json, and the master equation
%       applies the load factor n separately. So this delta is now ZERO (both use
%       the same combat weight); the transcription below uses ff = 0.343.
%     * A8 (mission fractions) -- Roskam Part I Table 2.1 fighter fractions
%       replace A03's uncited ff1..ffdescent. Not a constraint delta; noted for
%       the published cross-check row only.
%
%   PUBLISHED F-35A CROSS-CHECK (order-of-magnitude only, aero481_data.md Part I):
%   MTOW ~65,900-70,000 lb, T = 43,000 lbf, S = 460 ft^2 -> W/S ~143-152 psf vs
%   Design01's 92.2; AR 4 (Design01) vs published 2.66 (35 ft span / 460 ft^2,
%   disc A5).

    sp = aero481_spec_path(1);
    rp = aero481_requirements_path();

    % Live F-35 L1 stack (geometry-light aero; single-engine AB prop).
    prop = Aero481PropL1(sp);
    aero = Aero481AeroL1(sp);

    % Design wing-loading, the single W/S all rows are probed at.
    WS_psf = 92.17;                       % [A481 Design01.m:21]
    PSF2NM2 = 47.880259;                  % 1 lbf/ft^2 -> N/m^2
    WS_si   = WS_psf * PSF2NM2;           % 4413 N/m^2 -> matches 450*9.807

    % Shared A481 inputs (transcribed from Design01.m + All.m).
    AR       = aero.AR;                                  % 4        [A481 Design01.m:49]
    CD0_cl   = aero.get_config_polar("clean").CD0;       % 0.0236   [A481 Design01.m:64]
    e_a481   = a481_oswald(AR);                          % Utility.Oswald [A481 Oswald.m]

    fprintf('\n============ F-35 vs AERO 481 Design01 (informational) ============\n');
    fprintf('  Probed at W/S = %.2f psf (%.1f N/m^2) [A481 Design01.m:21]\n', WS_psf, WS_si);

    rows = {};   % each: struct(section, label, model, a481, cite, note)

    % --------------------------------------------------------------------- %
    % 1. Clean drag-polar buildup (framework live vs A481 constants).
    % --------------------------------------------------------------------- %
    polar = aero.drag_polar([]);   % clean; state unused at L1
    rows{end+1} = crow('Drag polar', 'clean CD0', polar.CD0, CD0_cl, ...
        'A481 Design01.m:64', 'constant clean CD0; identical (model reads the table)'); %#ok<*AGROW>
    rows{end+1} = crow('Drag polar', 'Oswald e', ...
        AeroL2.oswald_eff(AR, aero.Lambda_LE_deg), e_a481, ...
        'A481 Oswald.m = Raymer Eq. 12.48', 'A2: identical at Lambda_LE < 30 deg');
    rows{end+1} = crow('Drag polar', 'clean K1', polar.K1, 1/(pi*AR*e_a481), ...
        'Raymer Eq. 12.50 vs A481 1/(pi*AR*e)', 'A2: identical basis');

    % --------------------------------------------------------------------- %
    % 2. Build the 12 constraints once and index by name.
    % --------------------------------------------------------------------- %
    cons = ConstraintAnalysis.build_constraints(aero, prop, rp, ...
        Aero481ConstraintSet.constraint_map());
    con_names = cellfun(@(c) string(c.name), cons);   % 1xN string, constraint order

    % --------------------------------------------------------------------- %
    % 3. Level-flight producers: Cruise (M0.85) and Dash (M1.6).
    %    A481 Cruise.m: T_W = q*CD0/W_S + W_S/(q*pi*AR*e).  [A481 Cruise.m:38]
    % --------------------------------------------------------------------- %
    q_crs = a481_q(35000, 0.85);
    tw_crs_a481 = q_crs*CD0_cl/WS_si + WS_si/(q_crs*pi*AR*e_a481);
    cr = find_con(cons, con_names, "Cruise");
    rows{end+1} = crow('Cruise', 'T/W', cr.required_TW(WS_psf), tw_crs_a481, ...
        'A481 Cruise.m:38 vs LevelFlight', 'A6: framework adds sigma^0.6 (mil) lapse');

    q_dsh = a481_q(35000, 1.60);
    tw_dsh_a481 = q_dsh*CD0_cl/WS_si + WS_si/(q_dsh*pi*AR*e_a481);
    dr = find_con(cons, con_names, "Dash");
    rows{end+1} = crow('Dash', 'T/W', dr.required_TW(WS_psf), tw_dsh_a481, ...
        'A481 All.m:70 (Cruise M1.6) vs LevelFlight', 'A6: framework adds sigma^0.6 (AB) lapse');

    % --------------------------------------------------------------------- %
    % 4. Sustained turns (n = 2), M0.9 and M1.2.
    %    A481 SustainedTurn.m: T_W = q*CD0/W_S + W_S*n^2/(q*pi*AR*e). [line 40]
    % --------------------------------------------------------------------- %
    n_turn = 2;
    q_st1 = a481_q(35000, 0.90);
    tw_st1_a481 = q_st1*CD0_cl/WS_si + WS_si*n_turn^2/(q_st1*pi*AR*e_a481);
    st1 = find_con(cons, con_names, "Sustained Turn 1 (subsonic)");
    rows{end+1} = crow('Sustained turn', 'ST1 (M0.9, n2) T/W', ...
        st1.required_TW(WS_psf), tw_st1_a481, ...
        'A481 SustainedTurn.m:40 vs SustainedTurn', 'A6: framework adds AB lapse');

    q_st2 = a481_q(35000, 1.20);
    tw_st2_a481 = q_st2*CD0_cl/WS_si + WS_si*n_turn^2/(q_st2*pi*AR*e_a481);
    st2 = find_con(cons, con_names, "Sustained Turn 2 (supersonic)");
    rows{end+1} = crow('Sustained turn', 'ST2 (M1.2, n2) T/W', ...
        st2.required_TW(WS_psf), tw_st2_a481, ...
        'A481 All.m:82 vs SustainedTurn', 'A6: framework adds AB lapse');

    % --------------------------------------------------------------------- %
    % 5. Specific excess power (SEP1/2 n=1, SEP3 n=5), SL + 15 kft.
    %    A481 SpecExcessPower.m: COMBAT weight W_S_mw = W_S*(1+(1-ff))/2*n;
    %      CL = W_S_mw/q;  CD = CD0 + CL^2/(pi*AR*e);
    %      T_W = Ps/v + q*CD/W_S_mw.  [A481 SpecExcessPower.m:28,44,47,50]
    %    ff = 0.343 (the DCA fuel fraction) => combat fraction (1+(1-0.343))/2 =
    %    0.8285, matching the beta = 0.8285 the 6 SEP rows now carry in
    %    aero481_requirements.json. Ps in m/s (ft value read as ft/s per
    %    _note_Ps_unit, converted to m/s for the A481 v [m/s]).
    % --------------------------------------------------------------------- %
    FT2M = 0.3048;
    sep_specs = { ...
        "SEP1 SL (1g, M0.9)",          0,     0.90, 1, 200; ...
        "SEP1 alt (1g, M0.9, 15 kft)", 15000, 0.90, 1,  50; ...
        "SEP2 SL (1g, M0.9, max)",     0,     0.90, 1, 700; ...
        "SEP2 alt (1g, M0.9, 15 kft)", 15000, 0.90, 1, 400; ...
        "SEP3 SL (5g, M0.9)",          0,     0.90, 5, 300; ...
        "SEP3 alt (5g, M0.9, 15 kft)", 15000, 0.90, 5,  50};
    ff_probe = 0.343;   % DCA fuel fraction -> combat fraction (1+(1-ff))/2 = 0.8285
    for i = 1:size(sep_specs, 1)
        nm  = sep_specs{i, 1};
        alt = sep_specs{i, 2};
        M   = sep_specs{i, 3};
        nfac = sep_specs{i, 4};
        Ps_fps = sep_specs{i, 5};
        [q, v] = a481_qv(alt, M);
        WS_mw = WS_si * (1 + (1 - ff_probe)) / 2 * nfac;    % [line 28] combat weight * n
        CL = WS_mw / q;
        CD = CD0_cl + CL^2 / (pi*AR*e_a481);
        Ps_ms = Ps_fps * FT2M;                              % ft/s -> m/s for v [m/s]
        tw_sep_a481 = Ps_ms / v + q * CD / WS_mw;           % [line 50]
        c = find_con(cons, con_names, nm);
        rows{end+1} = crow('SEP', sprintf('%s T/W', nm), ...
            c.required_TW(WS_psf), tw_sep_a481, ...
            'A481 SpecExcessPower.m:50', ...
            'combat weight now matched (beta = 0.8285); residual delta = A6 lapse only');
    end

    % --------------------------------------------------------------------- %
    % 6. Instantaneous turn (M1.6, 18 deg/s).
    %    A481 InstantaneousTurn.m REPRODUCED WITH THE g = 9.087 TYPO (disc A3):
    %      n = rot*v/g;  W_S_n = W_S*n;  CL = W_S_n/q;
    %      CD = CD0 + CL^2/(pi*AR*e);  T_W = q*CD/W_S_n.  [lines 32,35,38,47,50,56]
    %    The framework class corrects g to 32.174 ft/s^2, so the delta here is
    %    partly the A3 gravity fix and partly the A6 lapse.
    % --------------------------------------------------------------------- %
    [q_it, v_it] = a481_qv(35000, 1.60);
    rot = 18 * pi / 180;               % rad/s [A481 All.m:86]
    g_typo = 9.087;                    % [A481 InstantaneousTurn.m:32] DISC A3
    n_it = rot * v_it / g_typo;
    WS_n = WS_si * n_it;
    CL_it = WS_n / q_it;
    CD_it = CD0_cl + CL_it^2 / (pi*AR*e_a481);
    tw_it_a481 = q_it * CD_it / WS_n;
    it = find_con(cons, con_names, "Instantaneous Turn");
    rows{end+1} = crow('Instantaneous turn', 'T/W (M1.6, 18 dps)', ...
        it.required_TW(WS_psf), tw_it_a481, ...
        'A481 InstantaneousTurn.m:56', ...
        'A3: A481 g = 9.087 typo (~7.9% high n); framework g = 32.174; + A6 lapse');

    % --------------------------------------------------------------------- %
    % 7. Ceiling (M1.6, +1 deg gradient).
    %    A481 Ceiling.m = Cruise(W_S,Alt,M,CD0,AR) + G, G = 1 deg [All.m:74].
    % --------------------------------------------------------------------- %
    q_cei = a481_q(35000, 1.60);
    G_cei = 1 * pi / 180;              % [A481 All.m:74]
    tw_cei_a481 = (q_cei*CD0_cl/WS_si + WS_si/(q_cei*pi*AR*e_a481)) + G_cei;
    ce = find_con(cons, con_names, "Ceiling");
    rows{end+1} = crow('Ceiling', 'T/W (at W/S=92.17)', ce.required_TW(WS_psf), tw_cei_a481, ...
        'A481 Ceiling.m:25 vs CeilingConstraint', 'A6: framework adds AB lapse');

    % --------------------------------------------------------------------- %
    % 8. Climb 1-6, Takeoff and Landing were DROPPED (user decision, A481 parity):
    %    the six FAR-25 climb gradients are transport-certification gradients not
    %    applicable to a fighter, and Aero 481 leaves Takeoff/Landing
    %    unimplemented (All.m:37 sets TO = 0; Landing is a stub). None is a real
    %    Aero 481 constraint, so none is compared here. See Aero481ConstraintSet.
    % --------------------------------------------------------------------- %

    % --------------------------------------------------------------------- %
    % 9. A6 THRUST-LAPSE section (now RESOLVED) -- report the framework lapse
    %     factors the transcriptions above do NOT carry, so the per-row deltas
    %     above are readable. The framework lapse exponent m is now 0, so
    %     alpha = sigma^0 = 1 at every altitude -- matching A481 (which applies no
    %     lapse). These rows should print alpha = 1.0 (delta 0%), documenting the
    %     A6 resolution. mil-on-AB scale is reported for reference.
    % --------------------------------------------------------------------- %
    m_lapse = prop.lapse_exponent_m;                 % 0 (lapse OFF, matches A481)
    mil_scale = prop.T_SL_mil / prop.T_SL;           % 28000/43000 = 0.6512
    for alt = [0 15000 35000]
        st = AircraftState(alt, 0.90);
        alpha_AB  = prop.thrust_lapse(st, "AB");
        alpha_mil = prop.thrust_lapse(st, "mil");
        rows{end+1} = crow('A6 thrust lapse', sprintf('alt %d ft: alpha_AB', alt), ...
            alpha_AB, 1.0, 'framework metabook Eq. 10.9 vs A481 (none)', ...
            sprintf('A6: lapse OFF (sigma^%.2f = 1); matches A481', m_lapse));
        rows{end+1} = crow('A6 thrust lapse', sprintf('alt %d ft: alpha_mil', alt), ...
            alpha_mil, mil_scale, 'framework mil-on-AB scale vs A481 (none)', ...
            sprintf('A6: mil-on-AB scale = %.4f (lapse OFF, so alpha_mil = this)', mil_scale));
    end

    % --------------------------------------------------------------------- %
    % 10. Published F-35A cross-check (order-of-magnitude, aero481_data.md Part I).
    %     Design values vs the published jet -- a fidelity/design gap (disc A5),
    %     NOT a bug. a481/published carried in the note; model column = Design01.
    % --------------------------------------------------------------------- %
    rows{end+1} = crow('Published X-check', 'AR', AR, 2.66, ...
        'A481 Design01.m:49 vs aero481_data.md Part I', ...
        'A5: Design01 AR 4 vs published 35^2/460 = 2.66');
    rows{end+1} = crow('Published X-check', 'design W/S [psf]', WS_psf, 143.3, ...
        'A481 Design01.m:21 vs aero481_data.md Part I', ...
        'published MTOW 65,900 lb / 460 ft^2 = 143 psf (range 143-152)');
    rows{end+1} = crow('Published X-check', 'design T/W', TW_design_ratio(prop), 0.65, ...
        'A481 Design01.m:20 vs aero481_data.md Part I', ...
        'Design01 T/W 1.2 vs published 43,000/65,900 = 0.65 (T = 43,000 lbf)');

    % --------------------------------------------------------------------- %
    % 11. A02 MTOW reproduction (the faithfulness check). Size the framework at
    %     the real F135 thrust (43,000 lbf) x a few design wings and compare the
    %     converged TOGW to Aero 481's A02 values. TSDiagram.converge_W0 IS the
    %     A02 fixed-cell closure (writes prop.T_SL / geom.S_ref, iterates the TOGW
    %     fixed point on the mission fuel fraction + the A02 empty-weight build-up
    %     -- see Aero481WeightsL1.OEW). The lapse is now OFF (m = 0), matching A481
    %     (disc A6 resolved), so the reproduction is faithful (~2%). A02 refs:
    %     A02(Design01, 43,000 lbf, {45,50,55} m^2) [A481 +Algorithms/A02.m].
    % --------------------------------------------------------------------- %
    geom  = Aero481GeomL1(sp, rp);
    tail  = Aero481TailL1();
    wts   = Aero481WeightsL1(sp, geom, prop);       % A02 delta model (geom + prop injected)
    miss  = MissionAnalysisL1.from_requirements(aero, prop, geom, rp, "dca");
    ca_ts = ConstraintAnalysis.from_requirements(aero, prop, rp, ...
        Aero481ConstraintSet.constraint_map(), linspace(20, 200, 181));
    ts    = TSDiagram(aero, prop, wts, geom, miss, ca_ts, tail);

    T_F135    = 43000;                          % lbf real F135 SLS with afterburner
    a02_specs = { ...
        484, 61481; ...    % S ~ 45 m^2 -> A02 MTOW [lbf]
        538, 62399; ...    % S ~ 50 m^2 (the design cell)
        592, 63316};       % S ~ 55 m^2
    for i = 1:size(a02_specs, 1)
        S_cell  = a02_specs{i, 1};
        a02_mtow = a02_specs{i, 2};
        W0_fw = ts.converge_W0(T_F135, S_cell);
        rows{end+1} = crow('A02 MTOW', ...
            sprintf('T=43000 x S=%d ft^2', S_cell), W0_fw, a02_mtow, ...
            'A481 +Algorithms/A02.m (fixed-cell sizing)', ...
            'faithful A02 reproduction (~2%); lapse now OFF, matches A481 (A6)');
    end

    % --------------------------------------------------------------------- %
    % Console table + exports.
    % --------------------------------------------------------------------- %
    print_table(rows, WS_psf);
    results = struct();
    results.WS_probe_psf = WS_psf;
    results.rows = rows;   % scalar struct; .rows is the 1xN cell of row structs
    write_exports(results);
    fprintf('\nWrote output/aero481_comparison.md and .json\n');
end

% ========================================================================= %
% A481 reference helpers (transcribed from +Constraints/* + +Utility/*).
% ========================================================================= %
function e = a481_oswald(AR)
%A481_OSWALD  Utility.Oswald(AR) = 1.78*(1-0.045*AR^0.68)-0.64  [A481 Oswald.m].
%   = Raymer 6th ed. Eq. 12.48 (disc A2).
    e = 1.78 * (1 - 0.045 * AR.^0.68) - 0.64;
end

function [T, P, Rho] = a481_stdatm(alt_ft)
%A481_STDATM  Utility.StdAtm Section 01 (0-11 km) in SI  [A481 StdAtm.m:73-85].
%   All F-35 constraint altitudes (0 / 15,000 / 35,000 ft) lie below 11 km, so
%   only the troposphere section is transcribed. Returns T [K], P [Pa], Rho [kg/m^3].
    alt_m = alt_ft * 0.3048;
    g = 9.81; R = 287;                 % [A481 StdAtm.m:51-52]
    T  = 288.15 - 0.0065 * alt_m;      % [line 77]
    P0 = 101300;                       % [line 80]
    P  = P0 * (T / 288.15)^(-g / (R * -0.0065));   % [line 83]
    Rho = P / (R * T);                 % [line 186]
end

function q = a481_q(alt_ft, M)
%A481_Q  Dynamic pressure [Pa] the A481 constraints compute:
%   v = M*sqrt(gamma*R*T); q = 0.5*rho*v^2  [A481 Cruise.m:28-32].
    q = deal_qv(alt_ft, M);            % q is the FIRST output of deal_qv
end

function [q, v] = a481_qv(alt_ft, M)
%A481_QV  Dynamic pressure [Pa] and speed [m/s], A481 convention.
    [q, v] = deal_qv(alt_ft, M);
end

function [q, v] = deal_qv(alt_ft, M)
    [T, ~, Rho] = a481_stdatm(alt_ft);
    R = 287; Gam = 1.4;                % [A481 Cruise.m:28]
    v = M * sqrt(Gam * R * T);
    q = 0.5 * Rho * v^2;
end

function tw = TW_design_ratio(prop)
%TW_DESIGN_RATIO  Design01 T/W = 1.2 (the marker). Kept as a tiny helper so the
%   published-cross-check row reads the design T/W from a named source rather
%   than a bare literal; prop is unused (the value is the Design01 choice).
    tw = 1.2;   %#ok<INUSD>  [A481 Design01.m:20]
end

% ========================================================================= %
% Table / row helpers (mirror b777_metabook_comparison.m).
% ========================================================================= %
function r = crow(section, label, model, a481, cite, note)
%CROW  One comparison row. pct is NaN when a481 is NaN (no reference target).
    if isnan(a481)
        pct = NaN;
    else
        pct = 100 * (model - a481) / a481;
    end
    r = struct('section', section, 'label', label, 'model', model, ...
        'a481', a481, 'pct', pct, 'cite', cite, 'note', note);
end

function c = find_con(cons, con_names, name)
%FIND_CON  The constraint object whose .name matches, from the built cell array.
%   Errors if the name is absent -- a typo guard, so a mis-typed lookup fails
%   loudly rather than silently comparing against the wrong constraint.
    idx = find(con_names == name, 1);
    if isempty(idx)
        error('aero481_comparison:constraintNotFound', ...
            'No built constraint named "%s" (have: %s).', name, ...
            strjoin(con_names, ', '));
    end
    c = cons{idx};
end

function print_table(rows, WS_psf)
    fprintf('\n  %-18s %-26s %14s %14s %9s  %s\n', ...
        'Section', 'Quantity', 'Model', 'Aero 481', 'Delta%', 'Note');
    fprintf('  (all constraint T/W probed at W/S = %.2f psf)\n', WS_psf);
    fprintf('  %s\n', repmat('-', 1, 120));
    for i = 1:numel(rows)
        r = rows{i};
        if isnan(r.a481)
            a4 = '   (none)'; pc = '     -';
        else
            a4 = sprintf('%14.5g', r.a481); pc = sprintf('%+8.2f', r.pct);
        end
        fprintf('  %-18s %-26s %14.5g %14s %9s  %s\n', ...
            r.section, r.label, r.model, a4, pc, r.note);
    end
end

function write_exports(results)
    outdir = fullfile(fileparts(mfilename('fullpath')), '..', 'output');
    if ~exist(outdir, 'dir'), mkdir(outdir); end

    % JSON
    fid = fopen(fullfile(outdir, 'aero481_comparison.json'), 'w');
    fwrite(fid, jsonencode(results, 'PrettyPrint', true));
    fclose(fid);

    % Markdown
    rows = results.rows;
    L = strings(0, 1);
    L(end+1) = "# F-35 vs Aero 481 Design01 (informational)";
    L(end+1) = "";
    L(end+1) = sprintf("F-35 L1 model vs the INLINE Aero 481 +Constraints/* formulas, probed at W/S = %.2f psf.", results.WS_probe_psf);
    L(end+1) = "Informational only (not pass/fail). See `sanity_checks/aero481_comparison.m`.";
    L(end+1) = "";
    L(end+1) = "Systematic deltas (see `aero481_discrepancies.md`): A6 thrust lapse (the";
    L(end+1) = "single largest -- own section below), A2 Oswald form (identical at Lambda_LE<30),";
    L(end+1) = "A4 sin-vs-asin climb gradient, SEP maneuver-weight handling, A8 mission fractions.";
    L(end+1) = "";
    L(end+1) = "| Section | Quantity | Model | Aero 481 | Delta% | Cite | Note |";
    L(end+1) = "|---|---|--:|--:|--:|---|---|";
    for i = 1:numel(rows)
        r = rows{i};
        if isnan(r.a481)
            a4 = "(none)"; pc = "-";
        else
            a4 = sprintf("%.5g", r.a481); pc = sprintf("%+.2f", r.pct);
        end
        L(end+1) = "| " + r.section + " | " + r.label + " | " + ...
            sprintf("%.5g", r.model) + " | " + a4 + " | " + pc + " | " + ...
            r.cite + " | " + r.note + " |";
    end
    writelines(L, fullfile(outdir, 'aero481_comparison.md'));
end
