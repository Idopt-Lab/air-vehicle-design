classdef F16SubsystemsL3 < SubsystemsModelL3
%F16SUBSYSTEMSL3  F-16A Block 10/15 Level-3 subsystems student class.
%
%   Inherits from SubsystemsModelL3 (abstract enforcer). Every abstract
%   method is satisfied by a single delegation line to SubsystemsL3 statics
%   -- no equations are duplicated here.
%
%   Same equations as F16SubsystemsL2 (Raymer Eq. 7.14 fuselage volume,
%   Roskam Eq. 6.2/6.3 wing volume, Nicolai fuel/avionics tables); the ONLY
%   difference is that the fuselage raw-volume term is fed A_top/A_side from
%   the injected L3 geometry's frame-integrated station table instead of
%   L2's envelope-ellipse approximation (Fidelity split). SubsystemsL3
%   reuses SubsystemsL2's statics directly for every level-agnostic equation
%   -- see SubsystemsL3.m's header.
%
%   internal_volume() and the "landing-gear bay volume not auto-summed" note
%   are identical to F16SubsystemsL2 -- see that class's header for the full
%   rationale (item 11's citation gap; Objectives §3 is aspirational).
%
%   DEPENDENCY INJECTION -- identical shape to F16SubsystemsL2, but geom is
%   typed to GeometryModelL3 (guarded at the L3 ENFORCER), and
%   fuel_weight_source is typically an F16WeightsL3 instance (also a
%   WeightsBase). See F16SubsystemsL2.m for the full fuel_weight_source
%   rationale (one injected object serves both the fuel-sufficiency check
%   and the avionics W_empty term).
%
%   CONSTRUCTOR: F16SubsystemsL3(json_path, geom, fuel_weight_source). All
%   three REQUIRED, no silent default.
%
%   SOURCES: same as F16SubsystemsL2 -- see that class's header.
%
%   Companion doc: examples/F16A/models/disciplines/subsystems/F16SubsystemsL3.md

    % INPUTS (3) + 2 injected objects -- plain mutable properties, set once by
    % the constructor. Authoritative table: F16SubsystemsL3.md §2.
    properties
        fuel_type                 = 'JP-8'                              % [f16a_L3.json .subsystems.fuel.fuel_type]
        packaging_factor_category = 'Integral tank — shallow fuselage'   % [f16a_L3.json .subsystems.fuel.packaging_factor_category]
        avionics_table_row        = 'Fighters'                          % [f16a_L3.json .subsystems.avionics.aircraft_category_table_row]

        % ----- Injected collaborators (NOT numeric spec data) ------------- %
        geom                % (1,1) GeometryModelL3 -- supplies fuselage/wing geometry for the volume terms
        fuel_weight_source  % (1,1) WeightsBase -- supplies W_energy (fuel sufficiency check) and OEW/W_TO (avionics W_empty)
    end

    % DERIVED (9) -- same rationale as F16SubsystemsL2: zero-extra-arg
    % quantities that read only the inputs/injected collaborators above,
    % implemented as Dependent getters, not methods.
    properties (Dependent)
        avionics_weight_fraction
        avionics_density
        avionics_weight
        avionics_volume
        fuel_density
        fuselage_raw_volume
        fuselage_usable_fuel_volume
        wing_fuel_volume
        fuel_volume  % = L3's own fuselage_usable_fuel_volume + wing_fuel_volume [SubsystemsBase.m]
    end

    methods

        function obj = F16SubsystemsL3(json_path, geom, fuel_weight_source)
        %F16SUBSYSTEMSL3  Construct from a required unified L3 input JSON
        %   path (f16a_spec_path(3)), a required injected L3 geometry
        %   object, and a required injected weights object. NO silent
        %   default on any argument.
            arguments
                json_path                {mustBeTextScalar, mustBeNonzeroLengthText}
                geom               (1,1) GeometryModelL3
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
        % a single delegation into the SubsystemsL3 static toolbox.
        % ================================================================== %

        function val = battery_volume(obj, E_required_kWh)
            val = SubsystemsL3.battery_volume(obj, E_required_kWh);
        end

        function val = fuel_volume_from_weight(obj, fuel_weight_lb)
            val = SubsystemsL3.fuel_volume_from_weight(obj, fuel_weight_lb);
        end

        function val = internal_volume(obj)
            val = SubsystemsL3.internal_volume(obj);
        end

        function result = fuel_volume_check(obj)
            result = SubsystemsL3.fuel_volume_check(obj);
        end

        % ================================================================== %
        % DERIVED-property getters required by the abstract contract -- each a
        % single delegation into the SubsystemsL3 static toolbox, recomputed
        % live on every read.
        % ================================================================== %

        function val = get.avionics_weight_fraction(obj)
            val = SubsystemsL3.avionics_weight_fraction(obj);
        end

        function val = get.avionics_density(obj)
            val = SubsystemsL3.avionics_density(obj);
        end

        function val = get.avionics_weight(obj)
            val = SubsystemsL3.avionics_weight(obj);
        end

        function val = get.avionics_volume(obj)
            val = SubsystemsL3.avionics_volume(obj);
        end

        function val = get.fuel_density(obj)
            val = SubsystemsL3.fuel_density(obj);
        end

        function val = get.fuselage_raw_volume(obj)
            val = SubsystemsL3.fuselage_raw_volume(obj);
        end

        function val = get.fuselage_usable_fuel_volume(obj)
            val = SubsystemsL3.fuselage_usable_fuel_volume(obj);
        end

        function val = get.wing_fuel_volume(obj)
            val = SubsystemsL3.wing_fuel_volume(obj);
        end

        function val = get.fuel_volume(obj)
            val = SubsystemsL3.fuel_volume(obj);
        end

    end

end
