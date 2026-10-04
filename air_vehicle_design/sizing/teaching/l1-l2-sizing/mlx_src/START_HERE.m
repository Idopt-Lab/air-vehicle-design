%[text] # START HERE
%[text] # AOE 4065 - Aircraft Sizing
%[text] Run this file first. It puts the framework on the MATLAB path, checks that you have the two toolboxes the sizing loops need, and sizes an aircraft to prove the package works.
%[text] Everything is inside this folder. Nothing else has to be installed or downloaded.

%%
%[text] ## 1. Put the framework on the path
root = setup_sizing_path()

%%
%[text] ## 2. Check the release
%[text] The framework needs R2022b or newer. Live Scripts in this package were saved on R2026a.

rel     = version('-release');
relYear = str2double(rel(1:4));
relOK   = relYear > 2022 || (relYear == 2022 && rel(5) >= 'b');

releaseCheck = table(string(rel), relOK, ...
    'VariableNames', ["Your_release", "OK"], 'RowNames', {'MATLAB'})

%%
%[text] ## 3. Check the two toolboxes
%[text] **Aerospace Toolbox** supplies `atmosisa`, the standard atmosphere. Every flight condition in the framework is built with it.
%[text] **Optimization Toolbox** supplies `fmincon`, which both sizing loops use to find the design point.
%[text] If either row says false, the sizing loops will not run. Install the missing toolbox through the MATLAB Add-On Explorer, or use a lab machine.

haveAero = exist('atmosisa', 'file') > 0;
haveOpt  = exist('fmincon',  'file') > 0;

toolboxes = table([haveAero; haveOpt], ["atmosisa"; "fmincon"], ...
    'VariableNames', ["Available", "Function_needed"], ...
    'RowNames', {'Aerospace Toolbox', 'Optimization Toolbox'})

%%
%[text] ## 4. Smoke test - size a Boeing 777
%[text] This builds the whole 777 discipline stack and runs the Level-1 sizing loop. It takes a few seconds. A converged result near 740,000 lbf means the package is working.

assert(haveAero && haveOpt, ...
    "A required toolbox is missing. See the table above.");

[aero, prop, wts, geom, miss, con] = build_b777_stack();
result = SizingLoopL1(aero, prop, wts, geom, miss, con).run(700000);

smoke = table([result.W_TO; result.T_SL; result.S_ref; result.n_iter; result.converged], ...
    'VariableNames', "Value", 'RowNames', ...
    {'W_TO  [lbf]  (expect about 740,000)', 'T_SL  [lbf]', 'S_ref [ft^2]', ...
     'iterations', 'converged'})

%%
%[text] ## 5. What is in this folder
%[text] **`guide/`** - `Sizing_Guide.pdf` is the written reference: the algorithm, the diagrams, and the Level-1 against Level-2 comparison. `diagrams.html` opens the same diagrams in a browser, with pan and zoom, and needs no internet.
%[text] **`lecture/`** - the Boeing 777 walkthrough, L01 to L07. Run them in order.
%[text] **`lab/`** - the F-16A exercise. `LAB00` is a worked warm-up; `LAB01` is the one you write.
%[text] **`helpers/`** - small functions the Live Scripts call, so the scripts stay about sizing instead of plumbing. Read them; they are short.
%[text] **`framework/`** - the sizing framework itself. You do not need to edit anything in here.
%[text] **`output/`** - somewhere to save your figures. \

%%
%[text] ## 6. How to run a Live Script in class
%[text] Press **Ctrl+Enter** to run one section and stay put. Press **Ctrl+Shift+Enter** to run a section and move to the next. That is how the lecture files are meant to be used: one section at a time, with the output on screen.
%[text] A warning about handles: every discipline object is a MATLAB `handle`, and a sizing run **writes into it**. Build a fresh stack before each run. Every script here does that with `build_b777_stack` or `build_f16_stack_L2`.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
