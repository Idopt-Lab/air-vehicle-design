%% run_F16_constraint_diagram
%   Builds the F-16's 8 constraint objects (F16ConstraintSet, reading
%   Constraints.xlsx's 8 rows), aggregates them (ConstraintAnalysis), and
%   produces the constraint diagram + optimum design point.
%
%   Stall (F16ConstraintSet's 9th, sanity-check-only condition) is excluded
%   by default -- see F16ConstraintSet.m's header: it has no Brandt
%   reference row, and at L2/L3 its geometry-based clean-CLmax wall was
%   found to silently dominate the design point (W/S~=62 instead of the
%   ~83-104 range the real Constraints.xlsx conditions + Brandt give).
%   Pass F16ConstraintSet.build(fidelityLevel, true) to add it back as an
%   overlay if wanted.
%
%   Edit fidelityLevel and/or trim the constraints list below to analyze a
%   different fidelity level or a subset of conditions.

fidelityLevel = "L3";   % "L1" | "L2" | "L3"

constraints = F16ConstraintSet.build(fidelityLevel);

ca = ConstraintAnalysis(constraints, PointPerformanceBase.WS_RANGE_BRANDT);
ca.plot_diagram();
ca.report();
