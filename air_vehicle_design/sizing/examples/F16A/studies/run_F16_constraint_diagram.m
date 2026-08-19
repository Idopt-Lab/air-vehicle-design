%% run_F16_constraint_diagram
%   Builds the F-16's 8 constraint objects (F16ConstraintSet, reading
%   f16a_requirements.json), aggregates them (ConstraintAnalysis), and
%   produces the constraint diagram + optimum design point.
%
%   Stall is not among the 8 conditions -- see F16ConstraintSet.m's header: its
%   L2/L3 geometry-based clean-CLmax wall would spuriously dominate the design
%   point (W/S ~ 62 vs the ~83-104 range the real conditions + Brandt give).
%   The clean-CLmax fix belongs in aerodynamics (ToDo_Darshan.md §3).
%
%   This script builds the L3 discipline objects explicitly and injects them
%   into ConstraintAnalysis.from_requirements. To analyze a different fidelity
%   level, swap the three construction lines below for the matching L1/L2 constructors
%   (see f16_sizing_L1.m / f16_sizing_L2.m); to analyze a subset of
%   conditions, trim the constraints list.

% Caller owns discipline construction (dependency injection): build the L3
% aero/prop pair explicitly, then hand it to the constraint set. L3 uses
% F16PropL2 (no L3 propulsion tier) and injects prop into geometry, whose
% nacelle diameter sizes the duct wetted area and hence CD0.
prop = F16PropL2(f16a_spec_path(2));
geom = F16GeomL3(f16a_spec_path(3), prop, f16a_requirements_path());
aero = F16AeroL3(geom, f16a_spec_path(3));

ca = ConstraintAnalysis.from_requirements(aero, prop, f16a_requirements_path(), ...
    F16ConstraintSet.constraint_map(), PointPerformanceBase.WS_RANGE_BRANDT);
ca.plot_diagram();
ca.report();
