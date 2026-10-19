function T = trend_737(var, n)
%TREND_737  Change one wing variable of the 737 and record six metrics.
%
%   T = TREND_737(var) with var one of
%       "AR", "Sweep", "Taper", "t/c", "LE radius", "Camber"
%   T = TREND_737(var, n) uses n points (default 41).
%
%   The wing area and every other input stay at the baseline values
%   (b737_baseline). The metrics are taken at the cruise condition:
%     CD0_sub, K, CL_alpha, CL_max, Wing_wt (kg), Wing_vol (m^3)
%   for Level 2 (T.L2) and Level 3 (T.L3); see aero_737.
%
%   Rows that need a stand-in (labelled "proxy" in the lesson):
%   - "LE radius": no source relates LE radius to K or to CL_max directly.
%       K      : leading-edge suction S from 0.85 to 0.95 (Raymer p. 447:
%                "moderate sweep and a large leading-edge radius ... S equal
%                to about 0.85 to 0.95"). Larger radius -> more suction.
%       CL_max : NACA 00XX family, t/c 6 % to 12 % (LE radius 0.40 % to
%                1.6 % c; LE radius scales with (t/c)^2, R App D), section
%                clmax from Raymer Fig. 4.13 and dy = 26 t/c.
%       x is a 0-1 index from "small" to "large" LE radius.
%   - "Camber": Nicolai Eq. 2.17 polar. CL at minimum drag = 0.1 x camber %
%       (assumption). CD0_sub is C_D at C_L = 0; K is the effective K at the
%       cruise C_L. Section clmax from book_data().camber. The section lift
%       slope is held: "C_l_alpha ~ 2*pi/rad" for all low-speed sections
%       (Nicolai Sec. 7.5, p. 178).

    arguments
        var (1,1) string {mustBeMember(var, ["AR", "Sweep", "Taper", ...
                                             "t/c", "LE radius", "Camber"])}
        n   (1,1) double {mustBeInteger, mustBePositive} = 41
    end

    base = b737_baseline();
    bd   = book_data();
    W    = base.MTOW*base.frac_to*base.frac_cl*9.80665;     % start-of-cruise weight (N)

    switch var
        case "AR",        x = linspace(6, 14, n);     xb = base.AR;       xl = "Aspect ratio";
        case "Sweep",     x = linspace(0, 40, n);     xb = base.sweep_c4; xl = "Quarter-chord sweep (deg)";
        case "Taper",     x = linspace(0, 1, n);      xb = base.lambda;   xl = "Taper ratio";
        case "t/c",       x = linspace(0.08, 0.16, n);xb = base.tc;       xl = "Thickness ratio t/c";
        case "LE radius", x = linspace(0, 1, n);      xb = 0.8;           xl = "LE radius index (0 small, 1 large): proxy";
        case "Camber",    x = linspace(0, 4, n);      xb = base.camber;   xl = "Max camber (% chord)";
    end

    names = ["CD0_sub", "K", "CL_alpha", "CL_max", "Wing_wt", "Wing_vol"];
    L2 = nan(n, 6);  L3 = nan(n, 6);
    for i = 1:n
        ac = set_variable(base, var, x(i), bd);
        for lev = [2 3]
            o  = aero_737(ac, lev);
            CL = W/(o.q*ac.S);
            m  = [o.CD0, o.K, o.CLa, o.CLmax, o.m_wing, o.V_wing];
            if lev == 3 && var == "Camber"
                clmin = ac.clmin_per_pct*ac.camber;
                m(1)  = o.CD0 + o.Kpp*clmin^2;               % Nicolai Eq. 2.17 at CL = 0
                m(2)  = o.K - 2*o.Kpp*clmin/CL;              % (CD - CD(CL=0))/CL^2
            end
            if var == "LE radius"
                tc00 = 0.06 + 0.06*x(i);
                cl00 = interp1(bd.fig4_13.tc_00, bd.fig4_13.cl_00, tc00);
                if lev == 2
                    m(4) = clmax_wing("raymer12_15", cl00, ac.sweep_c4);
                else
                    m(4) = clmax_wing("raymer12_16", cl00, ac.dy_coeff*tc00, o.planform.sweep_LE);
                    m(6) = NaN;    % no source relates LE radius to wing volume
                end
            end
            if lev == 2, L2(i,:) = m; else, L3(i,:) = m; end
        end
    end

    % Baseline values (the value at xb on each curve)
    T.var = var;  T.x = x;  T.xb = xb;  T.xlabel = xl;  T.names = names;
    T.L2 = array2table(L2, 'VariableNames', names);
    T.L3 = array2table(L3, 'VariableNames', names);
    T.base2 = interp1(x(:), L2, xb);
    T.base3 = interp1(x(:), L3, xb);
end

function ac = set_variable(ac, var, v, bd)
    switch var
        case "AR",       ac.AR = v;
        case "Sweep",    ac.sweep_c4 = v;
        case "Taper",    ac.lambda = v;
        case "t/c"
            ac.tc = v;
            % Section clmax follows the NACA 24XX curve, scaled to 1.67 at 12 %
            f = @(tc) interp1(bd.fig4_13.tc_24, bd.fig4_13.cl_24, tc);
            ac.clmax2d = ac.clmax2d*f(v)/f(0.12);
        case "LE radius"
            ac.S_suction = 0.85 + 0.10*v;
        case "Camber"
            ac.camber  = v;
            ac.clmax2d = interp1(bd.camber.pct, bd.camber.clmax, v);
    end
end
