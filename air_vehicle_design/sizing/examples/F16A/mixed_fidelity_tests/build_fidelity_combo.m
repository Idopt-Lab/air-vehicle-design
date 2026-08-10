function [objs, status] = build_fidelity_combo(geomLv, aeroLv, propLv, weightsLv, missionLv, loopLv, W_TO_guess, T_SL_guess)
%BUILD_FIDELITY_COMBO  Construct one F-16A discipline combination at
%   independently-chosen fidelity levels (including "Brandt") and run it
%   through the sizing loop.
%
%   [objs, status] = build_fidelity_combo(geomLv, aeroLv, propLv, ...
%       weightsLv, missionLv, loopLv, W_TO_guess, T_SL_guess)
%
%   geomLv, aeroLv, weightsLv, missionLv -- one of "L1"/"L2"/"L3"/"Brandt".
%   propLv                               -- one of "L1"/"L2"/"Brandt" (no L3
%                                            propulsion tier exists anywhere
%                                            in this framework -- see
%                                            design_study_03_L3.m's header).
%   loopLv                               -- one of "L1"/"L2" (there is no
%                                            "Brandt loop": Brandt's
%                                            spreadsheet has no injectable
%                                            iterative sizing loop of its
%                                            own).
%   W_TO_guess, T_SL_guess                -- initial sizing-loop guesses,
%                                            lbf. T_SL_guess is unused when
%                                            loopLv == "L1" (SizingLoopL1.run
%                                            takes only W_TO_guess) but is
%                                            always required here so this
%                                            function has one fixed
%                                            signature regardless of loopLv.
%
%   Single shared builder: the ONE place that knows how to turn six level
%   strings into constructed discipline objects and a converged (or failed)
%   sizing result -- both run_fidelity_sweep.m (the full 4x4x3x4x4x2
%   cross-product) and any curated regression test call this function, so
%   there is exactly one implementation of "how do I wire this up."
%
%   Construction proceeds in DEPENDENCY ORDER -- prop -> geom -> aero -> wts
%   -> miss -> constraints/loop -- exactly mirroring design_study_01_L1.m /
%   design_study_02_L2.m / design_study_03_L3.m, reusing their exact
%   construction calls and the f16a_spec_path(level)/f16a_requirements_path()
%   helpers verbatim. EACH discipline's construction
%   is wrapped in its OWN try/catch: on failure this function returns
%   IMMEDIATELY with status.ok=false, status.stage set to the discipline
%   that failed, and status.message = the caught exception's message, and
%   objs = [] -- so a mustBeA type-guard rejection (e.g. Aero L2/L3 fed an
%   L1 geometry object; Weights L2/L3 fed a Brandt geometry object) is
%   reported as a clean, attributable row rather than propagating as a bare
%   stack trace out of this function. See COMPATIBILITY_NOTES.md for the
%   recurring failure patterns this surfaces.
%
%   On success for all five disciplines, builds the constraint analysis via
%   ConstraintAnalysis.from_requirements(aero, prop, ...,
%   F16ConstraintSet.constraint_map(), ...) (same call shape as every
%   design_study_*.m), picks SizingLoopL1 or SizingLoopL2 per
%   loopLv (L3 disciplines reuse SizingLoopL2, per design_study_03_L3.m --
%   sizing has no per-fidelity-level equation set of its own), runs it
%   (also inside its own try/catch -> status.stage = "loop" on failure OR
%   non-convergence), and returns status.ok=true, status.stage="converged"
%   plus objs = struct('aero','prop','wts','geom','miss','con','result').

    arguments
        geomLv     (1,1) string {mustBeMember(geomLv,    ["L1", "L2", "L3", "Brandt"])}
        aeroLv     (1,1) string {mustBeMember(aeroLv,    ["L1", "L2", "L3", "Brandt"])}
        propLv     (1,1) string {mustBeMember(propLv,    ["L1", "L2", "Brandt"])}
        weightsLv  (1,1) string {mustBeMember(weightsLv, ["L1", "L2", "L3", "Brandt"])}
        missionLv  (1,1) string {mustBeMember(missionLv, ["L1", "L2", "L3", "Brandt"])}
        loopLv     (1,1) string {mustBeMember(loopLv,    ["L1", "L2"])}
        W_TO_guess (1,1) double {mustBePositive}
        T_SL_guess (1,1) double {mustBePositive}
    end

    objs = [];

    % ---- Propulsion ---------------------------------------------------- %
    try
        switch propLv
            case "L1",     prop = F16PropL1(f16a_spec_path(1));
            case "L2",     prop = F16PropL2(f16a_spec_path(2));
            case "Brandt"
                eng = BrandtEngine(); eng.analyze();
                prop = BrandtConstraintPropAdapter(eng);
            otherwise
                error('build_fidelity_combo:unknownPropLevel', ...
                    'Unhandled propulsion level "%s".', propLv);
        end
    catch ME
        status = struct('ok', false, 'stage', 'prop', 'message', ME.message);
        return
    end

    % ---- Geometry (takes prop -- nacelle diameter is engine data) ------- %
    try
        switch geomLv
            case "L1",     geom = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            case "L2",     geom = F16GeomL2(f16a_spec_path(2), prop);
            case "L3",     geom = F16GeomL3(f16a_spec_path(3), prop);
            case "Brandt", geom = BrandtGeomAdapter();
            otherwise
                error('build_fidelity_combo:unknownGeomLevel', ...
                    'Unhandled geometry level "%s".', geomLv);
        end
    catch ME
        status = struct('ok', false, 'stage', 'geom', 'message', ME.message);
        return
    end

    % ---- Aerodynamics (L2/L3 take the injected geometry object) -------- %
    try
        switch aeroLv
            case "L1",     aero = F16AeroL1(f16a_spec_path(1));
            case "L2",     aero = F16AeroL2(geom, f16a_spec_path(2));
            case "L3",     aero = F16AeroL3(geom, f16a_spec_path(3));
            case "Brandt"
                bgeom = BrandtGeometry(); bgeom.analyze();
                baero = BrandtAerodynamics(bgeom); baero.analyze();
                aero = BrandtConstraintAeroAdapter(baero);
            otherwise
                error('build_fidelity_combo:unknownAeroLevel', ...
                    'Unhandled aerodynamics level "%s".', aeroLv);
        end
    catch ME
        status = struct('ok', false, 'stage', 'aero', 'message', ME.message);
        return
    end

    % ---- Weights (L2/L3 take the injected geometry + propulsion) ------- %
    try
        switch weightsLv
            case "L1",     wts = F16WeightsL1(f16a_spec_path(1));
            case "L2",     wts = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), geom, prop);
            case "L3",     wts = F16WeightsL3(f16a_spec_path(3), f16a_requirements_path(), geom, prop);
            case "Brandt", wts = BrandtWeightsAdapter();
            otherwise
                error('build_fidelity_combo:unknownWeightsLevel', ...
                    'Unhandled weights level "%s".', weightsLv);
        end
    catch ME
        status = struct('ok', false, 'stage', 'weights', 'message', ME.message);
        return
    end

    % ---- Mission --------------------------------------------------------%
    try
        % L1/L2 = new core mission (aircraft-agnostic, injects aero/prop/geom).
        % L3 mission maps to MissionAnalysisL2 (there is no L3 mission tier).
        switch missionLv
            case "L1",     miss = MissionAnalysisL1.from_requirements(aero, prop, geom, f16a_requirements_path(), "cap");
            case "L2",     miss = MissionAnalysisL2.from_requirements(aero, prop, geom, f16a_requirements_path(), "cap");
            case "L3",     miss = MissionAnalysisL2.from_requirements(aero, prop, geom, f16a_requirements_path(), "cap");
            case "Brandt", miss = BrandtMissionAdapter();
            otherwise
                error('build_fidelity_combo:unknownMissionLevel', ...
                    'Unhandled mission level "%s".', missionLv);
        end
    catch ME
        status = struct('ok', false, 'stage', 'mission', 'message', ME.message);
        return
    end

    % ---- Constraint set + analysis (same call shape as every
    %      design_study_*.m) -------------------------------------------- %
    try
        con = ConstraintAnalysis.from_requirements(aero, prop, ...
            f16a_requirements_path(), F16ConstraintSet.constraint_map(), ...
            PointPerformanceBase.WS_RANGE_BRANDT);
    catch ME
        status = struct('ok', false, 'stage', 'constraints', 'message', ME.message);
        return
    end

    % ---- Sizing loop ------------------------------------------------------%
    % TAIL SIZING (2026-08-03 absorption into Geometry REVERTED, 2026-08-05):
    % SizingLoopL2 takes tail/control-surface objects as dependency injection
    % again -- same construction as design_study_02_L2.m/design_study_03_L3.m.
    try
        switch loopLv
            case "L1"
                loop = SizingLoopL1(aero, prop, wts, geom, miss, con);
                result = loop.run(W_TO_guess);
            case "L2"
                tail = F16TailL1();
                ctrl = ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30, 0.90);
                loop = SizingLoopL2(aero, prop, wts, geom, miss, con, tail, ctrl);
                result = loop.run(W_TO_guess, T_SL_guess);
            otherwise
                error('build_fidelity_combo:unknownLoopLevel', ...
                    'Unhandled sizing-loop level "%s".', loopLv);
        end
    catch ME
        status = struct('ok', false, 'stage', 'loop', 'message', ME.message);
        return
    end

    if ~result.converged
        status = struct('ok', false, 'stage', 'loop', 'message', sprintf( ...
            'SizingLoop%s did not converge within %d iterations.', loopLv, result.n_iter));
        return
    end

    status = struct('ok', true, 'stage', 'converged', 'message', '');
    objs = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
        'miss', miss, 'con', con, 'result', result);
end
