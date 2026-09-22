%% verify_framework.m  - checks the IHW3a preliminary-design-framework claims
%  Companion to verify_ihw3a.m, which checks the sizing-loop and geometry
%  claims. This one checks everything added for the framework rebuild:
%  the two sizing modes, the two mission methods, the two weight methods,
%  the two cruise-constraint methods, and the memoised atmosphere.
clear; clc
warning('off','TtpaProp:BhpOutOfRange');

jp = ttpa_requirements_path();
J0 = jsondecode(fileread(jp));

fprintf('=== CLAIM A: get_state memoisation is bit-identical ===\n');
clear get_state
a1 = get_state(8000); b1 = get_state(8000); s0 = get_state(0);
fprintf('  repeat call identical: rho %d  sigma %d\n', isequal(a1.rho,b1.rho), isequal(a1.sigma,b1.sigma));
fprintf('  sigma at sea level = %.15g  (must be exactly 1)\n', s0.sigma);
fprintf('  rho(8000) = %.15g\n', a1.rho);

fprintf('\n=== CLAIM B: the L2 mission L/D values match a hand calculation ===\n');
ob = build_(jp, struct()); ob.geom.S_ref = 128.47; ob.prop.P_SL = 555.53;
[~,~,~,~,~,det] = mission_fuel(5138.65, ob);
st = get_state(8000); V = 200*6076.115/3600; q = 0.5*st.rho*V^2;
W  = 5138.65*0.984*0.990;  CLh = (W/128.47)/q;
CD0 = ob.aero.CD0; K = ob.aero.K;  LDh = CLh/(CD0+K*CLh^2);
ic = find(strcmp([det.type],"cruise"),1);
fprintf('  cruise, first sub-segment by hand : C_L %.4f   L/D %.3f\n', CLh, LDh);
fprintf('  cruise, model segment average     : C_L %.4f   L/D %.3f\n', det(ic).CL, det(ic).LD);
fprintf('  L/D_max the L1 mission would use  :            %.3f   -> %+.1f %% optimistic\n', ...
        ob.aero.LD_max, 100*(ob.aero.LD_max-LDh)/LDh);

fprintf('\n=== CLAIM C: the two sizing modes agree when they describe the same airplane ===\n');
fprintf('  design_point/OPTIMUM sizes to the envelope corner and outputs S_ref.\n');
fprintf('  fixed_wing_area at THAT S_ref must rebuild the same airplane.\n');
o = opts_(J0, "design_point"); o.design_point_mode = "optimum";
rA = sizing_loop(build_(jp, struct()), o);
o2 = opts_(J0, "fixed_wing_area"); o2.S_ref = rA.S_ref;
rB = sizing_loop(build_(jp, struct()), o2);
fprintf('  design_point(optimum)  W_TO %9.4f  P_SL %8.4f  S_ref %8.4f  W/S %7.4f\n', rA.W_TO, rA.P_SL, rA.S_ref, rA.WS);
fprintf('  fixed_wing_area        W_TO %9.4f  P_SL %8.4f  S_ref %8.4f  W/S %7.4f\n', rB.W_TO, rB.P_SL, rB.S_ref, rB.WS);
fprintf('  relative difference    %.2e (weight), %.2e (power)\n', ...
        abs(rB.W_TO-rA.W_TO)/rA.W_TO, abs(rB.P_SL-rA.P_SL)/rA.P_SL);

fprintf('\n=== CLAIM D: the aspect-ratio trade study reproduces the lecture ===\n');
fprintf('  Empty weight II must say "more AR is always better" (edge minimum);\n');
fprintf('  Empty weight III must show a real interior minimum.\n');
ARs = 6:0.5:12;
for wm = ["table_15_2","raymer_ga_III"]
    W = nan(size(ARs));
    for i = 1:numel(ARs)
        try
            r = one_(jp, struct('AR',ARs(i),'weights',wm,'mode',"fixed_wing_area"));
            W(i) = r.W_TO;
        catch, end
    end
    [m,k] = min(W);
    edge = (k==1) || (k==numel(ARs));
    fprintf('  %-14s MTOW min %.1f lbf at AR %.1f   %s\n', wm, m, ARs(k), ...
        string(ternary_(edge,'AT THE EDGE - no interior optimum','<- INTERIOR OPTIMUM')));
end

