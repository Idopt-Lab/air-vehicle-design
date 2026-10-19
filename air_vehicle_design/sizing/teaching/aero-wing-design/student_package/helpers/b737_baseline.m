function [ac, sources] = b737_baseline()
%B737_BASELINE  Input data for the Boeing 737 MAX 8 (SI units).
%
%   [ac, sources] = B737_BASELINE() returns a struct of INPUTS only. Derived
%   quantities (chords, MAC, sweeps, areas) are not stored. Functions such as
%   wing_planform(ac) compute them from the inputs every time, so a change to
%   an input (ac.AR = 12, for example) changes every result that depends on it.
%
%   The second output is a table: one row per input, with its source.
%
%   Units: m, m^2, kg, N, s, deg. Weights are masses in kg; multiply by g0 to
%   get a force.
%
%   Abbreviations in the sources:
%     ACAP = Boeing D6-38A004, 737 MAX Airplane Characteristics for Airport
%            Planning, Rev K, July 2025.
%     JSR  = Jenkinson, Simpkin & Rhodes, Civil Jet Aircraft Design, 1999,
%            companion Data A, Table 2, 737-800 row.
%     R    = Raymer, Aircraft Design, 6th ed., 2018.
%     N    = Nicolai & Carichner, Fundamentals of Aircraft and Airship
%            Design, Vol. I, 2010.
%   Assumption: the MAX has the 737-800 reference wing, plus its own winglet.

    % ---- Wing (reference trapezoid) ---------------------------------------
    ac.S        = 124.60;  % reference area (m^2)             [JSR]
    ac.AR       = 9.44;    % geometric aspect ratio            [JSR]
    ac.lambda   = 0.278;   % taper ratio c_tip/c_root          [JSR]
    ac.sweep_c4 = 25.0;    % quarter-chord sweep (deg)         [JSR]
    ac.h_winglet = 2.92;   % winglet height (m)                [ACAP Sec. 2.2.2, p. 2-10]
    ac.dspan_winglet = 35.92 - 34.30;  % span added by the winglets (m) [ACAP 2.2.2; JSR]

    % ---- Airfoil: NACA 4412 surrogate (Boeing does not publish the MAX sections)
    ac.tc        = 0.12;   % thickness ratio
    ac.xc_m      = 0.30;   % chordwise position of max thickness  [R p. 422: about 0.3 for low-speed airfoils]
    ac.camber    = 4.0;    % max camber (% chord), NACA 4412 designation
    ac.clmax2d   = 1.67;   % section clmax, Re 9e6              [N Table F.1]
    ac.cla2d     = 0.105;  % section lift slope (per deg)       [N Table F.1]
    ac.alpha0L   = -3.8;   % zero-lift angle (deg)              [N Table F.1]
    ac.cdmin2d   = 0.0060; % section minimum drag               [Abbott & von Doenhoff, App IV, pp. 488-489]
    ac.dy_coeff  = 26.0;   % dy = 26 t/c, NACA 4-digit          [R Table 12.1, p. 405]

    % ---- Drag-due-to-lift --------------------------------------------------
    ac.S_suction = 0.93;   % leading-edge suction, airliner wing  [R p. 450]
    ac.clmin_per_pct = 0.1;% CL at min drag per % camber (assumption: centres of the
                           % NACA 2415 / 4415 drag buckets, about 0.22 / 0.40, R App D)

    % ---- Fuselage ----------------------------------------------------------
    ac.fus_l = 39.12;      % length, nose to tail cone (m)      [ACAP Sec. 2.2.2]
    ac.fus_w = 3.76;       % width (m)                          [ACAP Sec. 2.2.2]
    ac.fus_h = 4.01;       % depth (m)                          [ACAP Sec. 2.2.2]

    % ---- Tails (areas taken as exposed: assumption) ----------------------
    ac.ht_S = 32.40;  ac.ht_b = 13.40;  ac.ht_sweep = 30.0;   % [JSR]
    ac.vt_S = 23.13;  ac.vt_h = 6.00;   ac.vt_sweep = 35.0;   % [JSR]
    ac.tail_tc = 0.12;     % assumption: tail sections as thick as the wing section

    % ---- Nacelles (CFM56-7 data; the LEAP-1B nacelle is not published) ----
    ac.nac_d = 2.06;  ac.nac_l = 4.70;  ac.n_eng = 2;          % [JSR]

    % ---- Drag build-up factors ---------------------------------------------
    ac.Q_wing = 1.0;       % low wing, well filleted           [R p. 425]
    ac.Q_fus  = 1.0;       % fuselage                          [R p. 425]
    ac.Q_tail = 1.04;      % conventional tail                 [R p. 425]
    ac.Q_nac  = 1.3;       % nacelle < about 1 diameter from the wing [R p. 425]
    ac.k_rough = 0.634e-5; % smooth paint (m)                  [R Table 12.5, p. 421]
    ac.LP_frac = 0.035;    % leakage and protuberance, 2-5 % for jet transports; midpoint [R Table 12.8, p. 431]

    % ---- Weights (737-8, highest weight option) ----------------------------
    ac.MTOW = 82644;       % kg                                [ACAP Sec. 2.1.2, p. 2-3]
    ac.MZFW = 65952;       % kg                                [ACAP Sec. 2.1.2]
    ac.MLW  = 69308;       % kg                                [ACAP Sec. 2.1.2]
    ac.Nz   = 1.5*2.5;     % ultimate load factor = 1.5 x limit [R p. 576; 14 CFR 25.303, 25.337]
    ac.Scsw_frac = 0.30;   % control-surface area / wing area (b737.org.uk, secondary)

    % ---- Mission and low speed ---------------------------------------------
    ac.M_cruise = 0.785;   % cruise Mach                       [Boeing 737-800 tech page, archived 2008-12-17]
    ac.H_cruise = 35000*0.3048;  % cruise altitude (m), 35,000 ft  [same]
    ac.frac_to  = 0.970;   % warm-up and takeoff               [R Table 3.2, p. 34]
    ac.frac_cl  = 0.985;   % climb                             [R Table 3.2, p. 34]
    ac.frac_ld  = 0.995;   % landing                           [R Table 3.2, p. 34]
    ac.tsfc_hr  = 0.5;     % high-bypass turbofan, cruise (1/hr) [R Table 3.3, p. 36]
    ac.rho_fuel = 803;     % Jet A-1 at 15 C (kg/m^3)          [R Table 10.5, p. 327]
    ac.fuel_cap = 25.816;  % usable fuel (m^3)                 [ACAP Sec. 2.1.2]
    ac.V_app_kt = 141;     % approach speed at MLW (kt)        [Boeing, Aerodrome Reference Code and Approach Speeds, Rev A, p. 3]
    ac.T_eng    = 130.41e3;% LEAP-1B28B1 takeoff thrust (N)    [EASA TCDS E.115, Issue 09, Sec. III.6, p. 7]
    ac.MAC_tcds = 3.96;    % check value (m)                   [EASA TCDS IM.A.120, Issue 29, Sec. 8.III.16, p. 69]

    if nargout > 1
        sources = table( ...
            ["S"; "AR"; "lambda"; "sweep_c4"; "h_winglet"; "tc"; "clmax2d"; "cla2d"; ...
             "fus_l, fus_w, fus_h"; "ht_S, vt_S"; "nac_d, nac_l"; "MTOW, MZFW, MLW"; ...
             "M_cruise, H_cruise"; "V_app_kt"; "T_eng"], ...
            [ac.S; ac.AR; ac.lambda; ac.sweep_c4; ac.h_winglet; ac.tc; ac.clmax2d; ac.cla2d; ...
             ac.fus_l; ac.ht_S; ac.nac_d; ac.MTOW; ac.M_cruise; ac.V_app_kt; ac.T_eng], ...
            ["JSR Data A, 737-800 reference wing"; "JSR Data A"; "JSR Data A"; "JSR Data A"; ...
             "ACAP Sec. 2.2.2"; "NACA 4412 (surrogate)"; "Nicolai Table F.1"; "Nicolai Table F.1"; ...
             "ACAP Sec. 2.2.2"; "JSR Data A"; "JSR Data A (CFM56-7)"; "ACAP Sec. 2.1.2"; ...
             "Boeing 737-800 page (archived)"; "Boeing approach-speed document"; "EASA TCDS E.115"], ...
            'VariableNames', ["Input", "Value_first", "Source"]);
    end
end
