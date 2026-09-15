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
        
        %AVIONICS_WEIGHT  fraction * W_empty [lbf], W_empty =
        %   fuel_weight_source.get_OEW(fuel_weight_source.W_TO); zero extra args.
        avionics_weight

        %WING_FUEL_VOLUME  Wing-internal fuel volume [ft^3].
        %   [Roskam Airplane Design Part II, Eq. 6.2/6.3] Off obj.geom's
        %   S_ref, b_wing, tc_r_wing, tc_t_wing, lambda_wing. Not multiplied
        %   by a second packaging factor (Nicolai's applies only to fuselage).
        wing_fuel_volume

        %TOTAL_DESIGN_VOLUME
        % Just the entire design's volume.
        total_design_volume
    end

    methods (Abstract)

        %GET_AVIONICS_WEIGHT  W_avionics = fraction * W_empty [lbf].
        val = get_avionics_weight_categorical(obj, W_empty)

        % Estimate the design's total avionics volume using statistical methods.
        val = get_total_avionics_volume_categorical(obj, W_empty)

        % Estimate the fuel-useable volume of the aircraft's main wings.
        % This can be the fuselage (tube-and-wing) or just the wings (flying wing).
        val = get_wing_fuel_volume_available(obj)

        % GET_DESIGN_TOTAL_VOLUME
        % Estimate the design's total volume using rough geometric methods by Raymer and/or Roskam.
        % User is expected to estimate internal volumes of major aircraft parts, such as the main wings and fuselage.
        val = get_total_design_volume(obj)

    end

    methods
        function v = get_total_avionics_volume_occupied(obj)
            v = obj.get_total_avionics_volume_categorical();
        end
        function v = get_avionics_weight(obj, W_empty)
            v = obj.get_total_avionics_weight_categorical(W_empty);
        end
    end

end
