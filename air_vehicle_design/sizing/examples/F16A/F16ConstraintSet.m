classdef F16ConstraintSet
%F16CONSTRAINTSET  Builds the F-16's 9 constraint objects (6 thrust, 2 field,
%   1 stall) from examples/F16A/jsons/f16a_requirements.json, with the Stall
%   condition excluded by default.
%
%   Layer-2 (aircraft-specific) wiring: reads the F-16's constraint
%   conditions (altitude, Mach, weight fraction, load factor, specific
%   excess power for the 6 point-performance rows; field length, friction
%   coefficient, k-factor for the 2 field rows; liftoff Mach for takeoff;
%   Mach for stall) from the requirements JSON via
%   ConstraintSetImporter.read_conditions, then instantiates the matching
%   generic Layer-1 constraint class per condition using EXPLICIT JSON keys.
%   The Master-Equation thrust rows map to the MasterEquationConstraint
%   subtree by their own data (T9, 2026-08-04): Ps_fps>0 ->
%   ExcessPowerConstraint, else n>1 -> SustainedTurnConstraint, else
%   LevelFlightConstraint. The two field rows map to TakeoffConstraint/
%   LandingConstraint (ground-roll equations); Stall maps to StallConstraint.
%   All are wired to the F-16 aero/prop discipline objects for the requested
%   fidelity level. The Stall condition is EXCLUDED BY DEFAULT (changed
%   2026-07-27; was included by default until then).
%
%   DATA SOURCE (changed 2026-08-04, subplan 06-refactor T3): the conditions
%   now come from the requirements JSON, resolved by f16a_requirements_path().
%   This replaces the previous examples/F16A/Constraints.xlsx read and its
%   brittle mangled-column-name coupling (row.Distance_ft_ / row.PS_ft_s_ /
%   row.AB_). power_setting ("AB"/"mil") now comes DIRECTLY from the JSON --
%   the old AB% -> power-setting mapping is gone. The Stall condition is now a
%   real JSON row too (it used to be hardcoded via a STALL_MACH constant).
%
%   ONE INTENTIONAL NUMERIC CHANGE with the JSON source: Takeoff is now
%   evaluated at the JSON's mach_liftoff = 0.2 (the real V_liftoff/a_SL,
%   Brandt Consts!AT32), where the Excel-era code hardcoded 0.1. rho at sea
%   level is Mach-independent, so this shifts nothing in TakeoffConstraint's
%   ground-roll equation (which reads only state.rho) -- the change makes the
%   modeled liftoff condition match Brandt, it does not move the F-16
%   optimum. Landing keeps the nominal sea-level M=0.1 state used only for its
%   rho.
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
%   See examples/F16A/mds/f16a_requirements.md and
%   sizing/docs/subplans/06_constraint_analysis.md, "F-16 Constraint
%   Conditions" tables, for the condition data; the constraint equations
%   themselves are cited in MasterEquationConstraint.m/TakeoffConstraint.m/
%   LandingConstraint.m/StallConstraint.m, not repeated here.
%
%   POWER SETTING COMES DIRECTLY FROM THE JSON (2026-08-04, T3): each thrust
%   condition carries an explicit power_setting key ("AB"/"mil") that selects
%   its alpha basis -- "mil" -> PropulsionBase.thrust_lapse_mil_on_AB_scale,
%   "AB" -> PropulsionBase.thrust_lapse. This replaces the earlier AB%->
%   power-setting mapping; the JSON stores the resolved setting, so no mapping
%   is needed here. requirePowerSetting below is a thin validator only: it
%   errors on a missing or non-{AB,mil} value, preserving the guard that a
%   silent "AB" default (the old cruise -58% bug,
%   cruise_and_combatturn2_error_scrape.md) is what this build path must
%   prevent.
%
%   FIELD SPEED MARGINS: the JSON's k_factor is now passed through to
%   TakeoffConstraint/LandingConstraint (k_TO/k_L) with the explicit keys
%   c.k_factor. The JSON values (1.2 takeoff, 1.3 landing; Brandt Main!U12/U13)
%   equal those classes' own defaults, so this is behavior-neutral versus the
%   pre-T3 code that let the defaults apply -- but the requirement value now
%   comes from the requirements file, not a src default.

    methods (Static)

        function constraints = build(fidelityLevel, includeStall)
        %BUILD  Construct the F-16's constraint objects for one fidelity
        %   level. Returns a 1xN cell array of PointPerformanceBase objects,
        %   in requirements-JSON condition order (Stall last), ready to hand
        %   to ConstraintAnalysis (as-is, or trimmed/reordered by the caller
        %   first).
        %   includeStall -- default false (changed 2026-07-27; see this
        %   class's header for why). The Stall condition is skipped unless
        %   includeStall is true; pass includeStall=true to add it back as an
        %   overlay, e.g. for a sanity-check plot -- but note it will again
        %   dominate optimal_point() at L2/L3 if you do.
            arguments
                fidelityLevel (1,1) string {mustBeMember(fidelityLevel, ["L1", "L2", "L3"])} = "L3"
                includeStall  (1,1) logical = false
            end

            [aero, prop] = F16ConstraintSet.buildDisciplines(fidelityLevel);

            cond = ConstraintSetImporter.read_conditions(f16a_requirements_path());

            constraints = cell(1, numel(cond));
            keep = false(1, numel(cond));
            for i = 1:numel(cond)
                c    = cond(i);
                name = string(c.name);
                switch name
                    case "Takeoff"
                        % State built at the real liftoff Mach (0.2), not the
                        % old hardcoded 0.1 -- rho at sea level is Mach-
                        % independent, so this only makes the modeled condition
                        % match Brandt (Consts!AT32); it does not move the
                        % optimum. See class header.
                        state = AircraftState(c.altitude_ft, c.mach_liftoff);
                        constraints{i} = TakeoffConstraint(name, state, aero, prop, ...
                            c.distance_ft, c.mu, c.beta, c.k_factor);
                        keep(i) = true;
                    case "Landing"
                        % Nominal low-Mach sea-level state used only for its
                        % rho (LandingConstraint reads no Mach) -- kept at the
                        % 0.1 the pre-T3 code used.
                        state = AircraftState(c.altitude_ft, 0.1);
                        constraints{i} = LandingConstraint(name, state, aero, ...
                            c.distance_ft, c.mu, c.beta, c.k_factor);
                        keep(i) = true;
                    case "Stall"
                        if includeStall
                            state = AircraftState(c.altitude_ft, c.mach);
                            constraints{i} = StallConstraint(name, state, aero);
                            keep(i) = true;
                        end
                    otherwise
                        % Master-Equation thrust row. Pick the specialization
                        % by data (T9): Ps_fps>0 -> ExcessPower, else n>1 ->
                        % SustainedTurn, else LevelFlight.
                        state = AircraftState(c.altitude_ft, c.mach);
                        powerSetting = F16ConstraintSet.requirePowerSetting(name, c);
                        if c.Ps_fps > 0
                            constraints{i} = ExcessPowerConstraint(name, state, aero, prop, ...
                                c.beta, c.Ps_fps, powerSetting);
                        elseif c.n > 1
                            constraints{i} = SustainedTurnConstraint(name, state, aero, prop, ...
                                c.beta, c.n, powerSetting);
                        else
                            constraints{i} = LevelFlightConstraint(name, state, aero, prop, ...
                                c.beta, powerSetting);
                        end
                        keep(i) = true;
                end
            end

            % Drop the skipped Stall slot (includeStall=false), preserving
            % JSON condition order for the rest.
            constraints = constraints(keep);
        end

    end

    methods (Static, Access = private)

        function powerSetting = requirePowerSetting(name, cond)
        %REQUIREPOWERSETTING  Read + validate a thrust row's power_setting.
        %   The requirements JSON stores the resolved setting ("AB"/"mil")
        %   directly, so no AB%->setting mapping is needed. "mil" is a
        %   dry/military-power condition, whose thrust lapse comes from
        %   PropulsionBase.thrust_lapse_mil_on_AB_scale (T_mil/T_SL_AB) rather
        %   than the AB-basis thrust_lapse -- see
        %   MasterEquationConstraint.get_alpha and
        %   cruise_and_combatturn2_error_scrape.md Sec. 2.
        %
        %   Errors rather than defaulting on a missing or out-of-set value: an
        %   unstated power setting silently defaulting to "AB" is exactly the
        %   bug this validator exists to prevent, and the Master-Equation
        %   classes model only the two discrete bases (there is no partial-AB
        %   thrust model).
            arguments
                name (1,1) string
                cond (1,1) struct
            end
            if ~isfield(cond, 'power_setting')
                error('F16ConstraintSet:missingPowerSetting', ...
                    ['Constraint "%s" has no power_setting key. A Master-Equation ', ...
                     'constraint needs an explicit power setting ("mil" or "AB"); ', ...
                     'add the power_setting field to this condition in the ', ...
                     'requirements JSON.'], name);
            end
            powerSetting = string(cond.power_setting);
            if ~ismember(powerSetting, ["AB", "mil"])
                error('F16ConstraintSet:invalidPowerSetting', ...
                    ['Constraint "%s" specifies power_setting = "%s". Only "mil" ', ...
                     'and "AB" are modeled -- PropulsionBase exposes no ', ...
                     'partial-afterburner thrust lapse.'], name, powerSetting);
            end
        end

        function [aero, prop] = buildDisciplines(fidelityLevel)
        %BUILDDISCIPLINES  F-16 aero/prop discipline pair for a fidelity level.
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

end
