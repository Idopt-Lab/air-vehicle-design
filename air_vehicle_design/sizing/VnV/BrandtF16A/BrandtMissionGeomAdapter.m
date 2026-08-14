classdef BrandtMissionGeomAdapter < GeometryBase
%BRANDTMISSIONGEOMADAPTER  Makes a BrandtGeometry object satisfy the src
%   GeometryBase interface, so the Brandt discipline stack can be injected
%   into mission analysis and the sizing loops alongside BrandtAeroAdapter /
%   BrandtPropAdapter / BrandtWeightAdapter.
%
%   NAME. Mission analysis was this adapter's first consumer, so a plain
%   BrandtGeomAdapter name would read more naturally. The "Mission" qualifier
%   is kept on purpose: the mixed-fidelity swap harness (examples/F16A/
%   mixed_fidelity_tests/) and its own adapters/BrandtGeomAdapter.m were
%   deleted on 2026-08-12 for a planned rewrite. No name collision exists
%   right now, but this qualifier keeps the plain BrandtGeomAdapter name free
%   so that rewrite can re-use it without shadowing this class on the MATLAB
%   path (the failure mode the sibling BrandtAeroAdapter / BrandtPropAdapter
%   rename already documents).
%
%   PURPOSE. Mission analysis takes an injected GeometryBase and reads
%   geom.get_S_ref() (wing reference area, for W/S and the Breguet CL) and
%   geom.n_engines (for the takeoff warmup fixed-fuel term). BrandtGeometry
%   already carries both -- the reference area in inp.wing.S_ref_ft2 and the
%   engine count in inp.engine.n_engines -- but exposes no GeometryBase
%   interface. This thin adapter provides it, wiring to those existing values.
%   NO new equation.
%
%   MUTATION-CAPABLE (2026-08-13 sizing pass, user-approved). The sizing
%   loops mutate design variables on the geometry object in place and expect
%   updated outputs on the next read, so this adapter is no longer a pure
%   reader:
%     - SETTABLE inputs: S_ref (Main!B18), S_ht (Main!C18, Brandt's "pitch
%       control"/stabilator), S_vt (Main!H18). Each setter writes through to
%       brandtGeom.inp, then re-runs brandtGeom.analyze() AND every handle
%       registered in `dependents` (see reanalyze_), so the whole Brandt
%       stack stays coherent under mutation.
%     - READ-ONLY derived outputs: b_wing, cbar_wing (from the ANALYZED
%       brandtGeom.wing struct), L_fus (input, Main!B32). Assigning to one
%       errors, which is correct -- they are outputs.
%   Mission analysis itself remains a pure reader; only the sizing loop
%   writes.
%
%   The Brandt stack computes S_ref = 300 ft^2 (Brandt Main!B18) and
%   n_engines = 1 (Brandt Main!B28). S_wet is provided only to complete the
%   GeometryBase contract (mission analysis never reads it); it returns Brandt's
%   own computed total wetted area, which requires analyze() to have been called.
%
%   Reference only -- lives under VnV, is NOT part of the shipped src tree.

    properties
        brandtGeom   % BrandtGeometry handle

        %DEPENDENTS  Cell row of Brandt discipline handles (BrandtAerodynamics,
        %   BrandtWeight, ...) whose analyze() must re-run after a geometry
        %   mutation. Registered by the stack-builder AFTER construction:
        %     gA = BrandtMissionGeomAdapter(bg);
        %     gA.dependents = {ba, bw};
        %   Re-analysis runs in registration order (see reanalyze_). An empty
        %   list is valid: the geometry itself still re-analyzes on mutation.
        dependents (1,:) cell = {}
    end

    properties (Dependent)
        S_ref        % ft^2  wing reference area (Brandt Main!B18) -- SETTABLE
        S_wet        % ft^2  total wetted area (Brandt Geom!B19; needs analyze())
        n_engines    % engine count (Brandt Main!B28) -- extra, for mission DI

        S_ht         % ft^2  pitch-control (stabilator/HT) planform area (Brandt Main!C18) -- SETTABLE
        S_vt         % ft^2  vertical-tail planform area (Brandt Main!H18) -- SETTABLE
        b_wing       % ft    wing span = 2 x analyzed half-span (read-only)
        cbar_wing    % ft    wing mean aerodynamic chord (read-only, see getter)
        L_fus        % ft    fuselage length (Brandt Main!B32, read-only)
    end

    methods

        function obj = BrandtMissionGeomAdapter(brandtGeom)
        %BRANDTMISSIONGEOMADAPTER  Wrap a BrandtGeometry handle.
        %   The argument is optional: with none, a fresh default BrandtGeometry
        %   is constructed and analyzed (BrandtGeometry itself loads the default
        %   F-16A JSON no-arg). Mission analysis passes an already-analyzed
        %   BrandtGeometry explicitly.
            arguments
                brandtGeom (1,1) BrandtGeometry = BrandtGeometry()
            end
            if ~brandtGeom.analyzed_
                brandtGeom.analyze();
            end
            obj.brandtGeom = brandtGeom;
        end

        % ---------------- getters ---------------- %

        function v = get.S_ref(obj)
            v = obj.brandtGeom.inp.wing.S_ref_ft2;
        end

        function v = get.S_wet(obj)
            v = obj.brandtGeom.S_wet_total_simple_ft2;
        end

        function v = get.n_engines(obj)
            v = obj.brandtGeom.inp.engine.n_engines;
        end

        function v = get.S_ht(obj)
            v = obj.brandtGeom.inp.pitch_ctrl.S_ft2;
        end

        function v = get.S_vt(obj)
            v = obj.brandtGeom.inp.vert_tail.S_ft2;
        end

        function v = get.b_wing(obj)
        %GET.B_WING  Wing span [ft] = 2 x analyzed half-span.
        %   BrandtGeometry stores wing.half_span_ft = sqrt(S_ref*AR)/2
        %   (Brandt Main!B18/B19 identity, computed in computeLiftingSurfaces).
            v = 2 * obj.brandtGeom.wing.half_span_ft;
        end

        function v = get.cbar_wing(obj)
        %GET.CBAR_WING  Wing mean aerodynamic chord [ft].
        %   BrandtGeometry stores no MAC field (checked 2026-08-13), so this
        %   recomputes it from the ANALYZED root/tip chords via the shared
        %   GeometryBase.compute_mac static:
        %     cbar = (2/3)*c_root*(1 + lambda + lambda^2)/(1 + lambda)
        %   [Raymer 7th ed. Eq. 7.8; same identity as VnV/BrandtF16A/
        %   readme_bsc.md "MAC" equation]. lambda = c_tip/c_root equals the
        %   input taper exactly (c_tip = taper*c_root in computeLiftingSurfaces).
            c_root = obj.brandtGeom.wing.c_root_ft;
            c_tip  = obj.brandtGeom.wing.c_tip_ft;
            v = GeometryBase.compute_mac(c_root, c_tip / c_root);
        end

        function v = get.L_fus(obj)
            v = obj.brandtGeom.inp.fuselage.length_ft;
        end

        % ---------------- setters (mutation entry points) ---------------- %

        function set.S_ref(obj, val)
        %SET.S_REF  Mutate wing reference area [ft^2] (Brandt Main!B18), then
        %   re-analyze the geometry and every registered dependent.
            obj.mustBePositiveFiniteScalar_(val, 'S_ref');
            obj.brandtGeom.inp.wing.S_ref_ft2 = val;
            obj.reanalyze_();
        end

        function set.S_ht(obj, val)
        %SET.S_HT  Mutate pitch-control (stabilator/HT) planform area [ft^2]
        %   (Brandt Main!C18), then re-analyze geometry + dependents.
            obj.mustBePositiveFiniteScalar_(val, 'S_ht');
            obj.brandtGeom.inp.pitch_ctrl.S_ft2 = val;
            obj.reanalyze_();
        end

        function set.S_vt(obj, val)
        %SET.S_VT  Mutate vertical-tail planform area [ft^2] (Brandt
        %   Main!H18), then re-analyze geometry + dependents.
            obj.mustBePositiveFiniteScalar_(val, 'S_vt');
            obj.brandtGeom.inp.vert_tail.S_ft2 = val;
            obj.reanalyze_();
        end

        % ---------------- GeometryBase contract ---------------- %

        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        function val = get_S_wet(obj, ~)
        %GET_S_WET  Total wetted area [ft^2]. Ignores W_TO (Brandt has real
        %   geometry). Mission analysis does not read this.
            val = obj.S_wet;
        end

    end

    methods (Access = private)

        function reanalyze_(obj)
        %REANALYZE_  Re-run the geometry and every registered dependent after
        %   an input mutation.
        %
        %   ORDER. brandtGeom.analyze() runs FIRST, so dependents read fresh
        %   computed geometry; then each dependent in registration order.
        %
        %   INP RE-SYNC. BrandtWeight COPIES geom.inp at construction, and
        %   BrandtAerodynamics loads its OWN copy of the same JSON, so a
        %   mutation of brandtGeom.inp is invisible to both until their copies
        %   are re-synced here. (Their analyze() reads obj.inp for the planform
        %   INPUTS -- S_ref, AR, areas -- and the live geom handle only for
        %   COMPUTED outputs like S_wet; without the re-sync, aero would
        %   rebuild CD0 = Cfe*S_wet/S_ref with the NEW S_wet over the STALE
        %   S_ref.)
        %
        %   ORDERING HAZARD (engine thrust). BrandtWeight.inp.engine.
        %   T_AB_SLS_lb may have been rubber-scaled by BrandtWeightAdapter.OEW,
        %   which syncs it from the live BrandtEngine on every call. A blanket
        %   dep.inp = brandtGeom.inp would silently reset that thrust to the
        %   JSON stock value, so the CURRENT value is captured before the
        %   re-sync and restored after -- a geometry mutation must never move
        %   the thrust design point.
            obj.brandtGeom.analyze();
            for k = 1:numel(obj.dependents)
                dep = obj.dependents{k};
                if isa(dep, 'BrandtWeight')
                    T_now   = dep.inp.engine.T_AB_SLS_lb;
                    dep.inp = obj.brandtGeom.inp;
                    dep.inp.engine.T_AB_SLS_lb = T_now;
                elseif isa(dep, 'BrandtAerodynamics')
                    % Field-by-field copy: overwrite every geometry-owned block
                    % while PRESERVING aero-only fields absent from geom.inp
                    % (the inp.geom_ handle BrandtAerodynamics injects at
                    % construction).
                    gi = obj.brandtGeom.inp;
                    fn = fieldnames(gi);
                    for f = 1:numel(fn)
                        dep.inp.(fn{f}) = gi.(fn{f});
                    end
                end
                dep.analyze();
            end
        end

        function mustBePositiveFiniteScalar_(~, val, name)
        %MUSTBEPOSITIVEFINITESCALAR_  Guard for the mutation setters.
            if ~(isnumeric(val) && isscalar(val) && isfinite(val) && val > 0)
                error('BrandtMissionGeomAdapter:invalidInput', ...
                    '%s must be a positive finite numeric scalar [ft^2].', name);
            end
        end

    end

end
