classdef BrandtMissionGeomAdapter < GeometryBase
%BRANDTMISSIONGEOMADAPTER  Makes a BrandtGeometry object satisfy the src
%   GeometryBase interface, so the Brandt discipline stack can be injected
%   into mission analysis alongside BrandtConstraintAeroAdapter /
%   BrandtConstraintPropAdapter.
%
%   RENAMED 2026-08-10 (from BrandtGeomAdapter): this class collided with
%   the unrelated, differently-shaped examples/F16A/mixed_fidelity_tests/
%   adapters/BrandtGeomAdapter.m (optional-json-path constructor, exposes
%   "Brandt" as a selectable fidelity LEVEL, PLAIN mutable S_ref so
%   SizingLoopL1 can overwrite it in place). run_all_tests.m puts both this
%   file's directory (VnV/BrandtF16A, via genpath) and that one's on the
%   MATLAB path every run; with the same class name, whichever came first on
%   the path silently shadowed the other -- same failure mode the sibling
%   BrandtConstraintAeroAdapter/BrandtConstraintPropAdapter rename already
%   fixed (see those files' headers), just not yet applied here.
%
%   PURPOSE. Mission analysis takes an injected GeometryBase and reads
%   geom.get_S_ref() (wing reference area, for W/S and the Breguet CL) and
%   geom.n_engines (for the takeoff warmup fixed-fuel term). BrandtGeometry
%   already carries both -- the reference area in inp.wing.S_ref_ft2 and the
%   engine count in inp.engine.n_engines -- but exposes no GeometryBase
%   interface. This thin adapter provides it, wiring to those existing values.
%   NO new equation.
%
%   The Brandt stack computes S_ref = 300 ft^2 (Brandt Main!B18) and
%   n_engines = 1 (Brandt Main!B28). S_wet is provided only to complete the
%   GeometryBase contract (mission analysis never reads it); it returns Brandt's
%   own computed total wetted area, which requires analyze() to have been called.
%
%   Reference only -- lives under VnV, is NOT part of the shipped src tree.

    properties
        brandtGeom   % BrandtGeometry handle
    end

    properties (Dependent)
        S_ref        % ft^2  wing reference area (Brandt Main!B18)
        S_wet        % ft^2  total wetted area (Brandt Geom!B19; needs analyze())
        n_engines    % engine count (Brandt Main!B28) -- extra, for mission DI
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

        function v = get.S_ref(obj)
            v = obj.brandtGeom.inp.wing.S_ref_ft2;
        end

        function v = get.S_wet(obj)
            v = obj.brandtGeom.S_wet_total_simple_ft2;
        end

        function v = get.n_engines(obj)
            v = obj.brandtGeom.inp.engine.n_engines;
        end

        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        function val = get_S_wet(obj, ~)
        %GET_S_WET  Total wetted area [ft^2]. Ignores W_TO (Brandt has real
        %   geometry). Mission analysis does not read this.
            val = obj.S_wet;
        end

    end

end
