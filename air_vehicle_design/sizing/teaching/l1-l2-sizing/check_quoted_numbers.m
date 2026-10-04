function ok = check_quoted_numbers(pkg)
%CHECK_QUOTED_NUMBERS  Re-derive every number the teaching material quotes.
%
%   ok = CHECK_QUOTED_NUMBERS() runs against the built student_package and
%   compares each result with the value written into the guide, the lecture
%   Live Scripts and the worksheet.
%
%   Run this after every `git pull`. The framework is a live codebase; a
%   change to WeightsL2 or F16GeomL2 moves the sized aircraft, and then the
%   prose quotes a number the code no longer produces. The lab still PASSES
%   when that happens -- the checker compares a student loop against
%   SizingLoopL2, and both move together -- so nothing else catches it.

    arguments
        pkg (1,1) string = string(fullfile(fileparts(mfilename('fullpath')), 'student_package'))
    end

    oldPath = path; oldDir = pwd;
    cleaner = onCleanup(@() restore_state(oldPath, oldDir)); %#ok<NASGU>
    restoredefaultpath; addpath(pkg); cd(pkg); setup_sizing_path();

    % name, got, want, relative tolerance, where it is quoted
    E = {};
    add = @(n,got,want,rtol,where) {n,got,want,rtol,where};

    % ---------------- B777, Level-1 loop -----------------------------------
    [a,p,w,g,m,c] = build_b777_stack();
    r1 = SizingLoopL1(a,p,w,g,m,c).run(700000);
    E(end+1,:) = add("B777 L1 W_TO",   r1.W_TO,   740125,  1e-3, "guide 9.4, L05");
    E(end+1,:) = add("B777 L1 T_SL",   r1.T_SL,   196671,  1e-3, "guide 9.4, L05");
    E(end+1,:) = add("B777 L1 S_ref",  r1.S_ref,  4597,    1e-3, "guide 9.4, L05");
    E(end+1,:) = add("B777 L1 passes", r1.n_iter, 14,      0,    "guide 9.4");

    % ---------------- B777, Level-2 loop -----------------------------------
    [a,p,w,g,m,c,t] = build_b777_stack();
    r2 = SizingLoopL2(a,p,w,g,m,c,t).run(700000, 200000);
    E(end+1,:) = add("B777 L2 W_TO",   r2.W_TO,   740060,  1e-3, "guide 9.4, L06");
    E(end+1,:) = add("B777 L2 T_SL",   r2.T_SL,   196674,  1e-3, "guide 9.4, L06");
    E(end+1,:) = add("B777 L2 S_ref",  r2.S_ref,  4598.5,  1e-3, "guide 9.4, L06");
    E(end+1,:) = add("B777 L2 S_ht",   r2.S_ht,   907.8,   1e-3, "guide 9.4, L06");
    E(end+1,:) = add("B777 L2 S_vt",   r2.S_vt,   800.7,   1e-3, "guide 9.4, L06");
    E(end+1,:) = add("B777 L2 passes", r2.n_iter, 52,      0,    "guide 9.4");

    % ---------------- B777, the bad-start test -----------------------------
    [a,p,w,g,m,c] = build_b777_stack();  g.S_ref = 2600;
    r1b = SizingLoopL1(a,p,w,g,m,c).run(700000);
    E(end+1,:) = add("B777 L1 bad-start W_TO", r1b.W_TO, 761614, 1e-3, "guide 9.4, L06");
    E(end+1,:) = add("B777 L1 bad-start WS",   r1b.WS,   170.00, 1e-3, "guide 9.4, L06");
    E(end+1,:) = add("B777 L1 bad-start TW",   r1b.TW,   0.28068,1e-3, "guide 9.4, L06");
    [a,p,w,g,m,c,t] = build_b777_stack();  g.S_ref = 2600;
    r2b = SizingLoopL2(a,p,w,g,m,c,t).run(700000, 200000);
    E(end+1,:) = add("B777 L2 bad-start W_TO", r2b.W_TO, 739821, 1e-3, "guide 9.4, L06");

    % ---------------- F-16A ------------------------------------------------
    [a,p,w,g,m,c] = build_f16_stack_L1();
    f1 = SizingLoopL1(a,p,w,g,m,c).run(30000);
    E(end+1,:) = add("F16 L1 W_TO",  f1.W_TO,  26762,  1e-3, "LAB00");
    E(end+1,:) = add("F16 L1 S_ref", f1.S_ref, 235.18, 1e-3, "LAB00");

    [a,p,w,g,m,c,t] = build_f16_stack_L2();
    f2 = SizingLoopL2(a,p,w,g,m,c,t).run(30000, 20000);
    E(end+1,:) = add("F16 L2 W_TO",   f2.W_TO,   23279.4, 1e-4, "guide 12, LAB01, L06b");
    E(end+1,:) = add("F16 L2 T_SL",   f2.T_SL,   20112.5, 1e-4, "guide 12, LAB01");
    E(end+1,:) = add("F16 L2 S_ref",  f2.S_ref,  175.02,  1e-4, "LAB01");
    E(end+1,:) = add("F16 L2 passes", f2.n_iter, 14,      0,    "L06b");

    % ---------------- the L06b trace claims --------------------------------
    T = trace_sizing_L2(@build_f16_stack_L2, 30000, 20000);
    E(end+1,:) = add("F16 trace WS first",   T.WS(1),   129.53, 1e-3, "L06b, guide 10.2");
    E(end+1,:) = add("F16 trace WS last",    T.WS(end), 133.01, 1e-3, "L06b, guide 10.2");
    E(end+1,:) = add("F16 trace TW first",   T.TW(1),   0.69659,1e-3, "L06b, guide 10.2");
    E(end+1,:) = add("F16 trace TW last",    T.TW(end), 0.86396,1e-3, "L06b, guide 10.2");
    E(end+1,:) = add("F16 S_wet/S_ref first",T.S_wet_S_ref(1),   5.0905, 1e-3, "L06b, guide 10.3");
    E(end+1,:) = add("F16 S_wet/S_ref last", T.S_wet_S_ref(end), 6.1828, 1e-3, "L06b, guide 10.3");
    E(end+1,:) = add("F16 CD0 rise [%]", 100*(T.CD0(end)-T.CD0(1))/T.CD0(1), 21.458, 2e-3, "L06b, guide 10.3");

    % ---------------- the B777 tail-is-write-only finding ------------------
    [~,~,w7,g7,~,~,t7] = build_b777_stack();
    tr = t7.size(); g7.S_ht = tr.S_ht; g7.S_vt = tr.S_vt; w7.W_TO = 740000;
    base = [g7.S_exposed_ht, g7.S_wet, w7.W_tail.HT, w7.get_OEW(740000)];
    g7.S_ht = 2*tr.S_ht;
    dbl  = [g7.S_exposed_ht, g7.S_wet, w7.W_tail.HT, w7.get_OEW(740000)];
    E(end+1,:) = add("B777 tail coupling (must be 0)", max(abs(dbl-base)), 0, 0, "guide 9.4, 10.4, L06, L06b");

    % ---------------- growth factor and elasticity -------------------------
    r0 = r2;
    den = 1 - r0.W_OEW/r0.W_TO - r0.W_fuel/r0.W_TO;
    E(end+1,:) = add("B777 1/denom", 1/den, 9.3891, 1e-3, "guide 11, L07");
    s = build_b777_stack_s();
    s.wts.W_payload_fixed = s.wts.W_payload_fixed + 5000;
    rg = SizingLoopL2(s.aero,s.prop,s.wts,s.geom,s.miss,s.con,s.tail).run(700000,200000);
    E(end+1,:) = add("B777 growth factor", (rg.W_TO-r0.W_TO)/5000, 3.2601, 2e-3, "guide 11, L07");

    % ---------------- report -----------------------------------------------
    nm = string(E(:,1)); got = cell2mat(E(:,2)); want = cell2mat(E(:,3));
    rtol = cell2mat(E(:,4)); where = string(E(:,5));
    reldiff = abs(got - want) ./ max(abs(want), eps);
    pass = (want == 0 & abs(got) <= 1e-9) | (reldiff <= rtol) | (rtol == 0 & got == want);

    R = table(got, want, reldiff, pass, where, 'RowNames', cellstr(nm), ...
        'VariableNames', ["Now", "Quoted", "RelDiff", "Pass", "Quoted_in"]);
    disp(R);

    ok = all(pass);
    if ok
        fprintf('\n  ALL %d QUOTED NUMBERS STILL HOLD.\n\n', numel(pass));
    else
        fprintf('\n  %d of %d QUOTED NUMBERS HAVE MOVED.\n', sum(~pass), numel(pass));
        fprintf('  The code changed under the prose. Update the files listed\n');
        fprintf('  in Quoted_in, then rebuild.\n\n');
    end
end

function restore_state(p, d)
    path(p); cd(d); close all force
end
