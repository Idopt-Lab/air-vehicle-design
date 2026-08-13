function results = mission_brandt_comparison()
%MISSION_BRANDT_COMPARISON  Informational cross-fidelity mission fuel report.
%
%   Runs the two mission-analysis fidelities (MissionAnalysisL1 / L2) over the
%   two mission profiles (CAP, Brandt-14) and the four discipline stacks
%   (L1, L2, L3, Brandt), all at a FIXED takeoff gross weight of 31,377 lbf, and
%   tabulates the per-segment fuel burn, the total burn, and the key drivers
%   (L/D, TSFC) that go into it -- to compare fidelities and debug the numbers.
%
%   INFORMATIONAL ONLY -- not a pass/fail unit test, and never used to backfill
%   a unit test's expected value (that separation is the CLAUDE.md two-tier
%   rule). Prints console tables and writes examples/F16A/output/
%   mission_brandt_comparison.md + .json.
%
%   Combos run:
%     L1 mission x CAP           x {disc-L1, disc-L2, disc-L3, Brandt}
%     L2 mission x {CAP, Brandt-14} x {disc-L1, disc-L2, disc-L3, Brandt}
%   (L1 mission handles only the CAP segment types; the 14-seg accel/patrol/
%   egress legs are L2-only, so L1 x Brandt-14 is intentionally skipped.)
%
%   Ground truth: Brandt Miss-tab total = 6000.43 lb (14-seg mission).
%
%   EXPECTED Brandt-stack divergence (INFORMATIONAL, by design -- not a bug):
%   the L2 x Brandt x brandt_14seg total runs ~6532 lb (+8.9% vs the 6000.43 lb
%   ground truth). The L2 form generalizes Brandt's method -- it handles accel
%   with the drag+energy master equation and uses the standard dynamic pressure,
%   not Brandt's Miss!C13 thrust-accel form or its q_43 override -- so accel and
%   climb run high while the other legs track to within a few percent.

    W_TO = 31377.0;
    req  = f16a_requirements_path();

    combos = { ...
        struct('miss', "L1", 'profile', "cap",          'stacks', ["disc-L1","disc-L2","disc-L3","Brandt"]), ...
        struct('miss', "L2", 'profile', "cap",          'stacks', ["disc-L1","disc-L2","disc-L3","Brandt"]), ...
        struct('miss', "L2", 'profile', "brandt_14seg", 'stacks', ["disc-L1","disc-L2","disc-L3","Brandt"]) };

    results = struct('W_TO', W_TO, 'runs', {{}});
    fprintf('\n================ MISSION FUEL COMPARISON (W_TO = %.0f lbf) ================\n', W_TO);

    for c = 1:numel(combos)
        combo = combos{c};
        fprintf('\n\n#### %s mission  x  profile "%s" ####\n', combo.miss, combo.profile);

        per_stack = struct('stack', {}, 'names', {}, 'fuel', {}, 'LD', {}, 'TSFC', {}, ...
            'raw_burn', {}, 'W_fuel', {});
        for sn = combo.stacks
            r = run_one(combo.miss, combo.profile, sn, req, W_TO);
            if isempty(r)
                fprintf('  [%s] skipped (build/run error)\n', sn);
                continue
            end
            per_stack(end+1) = r; %#ok<AGROW>
        end
        if isempty(per_stack), continue; end

        print_fuel_table(per_stack);
        print_debug_table(per_stack);

        run_rec = struct('mission_fidelity', combo.miss, 'profile', combo.profile, ...
            'stacks', per_stack);
        results.runs{end+1} = run_rec;
    end

    write_exports(results);
    fprintf('\nWrote output/mission_brandt_comparison.md and .json\n');
end

% ------------------------------------------------------------------------- %
function r = run_one(missLv, profile, stackName, req, W_TO)
    r = [];
    try
        S = make_stack(stackName);
        switch missLv
            case "L1", m = MissionAnalysisL1.from_requirements(S.aero, S.prop, S.geom, req, profile);
            case "L2", m = MissionAnalysisL2.from_requirements(S.aero, S.prop, S.geom, req, profile);
        end
        [Wf, bd] = m.total_fuel(W_TO);

        n = numel(bd.names);
        LD = nan(1, n); TSFC = nan(1, n);
        for i = 1:n
            d = bd.debug{i};
            if isfield(d, 'LD'),          LD(i)   = d.LD; end
            if isfield(d, 'TSFC_per_hr'), TSFC(i) = d.TSFC_per_hr; end
        end
        r = struct('stack', stackName, 'names', bd.names, 'fuel', bd.fuel_lbf, ...
            'LD', LD, 'TSFC', TSFC, 'raw_burn', bd.raw_burn, 'W_fuel', Wf);
    catch ME
        fprintf('    (error on %s: %s)\n', stackName, ME.message);
    end
end

