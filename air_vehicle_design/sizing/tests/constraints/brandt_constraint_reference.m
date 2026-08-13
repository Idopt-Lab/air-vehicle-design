function ref = brandt_constraint_reference(WS_psf)
%BRANDT_CONSTRAINT_REFERENCE  Live Brandt F-16A constraint ground truth for tests.
%
%   ref = brandt_constraint_reference() builds the Brandt discipline chain
%   (BrandtGeometry -> BrandtAerodynamics -> BrandtEngine) and
%   BrandtConstraintAnalysis, runs the constraint analysis over the Brandt
%   Consts-tab wing-loading sweep (20:7:160 psf, 21 points by default), and
%   returns a struct of reference values the constraint unit tests compare
%   the framework's output against.
%
%   This replaces the retired baseline/F16Baseline.m constraint tables: every
%   value below is computed LIVE from VnV/BrandtF16A, the same Brandt model the
%   informational report examples/F16A/sanity_checks/constraints_brandt_comparison.m uses, so
%   the tests validate against one authoritative source rather than a
%   hand-transcribed copy.
%
%   Fields:
%     .aero   BrandtAerodynamics handle -- aero.run(mach) -> .CD0/.K1/.K2/
%             .CLmax_TO/.CLmax_land (Consts-tab CDmin basis, ~0.017 subsonic);
%             aero.CLmax_takeoff/.CLmax_landing are the Mach-independent props.
%     .eng    BrandtEngine handle -- eng.run(alt_ft, mach, AB_p) -> .alpha_AB_ref
%             (thrust lapse on the T_SL_AB basis; AB_p in [0,1], 0 = mil/dry).
%     .ca     BrandtConstraintAnalysis handle (analyze()d).
%     .WS     the wing-loading sweep used [psf].
%     .run    ca.run(WS) result struct: .TW_max_mach/.TW_cruise/.TW_max_alt/
%             .TW_combat_turn_sub/.TW_combat_turn_sup/.TW_ps500/.TW_takeoff
%             (each an numel(WS)x1 column), .WS_landing_max, .WS_opt, .TW_opt.
%     .S_ref  wing reference area [ft^2]   (f16a_geometry.json wing.S_ref_ft2)
%     .T_SL   SLS AB thrust [lbf]          (f16a_geometry.json engine.T_AB_SLS_lb)
%     .TOGW   takeoff gross weight [lbf]   (f16a_geometry.json mission.W_TO_lb)
%
%   Sources: VnV/BrandtF16A/BrandtConstraintAnalysis.m (Brandt-F16-A.xls Consts
%   tab), BrandtAerodynamics.m (Aero tab), BrandtEngine.m (Engn(s) tab), fed
%   from VnV/BrandtF16A/GroundTruth/f16a_geometry.json.
    arguments
        WS_psf (1,:) double = 20:7:160
    end

    % Self-contained path setup (mirrors constraints_brandt_comparison.m): add
    % the Brandt classes + their GroundTruth folder if not already on the path.
    if isempty(which('BrandtConstraintAnalysis'))
        here        = fileparts(mfilename('fullpath'));
        sizing_root = fileparts(fileparts(here));
        vnv         = fullfile(sizing_root, 'VnV', 'BrandtF16A');
        addpath(vnv);
        addpath(fullfile(vnv, 'GroundTruth'));
    end

    geom     = BrandtGeometry();              geom.analyze();
    ref.aero = BrandtAerodynamics(geom);      ref.aero.analyze();
    ref.eng  = BrandtEngine();                ref.eng.analyze();
    ref.ca   = BrandtConstraintAnalysis(ref.aero, ref.eng);
    ref.ca.analyze();

    ref.WS  = WS_psf;
    ref.run = ref.ca.run(WS_psf);

    % Design-point trio (inputs used to form candidate DesignPoints / the
    % SL-static available-T/W diagnostic), read from the same JSON the Brandt
    % constraint analysis loaded.
    ref.S_ref = ref.ca.inp.wing.S_ref_ft2;
    ref.T_SL  = ref.ca.inp.engine.T_AB_SLS_lb;
    ref.TOGW  = ref.ca.inp.mission.W_TO_lb;
end
