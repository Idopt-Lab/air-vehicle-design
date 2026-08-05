classdef F16ConstraintSet
%F16CONSTRAINTSET  Builds the F-16's 9 constraint objects (6 thrust, 2 field,
%   1 stall) from examples/F16A/jsons/f16a_requirements.json, with the Stall
%   condition excluded by default.
%
%   Layer-2 (aircraft-specific) wiring. Reads the F-16's constraint conditions
%   from the requirements JSON via ConstraintSetImporter.read_conditions, then
%   instantiates the matching generic Layer-1 constraint class per condition
%   using explicit JSON keys. The Master-Equation thrust rows map to the
%   MasterEquationConstraint subtree by their own data: Ps_fps>0 ->
%   ExcessPowerConstraint, else n>1 -> SustainedTurnConstraint, else
%   LevelFlightConstraint. The two field rows map to
%   TakeoffConstraint/LandingConstraint; Stall maps to StallConstraint. All are
%   wired to the F-16 aero/prop discipline objects for the requested fidelity
%   level. Takeoff is evaluated at the JSON's mach_liftoff = 0.2 (Brandt
%   Consts!AT32); rho at sea level is Mach-independent, so this only makes the
%   modeled liftoff condition match Brandt, it does not move the optimum. See
%   examples/F16A/mds/f16a_requirements.md for the condition data; the
%   constraint equations are cited in MasterEquationConstraint.m /
%   TakeoffConstraint.m / LandingConstraint.m / StallConstraint.m.
%
%   WHY includeStall DEFAULTS TO FALSE: Stall has no Brandt reference row to
%   validate its CLmax against, and at L2/L3 its wall sits on AeroL2/L3's
%   geometry-based CLEAN CLmax estimate (~0.91 vs L1's Roskam-table ~1.50 --
%   see F16AeroL2.m/F16AeroL3.m). That low CLmax put Stall's wall at
%   W/S~=62-64 psf, tighter than every real condition, so it silently became
%   the BINDING constraint and pulled the reported optimum to W/S~=62 at L2/L3
%   (vs. Brandt's W/S=104.59). Excluding Stall by default raises L2/L3 to
%   W/S~=83; the residual gap traces to the documented aero/propulsion fidelity
%   gaps affecting the real curves, not to this class. Stall stays available as
%   a sanity-check overlay via includeStall=true. The underlying clean-CLmax
%   gap is tracked in ToDo_Darshan.md §3.
%
%   POWER SETTING comes directly from the JSON: each thrust condition carries
%   an explicit power_setting key ("AB"/"mil") selecting its alpha basis
%   ("mil" -> PropulsionBase.thrust_lapse_mil_on_AB_scale, "AB" ->
%   PropulsionBase.thrust_lapse -- see MasterEquationConstraint.get_alpha).
%   requirePowerSetting below is a thin validator: it errors on a missing or
%   non-{AB,mil} value, so a silent "AB" default cannot slip through.

    methods (Static)

        function constraints = build(fidelityLevel, includeStall)
        %BUILD  Construct the F-16's constraint objects for one fidelity
        %   level. Returns a 1xN cell array of PointPerformanceBase objects,
        %   in requirements-JSON condition order (Stall last), ready to hand
        %   to ConstraintAnalysis (as-is, or trimmed/reordered by the caller
        %   first).
        %   includeStall -- default false (see the class header for why). The
        %   Stall condition is skipped unless includeStall is true; pass true
        %   to add it back as an overlay, but note it will again dominate
        %   optimal_point() at L2/L3.
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
        %   There is deliberately no L3 propulsion tier: L3 pairs F16AeroL3 with
        %   F16PropL2 (anything reporting L3 propulsion numbers is computed by
        %   F16PropL2). F16GeomL{2,3} take the propulsion object, because the
        %   nacelle diameter -- and therefore duct wetted area and CD0 -- is
        %   sized from engine thrust. L3 builds the full L3 geometry tier
        %   F16GeomL3.
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
