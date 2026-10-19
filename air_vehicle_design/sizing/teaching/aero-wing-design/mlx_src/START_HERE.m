%[text] # START HERE
%[text] # AOE 4065 - Aerodynamics and Wing Design
%[text] Run this file first. It puts the lesson helpers on the MATLAB path, checks your release, and computes one number to prove that the package works.
%[text] Everything is inside this folder. Nothing else has to be installed or downloaded.
%%
%[text] ## 1. Put the helpers on the path
root = setup_aero_path()
%%
%[text] ## 2. Check the release
%[text] The Live Scripts in this package were saved on R2026a. The code runs on R2022b or newer.
%[text] No toolbox is necessary. All scripts use the helpers in this folder only. The atmosphere comes from `isa_si`.
rel     = version('-release');
relYear = str2double(rel(1:4));
relOK   = relYear > 2022 || (relYear == 2022 && rel(5) >= 'b');
releaseCheck = table(string(rel), relOK, ...
    'VariableNames', ["Your_release", "Release_OK"], 'RowNames', {'MATLAB'})
%%
%[text] ## 3. Smoke test - the 737 MAX 8 in cruise
%[text] This computes the drag of the 737 MAX 8 at its cruise condition (M 0.785 at 35,000 ft). An L/D near 18 means the package works.
ac = b737_baseline();
o  = aero_737(ac, 3);
W  = ac.MTOW*ac.frac_to*ac.frac_cl*9.80665;      % weight at the start of cruise (N)
CL = W/(o.q*ac.S);
smoke = table([CL; o.CD0; o.K; CL/(o.CD0 + o.K*CL^2)], 'VariableNames', "Value", ...
    'RowNames', {'Cruise CL', 'CD0', 'K', 'Cruise L/D  (expect about 18)'})
%%
%[text] ## 4. What is in this folder
%[text] **`lecture/`** - the Boeing 737 MAX 8 walkthrough, L01 to L05. Run them in order.
%[text] **`lab/`** - the assignment, `LAB01_pick_the_AR`.
%[text] **`helpers/`** - short functions that hold the textbook equations. Each one names its source (book, edition, equation, page). Read them; they are short.
%[text] **`output/`** - somewhere to save your figures.
%%
%[text] ## 5. How to run a Live Script in class
%[text] Press **Ctrl+Enter** to run one section and stay put. Press **Ctrl+Shift+Enter** to run a section and move to the next. The lecture files are meant to be used one section at a time, with the output on screen.
%[text] All quantities are SI: m, kg, N, Pa, s. Where a textbook equation uses British units (Raymer Eq. 15.25, for example), the helper converts the inputs and the result, and the comments show the conversion.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
