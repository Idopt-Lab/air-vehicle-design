classdef (Abstract) SubsystemsModelL2 < SubsystemsBase
%SUBSYSTEMSMODELL2  Tier-2 abstract enforcer for Level-2 subsystems.
%
%   Inherits SubsystemsBase directly. L2 is geometry-derived: fuselage volume
%   via Raymer Eq. 7.14 off the injected geometry's envelope-ellipse
%   A_top/A_side, wing volume via Roskam Eq. 6.2/6.3, plus a battery-electric
%   path (a documented citation gap, see battery_volume).
%
%   Dependency injection, guarded at this enforcer tier:
%     geom               -- (1,1) GeometryModelL2. Reads S_ref, b_wing,
%                           tc_r_wing/tc_t_wing, lambda_wing (Roskam wing
%                           term) and L_fus/W_max_fuselage/H_max_fuselage
%                           (Raymer fuselage term).
%     fuel_weight_source -- (1,1) WeightsBase. Supplies the required fuel
%                           weight for fuel_volume_check (obj.W_energy) and
%                           W_empty for the avionics term (obj.get_OEW(obj.W_TO)).
%
%   Every quantity below the injected collaborators is derived: recomputed
%   live on every read, never cached (CLAUDE.md optimization-ready pattern).
%
%   History and rationale: docs/decision_log.md
%   Toolbox companion: src/disciplines/subsystems/SubsystemsL2.md

    properties (Abstract)
        fuel_type                  % string, e.g. 'JP-8' -- selects SubsystemsL2.lookup_fuel_density [Nicolai & Carichner Table 8.6]
        packaging_factor_category  % string, e.g. 'Integral tank — shallow fuselage' -- selects SubsystemsL2.lookup_packaging_factor_nicolai [Nicolai & Carichner p.210]
        avionics_table_row         % string, e.g. 'Fighters' -- selects SubsystemsL2.lookup_avionics_weight_fraction [Raymer 6th ed. Table 11.6]

        % ----- Injected collaborators (NOT numeric spec data) ------------- %
        geom                % (1,1) GeometryModelL2
        fuel_weight_source  % (1,1) WeightsBase
    end

    % ======================================================================= %
    % avionics_weight_fraction, avionics_density, fuel_density,
    % fuselage_raw_volume and fuel_volume are declared on SubsystemsBase. Every
    % member below takes zero extra arguments and reads only obj's own inputs/
    % collaborators, so it is an abstract PROPERTY, not a method (matching
    % WeightsModelL2's split). An abstract METHOD is reserved for the form that
    % takes an external argument, e.g. battery_volume below. The concrete class
    % implements each as a get.<name> Dependent getter that recomputes live.
    % ======================================================================= %
    properties (Abstract)
        %AVIONICS_WEIGHT  fraction * W_empty [lbf], W_empty =
        %   fuel_weight_source.get_OEW(fuel_weight_source.W_TO); zero extra args.
        avionics_weight

        %AVIONICS_VOLUME  avionics_weight / avionics_density [ft^3]. MUST be
        %   summed into internal_volume() -- see SubsystemsBase header.
        avionics_volume

        %WING_FUEL_VOLUME  Wing-internal fuel volume [ft^3].
        %   [Roskam Airplane Design Part II, Eq. 6.2/6.3] Off obj.geom's
        %   S_ref, b_wing, tc_r_wing, tc_t_wing, lambda_wing. Not multiplied
        %   by a second packaging factor (Nicolai's applies only to fuselage).
        wing_fuel_volume
    end

    methods (Abstract)

        %BATTERY_VOLUME  NOT IMPLEMENTED -- documented citation gap. Stays a
        %   METHOD, not a Dependent property: it takes an external argument
        %   (E_required_kWh), and a Dependent getter must never throw (MATLAB
        %   evaluates every getter eagerly during object display). Errors with
        %   a distinct error identifier rather than fabricate a coefficient.
        val = battery_volume(obj, E_required_kWh)

        % Estimate the fuel-useable volume of the aircraft's main wings.
        % This can be the fuselage (tube-and-wing) or just the wings (flying wing).
        val = get_wing_fuel_volume_available(obj)

        % Estimate the fuel-useable volume of the entire aircraft.
        val = get_total_fuel_volume_available(obj)

        % Estimate the design's total avionics volume using statistical methods.
        val = get_total_avionics_volume_statistical(obj)

    end

    methods
        function v = get_avionics_volume(obj)
            v = obj.get_total_avionics_volume_statistical();
        end
        function v = get_avionics_weight(obj)
            v = obj.get_total_avionics_weight_statistical();
        end
    end

end
