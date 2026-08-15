function results = b777_metabook_comparison()
%B777_METABOOK_COMPARISON  Informational B777 model vs metabook Example 4.2.
%
%   Compares the B777 L1 discipline model against the PRINTED numbers of the
%   metabook worked Example 4.2 (docs/reference_extracts/metabook_data.md,
%   §4.11 / §4.12): the drag-polar buildup, the five config polars, the
%   field-length/climb/ceiling/cruise constraint values, and the converged
%   design point vs the actual 777-200LR.
%
%   INFORMATIONAL ONLY -- not a pass/fail unit test, and never used to backfill a
%   unit test's expected value (the CLAUDE.md two-tier rule). Prints console
%   tables and writes examples/B777/output/b777_metabook_comparison.{md,json}.
%   Mirrors the sanity_checks/*_brandt_comparison.m pattern.
%
%   ANNOTATED BY-DESIGN GAPS (metabook-internal or modelling choices, NOT bugs):
%     * D1: the model carries PHYSICAL CLmax = 2.0 in the takeoff config (USER
%       decision 2026-08-14), while the printed climb Eqs. 4.49-4.51 use 2.2 in
%       the takeoff slot. The takeoff-flap climbs therefore differ by ~ the
%       (2.2/2.0) CLmax factor. The report evaluates the printed Eqs. with 2.2
%       for parity and prints the model's 2.0-based value beside it.
%     * D5: the framework thrust lapse is ISA sigma^m; the printed ceiling/cruise
%       Eqs. 4.56/4.57 use off-ISA density ratios (0.2331, 0.2846). The report
%       evaluates the printed Eqs. with the PRINTED ratios for parity.
%     * TSFC: the generic Mattingly Eq. 10.11 gives ~0.675 at M0.84/40kft, ~30%
%       above the GE90's ~0.52. The model uses the Table 10.1 deck value (0.52)
%       so the mission closes; the report EVALUATES Eq. 10.11 to quantify the gap.
%     * Engine weight: Roskam Eq. 7.13-7.19 overestimates the real GE90; the
%       delta-weight model cancels it at the baseline design point.
%     * Design mission: metabook Example 2.1 -- 9,150 nmi cruise + 30-min loiter,
%       carrying 78,821 lbf (14 crew + 314 passengers x 109 kg). The converged
%       design weight is compared to the actual 777-200LR (MTOW 766,800 lbf =
%       347,815 kg page 17; OEW 320,000 lbf Table 7.4).

    sp = b777_spec_path(1);
    rp = b777_requirements_path();

    % Live B777 stack: L2 geometry (real trapezoidal planform + exposed areas,
    % metabook Table 7.2/7.3) and L2 component-build-up weights (Algorithm 5),
    % with L1 aero/prop/tail.
    geom = B777GeomL2(sp);
    prop = B777PropL1(sp);
    aero = B777AeroL1(geom, sp);
    tail = B777TailL1();
    wts  = B777WeightsL2(sp, geom, prop);

    fprintf('\n================ B777 vs METABOOK Example 4.2 (informational) ================\n');

    rows = {};   % each: struct(section, label, model, metabook, cite, note)

    % --------------------------------------------------------------------- %
    % 1. Drag-polar buildup [metabook Eqs. 4.42-4.44].
    % --------------------------------------------------------------------- %
    rows{end+1} = crow('Drag polar', 'S_wet [ft^2]', geom.S_wet, 28291, ...
        'metabook Eq. 4.42', 'S_wet_rest + 2*S_ref');
    polar = aero.drag_polar([]);   % clean; state unused at L1
    rows{end+1} = crow('Drag polar', 'clean CD0', polar.CD0, 0.01597, ...
        'metabook Eq. 4.44', 'Cfe*S_wet/S_ref');
    rows{end+1} = crow('Drag polar', 'clean K1', polar.K1, 0.03815, ...
        'metabook Eq. 2.10', '1/(pi*AR*e_clean)');

    % --------------------------------------------------------------------- %
    % 2. The five printed config polars [metabook §4.11 five-polar table].
    % --------------------------------------------------------------------- %
    cfg_names  = ["clean", "takeoff_flaps_gear_up", "takeoff_flaps_gear_down", ...
                  "landing_flaps_gear_up", "landing_flaps_gear_down"];
    cfg_CD0    = [0.01597, 0.03597, 0.06097, 0.09097, 0.11597];   % printed
    cfg_K1     = [0.03815, 0.04054, 0.04054, 0.04324, 0.04324];   % printed
    for i = 1:numel(cfg_names)
        cp = aero.get_config_polar(cfg_names(i));
        rows{end+1} = crow('Config polars', sprintf('%s CD0', cfg_names(i)), ...
            cp.CD0, cfg_CD0(i), 'metabook §4.11', ''); %#ok<*AGROW>
        rows{end+1} = crow('Config polars', sprintf('%s K1', cfg_names(i)), ...
            cp.K1, cfg_K1(i), 'metabook §4.11', '');
    end

    % --------------------------------------------------------------------- %
    % 3. Constraint values. Build the ten constraints once and index by name.
    % --------------------------------------------------------------------- %
    cons = ConstraintAnalysis.build_constraints(aero, prop, rp, ...
        B777ConstraintSet.constraint_map());
    con_names = cellfun(@(c) string(c.name), cons);   % 1xN string, constraint order

    % 3a. Landing field-length wall [metabook Eq. 4.46]: W/S = 113.27 * CLmax_L,
    %     CLmax_L = 2.6 -> 294.5 psf.
    lw = find_con(cons, con_names, "Landing Field Length");
    rows{end+1} = crow('Landing wall', 'WS_max [psf]', lw.WS_max(), 113.27*2.6, ...
        'metabook Eq. 4.46', '113.27*CLmax_L, CLmax_L=2.6');

    % 3b. Takeoff line slope [metabook Eq. 4.48]: T/W = (W/S)/(304*CLmax_TO), a
    %     line through the origin, so slope = required_TW(WS)/WS. CLmax_TO = 2.0
    %     -> slope = 1/(304*2.0) = 1/608.
    tk = find_con(cons, con_names, "Takeoff Field Length");
    WS_probe = 142.45;
    slope_model = tk.required_TW(WS_probe) / WS_probe;
    rows{end+1} = crow('Takeoff line', 'slope [1/psf]', slope_model, 1/(304*2.0), ...
        'metabook Eq. 4.48', 'T/W=(W/S)/(304*CLmax_TO), CLmax_TO=2.0');

    % 3c. The six climb T/W [metabook Eqs. 4.49-4.54]. Climbs are Only_TbyW
    %     (W/S-independent), so required_TW at any W/S is the constant value.
    %     Printed values below are the metabook Eqs. evaluated AS PRINTED (with
    %     CLmax=2.2 in the takeoff slot for Climbs 1-3 -- the D1 deviation).
    climb_names = { ...
        'Climb 1 (takeoff, FAR 25.111)', ...
        'Climb 2 (transition, FAR 25.121)', ...
        'Climb 3 (2nd segment, FAR 25.121)', ...
        'Climb 4 (enroute, FAR 25.121)', ...
        'Climb 5 (AEO balked landing, FAR 25.119)', ...
        'Climb 6 (OEI balked landing, FAR 25.121)'};
    climb_printed = [ ...
        (1/0.8)*(2/1)*(1.2^2/2.2*0.03597 + 2.2/1.2^2*0.04054 + 0.012), ...   % Eq. 4.49
        (1/0.8)*(2/1)*(1.15^2/2.2*0.06097 + 2.2/1.15^2*0.04054 + 0.0), ...   % Eq. 4.50
        (1/0.8)*(2/1)*(1.2^2/2.2*0.03597 + 2.2/1.2^2*0.04054 + 0.024), ...   % Eq. 4.51
        (1/0.8)*(1/0.94)*(2/1)*(1.25^2/0.9*0.01597 + 0.9/1.25^2*0.03815 + 0.012), ... % Eq. 4.52
        (1/0.8)*(0.65/1)*(1.3^2/2.6*0.11597 + 2.6/1.3^2*0.04324 + 0.032), ... % Eq. 4.53
        (1/0.8)*(2/1)*(0.65/1)*(1.5^2/(0.85*2.6)*0.08847 + (0.85*2.6)/1.5^2*0.04324 + 0.021)]; % Eq. 4.54
    climb_notes = { ...
        'D1: model uses CLmax=2.0, printed Eq. uses 2.2', ...
        'D1: model uses CLmax=2.0, printed Eq. uses 2.2', ...
        'D1: model uses CLmax=2.0, printed Eq. uses 2.2', ...
        'clean config, max-continuous 1/0.94', ...
        'AEO balked landing, 0.65 MLW/MTOW', ...
        'OEI balked landing, approach config'};
    for i = 1:numel(climb_names)
        cc = find_con(cons, con_names, string(climb_names{i}));
        rows{end+1} = crow('Climb T/W', sprintf('Eq. 4.%d %s', 48+i, short_climb(climb_names{i})), ...
            cc.required_TW(WS_probe), climb_printed(i), ...
            sprintf('metabook Eq. 4.%d', 48+i), climb_notes{i});
    end

    % 3d. Ceiling [metabook Eq. 4.56] and Cruise [metabook Eq. 4.57], evaluated
    %     with the PRINTED off-ISA density ratios for parity (D5). The model uses
    %     ISA sigma^m, so the model curve is a function of W/S; report both the
    %     printed scalar and the model's required_TW at the actual W/S = 142.45.
    e_cl = 0.85; AR = 9.8; CD0_cl = 0.01597;
    ceiling_printed = 1/0.2331^0.6 * (0.001 + 2*sqrt(CD0_cl/(pi*AR*e_cl)));   % Eq. 4.56
    cruise_printed  = 1/0.2846^0.6 * (228.8*CD0_cl/WS_probe ...
                        + WS_probe*1/(228.8*pi*AR*e_cl));                     % Eq. 4.57
    ce = find_con(cons, con_names, "Ceiling");
    cr = find_con(cons, con_names, "Cruise");
    rows{end+1} = crow('Ceiling', 'T/W (at W/S=142.45)', ce.required_TW(WS_probe), ceiling_printed, ...
        'metabook Eq. 4.56', 'D5: model ISA sigma^m vs printed 0.2331^0.6');
    rows{end+1} = crow('Cruise', 'T/W (at W/S=142.45)', cr.required_TW(WS_probe), cruise_printed, ...
        'metabook Eq. 4.57', 'D5: model ISA sigma^m vs printed 0.2846^0.6');

    % --------------------------------------------------------------------- %
    % 4. TSFC gap [metabook Eq. 10.11 vs Table 10.1 deck].
    % --------------------------------------------------------------------- %
    st_cruise = AircraftState(40000, 0.84);
    tsfc_1011 = PropL1.tsfc_mattingly_hibpr(st_cruise);   % generic Eq. 10.11
    tsfc_deck = prop.get_TSFC(st_cruise);                 % 0.52 [Table 10.1]
    rows{end+1} = crow('TSFC', 'cruise TSFC [1/hr]', tsfc_deck, tsfc_1011, ...
        'metabook Table 10.1 vs Eq. 10.11', ...
        sprintf('Eq. 10.11 overestimates the GE90 deck by %+.1f%%', ...
            100*(tsfc_1011 - tsfc_deck)/tsfc_deck));

    % --------------------------------------------------------------------- %
    % 5. Converged design vs actual 777 [converge_W0 at S=4605, T=220000].
    % --------------------------------------------------------------------- %
    miss = MissionAnalysisL1.from_requirements(aero, prop, geom, rp, "long_range");
    con  = ConstraintAnalysis.from_requirements(aero, prop, rp, ...
        B777ConstraintSet.constraint_map(), linspace(60, 300, 241));
    ts = TSDiagram(aero, prop, wts, geom, miss, con, tail);
    W0_conv = ts.converge_W0(220000, 4605);
    % After converge_W0 the stack sits at the converged cell state.
    OEW_conv  = wts.OEW(W0_conv);
    [Wf_conv, ~] = miss.total_fuel(W0_conv);
    WS_conv = W0_conv / geom.S_ref;
    TW_conv = 220000 / W0_conv;

    rows{end+1} = crow('Converged design', 'W_TO [lbf]', W0_conv, 766800, ...
        'metabook p.17 / Table 4.3 (actual MTOW)', 'Example 2.1: 9150 nmi, 78,821 lb (14 crew + 314 pax @ 109 kg)');
    rows{end+1} = crow('Converged design', 'OEW [lbf]', OEW_conv, 320000, ...
        'metabook Table 7.4 (actual OEW)', 'Ch.7 component build-up (Algorithm 5) at T_SL=220k; +4% = Roskam GE90 over-prediction');
    rows{end+1} = crow('Converged design', 'W_fuel [lbf]', Wf_conv, NaN, ...
        'metabook §4.12 Algorithm 3', 'L1 mission long_range fuel (9150 nmi cruise + 30-min loiter + 6% reserve)');
    rows{end+1} = crow('Converged design', 'W/S [psf]', WS_conv, 142.45, ...
        'metabook Table 4.3', '');
    rows{end+1} = crow('Converged design', 'T/W', TW_conv, 220000/766800, ...
        'metabook Fig. 4.7', '');

    % --------------------------------------------------------------------- %
    % Console table + exports.
    % --------------------------------------------------------------------- %
    print_table(rows);
    results = struct();
    results.rows = rows;   % scalar struct; .rows is the 1xN cell of row structs
    write_exports(results);
    fprintf('\nWrote output/b777_metabook_comparison.md and .json\n');
end

% ------------------------------------------------------------------------- %
function r = crow(section, label, model, metabook, cite, note)
%CROW  One comparison row. pct is NaN when metabook is NaN (no printed target).
    if isnan(metabook)
        pct = NaN;
    else
        pct = 100 * (model - metabook) / metabook;
    end
    r = struct('section', section, 'label', label, 'model', model, ...
        'metabook', metabook, 'pct', pct, 'cite', cite, 'note', note);
end

% ------------------------------------------------------------------------- %
function c = find_con(cons, con_names, name)
%FIND_CON  The constraint object whose .name matches, from the built cell array.
%   Errors if the name is absent -- a typo guard, so a mis-typed lookup fails
%   loudly rather than silently comparing against the wrong constraint.
    idx = find(con_names == name, 1);
    if isempty(idx)
        error('b777_metabook_comparison:constraintNotFound', ...
            'No built constraint named "%s" (have: %s).', name, ...
            strjoin(con_names, ', '));
    end
    c = cons{idx};
end

% ------------------------------------------------------------------------- %
function s = short_climb(name)
%SHORT_CLIMB  Trim the "Climb N (" prefix for a compact table label.
    tok = regexp(name, '\((.*)\)', 'tokens', 'once');
    if isempty(tok), s = name; else, s = tok{1}; end
end

% ------------------------------------------------------------------------- %
function print_table(rows)
    fprintf('\n  %-16s %-26s %14s %14s %9s  %s\n', ...
        'Section', 'Quantity', 'Model', 'Metabook', 'Delta%', 'Note');
    fprintf('  %s\n', repmat('-', 1, 110));
    for i = 1:numel(rows)
        r = rows{i};
        if isnan(r.metabook)
            mb = '   (none)'; pc = '     -';
        else
            mb = sprintf('%14.5g', r.metabook); pc = sprintf('%+8.2f', r.pct);
        end
        fprintf('  %-16s %-26s %14.5g %14s %9s  %s\n', ...
            r.section, r.label, r.model, mb, pc, r.note);
    end
end

% ------------------------------------------------------------------------- %
function write_exports(results)
    outdir = fullfile(fileparts(mfilename('fullpath')), '..', 'output');
    if ~exist(outdir, 'dir'), mkdir(outdir); end

    % JSON
    fid = fopen(fullfile(outdir, 'b777_metabook_comparison.json'), 'w');
    fwrite(fid, jsonencode(results, 'PrettyPrint', true));
    fclose(fid);

    % Markdown
    rows = results.rows;
    L = strings(0, 1);
    L(end+1) = "# B777 vs Metabook Example 4.2 (informational)";
    L(end+1) = "";
    L(end+1) = "B777 L1 model vs the PRINTED metabook Example 4.2 numbers. Informational only";
    L(end+1) = "(not pass/fail). See `sanity_checks/b777_metabook_comparison.m`.";
    L(end+1) = "";
    L(end+1) = "| Section | Quantity | Model | Metabook | Delta% | Cite | Note |";
    L(end+1) = "|---|---|--:|--:|--:|---|---|";
    for i = 1:numel(rows)
        r = rows{i};
        if isnan(r.metabook)
            mb = "(none)"; pc = "-";
        else
            mb = sprintf("%.5g", r.metabook); pc = sprintf("%+.2f", r.pct);
        end
        L(end+1) = "| " + r.section + " | " + r.label + " | " + ...
            sprintf("%.5g", r.model) + " | " + mb + " | " + pc + " | " + ...
            r.cite + " | " + r.note + " |";
    end
    writelines(L, fullfile(outdir, 'b777_metabook_comparison.md'));
end
