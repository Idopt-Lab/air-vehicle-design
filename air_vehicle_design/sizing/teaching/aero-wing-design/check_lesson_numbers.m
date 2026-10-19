function ok = check_lesson_numbers(pkg)
%CHECK_LESSON_NUMBERS  Re-derive every number that the lesson text quotes.
%
%   ok = CHECK_LESSON_NUMBERS() runs the helpers in student_package and
%   compares each result with the value written in the Live Script text
%   (mlx_src) and in the lab solution. Run it after any change to a helper:
%   the scripts still run when a number moves, so nothing else catches a
%   text that quotes an old value.

    arguments
        pkg (1,1) string = string(fullfile(fileparts(mfilename('fullpath')), 'student_package'))
    end

    oldPath = path;  oldDir = pwd;
    cleaner = onCleanup(@() restore_state(oldPath, oldDir)); %#ok<NASGU>
    restoredefaultpath;  addpath(pkg);  cd(pkg);  setup_aero_path();

    E = cell(0, 5);     % name, got, want, relative tolerance, where it is quoted
    g0 = 9.80665;  kt = 1852/3600;

    % ---------------- baseline, cruise ------------------------------------
    ac = b737_baseline();  o2 = aero_737(ac, 2);  o3 = aero_737(ac, 3);  p = o3.planform;
    W  = ac.MTOW*ac.frac_to*ac.frac_cl*g0;   CL = W/(o3.q*ac.S);
    LD3 = CL/(o3.CD0 + o3.K*CL^2);
    E(end+1,:) = {"cruise L/D (L3)", LD3, 18, 0.03, "START_HERE (about 18)"};
    E(end+1,:) = {"cruise CL", CL, 0.60, 0.02, "SOURCES.md"};

    % ---------------- L01 --------------------------------------------------
    E(end+1,:) = {"MAC vs TCDS, %", 100*(p.MAC/ac.MAC_tcds - 1), 1.5, 0.05, "L01 (within 1.5 %)"};
    E(end+1,:) = {"S_wet/S", o3.S_wet/ac.S, 6.4, 0.02, "L01 (about 6.4)"};
    E(end+1,:) = {"wing share of S_wet", o3.buildup.S_wet_m2(1)/o3.S_wet, 0.25, 0.10, "L01 (about a quarter)"};

    % ---------------- L02 --------------------------------------------------
    d = book_data();  A = d.avd4412;
    kpp = (A.cd_2 - A.cd_min)/(A.cl_2 - A.cl_min)^2;  clo = sqrt(A.cd_min/kpp + A.cl_min^2);
    pol = @(cl) A.cd_min + kpp*(cl - A.cl_min).^2;
    E(end+1,:) = {"k''", kpp, 0.011, 0.02, "L02 (about 0.011; figure note)"};
    E(end+1,:) = {"cl/cd at minimum drag", A.cl_min/A.cd_min, 100, 1e-9, "L02 (100)"};
    E(end+1,:) = {"cl for max cl/cd", clo, 0.95, 0.01, "L02 (about 0.95)"};
    E(end+1,:) = {"section max cl/cd", clo/pol(clo), 129, 0.01, "L02 (about 129; near 130)"};
    E(end+1,:) = {"cd at clmax (parabola)", pol(d.tableF1.clmax), 0.0187, 0.005, "L02 (about 0.0187; figure note)"};
    E(end+1,:) = {"cd at cl = 0 (parabola)", pol(0), 0.0100, 0.005, "L02 (about 0.0100)"};
    E(end+1,:) = {"Fig 4.11 rise 8->16 %, %", 100*(d.fig4_11.cd_cl0(6)/d.fig4_11.cd_cl0(2) - 1), 30, 0.03, "L02 (+30 %)"};

    % ---------------- L03 --------------------------------------------------
    [~, ~, e49] = oswald_raymer(o2.A_eff, p.sweep_LE);
    E(end+1,:) = {"Raymer Eq 12.49 e at the 737", e49, 0.38, 0.02, "L03 (about 0.38)"};
    LDmax1 = 15.5*sqrt(p.b^2/o3.S_wet);  LDmax3 = 1/(2*sqrt(o3.CD0*o3.K));
    LDmax2A = 1/(2*sqrt(o2.CD0/(pi*o2.A_eff*o2.e_raymer)));     % Level 2, method A
    LDmax2B = 1/(2*sqrt(o2.CD0*o2.K));                         % Level 2, method B (used)
    E(end+1,:) = {"(L/D)max L1 / L3", LDmax1/LDmax3, 1.0, 0.03, "L03 (L1 and L3 agree)"};
    E(end+1,:) = {"(L/D)max L2 A vs L3, %", 100*(LDmax2A/LDmax3 - 1), -20, 0.05, "L03 (A about 20 % low)"};
    E(end+1,:) = {"(L/D)max L2 B vs L3, %", 100*(LDmax2B/LDmax3 - 1), 11, 0.05, "L03 (B about 11 % high)"};
    E(end+1,:) = {"L2 B / L2 A, %", 100*(LDmax2B/LDmax2A - 1), 40, 0.05, "L03 (differ by about 40 %)"};
    E(end+1,:) = {"e, Kroo/Shevell", o2.e, 0.80, 0.01, "L03 (about 0.80)"};

    % ---------------- L04 --------------------------------------------------
    atm = isa_si(0);  V_SR0 = ac.V_app_kt*kt/1.23;
    CLmaxL = 2*ac.MLW*g0/(atm.rho*ac.S*V_SR0^2);  dCL = CLmaxL - o3.CLmax;
    E(end+1,:) = {"CLmax landing needed", CLmaxL, 2.6, 0.02, "L04 (about 2.6)"};
    E(end+1,:) = {"CLmax clean L3", o3.CLmax, 1.34, 0.01, "L04 (about 1.34)"};
    E(end+1,:) = {"Delta CLmax needed", dCL, 1.2, 0.03, "L04 (about 1.2)"};
    perTE = 0.9*1.6*0.60*cosd(sweep_at(1, ac.sweep_c4, 0.25, ac.AR, ac.lambda));
    perSl = 0.9*0.4*0.80*cosd(p.sweep_LE);
    E(end+1,:) = {"c'/c flaps only", dCL/perTE, 1.5, 0.03, "L04 (about 1.5)"};
    E(end+1,:) = {"c'/c flaps + slats", (dCL - perSl)/perTE, 1.17, 0.01, "L04 (about 1.17)"};

    % ---------------- L05 --------------------------------------------------
    pick = @(v) cd0_change(v);          % Level-3 CD0 change over the range, %
    E(end+1,:) = {"AR -> CD0 sub, %",    pick("AR"),    5,  0.05, "L05 (5 %)"};
    E(end+1,:) = {"Taper -> CD0 sub, %", pick("Taper"), 6,  0.10, "L05 (about 6 %)"};
    E(end+1,:) = {"t/c -> CD0 sub, %",   pick("t/c"),   7,  0.05, "L05 (about 7 %)"};
    E(end+1,:) = {"Sweep -> CD0 sub, %", pick("Sweep"), -3, 0.15, "L05 (about 3 %)"};
    G = trend_table();
    agree = sum(cellfun(@(s) strcmp(strtrim(extractBefore(s, "|")), strtrim(extractAfter(s, "|"))), cellstr(G{:,:})), 'all');
    E(end+1,:) = {"cells that agree (of 36)", agree, 30, 0, "L05 grid (not quoted; guards the grid)"};

    % ---------------- LAB01 solution ---------------------------------------
    S = lab_solution(ac);
    E(end+1,:) = {"lab best AR", S.ARbest, 9.0, 0, "LAB01_SOLUTION quiz (Q5 answer, Q7 why)"};
    E(end+1,:) = {"lab best range, km", S.Rbest, 5351, 1e-3, "LAB01_SOLUTION quiz (Q5 answer, Q7 why)"};
    E(end+1,:) = {"lab range at 9.44, km", S.R944, 5347, 1e-3, "LAB01_SOLUTION quiz (Q5 answer, Q7 why)"};
    E(end+1,:) = {"lab L/D gain AR 9->12, %", S.LDgain, 7, 0.05, "LAB01_SOLUTION quiz (Q5 answer, Q7 why)"};
    E(end+1,:) = {"lab wing mass AR 9->12, kg", S.dm, 980, 0.01, "LAB01_SOLUTION quiz (Q5 answer, Q7 why)"};
    E(end+1,:) = {"lab log-term change 9->12, %", S.dlog, -8, 0.06, "LAB01_SOLUTION quiz (Q5 answer, Q7 why)"};
    E(end+1,:) = {"lab fuel fraction", S.ffrac, 0.20, 0.03, "LAB01_SOLUTION quiz (Q5 answer, Q7 why)"};
    E(end+1,:) = {"lab span-limit AR", S.ARspan, 9.49, 1e-3, "LAB01_SOLUTION quiz (Q6 answer, Q9 why)"};
    E(end+1,:) = {"lab less payload best AR", S.ARbest_lp, 11, 0, "LAB01_SOLUTION quiz (Q10)"};
    E(end+1,:) = {"lab less payload fuel, m^3", S.Vneed_lp, 26.4, 0.005, "LAB01_SOLUTION quiz (Q10)"};
    E(end+1,:) = {"lab wing volume at AR 11, m^3", S.Vwing_lp, 22.5, 0.005, "LAB01_SOLUTION quiz (Q10)"};

    % ---------------- report -------------------------------------------------
    got  = [E{:,2}]';  want = [E{:,3}]';  rtol = [E{:,4}]';
    pass = abs(got - want) <= rtol.*abs(want) + 1e-12;
    T = table(string(E(:,1)), got, want, rtol, pass, string(E(:,5)), ...
        'VariableNames', ["Quantity", "Computed", "Quoted", "RelTol", "OK", "Where"]);
    disp(T);
    ok = all(pass);
    fprintf('%d of %d quoted numbers agree.\n', sum(pass), numel(pass));
