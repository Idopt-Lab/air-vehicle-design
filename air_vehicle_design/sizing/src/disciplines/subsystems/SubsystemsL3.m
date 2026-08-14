classdef SubsystemsL3
%SUBSYSTEMSL3  Level-3 subsystems static toolbox.
%
%   Call as SubsystemsL3.method(...); never instantiated, not in the
%   inheritance chain. F16SubsystemsL3 inherits SubsystemsModelL3 and
%   delegates here.
%
%   L3 differs from L2 in exactly ONE respect: the fuselage raw-volume term
%   (Raymer Eq. 7.14) is fed A_top/A_side from GeomL3's frame-integrated
%   station table instead of GeomL2's envelope-ellipse approximation
%   (Fidelity split). Every other equation is level-agnostic and is REUSED
%   by direct cross-toolbox call to SubsystemsL2, not duplicated -- same
%   reuse pattern used elsewhere in this repo (e.g. TailL2 cross-calling
%   TailL1.compute_tail_arm).
%
%   Companion doc: src/disciplines/subsystems/SubsystemsL3.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function val = avionics_weight_fraction(obj)
        %AVIONICS_WEIGHT_FRACTION  Level-agnostic -- reused from SubsystemsL1.
            val = SubsystemsL1.lookup_avionics_weight_fraction(obj.avionics_table_row);
        end

        function val = avionics_density(obj)
        %AVIONICS_DENSITY  Level-agnostic (L2/L3 share the flat Nicolai 45
        %   figure) -- reused from SubsystemsL2.
            val = SubsystemsL2.avionics_density(obj);
        end

        function val = avionics_weight(obj)
        %AVIONICS_WEIGHT  Level-agnostic combination -- reused from
        %   SubsystemsL2 (fraction * W_empty, self-referencing
        %   fuel_weight_source).
            val = SubsystemsL2.avionics_weight(obj);
        end

        function val = avionics_volume(obj)
        %AVIONICS_VOLUME  Level-agnostic -- reused from SubsystemsL2.
            val = SubsystemsL2.avionics_volume(obj);
        end

        function val = fuel_density(obj)
        %FUEL_DENSITY  Level-agnostic Nicolai Table 8.6 lookup -- reused
        %   from SubsystemsL1.
            val = SubsystemsL1.lookup_fuel_density(obj.fuel_type);
        end

        function val = fuselage_raw_volume(obj)
        %FUSELAGE_RAW_VOLUME  [Raymer 6th ed. Eq. 7.14], A_top/A_side from
        %   obj.geom's FRAME-INTEGRATED station table -- refines L2's
        %   envelope-ellipse approximation. The 3.4/(4L) combination formula
        %   itself is reused from SubsystemsL2, not duplicated.
            g = obj.geom;
            [A_top, A_side] = SubsystemsL3.compute_frame_integrated_projected_areas( ...
                g.frames_normalized, g.L_fuselage, g.W_max_fuselage, g.H_max_fuselage);
            val = SubsystemsL2.compute_raymer_fuselage_volume(A_top, A_side, g.L_fuselage);
        end

        function val = fuselage_usable_fuel_volume(obj)
        %FUSELAGE_USABLE_FUEL_VOLUME  fuselage_raw_volume * packaging_factor
        %   [ft^3]. Packaging-factor lookup is level-agnostic -- reused from
        %   SubsystemsL2 -- but fuselage_raw_volume above is L3's own
        %   frame-integrated figure.
            pf = SubsystemsL2.lookup_packaging_factor(obj.packaging_factor_category);
            val = SubsystemsL3.fuselage_raw_volume(obj) * pf;
        end

        function val = wing_fuel_volume(obj)
        %WING_FUEL_VOLUME  Level-agnostic [Roskam Eq. 6.2/6.3] -- reused from
        %   SubsystemsL2 (GeometryModelL3 exposes the same S_ref/b_wing/
        %   tc_r_wing/tc_t_wing/lambda_wing member names as GeometryModelL2).
            val = SubsystemsL2.wing_fuel_volume(obj);
        end

        function val = fuel_volume_from_weight(obj, fuel_weight_lb)
        %FUEL_VOLUME_FROM_WEIGHT  Level-agnostic definitional conversion --
        %   reused from SubsystemsL2 (same fuel_density path).
            val = SubsystemsL2.fuel_volume_from_weight(obj, fuel_weight_lb);
        end

        function val = fuel_volume(obj)
        %FUEL_VOLUME  Total available fuel volume [ft^3] = L3's OWN
        %   fuselage usable fuel volume (frame-integrated) + wing fuel
        %   volume. Deliberately NOT delegated to SubsystemsL2.fuel_volume,
        %   which would silently substitute L2's envelope-ellipse fuselage
        %   term for L3's frame-integrated one.
            val = SubsystemsL3.fuselage_usable_fuel_volume(obj) + SubsystemsL3.wing_fuel_volume(obj);
        end

        function val = battery_volume(obj, E_required_kWh)
        %BATTERY_VOLUME  NOT IMPLEMENTED -- same documented citation GAP as
        %   L2; reused (errors identically) from SubsystemsL2, not
        %   duplicated.
            val = SubsystemsL2.battery_volume(obj, E_required_kWh);
        end

        function val = internal_volume(obj)
        %INTERNAL_VOLUME  Total usable internal volume [ft^3] = fuselage
        %   usable fuel volume + wing fuel volume + avionics volume.
        %   Landing-gear bay volume deliberately NOT summed -- see
        %   SubsystemsL2.internal_volume's identical note.
            val = SubsystemsL3.fuel_volume(obj) + SubsystemsL3.avionics_volume(obj);
        end

        function result = fuel_volume_check(obj)
        %FUEL_VOLUME_CHECK  Same sufficiency check as L2, fed L3's own
        %   frame-integrated fuel_volume(obj). NEVER checks only one of
        %   fuselage/wing.
            available = SubsystemsL3.fuel_volume(obj);
            W_energy = obj.fuel_weight_source.W_energy;
            if ~isfinite(W_energy)
                error('SubsystemsL3:fuelWeightNotSet', ...
                    ['fuel_weight_source.W_energy is NaN -- mission analysis ' ...
                     'has not set the required internal-fuel weight yet. Set ' ...
                     'it on the injected weights object before calling ' ...
                     'fuel_volume_check.']);
            end
            required_vol = SubsystemsL3.fuel_volume_from_weight(obj, W_energy);
            result = struct('available_vol_ft3', available, ...
                             'required_vol_ft3', required_vol, ...
                             'sufficient', available >= required_vol);
        end

        % ================================================================== %
        % LOW-LEVEL: originates here -- frame-table integration.
        % ================================================================== %

        function [A_top, A_side] = compute_frame_integrated_projected_areas(frames_normalized, L_fus, W_max, H_max)
        %COMPUTE_FRAME_INTEGRATED_PROJECTED_AREAS  Top-view and side-view
        %   projected areas [ft^2] of the fuselage, by trapezoidal
        %   integration of GeomL3's per-frame width/height profile -- refines
        %   L2's envelope-ellipse approximation with real station data,
        %   feeding Raymer Eq. 7.14's A_top/A_side inputs.
        %
        %   frames_normalized is the (N,3) table declared on
        %   GeometryModelL3 -- columns [x/L, w/W_max, h/H_max]. Denormalized
        %   via GeomL3.denormalize_frames (reused directly, NOT duplicated --
        %   GeomL3.get_Amax already denormalizes the same table the same
        %   way, so this is the single source of truth for that step). A
        %   (0,0,0) nose station is prepended before integrating, mirroring
        %   GeomL2.compute_s_wet_fus_brandt_highfi's own frame-integration
        %   convention (that method prepends x=0, P=0 the same way).
        %
        %   No separate textbook equation number -- this is a definitional
        %   trapezoidal integration of the geometry object's own frame data
        %   to obtain the A_top/A_side quantities Raymer Eq. 7.14 calls for;
        %   the 3.4/(4L) formula itself remains the cited Raymer equation
        %   (SubsystemsL2.compute_raymer_fuselage_volume).
            arguments
                frames_normalized (:,3) double
                L_fus (1,1) double {mustBePositive}
                W_max (1,1) double {mustBePositive}
                H_max (1,1) double {mustBePositive}
            end
            [x, w, h] = GeomL3.denormalize_frames(frames_normalized, L_fus, W_max, H_max);

            x_all = [0; x(:)];
            w_all = [0; w(:)];
            h_all = [0; h(:)];

            A_top  = trapz(x_all, w_all);
            A_side = trapz(x_all, h_all);
        end

    end
end
