function objs = f16_brandt_stack()
%F16_BRANDT_STACK  The Brandt-discipline VALIDATION stack for the sizing loops.
%
%   objs = f16_brandt_stack() builds the four VnV Brandt discipline objects
%   (BrandtGeometry/BrandtAerodynamics/BrandtEngine/BrandtWeight), wraps them
%   in the mutation-capable src adapters, and wires them into the FRAMEWORK
%   mission analysis (MissionAnalysisL2 over the brandt_14seg profile) and the
%   FRAMEWORK constraint analysis (ConstraintAnalysis.from_requirements with
%   the F-16 map). This is the validation stack the sizing loops run on:
%   Brandt DISCIPLINES through the FRAMEWORK mission/constraint analyses
%   (user-directed 2026-08-13). It deliberately does NOT use BrandtMission /
%   BrandtConstraintAnalysis -- those stay VnV ground-truth tools, never
%   wired into src orchestrators.
%
%   WIRING PRECEDENTS. Discipline construction + adapter wrapping follows
%   examples/F16A/sanity_checks/mission_brandt_comparison.m (make_stack,
%   "Brandt" case), extended with BrandtWeight/BrandtWeightAdapter for the
%   sizing loops' OEW(W_TO) closure. Constraint construction follows
%   F16ConstraintSet.m's own header / the sizing studies (f16_sizing_L*.m).
%
%   MUTATION COHERENCE. geom.dependents = {ba, bw} registers the Brandt
%   aero and weight objects with the geometry adapter, so a sizing-loop
%   write to geom.S_ref/S_ht/S_vt re-runs BrandtGeometry.analyze() AND both
%   dependents' analyze() in that order (see BrandtMissionGeomAdapter.
%   reanalyze_, including its thrust re-sync ordering hazard). prop.T_SL
%   writes rubber-scale the live BrandtEngine (BrandtPropAdapter.set.T_SL);
%   BrandtWeightAdapter.OEW re-syncs that thrust into the weight object on
%   every call.
%
%   W/S SWEEP. linspace(20, 160, 1401) -- the Brandt Consts-tab span
%   [PointPerformanceBase.WS_RANGE_BRANDT] at 0.1-psf resolution instead of
%   Brandt's 7-psf grid. The sweep only seeds optimal_point_continuous (the
%   grid argmin is its warm start), but the coarse 20:7:160 grid quantizes
%   W/S_opt to 104 vs the true 104.59 [Brandt Size&Opt sheet; GroundTruth/
%   cell-map.md Size!W_S], which can start fmincon in the wrong basin near a
%   constraint crossing -- the fine sweep removes that quantization for
%   negligible cost (the residuals are cheap closed forms).
%
%   Returns a struct with fields aero, prop, wts, geom, miss, con, tail --
%   exactly the injection list SizingLoopL2/TSDiagram take (SizingLoopL1
%   takes the first six).

    % Brandt discipline objects [mission_brandt_comparison.m make_stack
    % precedent; BrandtWeight added for the sizing loops].
    bg = BrandtGeometry();       bg.analyze();
    ba = BrandtAerodynamics(bg); ba.analyze();
    be = BrandtEngine();         be.analyze();
    bw = BrandtWeight(bg);       bw.analyze();

    % src-interface adapters (VnV/BrandtF16A/Brandt*Adapter.m).
    aero = BrandtAeroAdapter(ba);
    prop = BrandtPropAdapter(be);
    geom = BrandtMissionGeomAdapter(bg);
    wts  = BrandtWeightAdapter(bw, be);

    % Register the geometry-mutation dependents (see class header note and
    % BrandtMissionGeomAdapter's dependents property doc): aero first, then
    % weight, matching reanalyze_'s documented registration-order contract.
    geom.dependents = {ba, bw};

    req = f16a_requirements_path();

    % FRAMEWORK mission over Brandt's own 14-segment profile
    % [mission_brandt_comparison.m precedent, "L2 x brandt_14seg" combo].
    miss = MissionAnalysisL2.from_requirements(aero, prop, geom, req, "brandt_14seg");

    % FRAMEWORK constraint analysis with the F-16 condition map
    % [F16ConstraintSet.m header precedent], on the fine sweep (see header).
    con = ConstraintAnalysis.from_requirements(aero, prop, req, ...
        F16ConstraintSet.constraint_map(), linspace(20, 160, 1401));

    % Tail sizing: the same F16TailL1 volume-coefficient object the
    % framework studies inject (see f16_sizing_L2.m and SizingLoopL2.m's
    % tail-box rationale). NOTE (corrected 2026-08-14): at the Brandt
    % planform this method predicts S_ht ~ 48.4 / S_vt ~ 25.7 ft^2 --
    % less than half the actual F-16A's 108 / 60 ft^2 [Brandt
    % Main!C18/H18]. A tail-sizing-discipline gap, documented in
    % f16_sizing_brandt_L2.m's header and sizing_brandt_comparison.m.
    tail = F16TailL1();

    objs = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
        'miss', miss, 'con', con, 'tail', tail);
end
