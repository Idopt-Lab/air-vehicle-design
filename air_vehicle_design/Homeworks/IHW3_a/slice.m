%% Which side of the curve is feasible? Walk a vertical slice in power.
clear; clc
warning('off','TtpaProp:BhpOutOfRange');
obj = ttpa_disciplines();
d   = TtpaPSDiagram(obj);

S = 128.47;                       % hold the wing fixed at the sized value
fprintf('VERTICAL SLICE at S_ref = %.2f ft^2  (each row is a separately sized airplane)\n\n', S);
fprintf('   P_SL     W_TO     W/S      W/P   |  W/P allowed   W/S wall | feasible | what stops it\n');
fprintf('   [hp]    [lbf]   [psf]  [lb/hp]   |    [lb/hp]      [psf]   |          |\n');
fprintf('  -------------------------------------------------------------------------------------\n');
for P = [400 450 481.6 500 555.5 650 712 800 1000]
    W  = d.converge_W0(P, S);
    WS = W/S;  WP = W/P;
    [WPl, WSw, nm] = run_constraints(WS, obj);
    ok = ~all(isnan(WPl),2);
    [WPallow, i] = min(WPl(ok));
    pn = nm(ok);
    WSallow = min(WSw(~isnan(WSw)));
    powerOK = WP <= WPallow;
    wallOK  = WS <= WSallow;
    why = "-";
    if ~powerOK && ~wallOK, why = "both";
    elseif ~powerOK,        why = "too little power (" + pn(i) + ")";
    elseif ~wallOK,         why = "TOO MUCH power -> too heavy -> landing wall";
    end
    fprintf('  %6.1f  %7.1f  %6.2f  %7.3f  |   %7.3f      %6.2f  |   %-5s  | %s\n', ...
        P, W, WS, WP, WPallow, WSallow, string(powerOK && wallOK), why);
end

fprintf('\n  -> Against every POWER curve, more power is always feasible: the W/P column\n');
fprintf('     falls monotonically and clears its limit from 500 hp up.\n');
fprintf('  -> BUT the region is capped from above. A bigger engine is a heavier\n');
fprintf('     airplane, W/S climbs with it, and past ~712 hp the LANDING WALL is\n');
fprintf('     broken on a 128.47 ft^2 wing. The wedge is bounded, not a half-plane.\n');

fprintf('\n\nHORIZONTAL SLICE at P_SL = 555.5 hp\n\n');
fprintf('   S_ref     W_TO     W/S      W/P   | W/S wall  | feasible | limited by\n');
fprintf('  ---------------------------------------------------------------------\n');
for S2 = [105 115 118.2 125 128.47 160 200 230]
    W  = d.converge_W0(555.5, S2);
    WS = W/S2; WP = W/555.5;
    [WPl, WSw, nm] = run_constraints(WS, obj);
    ok = ~all(isnan(WPl),2);
    [WPallow, i] = min(WPl(ok)); pn = nm(ok);
    WSallow = min(WSw(~isnan(WSw)));
    feas = (WP <= WPallow) && (WS <= WSallow);
    why = "-";
    if ~feas
        if WS > WSallow, why = "landing wall"; else, why = pn(i); end
    end
    fprintf('  %6.1f  %7.1f  %6.2f  %7.3f  |  %6.2f   |   %-5s  | %s\n', ...
        S2, W, WS, WP, WSallow, string(feas), why);
end
fprintf('\n  -> too SMALL a wing fails the landing wall; too BIG a wing fails cruise.\n');
fprintf('     The wing axis is bounded on BOTH sides.\n');

fprintf('\n\nOPTIMUM DIRECTION vs FEASIBLE SIDE - the two are not the same thing\n');
fprintf('  matching diagram (W/S, W/P):  feasible BELOW the envelope, best point is the HIGHEST\n');
fprintf('                                feasible one (max W/P = smallest engine)\n');
fprintf('  P-S diagram      (S,   P  ):  feasible ABOVE the curves,   best point is the LOWEST\n');
fprintf('                                feasible one (min P   = smallest engine)\n');
fprintf('  Both say "smallest engine". Only the OPTIMUM direction flips to down.\n');
