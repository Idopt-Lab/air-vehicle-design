function d = book_data()
%BOOK_DATA  Digitized textbook figures and tables used in this lesson.
%
%   d = BOOK_DATA() returns one struct. Each field holds the numbers read
%   from one figure or table, plus a .src string with the citation.
%
%   The figure values were read from page images, so they carry the error of
%   reading a graph (about +/-0.01 on the y-axis). They are good for trends,
%   not for the third decimal place.
%
%   R  = Raymer, Aircraft Design: A Conceptual Approach, 6th ed., AIAA, 2018.
%   N  = Nicolai & Carichner, Fundamentals of Aircraft and Airship Design,
%        Vol. I, AIAA, 2010.
%
%   TODO (Casey): cross-check EVERY digitized value in this file against the
%   source page, and mark each block checked (initials, date). Blocks and pages:
%     table7_1  N Table 7.1, p. 193 (arrows)
%     fig2_10   N Fig. 2.10, p. 45 (tau, delta; both panels)
%     fig12_9   R Fig. 12.9, p. 406 (CLmax/clmax against LE sweep, 7 dy curves)
%     table12_1 R Table 12.1, p. 405
%     fig4_11   R Fig. 4.11, p. 69 (c_l = 0 curve)
%     fig4_13   R Fig. 4.13, p. 70 (24XX, 14XX, 00XX curves)
%     camber    R Fig. 4.13 at t/c = 12 %; N Table F.1; R App. D pp. 981-982
%     le_radius R App. D (printed radii)
%     fig2_9    N Fig. 2.9, p. 44 (CLmax at AR 1, 5, 10, infinity)
%     figG_8    N Fig. G.8, p. 739 (three lines at x = 1.0, 1.2, 1.4)
%     tableF1   N Table F.1 (NACA 4412 row)
%     avd4412   Abbott & von Doenhoff, Theory of Wing Sections, App. IV,
%               pp. 488-489 (NACA 4412, Re = 9e6 curve)
%   Unchecked so far: all of them (read from page images, 2026-10-17).

    % --- Nicolai Table 7.1: effect of an INCREASE in each variable ---------
    % Rows: AR, sweep, taper, t/c, LE radius, camber.
    % Columns: CD0 sub, CD0 sup, K, CL_alpha, CL_max, wing weight, wing volume.
    % "0" = no effect. "v^" = decreases then increases. "^v" = the opposite.
    % Sweep / CL_max is "v" for aft sweep and "0" for forward sweep.
    d.table7_1.rows = ["AR", "Sweep", "Taper", "t/c", "LE radius", "Camber"];
    d.table7_1.cols = ["CD0_sub", "CD0_sup", "K", "CL_alpha", "CL_max", "Wing_wt", "Wing_vol"];
    d.table7_1.arrow = [ ...
        "0", "^", "v",  "^",  "^", "^", "v"; ...   % AR
        "0", "v", "^",  "v",  "v", "^", "0"; ...   % sweep (aft)
        "0", "0", "v^", "^v", "0", "^", "v"; ...   % taper
        "0", "^", "0",  "0",  "^", "v", "^"; ...   % t/c
        "0", "^", "v",  "0",  "^", "0", "^"; ...   % LE radius
        "^", "^", "v",  "0",  "^", "0", "0"];      % camber
    d.table7_1.src = "N Table 7.1, p. 193";

    % --- Nicolai Fig 2.10: tau and delta (non-elliptic lift distribution) -
    d.fig2_10.lambda    = [0 .05 .1 .15 .2 .25 .3 .35 .4 .5 .6 .7 .8 .9 1.0];
    d.fig2_10.tau_AR6   = [.147 .093 .054 .029 .013 .002 .001 .006 .012 .032 .054 .079 .105 .134 .163];
    d.fig2_10.delta_AR6 = [.111 .078 .054 .036 .024 .016 .011 .006 .0045 .007 .014 .025 .037 .050 .066];
    d.fig2_10.AR        = [2.1 3 4 5 6 7 8 9 10];
    d.fig2_10.tau_L1    = [.077 .099 .122 .144 .166 .183 .198 .212 .224];
    d.fig2_10.delta_L1  = [.007 .017 .028 .038 .047 .055 .063 .071 .078];
    d.fig2_10.src = "N Fig 2.10, p. 45 (top panel AR = 6; bottom panel 'zero taper' = untapered, lambda = 1)";

    % --- Raymer Fig 12.9: CLmax/clmax of high-AR wings, M about 0.2 --------
    d.fig12_9.Lambda_LE = [0 10 20 30 40 50 60];
    d.fig12_9.dy        = [1.4 1.6 1.8 2.0 2.2 2.4 2.5];   % 1.4 means <= 1.4; 2.5 means >= 2.5
    d.fig12_9.ratio = [ ...                                   % rows: Lambda_LE, cols: dy
        .90 .90 .90 .90 .90 .90 .90; ...
        .93 .92 .92 .90 .89 .87 .87; ...
        .97 .96 .93 .90 .87 .85 .84; ...
       1.03 1.00 .95 .89 .85 .81 .79; ...
       1.10 1.05 .97 .88 .82 .76 .73; ...
       1.19 1.11 1.00 .87 .78 .69 .65; ...
       1.30 1.19 1.02 .86 .73 .59 .52];
    d.fig12_9.src = "R Fig 12.9, p. 406 (untwisted, constant-section wings)";

    % --- Raymer Table 12.1: leading-edge sharpness parameter --------------
    d.table12_1.naca4digit = 26.0;    % dy = 26 * t/c
    d.table12_1.naca64     = 21.3;    % dy = 21.3 * t/c
    d.table12_1.src = "R Table 12.1, p. 405";

    % --- Raymer Fig 4.11: section drag against t/c (NACA 24XX) -----------
    d.fig4_11.tc     = [.063 .08 .10 .12 .14 .16 .18];
    d.fig4_11.cd_cl0 = [.0047 .0054 .0060 .0065 .0068 .0070 .0072];
    d.fig4_11.src = "R Fig 4.11, p. 69 (NACA 24XX, c_l = 0)";

    % --- Raymer Fig 4.13: section clmax against t/c -----------------------
    d.fig4_13.tc_24  = [.06 .08 .10 .12 .14 .16 .18];
    d.fig4_13.cl_24  = [1.32 1.50 1.61 1.66 1.66 1.62 1.55];
    d.fig4_13.tc_00  = [.06 .08 .10 .12];
    d.fig4_13.cl_00  = [0.82 1.08 1.33 1.54];
    d.fig4_13.tc_14  = [.08 .10 .12];
    d.fig4_13.cl_14  = [1.31 1.48 1.61];
    d.fig4_13.src = "R Fig 4.13, p. 70";

    % --- Section clmax against camber at t/c = 12 % ------------------------
    % 0 %: 00XX, 1 %: 14XX, 2 %: 24XX (R Fig 4.13); 4 %: NACA 4412 (N Table F.1).
    d.camber.pct   = [0 1 2 4];
    d.camber.clmax = [1.54 1.61 1.66 1.67];
    % Section lift slope (per deg): NACA 2415 and 4415 (R App D, pp. 981-982)
    d.camber.cla_pct = [2 4];
    d.camber.cla_deg = [0.101 0.105];
    d.camber.src = "R Fig 4.13 p. 70; N Table F.1; R App D pp. 981-982";

    % --- Leading-edge radius, % chord, printed in R App D ------------------
    d.le_radius.naca0006 = 0.40;
    d.le_radius.naca0009 = 0.89;
    d.le_radius.naca64006 = 0.256;
    d.le_radius.src = "R App D, pp. 973-982";

    % --- Nicolai Table F.1: NACA 4412, Re = 9e6 ----------------------------
    d.tableF1.alpha0L_deg   = -3.8;
    d.tableF1.cm0           = -0.093;
    d.tableF1.cla_per_deg   = 0.105;
    d.tableF1.ac            = 0.247;
    d.tableF1.alpha_clmax   = 14.0;     % deg (the column header misprints "per deg")
    d.tableF1.clmax         = 1.67;
    d.tableF1.alpha_star    = 7.5;      % deg, footnote a
    d.tableF1.src = "N Table F.1 (Low-Speed Data on Airfoil Sections, Re = 9e6)";

    % --- Abbott & von Doenhoff App. IV: NACA 4412 drag polar, Re = 9e6 ----
    % Read on the Re = 9e6 curve (diamond symbols) of the c_d-c_l chart:
    d.avd4412.cl_min  = 0.6;    % c_l at minimum drag (red box and red lines)
    d.avd4412.cd_min  = 0.0060; % minimum drag (red dashed line)
    d.avd4412.cd_cl0  = 0.0062; % c_d at c_l = 0 (green)
    d.avd4412.cl_2    = 1.2;    % second point, used for k'' (blue)
    d.avd4412.cd_2    = 0.010;  % c_d at c_l = 1.2 (blue dashed line)
    d.avd4412.src = "Abbott & von Doenhoff, Theory of Wing Sections, App. IV, pp. 488-489";

    % --- Nicolai Fig 2.9: CLmax of a NACA 65-410 wing against AR ----------
    d.fig2_9.AR    = [1 5 10 Inf];
    d.fig2_9.CLmax = [0.85 1.08 1.27 1.51];
    d.fig2_9.src = "N Fig 2.9, p. 44 (NACA 65-410)";

    % --- Nicolai Fig G.8: (L/D)max against b/sqrt(S_wet) -------------------
    d.figG_8.x      = [1.0 1.2 1.4];
    d.figG_8.upper  = [16.0 19.2 22.4];
    d.figG_8.centre = [14.6 17.5 20.5];
    d.figG_8.lower  = [12.3 14.9 17.5];
    d.figG_8.src = "N Fig G.8, p. 739";
end
