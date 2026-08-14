function results = sizing_brandt_comparison()
%SIZING_BRANDT_COMPARISON  Informational sizing-loop report, all rungs vs Brandt.
%
%   Runs the five sizing rungs -- the Brandt validation stack through
%   SizingLoopL1/L2 (f16_sizing_brandt_L1/L2) and the three framework
%   discipline stacks (f16_sizing_L1/L2/L3) -- and tabulates each converged
%   result (W_TO, OEW, W_fuel, S_ref, T_SL, W/S, T/W) against the Brandt
%   ground truth with %-diffs.
%
%   INFORMATIONAL ONLY -- not a pass/fail unit test, and never used to
%   backfill a unit test's expected value (the CLAUDE.md two-tier rule).
%   Prints a console table and writes examples/F16A/output/
%   sizing_brandt_comparison.md + .json. Each rung is wrapped in try/catch,
%   so one failing rung still lets the others report (the error is printed
%   and recorded).
%
%   GROUND TRUTH [VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json unless
%   noted]:
%     W_TO   = 31,377.00 lbf  [.weights.summary.TOGW  -- Brandt Wt!B3/B38]
%     OEW    = 19,980.70 lbf  [.weights.summary.OEW   -- Brandt Wt!B12]
%     W_fuel =  6,296.30 lbf  [.weights.summary.fuel  -- Brandt Wt!B6]
%     S_ref  =    300 ft^2    [Brandt Main!B18]
%     T_SL   = 23,770 lbf     [.propulsion.T_SL_wet_lb -- Brandt Engn!T_AB_SLS]
%     W/S    = 104.59 psf, T/W = 0.7576  [Brandt Size&Opt sheet;
%              GroundTruth/cell-map.md Size!W_S / Size!T_W]
%
%   EXPECTED DIVERGENCES (BY DESIGN, annotated per rung below -- not bugs):
%   (a) The brandt_* rungs sit ~+1.5-2% high on W_TO: the framework L2
%       mission GENERALIZES Brandt's method (accel via the drag+energy
%       master equation, standard dynamic pressure -- no Miss!C13 form, no
%       q_43 override), burning ~6,532 lb vs the Miss-tab 6,000.43 (+8.9%)
%       at fixed W_TO -- see mission_brandt_comparison.m.
%   (b) The ground-truth W_fuel = 6,296.30 is Brandt Wt!B6, a RESIDUAL
%       (W_TO - payloads - OEW), while the framework mission computes the
%       Miss-tab REQUIREMENT basis (6,000.43 at W_TO = 31,377) -- so even a
%       perfect mission reproduction would show ~-4.7% on this row.
%   (c) The framework_* rung gaps are DISCIPLINE fidelity (statistical L1
%       regressions, the L2/L3 aero/weights models), not sizing-loop bugs;
%       the loop logic is isolated by the brandt_* rungs above them.
%   (d) ENVELOPE MINIMUM vs ACTUAL-AIRCRAFT MARGIN (measured 2026-08-14).
%       Brandt's (W/S, T/W) = (104.59, 0.7576) is the ACTUAL F-16A
%       (0.7576 = 23,770/31,377), which sits ~5.3% ABOVE the constraint
%       envelope: the envelope over the Brandt aero/prop evaluates to
%       T/W ~= 0.719 at 104.59 and bottoms out at ~(110.8, 0.712). The
%       sizing loops, by definition [Raymer ch. 5; Martins slides 6/8],
%       pick the ENVELOPE MINIMUM -- the real aircraft carries thrust
%       margin the loops do not. Expect W/S ~+6% and T/W ~-6% on every
%       rung, and (through the engine-weight term) a systematic pull-down
%       on W_TO.
%   (e) TAIL-SIZING GAP (measured 2026-08-14). The volume-coefficient
%       method (F16TailL1: c_HT = 0.315 / c_VT = 0.063, arm 0.475*L_fus)
%       predicts S_ht ~ 48.4 / S_vt ~ 25.7 ft^2 at the Brandt planform --
%       less than half the actual 108 / 60 ft^2 [Brandt Main!C18/H18].
%       Lighter tails -> lower OEW -> lower W_TO on the L2 rungs. A
%       tail-sizing-DISCIPLINE finding, not a loop bug.

    % ---- Ground truth ---------------------------------------------------- %
    script_dir  = fileparts(mfilename('fullpath'));
    sizing_root = fileparts(fileparts(fileparts(script_dir)));
    gt_path     = fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth', 'f16a_ground_truth.json');
    gt          = jsondecode(fileread(gt_path));

    GT = struct( ...
        'W_TO',   gt.weights.summary.TOGW.value, ...    % 31,377.00 [Brandt Wt!B3]
        'W_OEW',  gt.weights.summary.OEW.value, ...     % 19,980.70 [Brandt Wt!B12]
        'W_fuel', gt.weights.summary.fuel.value, ...    %  6,296.30 [Brandt Wt!B6, RESIDUAL -- note (b)]
        'S_ref',  300, ...                              % ft^2 [Brandt Main!B18]
        'T_SL',   gt.propulsion.T_SL_wet_lb.value, ...  % 23,770 [Brandt Engn!T_AB_SLS]
        'WS',     104.59, ...                           % psf [Brandt Size&Opt; cell-map.md Size!W_S]
        'TW',     0.7576);                              % [Brandt Size&Opt; cell-map.md Size!T_W]

    metrics = ["W_TO", "W_OEW", "W_fuel", "S_ref", "T_SL", "WS", "TW"];

    % ---- The five rungs (defaults of each study function) ---------------- %
    rungs = { ...
        struct('name', "brandt_L1",    'fn', @() f16_sizing_brandt_L1(), ...
               'note', "Brandt disciplines + framework mission/constraints, SizingLoopL1. W_TO ~+1.5-2% BY DESIGN -- note (a)."), ...
        struct('name', "brandt_L2",    'fn', @() f16_sizing_brandt_L2(), ...
               'note', "Brandt disciplines + framework mission/constraints, SizingLoopL2 (live tail + wing resize). W_TO ~-5% BY DESIGN -- notes (a)+(d)+(e): +2% mission, -6% envelope-margin wing/engine shrink, lighter volume-coefficient tails."), ...
        struct('name', "framework_L1", 'fn', @() f16_sizing_L1(), ...
               'note', "Framework L1 disciplines. Gaps are L1 discipline fidelity -- note (c)."), ...
        struct('name', "framework_L2", 'fn', @() f16_sizing_L2(), ...
               'note', "Framework L2 disciplines. Gaps are L2 discipline fidelity -- note (c)."), ...
        struct('name', "framework_L3", 'fn', @() f16_sizing_L3(), ...
               'note', "Framework L3 disciplines (F16PropL2 -- no L3 propulsion tier). Gaps are discipline fidelity -- note (c).")};

    rows = struct('name', {}, 'ok', {}, 'err', {}, 'converged', {}, ...
        'n_iter', {}, 'vals', {}, 'note', {});
    for k = 1:numel(rungs)
        r = rungs{k};
        row = struct('name', r.name, 'ok', false, 'err', "", ...
            'converged', false, 'n_iter', NaN, 'vals', nan(1, numel(metrics)), ...
            'note', r.note);
        try
            res = r.fn();
            row.ok        = true;
            row.converged = res.converged;
            row.n_iter    = res.n_iter;
            row.vals = [res.W_TO, res.W_OEW, res.W_fuel, res.S_ref, ...
                res.T_SL, res.WS, res.TW];
        catch ME
            row.err = string(ME.message);
            fprintf('  [%s] FAILED: %s\n', r.name, ME.message);
        end
        rows(end+1) = row; %#ok<AGROW>
    end

    % ---- Console tables --------------------------------------------------- %
    gt_vals = cellfun(@(m) GT.(m), num2cell(metrics));
    fprintf('\n================ SIZING-LOOP COMPARISON vs BRANDT (informational) ================\n');
    fprintf('%-8s %12s', 'Metric', 'GroundTruth');
    for k = 1:numel(rows), fprintf('%15s', rows(k).name); end
    fprintf('\n');
    for i = 1:numel(metrics)
        fprintf('%-8s %12.4f', metrics(i), gt_vals(i));
        for k = 1:numel(rows), fprintf('%15.4f', rows(k).vals(i)); end
        fprintf('\n');
    end
    fprintf('\n%-8s %12s', '%Diff', '');
    for k = 1:numel(rows), fprintf('%15s', rows(k).name); end
    fprintf('\n');
    for i = 1:numel(metrics)
        fprintf('%-8s %12s', metrics(i), '');
        for k = 1:numel(rows)
            fprintf('%+14.2f%%', 100 * (rows(k).vals(i) - gt_vals(i)) / gt_vals(i));
        end
        fprintf('\n');
    end
    fprintf('\nPer-rung status and BY-DESIGN annotations:\n');
    for k = 1:numel(rows)
        if rows(k).ok
            fprintf('  [%s] converged=%d, n_iter=%d. %s\n', ...
                rows(k).name, rows(k).converged, rows(k).n_iter, rows(k).note);
        else
            fprintf('  [%s] RUN FAILED: %s\n', rows(k).name, rows(k).err);
        end
    end
    fprintf(['\nW_fuel row caveat: ground truth 6,296.30 is the Wt!B6 RESIDUAL; the framework\n' ...
             'mission computes the Miss-tab REQUIREMENT basis (6,000.43) -- note (b) in the header.\n']);

    results = struct('ground_truth', GT, 'metrics', metrics, 'rungs', rows);

    % ---- Exports (output/ pattern shared with the other *_brandt_comparison) %
    outdir = fullfile(script_dir, '..', 'output');
    if ~exist(outdir, 'dir'), mkdir(outdir); end

    fid = fopen(fullfile(outdir, 'sizing_brandt_comparison.json'), 'w');
    fwrite(fid, jsonencode(results, 'PrettyPrint', true));
    fclose(fid);

    L = strings(0, 1);
    L(end+1) = "# Sizing-Loop Comparison vs Brandt (informational)";
    L(end+1) = "";
    L(end+1) = "Informational only (never pass/fail). See sizing_brandt_comparison.m's header for the";
    L(end+1) = "ground-truth citations and the three BY-DESIGN divergence notes (a)/(b)/(c).";
    L(end+1) = "";
    hdr = "| Metric | Ground truth |"; sep = "|---|--:|";
    for k = 1:numel(rows), hdr = hdr + " " + rows(k).name + " |"; sep = sep + "--:|"; end
    L(end+1) = hdr; L(end+1) = sep;
    for i = 1:numel(metrics)
        row_s = "| " + metrics(i) + sprintf(" | %.4f |", gt_vals(i));
        for k = 1:numel(rows)
            row_s = row_s + sprintf(" %.4f (%+.2f%%) |", rows(k).vals(i), ...
                100 * (rows(k).vals(i) - gt_vals(i)) / gt_vals(i));
        end
        L(end+1) = row_s;
    end
    L(end+1) = "";
    for k = 1:numel(rows)
        if rows(k).ok
            L(end+1) = sprintf("- **%s** (converged=%d, n_iter=%d): %s", ...
                rows(k).name, rows(k).converged, rows(k).n_iter, rows(k).note);
        else
            L(end+1) = sprintf("- **%s**: RUN FAILED -- %s", rows(k).name, rows(k).err);
        end
    end
    writelines(L, fullfile(outdir, 'sizing_brandt_comparison.md'));
    fprintf('\nWrote output/sizing_brandt_comparison.md and .json\n');
end
