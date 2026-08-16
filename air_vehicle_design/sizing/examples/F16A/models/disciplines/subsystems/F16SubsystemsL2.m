classdef F16SubsystemsL2 < SubsystemsModelL2
%F16SUBSYSTEMSL2  F-16A Block 10/15 Level-2 subsystems student class.
%
%   Inherits from SubsystemsModelL2 (abstract enforcer). Every abstract
%   method is satisfied by a single delegation line to SubsystemsL2 statics
%   -- no equations are duplicated here.
%
%   METHOD: fuselage-internal raw volume [Raymer 6th ed. Eq. 7.14] off the
%   injected L2 geometry's envelope-ellipse A_top/A_side, x fuel-tank
%   packaging factor [Nicolai & Carichner p.210]; wing-internal fuel volume
%   [Roskam Eq. 6.2/6.3]; avionics volume from a weight fraction of W_empty
%   [Raymer Table 11.6] x Nicolai's flat 45 lb/ft^3 density. Battery-electric
%   volume is a documented citation GAP (see battery_volume).
%
%   internal_volume() = fuselage_usable_fuel_volume + wing_fuel_volume +
%   avionics_volume. Landing-gear bay volume is deliberately NOT summed in
%   here -- see the "Landing-gear bay volume" note below.
%
%   DEPENDENCY INJECTION (mirrors F16WeightsL2's geom/prop DI pattern):
%     geom               -- (1,1) GeometryModelL2, guarded at the L2 enforcer
%                           so a wrong-tier object fails at construction. Only
%                           S_ref, b_wing, tc_r_wing, tc_t_wing, lambda_wing
%                           (wing-volume term) and L_fuselage, W_max_fuselage,
%                           H_max_fuselage (fuselage-volume term) are read.
%     fuel_weight_source -- (1,1) WeightsBase. Supplies both the required fuel
%                           weight for fuel_volume_check (W_energy) and W_empty
%                           for the avionics-weight term (OEW(W_TO)). One
%                           injected object serves both roles.
%   No silent default on either argument.
%
%   LANDING-GEAR BAY VOLUME -- not auto-summed. Blocked on item 11's citation
%   gap (no textbook bay-volume packaging formula exists in this repo --
%   F16LandingGearL2.bay_volume always errors). A caller wanting the gear
%   contribution should call F16LandingGearL2.bay_volume() directly and add it.
%
%   CONSTRUCTOR: F16SubsystemsL2(json_path, geom, fuel_weight_source). All
%   three required.
%
%   SOURCES:
%     [Raymer] D.P. Raymer, Aircraft Design 6th/7th ed., Eq. 7.14, Table 11.6.
%     [Roskam] J. Roskam, Airplane Design Part II, Ch.6, Eq. 6.2/6.3.
%     [Nicolai] Nicolai & Carichner, Ch.8, p.210 (fuel packaging/density
%               table; avionics density Sec.8.1.11); Table 14.2, p.363
%               (battery gravimetric specific energy -- the cited half of
%               item 7's GAP).
%
%   Companion doc: examples/F16A/models/disciplines/subsystems/F16SubsystemsL2.md

    % INPUTS (3) + 2 injected objects -- plain mutable properties, set once by
    % the constructor. Authoritative table: F16SubsystemsL2.md §2.
    properties
        fuel_type                 = 'JP-8'                              % [f16a_L2.json .subsystems.fuel.fuel_type]
        packaging_factor_category = 'Integral tank — shallow fuselage'   % [f16a_L2.json .subsystems.fuel.packaging_factor_category]
        avionics_table_row        = 'Fighters'                          % [f16a_L2.json .subsystems.avionics.aircraft_category_table_row]

        % ----- Injected collaborators (NOT numeric spec data) ------------- %
        geom                % (1,1) GeometryModelL2 -- supplies fuselage/wing geometry for the volume terms
        fuel_weight_source  % (1,1) WeightsBase -- supplies W_energy (fuel sufficiency check) and OEW/W_TO (avionics W_empty)
    end

    % DERIVED (9) -- zero-extra-arg quantities that read only the inputs/
    % injected collaborators above. Dependent getters, recomputed live on every
    % read; SubsystemsBase/SubsystemsModelL2 declare these as abstract
    % PROPERTIES. battery_volume and fuel_volume_from_weight stay methods (both
    % take an external argument, and battery_volume deliberately errors).
    properties (Dependent)
        avionics_weight_fraction
        avionics_density
        avionics_weight
        avionics_volume
        fuel_density
        fuselage_raw_volume
        fuselage_usable_fuel_volume
        wing_fuel_volume
        fuel_volume  % = fuselage_usable_fuel_volume + wing_fuel_volume [SubsystemsBase.m]
    end

    methods

        function obj = F16SubsystemsL2(json_path, geom, fuel_weight_source)
        %F16SUBSYSTEMSL2  Construct from a required unified L2 input JSON
        %   path (f16a_spec_path(2)), a required injected L2 geometry
        %   object, and a required injected weights object supplying the
        %   fuel/avionics weight quantities. NO silent default on any
        %   argument.
            arguments
                json_path                {mustBeTextScalar, mustBeNonzeroLengthText}
                geom               (1,1) GeometryModelL2
                fuel_weight_source (1,1) WeightsBase
            end
            J = jsondecode(fileread(json_path));

            obj.geom               = geom;
            obj.fuel_weight_source = fuel_weight_source;

            obj.fuel_type                 = char(J.subsystems.fuel.fuel_type);
            obj.packaging_factor_category = char(J.subsystems.fuel.packaging_factor_category);
            obj.avionics_table_row        = char(J.subsystems.avionics.aircraft_category_table_row);
        end

        % ================================================================== %
        % Methods required by the abstract contract that take a genuine
        % external argument, or are the Tier-1 orchestrator contract -- each
        % a single delegation into the SubsystemsL2 static toolbox.
        % ================================================================== %

        function val = battery_volume(obj, E_required_kWh)
            val = SubsystemsL2.battery_volume(obj, E_required_kWh);
        end

        function val = fuel_volume_from_weight(obj, fuel_weight_lb)
            val = SubsystemsL2.fuel_volume_from_weight(obj, fuel_weight_lb);
        end

        function val = internal_volume(obj)
            val = SubsystemsL2.internal_volume(obj);
        end

        function result = fuel_volume_check(obj)
            result = SubsystemsL2.fuel_volume_check(obj);
        end

        % ================================================================== %
        % DERIVED-property getters required by the abstract contract -- each a
        % single delegation into the SubsystemsL2 static toolbox, recomputed
        % live on every read.
        % ================================================================== %

        function val = get.avionics_weight_fraction(obj)
            val = SubsystemsL2.avionics_weight_fraction(obj);
        end

        function val = get.avionics_density(obj)
            val = SubsystemsL2.avionics_density(obj);
        end

        function val = get.avionics_weight(obj)
            val = SubsystemsL2.avionics_weight(obj);
        end

        function val = get.avionics_volume(obj)
            val = SubsystemsL2.avionics_volume(obj);
        end

        function val = get.fuel_density(obj)
            val = SubsystemsL2.fuel_density(obj);
        end

        function val = get.fuselage_raw_volume(obj)
            val = SubsystemsL2.fuselage_raw_volume(obj);
        end

        function val = get.fuselage_usable_fuel_volume(obj)
            val = SubsystemsL2.fuselage_usable_fuel_volume(obj);
        end

        function val = get.wing_fuel_volume(obj)
            val = SubsystemsL2.wing_fuel_volume(obj);
        end

        function val = get.fuel_volume(obj)
            val = SubsystemsL2.fuel_volume(obj);
        end

    end

end
