classdef SubsystemsL2
%SUBSYSTEMSL2  Level-2 subsystems static toolbox: geometry-derived volumes.
%
%   Call as SubsystemsL2.method(...); never instantiated. F16SubsystemsL2
%   delegates here.
%
%   Formulas: fuselage raw volume [Raymer 6th ed. Eq. 7.14]; wing fuel volume
%   [Roskam, Airplane Design Part II, Ch.6, Eq. 6.2/6.3]; packaging factor and
%   fuel density [Nicolai & Carichner, Ch.8, p.210]; avionics weight fraction
%   [Raymer 6th ed. Table 11.6] with L2's flat Nicolai avionics density
%   (45 lb/ft^3). Fuel density and the avionics weight-fraction lookup are
%   level-agnostic and are reused from SubsystemsL1, not duplicated.
%
%   ROSKAM tau_w CONVENTION WARNING: Eq. 6.3 defines tau_w = (t/c)_tip /
%   (t/c)_root -- the OPPOSITE of the geometry discipline's Roskam Vol. II
%   Eq. 12.1, which uses tau = (t/c)_root/(t/c)_tip. Implemented per Eq. 6.3's
%   stated definition; do NOT "fix" it to match Eq. 12.1 -- Roskam does not
%   use one consistent tau across his equations.
%
%   Companion doc: src/disciplines/subsystems/SubsystemsL2.md

    properties (Constant)
        %AVIONICS_DENSITY  L2/L3 flat density [lb/ft^3].
        %  [Nicolai & Carichner Sec.8.1.11, p.210]
        AVIONICS_DENSITY = 45
    end

    methods (Static)

        function val = compute_battery_volume(E_required_kWh) %#ok<INUSD,STOUT>
        %BATTERY_VOLUME  NOT IMPLEMENTED -- documented citation gap. Only
        %   gravimetric specific energy is cited [Nicolai & Carichner,
        %   Table 14.2, p.363, batteries 0.27 kWh/lb]; no citable volumetric
        %   energy density (kWh/ft^3) or pack density (lb/ft^3) exists to
        %   convert required energy into volume. Errors rather than fabricate.
            error('SubsystemsL2:batteryVolumetricDensityNotAvailable', ...
                ['No citable battery VOLUMETRIC energy density (kWh/ft^3) or ' ...
                 'pack density (lb/ft^3) exists anywhere in this repository -- ' ...
                 'only gravimetric specific energy is cited [Nicolai & ' ...
                 'Carichner, Table 14.2, p.363, 0.27 kWh/lb]. Not implemented, ' ...
                 'not guessed. See examples/F16A/inputs/f16a_L2.json ' ...
                 '.subsystems._TODO_battery_specific_volume for the full gap ' ...
                 'record.']);
        end


        function result = fuel_volume_check(fuel_vol_required, fuel_vol_available)
        %FUEL_VOLUME_CHECK  Compares fuel_volume(obj) (fuselage-internal
        %   packaged + wing-internal, never just one) against
        %   obj.fuel_weight_source.W_energy, converted to a required volume
        %   via fuel_volume_from_weight. Errors if W_energy is not yet set.
            if (isnan(fuel_vol_required) || isnan(fuel_vol_available))
                error("fuel_volume_check: NaN in argument")
            else
                result = struct('available_vol_ft3', fuel_vol_available, ...
                        'required_vol_ft3', fuel_vol_required, ...
                        'sufficient', fuel_vol_available >= fuel_vol_required);
            end
        end

        % ================================================================== %
        % LOW-LEVEL: pure math/lookups
        % ================================================================== %

        function val = compute_fuselage_volume_raymer(A_top, A_side, L_fus)
        %COMPUTE_FUSELAGE_VOLUME_RAYMER  Raw fuselage internal volume [ft^3].
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
        %   A_top/A_side inputs. Elliptical footprints (length L, width W_max
        %   / height H_max): the lengthwise extension of
        %   F16GeomL2.compute_Amax_elliptical's (pi/4)*W*H assumption. No
        %   separate equation number; same citation status as that method.
        %   Mod (08/19/2026) (Claude)
            arguments
                L_fus (1,1) double {mustBePositive}
                W_max (1,1) double {mustBePositive}
                H_max (1,1) double {mustBePositive}
            end
            A_top  = (pi/4) * L_fus * W_max;
            A_side = (pi/4) * L_fus * H_max;
        end

        function val = compute_wing_fuel_volume_roskam(S, b, tc_r, tc_t, lambda_w)
        %COMPUTE_WING_FUEL_VOLUME_ROSKAM  Wing-internal fuel volume [ft^3].
        %   [Roskam, Airplane Design Part II, Ch.6, p.153, Eq. 6.2/6.3,
        %   attributed by Roskam to Torenbeek Ref.17 Eqn. B-12]
        %   tau_w = (t/c)_tip / (t/c)_root [Eq. 6.3] -- see this class's
        %   header for the convention warning vs. Roskam Eq. 12.1.
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

        function pf = lookup_packaging_factor_nicolai(category)
        %LOOKUP_PACKAGING_FACTOR_NICOLAI  Fuel-tank usable-volume packaging factor by
        %   construction/location category. Full 5-row table, verbatim.
        %   [Nicolai & Carichner, p.210, "Fuel Tank Packaging Factors" table]
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
