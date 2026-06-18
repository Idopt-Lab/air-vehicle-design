% run_sizing_template.m
%
% Generic template showing how to wire discipline objects to a sizing loop.
% Replace each placeholder class with the appropriate F-16 (or other aircraft)
% subclass from examples/. Fidelity level is changed by swapping class names only
% — the sizing loop code below does not change.
%
% This script is intentionally abstract: it will not run as-is. Copy it to
% examples/<your-aircraft>/ and substitute aircraft-specific classes.

%% 0. Load aircraft configuration
json_path = fullfile(fileparts(mfilename('fullpath')), ...
    '..', 'examples', '<aircraft>', 'Ground-Truth', '<aircraft>_geometry.json');
geom_json = jsondecode(fileread(json_path));

%% 1. Requirements struct
% Populate with aircraft-specific mission definition.
req.W_payload    = 0;          % payload weight (lbf)
req.S_ref        = 300;        % wing area (ft²) — used as fixed input for L2 sizing
req.AR           = 3.0;        % aspect ratio — used by L2/L3 mission analysis
req.W_TO_init    = 30000;      % initial TOGW guess (lbf)

% Mission segments
seg(1).name = 'startup';    seg(1).altitude_ft = 0;     seg(1).mach = 0;
seg(2).name = 'taxi';       seg(2).altitude_ft = 0;     seg(2).mach = 0;
seg(3).name = 'takeoff';    seg(3).altitude_ft = 0;     seg(3).mach = 0.2;
seg(4).name = 'climb';      seg(4).altitude_ft = 20000; seg(4).mach = 0.8;
seg(5).name = 'cruise';     seg(5).altitude_ft = 36000; seg(5).mach = 0.85; seg(5).range_ft = 500*6076;
seg(6).name = 'combat';     seg(6).altitude_ft = 20000; seg(6).mach = 0.9;  seg(6).time_min = 5;  seg(6).W_drop = 0;
seg(7).name = 'loiter';     seg(7).altitude_ft = 5000;  seg(7).mach = 0.3;  seg(7).time_min = 20;
seg(8).name = 'descent';    seg(8).altitude_ft = 0;     seg(8).mach = 0.3;
seg(9).name = 'landing';    seg(9).altitude_ft = 0;     seg(9).mach = 0.2;
req.segments = seg;

%% 2. Discipline objects  ← SWAP THESE LINES TO CHANGE FIDELITY
%
% --- Level I example ---
% aero  = F16AeroLevel1(geom_json);
% prop  = F16PropulsionLevel1(geom_json);
% wts   = F16WeightLevel1(geom_json);
% geom  = F16GeometryLevel1(geom_json);
% miss  = F16MissionLevel1(geom_json);
% con   = F16ConstraintAnalysis(aero, prop, req);
%
% --- Level II example ---
% aero  = F16AeroLevel2(geom_json);
% prop  = F16PropulsionLevel2(geom_json);
% wts   = F16WeightLevel2(geom_json);
% geom  = F16GeometryLevel2(geom_json);
% miss  = F16MissionLevel2();
% con   = F16ConstraintAnalysis(aero, prop, req);
% tail  = F16TailSizingLevel1();          % only needed for L2 sizing loop
%
% --- Level III example ---
% aero  = F16AeroLevel3(geom_json);
% prop  = F16PropulsionLevel3(geom_json);
% wts   = F16WeightLevel3(geom_json);
% geom  = F16GeometryLevel3(geom_json);
% miss  = F16MissionLevel3();             % same interface, better integration
% con   = F16ConstraintAnalysis(aero, prop, req);
% tail  = F16TailSizingLevel1();

%% 3. Sizing loop  ← same code regardless of discipline fidelity level

% --- L1 sizing: S_ref is an output; iterates W_TO alone ---
% sizer = SizingLoopL1(struct('verbose', true));
% [W_TO, S_ref, T_SL] = sizer.run(req, aero, prop, wts, geom, miss, con);

% --- L2 sizing: S_ref is an input; iterates W_TO and T_SL together ---
% sizer = SizingLoopL2(struct('verbose', true));
% [W_TO, T_SL] = sizer.run(req, aero, prop, wts, geom, miss, con, tail);

%% 4. Print results
% fprintf('W_TO  = %8.1f lbf\n', W_TO);
% fprintf('T_SL  = %8.1f lbf\n', T_SL);
% fprintf('S_ref = %8.2f ft^2\n', req.S_ref);
% fprintf('OEW   = %8.1f lbf\n', wts.OEW(W_TO));