fprintf('\n=== CLAIM E: the cruise-constraint methods disagree as documented ===\n');
obp = build_(jp, struct()); obp.geom.S_ref = 128.47; obp.prop.P_SL = 555.53;
obd = build_(jp, struct('cruise',"drag_based")); obd.geom.S_ref = 128.47; obd.prop.P_SL = 555.53;
ic = find(arrayfun(@(k) get_con(k,obp.cons).type=="cruise_speed", 1:numel(obp.cons)), 1);
fprintf('  at W/S = 40:  power_index W/P <= %.3f    drag_based W/P <= %.3f\n', ...
        constraint_cruise_speed(40,obp,ic), constraint_cruise_speed(40,obd,ic));
[~,~,~,wso1,wpo1] = matching_envelope(linspace(15,50,500), obp);
[~,~,~,wso2,wpo2] = matching_envelope(linspace(15,50,500), obd);
fprintf('  envelope corner: power_index (%.3f, %.3f)   drag_based (%.3f, %.3f)\n', wso1,wpo1,wso2,wpo2);
fprintf('  -> under drag_based the corner MOVES, so the design point is no longer stationary.\n');

fprintf('\n=== CLAIM F: guess robustness of both modes ===\n');
for m = ["design_point","fixed_wing_area"]
    ok=0; n=0; bad=[]; W=[];
    for g = 2500:500:10000
        n=n+1; o=opts_(J0,m); o.W_TO_guess=g;
        try
            r=sizing_loop(build_(jp,struct()),o);
            if r.converged, ok=ok+1; W(end+1)=r.W_TO; else, bad(end+1)=g; end
        catch, bad(end+1)=g; end
    end
    fprintf('  %-16s %2d/%2d converged, W_TO spread %.2e lbf', m, ok, n, max(W)-min(W));
    if isempty(bad), fprintf('   (every guess)\n'); else, fprintf('   failed at %s\n', mat2str(bad)); end
end

fprintf('\nFRAMEWORK VERIFICATION COMPLETE\n');


%% ---------------- helpers ----------------
function ob = build_(jp, change)
    J = jsondecode(fileread(jp));
    if isfield(change,'weights'), J.weights.method = char(change.weights); end
    if isfield(change,'mission'), J.missions.std_mission.method = char(change.mission); end
    if isfield(change,'AR'),      J.geometry.AR = change.AR; end
    if isfield(change,'cruise')
        for k=1:numel(J.constraints.conditions)
            if strcmp(J.constraints.conditions{k}.type,'cruise_speed')
                J.constraints.conditions{k}.method = char(change.cruise);
            end
        end
    end
    t = fullfile(tempdir,'ttpa_vfw.json');
    fid=fopen(t,'w'); fwrite(fid,jsonencode(J)); fclose(fid);
    pr=TtpaProp(t); g=TtpaGeom(t,pr); a=TtpaAero(t,g); w=TtpaWeights(t,g,pr);
    mi=MissionProfileReader.read_profile(t,'std_mission');
    c=ConstraintSetImporter.read_conditions(t);
    ob=struct('aero',a,'prop',pr,'wts',w,'geom',g,'miss',mi,'cons',c);
    delete(t);
end

function o = opts_(J, mode)
    S=J.sizing; C=J.constraints;
    relax = S.relaxation_W;
    if mode=="fixed_wing_area" && isfield(S,'relaxation_fixed_wing_area')
        relax = S.relaxation_fixed_wing_area;
    end
    o = struct('mode',mode,'S_ref',S.S_ref_ft2,'W_TO_guess',S.W_TO_guess_lbf, ...
        'tol_rel',S.tol_rel,'max_iter',800,'relax_W',relax,'relax_P',relax, ...
        'design_point_mode',"selected", ...
        'WS_sweep',linspace(C.wing_loading_range_psf(1),C.wing_loading_range_psf(2),C.wing_loading_points), ...
        'selected',struct('WS',C.design_point.wing_loading_psf, ...
                          'WP',C.design_point.power_loading_lb_per_hp));
end

function r = one_(jp, change)
    J = jsondecode(fileread(jp));
    ob = build_(jp, change);
    o = opts_(J, change.mode);
    if isfield(change,'S_ref'), o.S_ref = change.S_ref; end
    r = [];
    for rx = [o.relax_W 0.30 0.20 0.12]
        try
            o.relax_W=rx; o.relax_P=rx;
            r = sizing_loop(ob,o);
            if r.converged, return; end
        catch, r=[]; end
    end
    if isempty(r), error('one_:noClosure','no closure'); end
end

function s = ternary_(c,a,b), if c, s=a; else, s=b; end, end
