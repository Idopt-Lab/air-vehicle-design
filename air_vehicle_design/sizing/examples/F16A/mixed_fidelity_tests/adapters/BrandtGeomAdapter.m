classdef BrandtGeomAdapter < GeometryBase
%BRANDTGEOMADAPTER  Adapter exposing Brandt's own F-16A geometry
%   (VnV/BrandtF16A/BrandtGeometry.m) through the generic GeometryBase
%   contract, so "Brandt" can be selected as a fidelity LEVEL in the
%   mixed-fidelity sizing harness (examples/F16A/mixed_fidelity_tests/),
%   alongside F16GeomL1/L2/L3.
%
%   SELF-CONTAINED, BY DESIGN: the constructor builds its own PRIVATE
%   BrandtGeometry instance and calls .analyze() on it internally -- no
%   external geometry/aero/prop object crosses this adapter's boundary.
%   That is what lets this adapter work no matter what fidelity level the
%   REST of a mixed combo picked (see build_fidelity_combo.m and
%   COMPATIBILITY_NOTES.md item 3): Geometry=Brandt always reflects
%   Brandt's OWN airframe, never whatever f16a_L{1,2,3}.json spec a sibling
%   discipline is reading.
%
%   BrandtGeometry() with no argument (this class's default) loads its own
%   hardcoded VnV/BrandtF16A/GroundTruth/f16a_geometry.json -- see
%   COMPATIBILITY_NOTES.md item 5.
%
%   S_ref -- a PLAIN, MUTABLE property (NOT Dependent), seeded from
%   obj.brandt.inp.wing.S_ref_ft2 (300 ft^2, Brandt Main!B18) at
%   construction. This diverges from the original mixed-fidelity design
%   sketch, which proposed S_ref as read-only Dependent throughout; that
%   would break SizingLoopL1, whose run() body does
%   `obj.geom.S_ref = W_TO/WS_opt` every iteration (see F16GeomL1.m, which
%   stores S_ref the same way -- a plain property the L1 loop overwrites in
%   place, even though its initial value is also a cited T.O. constant).
%   Read-only Dependent is correct for a quantity that is ALWAYS recomputed
%   from other inputs (see S_wet below); S_ref here is a genuine STATE
%   variable an L1 sizing loop mutates, exactly like every other geometry
%   tier's S_ref, so it must be a plain settable property.
%   ! CONSEQUENCE: mutating S_ref does NOT feed back into obj.brandt, which
%   keeps computing S_wet from its own fixed internal geometry regardless of
%   what this adapter's S_ref currently holds -- documented "weirdness"
%   consistent with this harness's tolerance for mixed-fidelity artifacts.
%
%   S_wet -- Dependent, read LIVE from obj.brandt.S_wet_total_simple_ft2 --
%   the SIMPLE (low-fidelity) wetted-area total, deliberately NOT
%   S_wet_total_accurate_ft2. This mirrors F16GeomL2's own fidelity
%   philosophy: L2's get_S_wet uses the low-fidelity fuselage-envelope form
%   (CLAUDE.md's Amax/S_wet tiering note), and BrandtGeometry itself frames
%   "simple" vs "accurate" as exactly that same low/high-fidelity split (see
%   its class header and compareFidelities()). Since this adapter satisfies
%   only bare GeometryBase (the L1/L2-shape two-property contract), the
%   simple total is the better fidelity match. Fixed at Brandt's own
%   planform -- does not depend on this adapter's S_ref, and get_S_wet's
%   W_TO argument is accepted but ignored (see below).

    properties
        S_ref   % ft^2 -- wing reference area. Plain, mutable: see class header.
    end

    properties (Access = private)
        brandt   % BrandtGeometry handle, built + analyzed in the constructor
    end

    properties (Dependent)
        S_wet   % ft^2 -- total aircraft wetted area, SIMPLE fidelity [Brandt Geom!B19]
    end

    methods

        function obj = BrandtGeomAdapter(json_path)
        %BRANDTGEOMADAPTER  Construct and analyze a private BrandtGeometry.
        %   obj = BrandtGeomAdapter()           -- Brandt's own default JSON
        %       (VnV/BrandtF16A/GroundTruth/f16a_geometry.json).
        %   obj = BrandtGeomAdapter(json_path)  -- optional override, passed
        %       straight through to BrandtGeometry(source).
            arguments
                json_path (1,1) string = ""
            end
            if json_path == ""
                obj.brandt = BrandtGeometry();
            else
                obj.brandt = BrandtGeometry(json_path);
            end
            obj.brandt.analyze();
            obj.S_ref = obj.brandt.inp.wing.S_ref_ft2;   % [Brandt Main!B18 = 300]
        end

        function v = get.S_wet(obj)
            v = obj.brandt.S_wet_total_simple_ft2;
        end

        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        function val = get_S_wet(obj, W_TO)
        %GET_S_WET  Total wetted area [ft^2]. W_TO is ACCEPTED (GeometryBase's
        %   contract, matching L2/L3's real-planform signature) but IGNORED:
        %   Brandt's geometry model has no gross-weight dependence, unlike
        %   F16GeomL1's regression-based S_wet.
            arguments
                obj
                W_TO (1,1) double = NaN %#ok<INUSA>
            end
            val = obj.S_wet;
        end

    end

end
