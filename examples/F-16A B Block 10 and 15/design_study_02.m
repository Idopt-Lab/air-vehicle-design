% design_study_02.m  — F-16A Level II sizing
%
% Disciplines: L2 aero + L2 mission + L2 weights + L2 geometry + L1 tail sizing
% Sizing loop:  SizingLoopL2 (iterates W_TO and T_SL; S_ref is fixed input)
%
% Compared to study 01: aero uses Oswald efficiency; mission uses Breguet
% segment equations; sizing iterates both W_TO and T_SL simultaneously;
% tail surfaces are sized at each iteration.
%
% Brandt validation targets:
%   W_TO = 31,377 lb   OEW = 19,980 lb   fuel = 6,000 lb
%   W/S  = 104.59 psf  T/W = 0.7575      T_SL = 23,770 lb
%   S_HT ≈ 108 ft²     S_VT ≈ 60 ft²

%% 0. Paths
repo_root = fullfile(fileparts(mfilename('fullpath')), '..', '..');
addpath(genpath(fullfile(repo_root, 'src')));
addpath(genpath(fullfile(repo_root, 'examples')));

%% 1. Load F-16 configuration
json_path = fullfile(fileparts(mfilename('fullpath')), ...
    'Ground-Truth', 'f16a_geometry.json');
geom_json = jsondecode(fileread(json_path));

%% 2. Mission requirements
S_ref_fixed = geom_json.wing.S_ref_ft2;
W_payload   = geom_json.weight.exp_payload_lb;
W_payload_perm = geom_json.weight.perm_payload_lb;

req = struct();
req.W_payload   = W_payload + W_payload_perm;
req.W_TO_init   = 30000;
req.S_ref       = S_ref_fixed;          % fixed for L2 sizing
req.AR          = geom_json.wing.AR;

% Same mission segments as design_study_01
seg(1).name = 'startup';   seg(1).altitude_ft = 0;     seg(1).mach = 0;
seg(2).name = 'taxi';      seg(2).altitude_ft = 0;     seg(2).mach = 0;
seg(3).name = 'takeoff';   seg(3).altitude_ft = 0;     seg(3).mach = 0.282;
seg(4).name = 'climb';     seg(4).altitude_ft = 40000; seg(4).mach = 0.87;
seg(5).name = 'cruise';    seg(5).altitude_ft = 40000; seg(5).mach = 0.87;
                             seg(5).range_ft = 190.8*6076;
seg(6).name = 'dash';      seg(6).altitude_ft = 40000; seg(6).mach = 0.87;
                             seg(6).range_ft = 50*6076;
seg(7).name = 'combat';    seg(7).altitude_ft = 25000; seg(7).mach = 0.87;
                             seg(7).time_min = 2; seg(7).W_drop = W_payload;
seg(8).name = 'cruise';    seg(8).altitude_ft = 40000; seg(8).mach = 0.87;
                             seg(8).range_ft = 250*6076;
seg(9).name = 'loiter';    seg(9).altitude_ft = 10000; seg(9).mach = 0.30;
                             seg(9).time_min = 20;
seg(10).name = 'descent';  seg(10).altitude_ft = 0; seg(10).mach = 0.3;
seg(11).name = 'landing';  seg(11).altitude_ft = 0; seg(11).mach = 0.2;
req.segments = seg;

%% 3. Discipline objects (Level II)
aero  = F16AeroLevel2(geom_json);
prop  = F16PropulsionLevel2(geom_json);
wts   = F16WeightLevel2(geom_json);
geom  = F16GeometryLevel2(geom_json);
miss  = F16MissionLevel2();
con   = F16ConstraintAnalysis(geom_json);
tail  = F16TailSizingLevel1();

%% 4. Level II sizing loop (iterates W_TO and T_SL together)
sizer = SizingLoopL2(struct('verbose', true, 'tol', 0.5));
[W_TO, T_SL] = sizer.run(req, aero, prop, wts, geom, miss, con, tail);

%% 5. Derived quantities
OEW   = wts.OEW(W_TO);
fuel  = miss.compute_fuel(aero, prop, W_TO, req);
T_W   = T_SL / W_TO;
W_S   = W_TO / S_ref_fixed;
S_HT  = geom.S_HT;
S_VT  = geom.S_VT;

%% 6. Report
fprintf('\n=== Design Study 02 — F-16A Level II Sizing ===\n');
fprintf('%-22s %10.1f lb    (Brandt: 31,377)\n', 'W_TO:',  W_TO);
fprintf('%-22s %10.1f lb    (Brandt: 19,980)\n', 'OEW:',   OEW);
fprintf('%-22s %10.1f lb    (Brandt:  6,000)\n', 'Fuel:',  fuel);
fprintf('%-22s %10.1f lb    (Brandt: 23,770)\n', 'T_SL:',  T_SL);
fprintf('%-22s %10.3f       (Brandt: 0.7575)\n', 'T/W:',    T_W);
fprintf('%-22s %10.2f psf   (Brandt: 104.59)\n', 'W/S:',    W_S);
fprintf('%-22s %10.1f ft2   (Brandt:    108)\n', 'S_HT:',   S_HT);
fprintf('%-22s %10.1f ft2   (Brandt:     60)\n', 'S_VT:',   S_VT);
