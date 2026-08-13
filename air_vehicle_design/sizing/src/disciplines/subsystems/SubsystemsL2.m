classdef SubsystemsL2
%SUBSYSTEMSL2  Level-2 subsystems static toolbox: geometry-derived volumes.
%
%   Call as SubsystemsL2.method(...); never instantiated, not in the
%   inheritance chain. F16SubsystemsL2 inherits SubsystemsModelL2 and
%   delegates here.
%
%   Official formulas: fuselage-internal raw volume [Raymer 6th ed. Eq. 7.14],
%   wing-internal fuel volume [Roskam, Airplane Design Part II, Ch.6, Eq.
%   6.2/6.3], fuel-tank packaging factor / fuel-type density [Nicolai &
%   Carichner, Ch.8, p.210], avionics weight fraction [Raymer 6th ed. Table
%   11.6] with L2's own flat Nicolai avionics density (45 lb/ft^3).
%
%   Fuel density and the avionics weight-fraction lookup are LEVEL-AGNOSTIC
%   (same Nicolai/Raymer tables as L1) and are reused via a direct cross-
%   toolbox call to SubsystemsL1 rather than duplicated here -- same reuse
%   pattern as GeomL3 cross-calling GeomL1/GeomL2 statics.
%
%   ROSKAM tau_w CONVENTION WARNING: Eq. 6.3 defines tau_w = (t/c)_tip /
%   (t/c)_root -- the OPPOSITE of the geometry discipline's own Roskam Vol.
%   II Eq. 12.1, which uses tau = (t/c)_root/(t/c)_tip. Implemented exactly
%   per Eq. 6.3's own stated definition; do NOT "fix" it to match Eq. 12.1's
%   convention -- Roskam does not use one consistent tau across his own
%   equations.
%
%   Companion doc: src/disciplines/subsystems/SubsystemsL2.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function val = avionics_weight_fraction(obj)
        %AVIONICS_WEIGHT_FRACTION  Level-agnostic Raymer Table 11.6 lookup --
        %   reused directly from SubsystemsL1, not duplicated.
            val = SubsystemsL1.lookup_avionics_weight_fraction(obj.avionics_table_row);
        end

        function val = avionics_density(obj) %#ok<INUSD>
        %AVIONICS_DENSITY  Flat 45 lb/ft^3, L2/L3's own figure.
        %   [Nicolai & Carichner, Sec.8.1.11, p.210] -- fidelity-split
        %   decision (Casey, 2026-07-31), distinct from L1's Raymer-range
        %   average (~37.5).
            val = 45.0;
        end

        function val = avionics_weight(obj)
        %AVIONICS_WEIGHT  fraction * W_empty [lbf]. W_empty = obj's own
        %   injected fuel_weight_source.OEW(fuel_weight_source.W_TO) --
        %   self-referencing, zero extra args.
            ws = obj.fuel_weight_source;
            W_empty = ws.OEW(ws.W_TO);
            val = SubsystemsL2.avionics_weight_fraction(obj) * W_empty;
        end

        function val = avionics_volume(obj)
        %AVIONICS_VOLUME  avionics_weight / avionics_density [ft^3].
            val = SubsystemsBase.weight_to_volume( ...
                SubsystemsL2.avionics_weight(obj), SubsystemsL2.avionics_density(obj));
        end

        function val = fuel_density(obj)
        %FUEL_DENSITY  Level-agnostic Nicolai Table 8.6 lookup -- reused
        %   directly from SubsystemsL1, not duplicated.
            val = SubsystemsL1.lookup_fuel_density(obj.fuel_type);
        end

        function val = fuselage_raw_volume(obj)
        %FUSELAGE_RAW_VOLUME  [Raymer 6th ed. Eq. 7.14], A_top/A_side from
        %   obj.geom's fuselage-envelope ellipse.
            g = obj.geom;
            [A_top, A_side] = SubsystemsL2.compute_envelope_projected_areas( ...
                g.L_fuselage, g.W_max_fuselage, g.H_max_fuselage);
            val = SubsystemsL2.compute_raymer_fuselage_volume(A_top, A_side, g.L_fuselage);
        end

        function val = fuselage_usable_fuel_volume(obj)
        %FUSELAGE_USABLE_FUEL_VOLUME  fuselage_raw_volume * packaging_factor
        %   [ft^3]. Packaging factor applied BEFORE any comparison against a
        %   required fuel volume (item 5b; "Legacy Bugs to Avoid" addendum --
        %   the legacy code compared raw volume directly).
            pf = SubsystemsL2.lookup_packaging_factor(obj.packaging_factor_category);
            val = SubsystemsL2.fuselage_raw_volume(obj) * pf;
        end

        function val = wing_fuel_volume(obj)
        %WING_FUEL_VOLUME  [Roskam Eq. 6.2/6.3] off obj.geom's wing planform.
            g = obj.geom;
            val = SubsystemsL2.compute_wing_fuel_volume( ...
                g.S_ref, g.b_wing, g.tc_r_wing, g.tc_t_wing, g.lambda_wing);
        end

        function val = fuel_volume_from_weight(obj, fuel_weight_lb)
        %FUEL_VOLUME_FROM_WEIGHT  fuel_weight_lb / fuel_density [ft^3]. The
        %   definitional weight/density conversion, level-agnostic -- reused
        %   via SubsystemsBase.weight_to_volume, not duplicated. NO packaging
        %   factor applied: that only applies to the GEOMETRIC raw volume
        %   (fuselage_usable_fuel_volume) -- this is a weight-derived figure,
        %   a different quantity (see fuel_volume_check's own required_vol
        %   computation, which uses this identical path).
            arguments
                obj
                fuel_weight_lb (1,1) double {mustBeNonnegative}
            end
            val = SubsystemsBase.weight_to_volume(fuel_weight_lb, SubsystemsL2.fuel_density(obj));
        end

        function val = fuel_volume(obj)
        %FUEL_VOLUME  Total available (usable) fuel volume [ft^3] =
        %   fuselage-internal (packaged) + wing-internal. Same sum
        %   fuel_volume_check reports as 'available_vol_ft3' -- named here as
        %   its own property so a caller can read it without the full
        %   sufficiency-check struct.
            val = SubsystemsL2.fuselage_usable_fuel_volume(obj) + SubsystemsL2.wing_fuel_volume(obj);
        end

        function val = battery_volume(obj, E_required_kWh) %#ok<INUSD,STOUT>
        %BATTERY_VOLUME  NOT IMPLEMENTED -- documented citation GAP. Only
        %   GRAVIMETRIC specific energy is cited anywhere in
        %   this repo [Nicolai & Carichner, Table 14.2, p.363, batteries
        %   0.27 kWh/lb]; no citable VOLUMETRIC energy density (kWh/ft^3) or
        %   pack density (lb/ft^3) exists to convert a required energy into a
        %   volume. Errors rather than fabricating a coefficient -- mirrors
        %   TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo's
        %   established documented-TODO convention.
            error('SubsystemsL2:batteryVolumetricDensityNotAvailable', ...
                ['No citable battery VOLUMETRIC energy density (kWh/ft^3) or ' ...
                 'pack density (lb/ft^3) exists anywhere in this repository -- ' ...
                 'only gravimetric specific energy is cited [Nicolai & ' ...
                 'Carichner, Table 14.2, p.363, 0.27 kWh/lb]. Not implemented, ' ...
                 'not guessed. See examples/F16A/inputs/f16a_L2.json ' ...
                 '.subsystems._TODO_battery_specific_volume for the full gap ' ...
                 'record.']);
        end

        function val = internal_volume(obj)
        %INTERNAL_VOLUME  Total usable internal volume [ft^3] = fuselage
        %   usable fuel volume + wing fuel volume + avionics volume.
        %   Landing-gear bay volume is DELIBERATELY NOT summed here -- item
        %   11's citation gap means that term always errors; auto-summing it
        %   would make every internal_volume() call fail. See
        %   F16SubsystemsL2.md "Landing-gear bay volume" note.
            val = SubsystemsL2.fuel_volume(obj) + SubsystemsL2.avionics_volume(obj);
        end

        function result = fuel_volume_check(obj)
        %FUEL_VOLUME_CHECK  Compares fuel_volume(obj) (fuselage-internal
        %   packaged + wing-internal, NEVER just one -- "Legacy Bugs to
        %   Avoid" item 5) against obj.fuel_weight_source.W_energy, converted
        %   to a required volume via fuel_volume_from_weight. Errors if
        %   W_energy has not yet been set by mission analysis.
            available = SubsystemsL2.fuel_volume(obj);
            W_energy = obj.fuel_weight_source.W_energy;
            if ~isfinite(W_energy)
                error('SubsystemsL2:fuelWeightNotSet', ...
                    ['fuel_weight_source.W_energy is NaN -- mission analysis ' ...
                     'has not set the required internal-fuel weight yet. Set ' ...
                     'it on the injected weights object before calling ' ...
                     'fuel_volume_check.']);
            end
            required_vol = SubsystemsL2.fuel_volume_from_weight(obj, W_energy);
            result = struct('available_vol_ft3', available, ...
                             'required_vol_ft3', required_vol, ...
                             'sufficient', available >= required_vol);
        end

        % ================================================================== %
        % LOW-LEVEL: pure math/lookups -- scalars only, no object access.
        % ================================================================== %

        function val = compute_raymer_fuselage_volume(A_top, A_side, L_fus)
        %COMPUTE_RAYMER_FUSELAGE_VOLUME  Raw fuselage internal volume [ft^3].
        %   [Raymer 6th ed. Eq. 7.14]  V = 3.4*(A_top*A_side)/(4*L).
            arguments
                A_top  (1,1) double {mustBePositive}
                A_side (1,1) double {mustBePositive}
                L_fus  (1,1) double {mustBePositive}
            end
            val = 3.4 * (A_top * A_side) / (4 * L_fus);
        end

        function [A_top, A_side] = compute_envelope_projected_areas(L_fus, W_max, H_max)
        %COMPUTE_ENVELOPE_PROJECTED_AREAS  Top-view and side-view projected
        %   areas [ft^2] of the fuselage envelope, feeding Raymer Eq. 7.14's
        %   A_top/A_side inputs. Modeled as elliptical planform/profile
        %   footprints (length L, width W_max / height H_max) -- the natural
        %   extension of GeometryBase.compute_Amax_elliptical's existing
        %   (pi/4)*W*H cross-section-ellipse assumption to the LENGTHWISE
        %   projections, consistent with L2's "fuselage-envelope ellipse"
        %   geometry model (no separate equation number; standard elliptical-
        %   footprint identity, same citation status as
        %   GeometryBase.compute_Amax_elliptical).
            arguments
                L_fus (1,1) double {mustBePositive}
                W_max (1,1) double {mustBePositive}
                H_max (1,1) double {mustBePositive}
            end
            A_top  = (pi/4) * L_fus * W_max;
            A_side = (pi/4) * L_fus * H_max;
        end

        function val = compute_wing_fuel_volume(S, b, tc_r, tc_t, lambda_w)
        %COMPUTE_WING_FUEL_VOLUME  Wing-internal fuel volume [ft^3].
        %   [Roskam, Airplane Design Part II, Ch.6, p.153, Eq. 6.2/6.3,
        %   attributed by Roskam to Torenbeek Ref.17 Eqn. B-12]
        %   tau_w = (t/c)_tip / (t/c)_root [Eq. 6.3] -- see this class's
        %   header for the convention warning vs. Roskam Eq. 12.1.
        %   REPLACES the legacy uncited "MFV" formula (t_avg=0.7*(...),
        %   MFV=0.3*S_ref*t_avg) -- no source for its 0.7/0.3 coefficients
        %   was found anywhere in this repo, so it is dropped entirely, not
        %   carried forward in any form.
            arguments
                S       (1,1) double {mustBePositive}
                b       (1,1) double {mustBePositive}
                tc_r    (1,1) double {mustBePositive}
                tc_t    (1,1) double {mustBePositive}
                lambda_w (1,1) double {mustBeNonnegative}
            end
            tau_w = tc_t / tc_r;   % Eq. 6.3: tip/root -- NOT root/tip
            val = 0.54 * (S^2 / b) * tc_r ...
                * (1 + lambda_w*sqrt(tau_w) + lambda_w^2*tau_w) / (1 + lambda_w)^2;
        end

        function pf = lookup_packaging_factor(category)
        %LOOKUP_PACKAGING_FACTOR  Fuel-tank usable-volume packaging factor by
        %   construction/location category.
        %   [Nicolai & Carichner, p.210, unnumbered "Fuel Tank Packaging
        %   Factors" table]. Full 5-row table, reproduced verbatim.
            switch category
                case 'Integral tank — shallow fuselage', pf = 0.80;
                case 'Integral tank — deep fuselage',     pf = 0.85;
                case 'Integral tank — wing',              pf = 0.75;
                case 'Bladder tank — fuselage',           pf = 0.75;
                case 'Bladder tank — wing',                pf = 0.65;
                otherwise
                    error('SubsystemsL2:unknownPackagingCategory', ...
                        ['Unknown fuel-tank packaging category "%s". Known ' ...
                         'categories (Nicolai & Carichner Fuel Tank Packaging ' ...
                         'Factors table): Integral tank — shallow fuselage, ' ...
                         'Integral tank — deep fuselage, Integral tank — wing, ' ...
                         'Bladder tank — fuselage, Bladder tank — wing.'], category);
            end
        end

    end
end
