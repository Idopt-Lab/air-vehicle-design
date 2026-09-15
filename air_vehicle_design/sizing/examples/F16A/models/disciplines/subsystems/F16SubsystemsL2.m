classdef F16SubsystemsL2 < SubsystemsModelL2
%F16SUBSYSTEMSL2  F-16A Block 10/15 Level-2 subsystems student class.
%
%   Inherits from SubsystemsModelL2. Incorporates geometry into design analysis.
%   Re-uses parts of SubsystemsL1 because they're still relevant and there's no
%   L2 equivalent.
%
%   Properties:
%       fuel_type (char): fuel selecting the density table row.
%       avionics_table_row (char): Raymer Table 11.6 row.
%       packaging_factor_category (char): tank type selecting the packaging factor.
%       fuselage_packaging_factor_category (char): unused.
%       wing_packaging_factor_category (char): unused.
%       geom (GeometryModelL2): injected. Supplies S_ref, b_wing, tc_r_wing,
%           tc_t_wing, lambda_wing, L_fus, W_max_fuselage, H_max_fuselage.
%       fuel_weight_source (WeightsBase): injected. Supplies W_energy and
%           OEW(W_TO).
%
%   Properties (Dependent):
%       avionics_weight_fraction (double): fraction of W_empty.
%       avionics_density (double): avionics packing density (lb/ft^3).
%       avionics_weight (double): avionics weight (lbf).
%       total_avionics_volume_occupied (double): avionics volume (ft^3).
%       fuel_density (double): fuel density (lb/ft^3).
%       fuselage_fuel_volume (double): usable fuselage fuel volume (ft^3).
%       wing_fuel_volume (double): wing fuel volume (ft^3).
%       total_design_volume (double): wing fuel volume + raw fuselage volume (ft^3).
%       total_fuel_volume_occupied (double): volume the fuel occupies (ft^3).
%
%   Methods:
%       get_avionics_weight_fraction: fraction of W_empty for the table row.
%       get_avionics_weight_categorical: avionics weight (lbf) from W_empty.
%       get_total_avionics_volume_categorical: avionics volume (ft^3) from W_empty.
%       get_wing_fuel_volume_available: wing fuel volume (ft^3).
%       get_fuselage_internal_volume: raw fuselage volume (ft^3), no packaging factor.
%       get_fuselage_fuel_volume: raw fuselage volume x packaging factor (ft^3).
%       get_fuel_volume_available: wing + fuselage usable fuel volume (ft^3).
%       get_total_fuel_volume_occupied: fuel weight / density (ft^3).
%       get_total_design_volume: wing fuel volume + raw fuselage volume (ft^3).
%       get_fuel_density: fuel density (lb/ft^3) for the stored fuel type.
%       fuel_volume_check: required against available fuel volume, returns a struct.
%
%   Constructor: F16SubsystemsL2(json_path, geom, fuel_weight_source). All
%   three required.
%
%   Landing-gear bay volume is NOT summed into any volume here.
%   F16LandingGearL2.bay_volume errors on a citation gap; a caller wanting the
%   gear contribution adds it.
%
%   Sources: Raymer 6th ed. Eq. 7.14, Table 11.6; Roskam Airplane Design
%   Part II Ch.6 Eq. 6.2/6.3; Nicolai & Carichner Ch.8 p.210.
%
%   Companion doc: examples/F16A/models/disciplines/subsystems/F16SubsystemsL2.md


    properties
        fuel_type                 = 'JP-8'                              % [f16a_L2.json .subsystems.fuel.fuel_type]
        avionics_table_row        = 'Fighters'                          % [f16a_L2.json .subsystems.avionics.aircraft_category_table_row]
        packaging_factor_category = 'Integral tank — shallow fuselage'   % [f16a_L2.json .subsystems.fuel.packaging_factor_category]
        fuselage_packaging_factor_category = 'Integral tank — shallow fuselage'
        wing_packaging_factor_category = 'Integral tank — wing'
        % ----- Injected collaborators (NOT numeric spec data) ------------- %
        geom                % (1,1) GeometryModelL2 -- supplies fuselage/wing geometry for the volume terms
        fuel_weight_source  % (1,1) WeightsBase -- supplies W_energy (fuel sufficiency check) and OEW/W_TO (avionics W_empty)
    end


    properties (Dependent)
        avionics_weight_fraction
        avionics_density
        avionics_weight
        total_avionics_volume_occupied
        fuel_density
        fuselage_fuel_volume
        wing_fuel_volume
        total_design_volume  % = fuselage_usable_fuel_volume + wing_fuel_volume [SubsystemsBase.m]
        total_fuel_volume_occupied
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
        % Methods required by the abstract contract
        % ================================================================== %

        function val = get_avionics_weight_fraction(obj)
            range = SubsystemsL1.lookup_avionics_weight_fraction_range(obj.avionics_table_row);
            avi_WF = mean(range);
            val = avi_WF;
        end

        function val = get_fuel_density(obj)
        %GET_FUEL_DENSITY  Fuel density [lb/ft^3] for the stored fuel type.
        %   No write-back: fuel_density is Dependent, so it recomputes on read.
            val = SubsystemsBase.lookup_fuel_density_lb_per_ft_3(obj.fuel_type);
        end

        % Note (9/8/2026)(Casey): Using L1 methods because no suitable L2 methods could be found.
        function val = get_avionics_weight_categorical(obj, W_empty)
            avi_WF = obj.get_avionics_weight_fraction();
            val = SubsystemsL1.compute_avionics_weight(avi_WF, W_empty);
        end

        function val = get_total_avionics_volume_categorical(obj, W_empty)
            avi_weight = obj.get_avionics_weight_categorical(W_empty);
            val = SubsystemsL1.compute_avionics_volume(avi_weight, SubsystemsL2.AVIONICS_DENSITY);
        end

        function val = get_total_design_volume(obj)
            vol_wing = obj.get_wing_fuel_volume_available();
            vol_fuselage = obj.get_fuselage_internal_volume();
            val = vol_wing + vol_fuselage;
        end

        function val = get_wing_fuel_volume_available(obj)
            val = SubsystemsL2.compute_wing_fuel_volume_roskam(obj.geom.S_ref, ...
                      obj.geom.b_wing, obj.geom.tc_r_wing, obj.geom.tc_t_wing, ...
                      obj.geom.lambda_wing);
        end

        function val = get_fuselage_internal_volume(obj)
            [A_top, A_side] = SubsystemsL2.compute_envelope_projected_areas( ...
                      obj.geom.L_fus, obj.geom.W_max_fuselage, obj.geom.H_max_fuselage);
            val = SubsystemsL2.compute_fuselage_volume_raymer(A_top, A_side, obj.geom.L_fus);
        end

        function val = get_fuselage_fuel_volume(obj)
            fuselage_vol = obj.get_fuselage_internal_volume();
            pf = SubsystemsL2.lookup_packaging_factor_nicolai(obj.packaging_factor_category);
            val = pf*fuselage_vol;
        end

        function val = get_fuel_volume_available(obj)
            % GET FUEL-USEABLE VOLUME - WINGS
            Vol_fuel_wings = obj.wing_fuel_volume;

            % GET FUEL-USEABLE VOLUME - FUSELAGE
            % Get internal volume of fuselage
            % Get AVAILABLE fuel volume of fuselage
            Vol_fuel_fuselage = obj.get_fuselage_fuel_volume();

            % Sum the components
            val = Vol_fuel_wings + Vol_fuel_fuselage;
        end

        function val = get_total_fuel_volume_occupied(obj, fuel_weight_lb)
        %GET_FUEL_VOLUME_OCCUPIED  Volume the fuel itself takes up [ft^3].
        %   No packaging factor: that belongs to the tank, not the fuel.
            val = fuel_weight_lb / obj.fuel_density;
        end


        function result = fuel_volume_check(obj, fuel_weight_lb)
            result = SubsystemsL2.fuel_volume_check(obj.get_total_fuel_volume_occupied(fuel_weight_lb), ...
                                                    obj.get_fuel_volume_available());
        end

        % ================================================================== %
        % DERIVED-property getters required by the abstract contract
        % ================================================================== %

        function val = get.avionics_weight_fraction(obj)
            range = SubsystemsL1.lookup_avionics_weight_fraction_range(obj.avionics_table_row);
            val   = mean(range);
        end

        function val = get.avionics_density(obj) %#ok<MANU>
            val = SubsystemsL2.AVIONICS_DENSITY;
        end

        function val = get.avionics_weight(obj)
            ws  = obj.fuel_weight_source;
            val = SubsystemsL1.compute_avionics_weight( ...
                      obj.avionics_weight_fraction, ws.get_OEW(ws.W_TO));
        end

        function val = get.total_avionics_volume_occupied(obj)
            val = SubsystemsL1.compute_avionics_volume( ...
                      obj.avionics_weight, obj.avionics_density);
        end

        function val = get.wing_fuel_volume(obj)
            val = SubsystemsL2.compute_wing_fuel_volume_roskam(obj.geom.S_ref, ...
                      obj.geom.b_wing, obj.geom.tc_r_wing, obj.geom.tc_t_wing, ...
                      obj.geom.lambda_wing);
        end

        function val = get.fuel_density(obj)
            val = obj.get_fuel_density();
        end

        function val = get.fuselage_fuel_volume(obj)
            val = obj.get_fuselage_fuel_volume();
        end

        function val = get.total_design_volume(obj)
            val = obj.get_total_design_volume();
        end

        function val = get.total_fuel_volume_occupied(obj)
            val = obj.get_total_fuel_volume_occupied(obj.fuel_weight_source.W_energy);
        end

    end

end