% ------------------------------------------------------------------------- %
function S = make_stack(name)
    switch name
        case "disc-L1"
            p = F16PropL1(f16a_spec_path(1));
            g = F16GeomL1(f16a_spec_path(1), f16a_requirements_path()); g.W_TO = 31377;
            a = F16AeroL1(f16a_spec_path(1));
        case "disc-L2"
            p = F16PropL2(f16a_spec_path(2));
            g = F16GeomL2(f16a_spec_path(2), p);
            a = F16AeroL2(g, f16a_spec_path(2));
        case "disc-L3"
            p = F16PropL2(f16a_spec_path(2));               % no L3 propulsion tier
            g = F16GeomL3(f16a_spec_path(3), p);
            a = F16AeroL3(g, f16a_spec_path(3));
        case "Brandt"
            bg = BrandtGeometry();     bg.analyze();
            ba = BrandtAerodynamics(bg); ba.analyze();
            be = BrandtEngine();        be.analyze();
            a = BrandtAeroAdapter(ba); p = BrandtPropAdapter(be); g = BrandtMissionGeomAdapter(bg);
    end
    S = struct('aero', a, 'prop', p, 'geom', g);
end

% ------------------------------------------------------------------------- %
function print_fuel_table(per_stack)
    names = per_stack(1).names;
    fprintf('\n  Per-segment fuel [lb]\n');
    fprintf('  %-9s', 'Segment');
    for s = 1:numel(per_stack), fprintf('%11s', per_stack(s).stack); end
    fprintf('\n');
    for i = 1:numel(names)
        fprintf('  %-9s', names(i));
        for s = 1:numel(per_stack), fprintf('%11.1f', per_stack(s).fuel(i)); end
        fprintf('\n');
    end
    fprintf('  %-9s', 'RAW BURN');
    for s = 1:numel(per_stack), fprintf('%11.1f', per_stack(s).raw_burn); end
    fprintf('\n');
    fprintf('  %-9s', 'W_fuel+re');
    for s = 1:numel(per_stack), fprintf('%11.1f', per_stack(s).W_fuel); end
    fprintf('\n');
end

% ------------------------------------------------------------------------- %
function print_debug_table(per_stack)
    names = per_stack(1).names;
    fprintf('\n  Debug L/D (top) and TSFC [1/hr] (bottom) per segment\n');
    for s = 1:numel(per_stack)
        fprintf('  %-9s L/D :', per_stack(s).stack);
        for i = 1:numel(names)
            if isnan(per_stack(s).LD(i)), fprintf('%8s', '-'); else, fprintf('%8.2f', per_stack(s).LD(i)); end
        end
        fprintf('\n  %-9s TSFC:', '');
        for i = 1:numel(names)
            if isnan(per_stack(s).TSFC(i)), fprintf('%8s', '-'); else, fprintf('%8.3f', per_stack(s).TSFC(i)); end
        end
        fprintf('\n');
    end
end

% ------------------------------------------------------------------------- %
function write_exports(results)
    outdir = fullfile(fileparts(mfilename('fullpath')), '..', 'output');
    if ~exist(outdir, 'dir'), mkdir(outdir); end

    % JSON
    fid = fopen(fullfile(outdir, 'mission_brandt_comparison.json'), 'w');
    fwrite(fid, jsonencode(results, 'PrettyPrint', true));
    fclose(fid);

    % Markdown
    L = strings(0, 1);
    L(end+1) = "# Mission Fuel Comparison (informational)";
    L(end+1) = "";
    L(end+1) = sprintf("Fixed W_TO = %.0f lbf. Brandt Miss-tab ground-truth total = 6000.43 lb.", results.W_TO);
    L(end+1) = "Informational only (not pass/fail). See mission_brandt_comparison.m.";
    for k = 1:numel(results.runs)
        rn = results.runs{k};
        L(end+1) = "";
        L(end+1) = sprintf("## %s mission x profile `%s`", rn.mission_fidelity, rn.profile);
        L(end+1) = "";
        hdr = "| Segment |";
        sep = "|---|";
        for s = 1:numel(rn.stacks), hdr = hdr + " " + rn.stacks(s).stack + " |"; sep = sep + "--:|"; end
        L(end+1) = hdr; L(end+1) = sep;
        nm = rn.stacks(1).names;
        for i = 1:numel(nm)
            row = "| " + nm(i) + " |";
            for s = 1:numel(rn.stacks), row = row + sprintf(" %.1f |", rn.stacks(s).fuel(i)); end
            L(end+1) = row;
        end
        row = "| **RAW BURN** |";
        for s = 1:numel(rn.stacks), row = row + sprintf(" **%.1f** |", rn.stacks(s).raw_burn); end
        L(end+1) = row;
    end
    writelines(L, fullfile(outdir, 'mission_brandt_comparison.md'));
end
