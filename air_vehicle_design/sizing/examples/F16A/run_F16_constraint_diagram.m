%% run_F16_constraint_diagram
%   Builds the F-16's 8 constraint objects (F16ConstraintSet, reading
%   Constraints.xlsx), aggregates them (ConstraintAnalysis), and produces the
%   constraint diagram + optimum design point.
%
%   Edit fidelityLevel and/or trim the constraints list below to analyze a
%   different fidelity level or a subset of conditions.

fidelityLevel = "L1";   % "L1" | "L2" | "L3"

constraints = F16ConstraintSet.build(fidelityLevel);

ca = ConstraintAnalysis(constraints, PointPerformanceBase.WS_RANGE_BRANDT);
ca.plot_diagram();
ca.report();
