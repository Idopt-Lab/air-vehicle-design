function report = run_fidelity_sweep(W_TO_guess, T_SL_guess)
%RUN_FIDELITY_SWEEP  Full cross-product mixed-fidelity sizing sweep.
%
%   report = run_fidelity_sweep(W_TO_guess, T_SL_guess) enumerates every
%   combination of Geometry x Aerodynamics x Propulsion x Weights x Mission
%   x sizing-Loop fidelity level (4x4x3x4x4x2 = 1536 combinations, including
%   "Brandt" as a level on every discipline axis except Loop, which has no
%   Brandt equivalent), calls build_fidelity_combo.m for each, and returns
%   the full result as a table -- also written to sweep_report.csv next to
%   this file.
%
%   report = run_fidelity_sweep() defaults to W_TO_guess=30000,
%   T_SL_guess=20000, matching every design_study_*.m file's own default
%   guesses.
%
%   THIS SCRIPT IS DELIBERATELY INFORMATIONAL, NOT PASS/FAIL [CLAUDE.md's
%   two-test-tier rule; mirrors the project's existing "Brandt comparison
%   report" precedent, e.g. examples/F16A/*_brandt_comparison.m]: most of
%   the 1536 combinations are structurally invalid (see
%   COMPATIBILITY_NOTES.md) and that is EXPECTED -- this script must never
%   itself error just because a combination fails to construct or converge.
%   Every per-combination outcome is caught by build_fidelity_combo.m's own
%   try/catch and logged as one row; nothing here is asserted.
%
%   Report columns: geom, aero, prop, weights, mission, loop (the six level
%   strings), ok (logical), category ("converged" / "construction_error" /
%   "runtime_error"), stage, message, W_TO, T_SL (NaN unless converged).

    arguments
        W_TO_guess (1,1) double {mustBePositive} = 30000
        T_SL_guess (1,1) double {mustBePositive} = 20000
    end

    geomLevels    = ["L1", "L2", "L3", "Brandt"];
    aeroLevels    = ["L1", "L2", "L3", "Brandt"];
    propLevels    = ["L1", "L2", "Brandt"];        % no L3 propulsion tier -- pre-existing
    weightsLevels = ["L1", "L2", "L3", "Brandt"];
    missionLevels = ["L1", "L2", "L3", "Brandt"];
    loopLevels    = ["L1", "L2"];                  % no "Brandt loop" -- see build_fidelity_combo.m header

    n_total = numel(geomLevels) * numel(aeroLevels) * numel(propLevels) * ...
        numel(weightsLevels) * numel(missionLevels) * numel(loopLevels);

    rows = struct('geom', cell(n_total, 1), 'aero', cell(n_total, 1), ...
        'prop', cell(n_total, 1), 'weights', cell(n_total, 1), ...
        'mission', cell(n_total, 1), 'loop', cell(n_total, 1), ...
        'ok', cell(n_total, 1), 'category', cell(n_total, 1), ...
        'stage', cell(n_total, 1), 'message', cell(n_total, 1), ...
        'W_TO', cell(n_total, 1), 'T_SL', cell(n_total, 1));

    idx = 0;
    for iGeom = 1:numel(geomLevels)
        for iAero = 1:numel(aeroLevels)
            for iProp = 1:numel(propLevels)
                for iWts = 1:numel(weightsLevels)
                    for iMiss = 1:numel(missionLevels)
                        for iLoop = 1:numel(loopLevels)
                            idx = idx + 1;

                            geomLv    = geomLevels(iGeom);
                            aeroLv    = aeroLevels(iAero);
                            propLv    = propLevels(iProp);
                            weightsLv = weightsLevels(iWts);
                            missionLv = missionLevels(iMiss);
                            loopLv    = loopLevels(iLoop);

                            [objs, status] = build_fidelity_combo(geomLv, aeroLv, ...
                                propLv, weightsLv, missionLv, loopLv, ...
                                W_TO_guess, T_SL_guess);

                            if status.ok
                                category = "converged";
                                W_TO = objs.result.W_TO;
                                T_SL = objs.result.T_SL;
                            else
                                W_TO = NaN;
                                T_SL = NaN;
                                if strcmp(status.stage, "loop")
                                    category = "runtime_error";
                                else
                                    category = "construction_error";
                                end
                            end

                            rows(idx).geom     = geomLv;
                            rows(idx).aero     = aeroLv;
                            rows(idx).prop     = propLv;
                            rows(idx).weights  = weightsLv;
                            rows(idx).mission  = missionLv;
                            rows(idx).loop     = loopLv;
                            rows(idx).ok       = status.ok;
                            rows(idx).category = category;
                            rows(idx).stage    = string(status.stage);
                            rows(idx).message  = string(status.message);
                            rows(idx).W_TO     = W_TO;
                            rows(idx).T_SL     = T_SL;
                        end
                    end
                end
            end
        end
    end

    report = struct2table(rows);

    outPath = fullfile(fileparts(mfilename('fullpath')), 'sweep_report.csv');
    writetable(report, outPath);

    n_converged  = sum(report.ok);
    n_construct  = sum(strcmp(report.category, "construction_error"));
    n_runtime    = sum(strcmp(report.category, "runtime_error"));
    fprintf('%d/%d converged, %d construction_error, %d runtime_error\n', ...
        n_converged, n_total, n_construct, n_runtime);
end
