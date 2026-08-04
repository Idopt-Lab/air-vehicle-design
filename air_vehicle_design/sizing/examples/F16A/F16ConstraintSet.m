classdef F16ConstraintSet
%F16CONSTRAINTSET  Builds the F-16's 8 point-performance/field constraint
%   objects from examples/F16A/Constraints.xlsx, plus an optional 9th Stall
%   condition not yet present in that workbook (see STALL_MACH below).
%
%   Layer-2 (aircraft-specific) wiring: reads the F-16's constraint
%   conditions (altitude, Mach, weight fraction, load factor, specific
%   excess power for the 6 point-performance rows; field length, friction
%   coefficient for the 2 field rows) via ConstraintSetImporter, then
%   instantiates the matching generic Layer-1 constraint class per row --
%   ThrustConstraint (Mattingly Master Equation) for every row except
%   Takeoff/Landing, TakeoffConstraint/LandingConstraint (ground-roll
%   equations) for those two -- wired to the F-16 aero/prop discipline
%   objects for the requested fidelity level. A 9th constraint, Stall
%   (StallConstraint), can be appended directly rather than read from the
%   sheet (see STALL_MACH's comment for why) -- EXCLUDED BY DEFAULT
%   (changed 2026-07-27; was included by default until then).
%
%   WHY includeStall NOW DEFAULTS TO FALSE: Stall has no Brandt reference
%   row to validate its CLmax against (StallConstraint.m's header), and at
%   L2/L3 its wall sits on AeroL2/L3's geometry-based CLEAN CLmax estimate
%   (Raymer Eq. 12.15, ~0.91 -- see F16AeroL2.m/F16AeroL3.m's documented
%   1.50-vs-0.91 clean-CLmax discontinuity vs. L1's Roskam-table value).
%   That low CLmax put Stall's wall at W/S~=62-64 psf, tighter than every
%   real Constraints.xlsx condition, so it silently became the BINDING
%   constraint and pulled the reported optimum down to W/S~=62 at L2/L3 --
%   vs. Brandt's own W/S=104.59 and Casey's legacy-code result of ~125
%   (user-reported 2026-07-27, contradicting `TestF16ConstraintSet.m`'s
%   prior comment that this was "a real, physically expected shift, not a
%   bug"; it was a bug). Dropping Stall from the default build raises L2/L3
%   to W/S~=83 -- still short of Brandt/legacy, but that residual gap
%   traces to the same already-documented aero/propulsion fidelity gaps
%   (CD0, thrust-lapse) affecting the real Landing/Takeoff/thrust curves,
%   not to this class. Stall is still available as a sanity-check overlay
%   via includeStall=true; it just no longer determines the design point.
%
%   See sizing/docs/subplans/06_constraint_analysis.md, "F-16 Constraint
%   Conditions" tables, for the condition data; the constraint equations
%   themselves are cited in ThrustConstraint.m/TakeoffConstraint.m/
%   LandingConstraint.m/StallConstraint.m, not repeated here.
%
%   POWER SETTING IS WIRED FROM THE SHEET (fixed 2026-07-25): the workbook's
%   "AB%" column (read as row.AB_) selects each thrust row's alpha basis --
%   0% -> powerSetting="mil" (PropulsionBase.thrust_lapse_mil_on_AB_scale),
%   100% -> powerSetting="AB" (PropulsionBase.thrust_lapse). Before this fix
%   every row took ThrustConstraint's "AB" default, so the F-16's one dry-power
%   condition (Cruise, AB%=0) was built on the afterburner lapse and its
%   required T/W came out ~2.6x low -- the ~-58% error that
%   cruise_and_combatturn2_error_scrape.md records as FIXED. The fix had landed
%   in ThrustConstraint/TestThrustConstraint but never in this production build
%   path. See mapPowerSetting below.
%
%   NOT WIRED FROM THE SHEET (intentional, documented gaps -- out of scope
%   here):
%     Vstall -- would-be k_TO/k_L touchdown/liftoff speed margins. The sheet
%               currently disagrees with TakeoffConstraint/LandingConstraint's
%               documented defaults (k_TO=1.2, k_L=1.3, per subplan 06's
%               Field Constraints table) -- Takeoff's Vstall=1.3, Landing's
%               is blank -- so this class keeps those classes' own defaults
%               rather than reading a value that may not be finalized.

    properties (Constant, Access = private)
        %STALL_MACH  Mach number of the F-16 stall-speed requirement, sea
        %   level [Brandt F-16A.xls, "Ps" sheet, cell B10 -- see F16Baseline.m's
        %   b.constraints.stall.mach, same value]. examples/F16A/Constraints.xlsx
        %   has no Stall row yet (unlike the other 8 conditions), so this is
        %   hardcoded here rather than read via ConstraintSetImporter; flag
        %   for spreadsheet backfill.
        STALL_MACH = 0.217466
    end

    methods (Static)

        function constraints = build(aero, prop, includeStall)
        %BUILD  Construct the F-16's constraint objects, wired to the given
        %   aero/prop discipline objects. Returns a 1xN cell array of
        %   PointPerformanceBase objects, in Constraints.xlsx row order
        %   (plus a trailing Stall condition, unless includeStall is false),
        %   ready to hand to ConstraintAnalysis (as-is, or trimmed/reordered
        %   by the caller first).
        %
        %   aero, prop -- the F-16 aerodynamics/propulsion discipline
        %     objects to wire into every constraint. PASSED IN, NOT BUILT
        %     HERE (changed 2026-08-03; this class used to take a
        %     fidelityLevel string and construct its own internal aero/prop
        %     pair via buildDisciplines, duplicating whatever aero/prop a
        %     caller like a design_study_*.m had already built for its
        %     sizing loop). aero/prop are typically handle objects mutated
        %     in place as a sizing loop iterates (e.g. SizingLoopL2.run()
        %     sets prop.T_SL and, via geom, aero's wetted area, each
        %     iteration) -- passing the SAME objects in here means every
        %     constraint's next required_TW/drag_polar read sees that
        %     update, instead of holding a separate, never-mutated copy.
        %     A caller with no existing aero/prop (e.g. a standalone
        %     diagram script) can get a fresh pair for a given fidelity
        %     level via buildDisciplines(fidelityLevel) first.
        %   includeStall -- default false (changed 2026-07-27; see this
        %   class's header for why). Stall was never one of
        %   subplans/06_constraint_analysis.md's original 8 diagram
        %   constraints (Constraints.xlsx only has 8 rows; Stall was added
        %   later as a 9th, sanity-check-only condition -- see this class's
        %   header and StallConstraint.m's "no Brandt reference row exists"
        %   note); pass includeStall=true to add it back as an overlay, e.g.
        %   for a sanity-check plot -- but note it will again dominate
        %   optimal_point() at L2/L3 if you do.
            arguments
                aero (1,1) AerodynamicsBase
                prop (1,1) PropulsionBase
                includeStall  (1,1) logical = false
            end

            thisFile = mfilename('fullpath');
            xlsxPath = fullfile(fileparts(thisFile), 'Constraints.xlsx');
            T = ConstraintSetImporter.read(xlsxPath, "Constraints");

            names = string(T.Properties.RowNames);
            constraints = cell(1, numel(names));
            for i = 1:numel(names)
                name = names(i);
                row  = T(i, :);
                switch name
                    case "Takeoff"
                        state = AircraftState(0, 0.1);
                        constraints{i} = TakeoffConstraint(name, state, aero, prop, ...
                            row.Distance_ft_, row.SurfaceFrictionCoefficient_mu_, row.W_Wto);
                    case "Landing"
                        state = AircraftState(0, 0.1);
                        constraints{i} = LandingConstraint(name, state, aero, ...
                            row.Distance_ft_, row.SurfaceFrictionCoefficient_mu_, row.W_Wto);
                    otherwise
                        state = AircraftState(row.Altitude_ft_, row.MachNumber);
                        Ps = row.PS_ft_s_;
                        if isnan(Ps)
                            Ps = 0;
                        end
                        constraints{i} = ThrustConstraint(name, state, aero, prop, ...
                            row.W_Wto, row.n, Ps, ...
                            F16ConstraintSet.mapPowerSetting(name, row.AB_));
                end
            end

            if includeStall
                stallState = AircraftState(0, F16ConstraintSet.STALL_MACH);
                constraints{end+1} = StallConstraint("Stall", stallState, aero);
            end
        end

    end

    methods (Static)

        function [aero, prop] = buildDisciplines(fidelityLevel)
        %BUILDDISCIPLINES  Fresh F-16 aero/prop discipline pair for a
        %   fidelity level, for callers that don't already have one to pass
        %   into build() (e.g. a standalone diagram script). A caller that
        %   already has aero/prop (a design study, mid sizing-loop) should
        %   use those directly instead of calling this -- see build()'s
        %   header for why sharing, not rebuilding, matters.
        %
        %   PROPULSION AT THE L3 RUNG: there is deliberately NO L3 propulsion
        %   tier -- no PropL3/PropulsionModelL3/F16PropL3 exists, and none is
        %   planned (user decision 2026-07-25). L3 pairs F16AeroL3 with
        %   F16PropL2, and anything reporting L3 propulsion numbers must label
        %   them "computed by F16PropL2". Same pairing the constraint tests use.
        %
        %   GEOMETRY IS NOW INJECTED INTO BOTH AERO AND PROPULSION-AWARE
        %   GEOMETRY (Phase 2, 2026-07-25): F16GeomL{2,3} take the propulsion
        %   object, because the nacelle diameter -- and therefore duct wetted
        %   area and CD0 -- is sized from engine thrust. L3 now builds
        %   F16GeomL3, the full L3 geometry tier; it previously injected
        %   F16GeomL2, which made f16a_L3.json's whole .geometry block dead
        %   input (an edit there changed nothing).
            arguments
                fidelityLevel (1,1) string {mustBeMember(fidelityLevel, ["L1", "L2", "L3"])}
            end
            switch fidelityLevel
                case "L1"
                    aero = F16AeroL1(f16a_spec_path(1));
                    prop = F16PropL1(f16a_spec_path(1));
                case "L2"
                    prop = F16PropL2(f16a_spec_path(2));
                    aero = F16AeroL2(F16GeomL2(f16a_spec_path(2), prop), f16a_spec_path(2));
                case "L3"
                    prop = F16PropL2(f16a_spec_path(2));
                    aero = F16AeroL3(F16GeomL3(f16a_spec_path(3), prop), f16a_spec_path(3));
            end
        end

    end

    methods (Static, Access = private)

        function powerSetting = mapPowerSetting(name, AB_percent)
        %MAPPOWERSETTING  Workbook "AB%" -> ThrustConstraint powerSetting.
        %   0% afterburner is a dry/military-power condition, whose thrust lapse
        %   must come from PropulsionBase.thrust_lapse_mil_on_AB_scale
        %   (T_mil/T_SL_AB) rather than the AB-basis thrust_lapse -- see
        %   ThrustConstraint.get_alpha and
        %   cruise_and_combatturn2_error_scrape.md Sec. 2.
        %
        %   Errors rather than defaulting on a missing or partial value: an
        %   unstated power setting silently defaulting to "AB" is exactly the
        %   bug this method exists to prevent, and ThrustConstraint models only
        %   the two discrete bases (there is no partial-AB thrust model).
            arguments
                name       (1,1) string
                AB_percent (1,1) double
            end
            if isnan(AB_percent)
                error('F16ConstraintSet:missingPowerSetting', ...
                    ['Constraint row "%s" has no AB%% value. A ThrustConstraint ', ...
                     'needs an explicit power setting (0 = mil, 100 = AB); ', ...
                     'fill the AB%% column in Constraints.xlsx.'], name);
            end
            switch AB_percent
                case 0,   powerSetting = "mil";
                case 100, powerSetting = "AB";
                otherwise
                    error('F16ConstraintSet:partialAfterburnerNotModeled', ...
                        ['Constraint row "%s" specifies AB%% = %g. Only 0 (mil) ', ...
                         'and 100 (full AB) are modeled -- PropulsionBase exposes ', ...
                         'no partial-afterburner thrust lapse.'], name, AB_percent);
            end
        end

    end

end
