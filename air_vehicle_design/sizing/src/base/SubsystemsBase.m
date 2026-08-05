classdef (Abstract) SubsystemsBase < handle
%SUBSYSTEMSBASE  Tier-1 abstract enforcer for all subsystems discipline classes.
%
%   Declares the contract orchestrators call -- internal_volume (total usable
%   internal volume estimate available for fuel/avionics/gear, ft^3) and
%   fuel_volume_check (fuel-or-battery sufficiency check against that volume)
%   -- plus one fidelity-independent utility shared unchanged by every level.
%
%   Inheritance: SubsystemsBase -> SubsystemsModelLN (abstract) -> F16SubsystemsLN
%   The SubsystemsLN static toolboxes are NOT in this chain.
%
%   SIGNATURE NOTE (mirrors GeometryBase.get_S_wet(obj, W_TO), see that file's
%   header comment): the two abstract methods below are declared at their
%   WIDEST signature -- the one L1 needs, since L1 has no injected weights
%   object and must take the empty weight / required fuel weight as an
%   explicit argument. L2/L3 concrete classes implement the zero-extra-arg
%   form instead (internal_volume(obj), fuel_volume_check(obj)), reading an
%   injected weights collaborator live. MATLAB does not enforce matching
%   arity between an abstract declaration and its override -- this is a
%   documented, deliberate asymmetry, not the legacy signature-mismatch bug
%   (docs/subplans/09_subsystems.md "Legacy Bugs to Avoid" item 2) which was
%   an UNDOCUMENTED, accidental 2-arg-vs-3-arg drift.
%
%   AVIONICS VOLUME MUST BE SUMMED. Every internal_volume() implementation at
%   every level must actually add its avionics-volume term into the returned
%   total -- the legacy code computed it and silently dropped it
%   (docs/subplans/09_subsystems.md "Legacy Bugs to Avoid" item 1).
%
%   Companion doc: src/base/SubsystemsBase.md
%
%   SHARED ABSTRACT PROPERTIES (added 2026-08-03). avionics_weight_fraction,
%   avionics_density, fuel_density, fuselage_raw_volume and fuel_volume are
%   declared HERE, not independently re-declared per SubsystemsModelLN --
%   they were previously identical, duplicated abstract declarations across
%   all three (or, for fuselage_raw_volume/fuel_volume, present at L2/L3 and
%   missing at L1 entirely). Every one takes ZERO extra arguments and reads
%   only obj's own stored inputs/injected collaborators, so each is a
%   PROPERTY, not a method (CLAUDE.md "Optimization-ready property design").
%   L1 legitimately has no fuselage/fuel-bay geometry, so its
%   fuselage_raw_volume and fuel_volume getters both return a documented,
%   honest 0 -- not guessed, matching the same answer fuel_volume_check
%   already gives at that tier. avionics_weight/avionics_volume are
%   deliberately NOT lifted here even though "avionics volume" is the same
%   concept at every level: L1 has no injected weights object, so it MUST
%   take W_empty as an explicit argument (a method); L2/L3 have all the
%   state they need and are correctly Dependent PROPERTIES instead
%   (guarded by TestSubsystemsL2.testF16SubsystemsL2DerivedPropertiesAreReadOnly).
%   MATLAB requires one shared KIND (property XOR method) for any member
%   declared on a common abstract ancestor, so unifying avionics_volume here
%   would force L2/L3 to give up their Dependent-property guarantee just to
%   satisfy L1's argument requirement -- the wrong tradeoff. Each
%   SubsystemsModelLN still declares avionics_weight/avionics_volume
%   independently, at the kind that tier actually needs.
    properties (Abstract)
        %AVIONICS_WEIGHT_FRACTION  Decided fraction of W_empty -- the Table
        %   11.6 row's own range midpoint (Casey, 2026-08-03).
        %   [Raymer 6th ed. Table 11.6, p.375]
        avionics_weight_fraction

        %AVIONICS_DENSITY  Avionics packing density [lb/ft^3]. Same MEMBER
        %   NAME at every level; different cited VALUE by design -- L1 uses
        %   Raymer's own following-paragraph range average (~37.5); L2/L3
        %   switch to Nicolai's flat 45 [Sec.8.1.11] (fidelity-split
        %   decision, docs/subplans/09_subsystems.md Equations & Citations
        %   item 4).
        avionics_density

        %FUEL_DENSITY  Fuel density [lb/ft^3] for obj.fuel_type.
        %   [Nicolai & Carichner Table 8.6, p.210]
        fuel_density

        %FUSELAGE_RAW_VOLUME  Raw geometric fuselage-internal volume [ft^3],
        %   before any fuel-tank packaging factor. [Raymer 6th ed. Eq. 7.14]
        %   at L2/L3, off the injected geometry's envelope-ellipse (L2) or
        %   frame-integrated (L3) projected areas. HONESTLY 0 at L1 -- no
        %   fuselage geometry exists at that tier (Objectives, Fidelity
        %   split); not guessed.
        fuselage_raw_volume

        %FUEL_VOLUME  Total available (usable) fuel volume [ft^3] --
        %   fuselage-internal (packaged) + wing-internal, at L2/L3; HONESTLY
        %   0 at L1 (no fuel-bay geometry). Equal to fuel_volume_check's own
        %   'available_vol_ft3' figure, exposed as a named property so a
        %   caller can read it without the full sufficiency-check struct.
        fuel_volume
    end

    methods (Abstract)
        %INTERNAL_VOLUME  Total usable internal volume [ft^3] estimate for
        %   this fidelity level. L1: avionics volume only (no fuel/gear bay
        %   geometry exists yet). L2/L3: fuselage-internal (packaged) fuel
        %   volume + wing-internal fuel volume + avionics volume. Landing-gear
        %   bay volume is deliberately NOT auto-summed here even at L2/L3 --
        %   see F16SubsystemsL2.md/F16SubsystemsL3.md "Landing-gear bay volume"
        %   note for why (item 11's citation gap means that term always
        %   errors; auto-summing it would make every internal_volume() call
        %   fail).
        val = internal_volume(obj, W_empty)

        %FUEL_VOLUME_CHECK  Sufficiency check: does the available fuel-volume
        %   allocation (fuselage-internal + wing-internal usable volume, L2/L3
        %   only; 0 at L1, no bay geometry) cover the REQUIRED fuel weight,
        %   converted to a volume through this class's own fuel-density path?
        %   Returns a struct with fields 'available_vol_ft3', 'required_vol_ft3',
        %   'sufficient' (logical). required_weight_lb is the weight to check --
        %   L1 callers pass it explicitly; L2/L3 read it live from an injected
        %   fuel_weight_source (mission analysis or a WeightsBase object),
        %   never a hardcoded literal.
        result = fuel_volume_check(obj, required_weight_lb)

        %FUEL_VOLUME_FROM_WEIGHT  Given a fuel weight [lbf], the volume
        %   [ft^3] it occupies at this class's own fuel_density -- the
        %   definitional weight/density conversion (weight_to_volume below),
        %   specialized to the fuel path. Same signature at EVERY fidelity
        %   level (no widest-signature asymmetry needed -- every tier already
        %   takes an explicit weight argument for this one). NO packaging
        %   factor applied -- that only applies to the GEOMETRIC raw volume
        %   (fuselage_usable_fuel_volume), a different quantity from a
        %   weight-derived figure.
        val = fuel_volume_from_weight(obj, fuel_weight_lb)
    end

    methods (Static)

        function vol = weight_to_volume(W_lb, density_lb_per_ft3)
        %WEIGHT_TO_VOLUME  Generic weight -> volume conversion [ft^3].
        %   Shared by every fuel-type / avionics / battery density path at
        %   every fidelity level -- definitional (vol = W/density); the
        %   citation belongs to whichever density value the caller supplies,
        %   not to this identity itself.
            arguments
                W_lb               (1,1) double {mustBeNonnegative}
                density_lb_per_ft3 (1,1) double {mustBePositive}
            end
            vol = W_lb / density_lb_per_ft3;
        end

    end
end
