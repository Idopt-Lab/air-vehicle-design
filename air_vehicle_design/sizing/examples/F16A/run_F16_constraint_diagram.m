%% run_F16_constraint_diagram
%   Builds the F-16's 8 constraint objects (F16ConstraintSet, reading
%   f16a_requirements.json), aggregates them (ConstraintAnalysis), and
%   produces the constraint diagram + optimum design point.
%
%   Stall (F16ConstraintSet's 9th, sanity-check-only condition) is excluded
%   by default -- see F16ConstraintSet.m's header: it has no Brandt
%   reference row, and at L2/L3 its geometry-based clean-CLmax wall was
%   found to silently dominate the design point (W/S~=62 instead of the
%   ~83-104 range the real requirements-JSON conditions + Brandt give).
%   Pass includeStall=true to F16ConstraintSet.build (i.e.
%   F16ConstraintSet.build(aero, prop, true)) to add it back as an overlay
%   if wanted.
%
%   This script builds the L3 discipline objects explicitly and injects them
%   into F16ConstraintSet.build. To analyze a different fidelity level, swap
%   the three construction lines below for the matching L1/L2 constructors
%   (see design_study_01_L1.m / design_study_02_L2.m); to analyze a subset of
%   conditions, trim the constraints list.

% Caller owns discipline construction (dependency injection): build the L3
% aero/prop pair explicitly, then hand it to the constraint set. L3 uses
% F16PropL2 (no L3 propulsion tier) and injects prop into geometry, whose
% nacelle diameter sizes the duct wetted area and hence CD0.
prop = F16PropL2(f16a_spec_path(2));
geom = F16GeomL3(f16a_spec_path(3), prop);
aero = F16AeroL3(geom, f16a_spec_path(3));

constraints = F16ConstraintSet.build(aero, prop);

ca = ConstraintAnalysis(constraints, PointPerformanceBase.WS_RANGE_BRANDT);
ca.plot_diagram();
ca.report();