end

function S = lab_solution(base)
    g0 = 9.80665;  ARs = 7:0.25:14;  n = numel(ARs);
    atm = isa_si(base.H_cruise);  V = base.M_cruise*atm.a;  C = base.tsfc_hr/3600;
    Ws  = base.MTOW*base.frac_to*base.frac_cl;  CL = Ws*g0/(0.5*atm.rho*V^2*base.S);
    mb  = aero_737(base, 3).m_wing;
    [LD, mw, Z, R, Vw] = deal(zeros(1, n));
    for i = 1:n
        ac = base;  ac.AR = ARs(i);  o = aero_737(ac, 3);
        K  = ac.S_suction/(pi*o.A_eff) + (1 - ac.S_suction)/o.CLa;
        LD(i) = CL/(o.CD0 + K*CL^2);
        mw(i) = wing_weight_raymer(ac.MTOW, ac.Nz, ac.S, ac.AR, ac.tc, ac.lambda, ac.sweep_c4, ac.Scsw_frac*ac.S);
        Z(i)  = ac.MZFW + mw(i) - mb;
        R(i)  = breguet_range(V, C, LD(i), Ws, Z(i)/ac.frac_ld)/1e3;
        Vw(i) = o.V_wing;
    end
    [S.Rbest, ib] = max(R);  S.ARbest = ARs(ib);  S.R944 = interp1(ARs, R, base.AR);
    i9 = ARs == 9;  i12 = ARs == 12;
    S.LDgain = 100*(LD(i12)/LD(i9) - 1);  S.dm = mw(i12) - mw(i9);
    S.dlog   = 100*(log(Ws/(Z(i12)/0.995))/log(Ws/(Z(i9)/0.995)) - 1);
    S.ffrac  = (base.MTOW - base.MZFW)/base.MTOW;
    S.ARspan = (36 - base.dspan_winglet)^2/base.S;
    Rlp = zeros(1, n);
    for i = 1:n, Rlp(i) = breguet_range(V, C, LD(i), Ws, (Z(i) - 5000)/base.frac_ld)/1e3; end
    [~, ib] = max(Rlp);  S.ARbest_lp = ARs(ib);
    S.Vneed_lp = (base.MTOW - (Z(ib) - 5000))/base.rho_fuel;  S.Vwing_lp = Vw(ib);
end

function d = cd0_change(var)
    T = trend_737(var);
    k = find(T.names == "CD0_sub");
    [~, d] = classify_trend(T.L3{:,k}', T.base3(k), 0.03);
    d = round(d, 1);
end

function restore_state(p, d)
    path(p);  cd(d);
end
