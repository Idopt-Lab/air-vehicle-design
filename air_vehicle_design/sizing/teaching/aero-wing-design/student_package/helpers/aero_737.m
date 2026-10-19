function out = aero_737(ac, level, M, H)
%AERO_737  Aerodynamics, wing mass and wing volume of the 737 at one condition.
%
%   out = AERO_737(ac, level) uses the cruise condition in ac.
%   out = AERO_737(ac, level, M, H) uses Mach M and altitude H (m).
%   ac comes from b737_baseline (or a changed copy). level is 2 or 3:
%
%   Level 2: planform only (S, AR, taper, sweep, fuselage size).
%     CD0   = Cfe*S_wet/S, Cfe = 0.0026 civil transport  Raymer Table 12.3, p. 417
%             (wing S_wet = 2.003*S_exp: no t/c at this level, Raymer Eq. 7.11)
%     CLa   = Raymer Eq. 12.6, eta = 0.95 (p. 400), quarter-chord sweep
%     K     = 1/(pi*A*e), e by Kroo's method (Nita & Scholz 2012, Eqs. 6-8;
%             see oswald_kroo). out.e_raymer = Raymer Eqs. 12.48/12.49,
%             the second Level-2 method, kept for comparison.
%     CLmax = Raymer Eq. 12.15
%     m_wing = 49 kg/m^2 x S_exp, transport               Raymer Table 15.2, p. 568
%     V_wing = NaN (needs t/c)
%   Level 3: planform + airfoil + components.
%     CD0   = component build-up, Raymer Eq. 12.24 (p. 417), see the code
%     CLa   = Raymer Eq. 12.6 with the section slope, times the Nicolai tau
%             correction for a non-elliptic lift distribution (see below)
%     K     = leading-edge suction, Raymer Eq. 12.57, with Nicolai delta
%     CLmax = Raymer Eq. 12.16 with Fig. 12.9
%     m_wing = Raymer Eq. 15.25
%     V_wing = Roskam Eqs. 6.2, 6.3
%   Both levels use the effective AR with winglets, A = AR*(1 + h/b)^2
%   (Raymer Eq. 12.11, p. 400) for CLa and K.

    arguments
        ac    (1,1) struct
        level (1,1) double {mustBeMember(level, [2 3])}
        M     (1,1) double {mustBePositive} = ac.M_cruise
        H     (1,1) double {mustBeNonnegative} = ac.H_cruise
    end

    p     = wing_planform(ac.S, ac.AR, ac.lambda, ac.sweep_c4, ac.fus_w, ac.xc_m);
    A     = ac.AR*(1 + ac.h_winglet/p.b)^2;          % Raymer Eq. 12.11, p. 400
    atm   = isa_si(H);
    V     = M*atm.a;
    D_fus = sqrt(ac.fus_w*ac.fus_h);                 % equivalent diameter (assumption)
    S_csw = ac.Scsw_frac*ac.S;

    out.planform = p;  out.A_eff = A;  out.atm = atm;  out.V = V;  out.M = M;
    out.q = 0.5*atm.rho*V^2;

    % Wetted areas (used by both levels for the fuselage, tails, nacelles)
    Sw_fus = wetted_area("fuselage", ac.fus_l, D_fus);
    Sw_nac = ac.n_eng*wetted_area("cylinder", ac.nac_l, ac.nac_d);

    if level == 2
        Sw_wing = 2.003*p.S_exp;                       % Raymer Eq. 7.11 form (no t/c)
        Sw_tail = 2.003*(ac.ht_S + ac.vt_S);
        out.S_wet = Sw_wing + Sw_fus + Sw_tail + Sw_nac;
        out.CD0   = 0.0026*out.S_wet/ac.S;             % Raymer Table 12.3, p. 417
        out.CLa   = cl_alpha_raymer(A, M, ac.sweep_c4, 0.95, p.S_exp/ac.S, D_fus/p.b);
        % Two Level-2 methods for e. The one used is Kroo's (Nita & Scholz
        % Eqs. 6-8); Raymer's fits (Eqs. 12.48/12.49) are kept for comparison.
        out.e_raymer = oswald_raymer(A, p.sweep_LE);
        out.e     = oswald_kroo(A, out.CD0, D_fus/p.b);
        out.K     = 1/(pi*A*out.e);
        out.CLmax = clmax_wing("raymer12_15", ac.clmax2d, ac.sweep_c4);
        out.m_wing = 49*p.S_exp;                       % Raymer Table 15.2, p. 568
        out.V_wing = NaN;
        return
    end

    % ---------------- Level 3: component drag build-up --------------------
    % CD0 = sum(Cf*FF*Q*S_wet)/S_ref + CD_L&P              Raymer Eq. 12.24, p. 417
    % Re on the MAC for wings/tails, the length for bodies  Raymer Eq. 12.25, p. 418
    Re  = @(len) atm.rho*V*len/atm.mu;
    Cf  = @(len) skin_friction(Re(len), M, len, ac.k_rough);
    c_ht = ac.ht_S/ac.ht_b;   c_vt = ac.vt_S/ac.vt_h;    % tail mean chords

    comp = ["wing"; "fuselage"; "HT"; "VT"; "nacelles"];
    Cfv  = [Cf(p.MAC); Cf(ac.fus_l); Cf(c_ht); Cf(c_vt); Cf(ac.nac_l)];
    % The tails use the quarter-chord sweep for the max-thickness sweep
    % (Raymer p. 74 footnote: the difference is "trivial").
    FFv  = [form_factor("surface", ac.tc, ac.xc_m, p.sweep_maxt, M); ...
            form_factor("body", ac.fus_l/D_fus); ...
            form_factor("surface", ac.tail_tc, ac.xc_m, ac.ht_sweep, M); ...
            form_factor("surface", ac.tail_tc, ac.xc_m, ac.vt_sweep, M); ...
            form_factor("nacelle", ac.nac_l/ac.nac_d)];
    Qv   = [ac.Q_wing; ac.Q_fus; ac.Q_tail; ac.Q_tail; ac.Q_nac];
    Swv  = [wetted_area("surface", p.S_exp, ac.tc); Sw_fus; ...
            wetted_area("surface", ac.ht_S, ac.tail_tc); ...
            wetted_area("surface", ac.vt_S, ac.tail_tc); Sw_nac];
    CD0c = Cfv.*FFv.*Qv.*Swv/ac.S;

    out.buildup = table(comp, Cfv, FFv, Qv, Swv, CD0c, ...
        'VariableNames', ["component", "Cf", "FF", "Q", "S_wet_m2", "CD0"]);
    out.S_wet = sum(Swv);
    out.CD0_LP = ac.LP_frac*sum(CD0c);               % Raymer Table 12.8, p. 431
    out.CD0    = sum(CD0c) + out.CD0_LP;

    % ---------------- Level 3: lift slope and drag due to lift -------------
    beta = sqrt(1 - M^2);
    cla  = ac.cla2d*180/pi;                          % section slope, M = 0 (per rad)
    eta  = cla/(2*pi);                               % Raymer Eq. 12.8 with Prandtl-Glauert
                                                     % (Nicolai Eq. 2.7): beta cancels
    [CLa_R, info] = cl_alpha_raymer(A, M, p.sweep_maxt, eta, p.S_exp/ac.S, D_fus/p.b);

    % Nicolai tau correction (taper): ratio of Nicolai Eq. 2.9 with tau to
    % Eq. 2.9 with tau = 0, on the geometric planform (assumption: this
    % combination of the two books is a lesson choice).
    [tau, delta] = tau_delta_nicolai(ac.lambda, ac.AR);
    m0    = cla/beta;                                % Nicolai Eq. 2.7, p. 43
    r_tau = (1 + m0/(pi*A))/(1 + m0*(1 + tau)/(pi*A));
    out.CLa = CLa_R*r_tau;
    out.CLa_info = info;  out.eta = eta;  out.tau = tau;  out.delta = delta;

    [out.K, out.e] = k_le_suction(A, out.CLa, ac.S_suction, delta);
    % The part of K that leading-edge suction does not recover is taken as
    % Nicolai's viscous K'' (assumption): K'' = (1 - S)*(K0 - K100).
    out.Kpp = (1 - ac.S_suction)*(1/out.CLa - (1 + delta)/(pi*A));

    % ---------------- Level 3: maximum lift, wing mass, wing volume --------
    dy = ac.dy_coeff*ac.tc;                          % Raymer Table 12.1, p. 405
    out.CLmax = clmax_wing("raymer12_16", ac.clmax2d, dy, p.sweep_LE);
    out.m_wing = wing_weight_raymer(ac.MTOW, ac.Nz, ac.S, ac.AR, ac.tc, ...
                                    ac.lambda, ac.sweep_c4, S_csw);
    out.V_wing = wing_fuel_volume(ac.S, p.b, ac.tc, ac.tc, ac.lambda);
end
