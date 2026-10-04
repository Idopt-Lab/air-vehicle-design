classdef F16LandingGearL2 < handle
%F16LANDINGGEARL2  F-16A Block 10/15 Level-2 landing-gear student class.
%
%   F-16-only, no abstract Base tier: not every airframe has conventional
%   landing gear, so this class does not get a generic src/disciplines/ home.
%   It still follows the toolbox-static-equations pattern -- high-level
%   instance methods read obj's inputs and the injected weights object, then
%   delegate to Static low-level methods that take only scalars.
%
%   < handle IS REQUIRED: this class has genuine mutable design-variable state
%   an optimizer/sizing loop mutates in place, but has no abstract Base tier to
%   inherit `< handle` from transitively. Without it, it would silently be a
%   value class and property mutations would not propagate back to the caller.
%
%   METHOD: Raymer 6th ed. Ch.11 statistical tire sizing (Table 11.1, p.344)
%   off the per-wheel static load, from the gear load split (90% main / 10%
%   nose, Raymer p.344 prose) applied to W_TO.
%
%   TWO-WHEEL MAIN GEAR ASSUMPTION: the F-16 uses a standard tricycle
%   arrangement (one nose wheel, two main wheels), so the per-wheel main load
%   W_w that Table 11.1 wants is half the total main-gear load. Ordinary
%   tricycle-gear configuration knowledge (a judgment call, not a citation).
%
%   GEAR BAY VOLUME -- not implemented. See bay_volume: documented citation
%   GAP (item 11). Tire/strut SIZE (diameter/width) is unaffected.
%
%   DEPENDENCY INJECTION: weights -- (1,1) WeightsBase. Only W_TO is read.
%   Geometry is not injected: no equation here reads it. Add it when item 11
%   is resolved, not before.
%
%   CONSTRUCTOR: F16LandingGearL2(json_path, weights). Both required.
%
%   History and rationale: docs/decision_log.md
%
%   SOURCES:
%     [Raymer] D.P. Raymer, Aircraft Design 6th ed., Ch.11, p.344 (gear load
%              split prose; Table 11.1 "Statistical Tire Sizing").
%
%   Companion doc: examples/F16A/models/disciplines/landing_gear/F16LandingGearL2.md

    properties (Constant)
        N_MAIN_WHEELS = 2   % F-16 standard tricycle gear: two main wheels [judgment call, ordinary tricycle-gear configuration knowledge -- see class header]
        N_NOSE_WHEELS = 1   % F-16 standard tricycle gear: one nose wheel
    end

    % INPUTS (5) + 1 injected object -- plain mutable properties, set once by
    % the constructor. Authoritative table: F16LandingGearL2.md §2.
    properties
        aircraft_category_table_row = 'Jet fighter/trainer'  % selects lookup_tire_sizing_coeffs [Raymer 6th ed. Table 11.1, p.344; f16a_L2.json .subsystems.landing_gear.tire_sizing.aircraft_category_table_row]
        main_pct = 90   % % of W_TO carried by the main gear [Raymer 6th ed. Ch.11 p.344 prose; f16a_L2.json .subsystems.landing_gear.gear_load_split.main_pct]
        nose_pct = 10   % % of W_TO carried by the nose gear [same source; .gear_load_split.nose_pct]
        nose_tire_fraction_of_main = 0.80   % decided point value within Raymer's stated 60-100% range [f16a_L2.json .subsystems.landing_gear.nose_tire_fraction_of_main]

        % ----- Injected collaborator (NOT numeric spec data) --------------- %
        weights   % (1,1) WeightsBase -- supplies W_TO
    end

    % DERIVED (8) -- zero-extra-arg quantities that read only the inputs/
    % injected weights collaborator above. Dependent getters, recomputed live
    % on every read. bay_volume stays a plain METHOD, not Dependent: it
    % deliberately errors (item 11's citation gap), and a Dependent getter's
    % eager evaluation (e.g. `disp(obj)`) would break object display.
    properties (Dependent)
        W_main_total
        W_nose_total
        W_w_main
        W_w_nose
        tire_diameter_main
        tire_width_main
        tire_diameter_nose
        tire_width_nose
    end

    methods

        function obj = F16LandingGearL2(json_path, weights)
        %F16LANDINGGEARL2  Construct from a required unified L2 input JSON
        %   path (f16a_spec_path(2)), reading its .subsystems.landing_gear
        %   block, and a required injected weights object. NO silent default
        %   on either argument.
            arguments
                json_path      {mustBeTextScalar, mustBeNonzeroLengthText}
                weights  (1,1) WeightsBase
            end
            J = jsondecode(fileread(json_path));
            LG = J.subsystems.landing_gear;

            obj.weights = weights;

            obj.aircraft_category_table_row = char(LG.tire_sizing.aircraft_category_table_row);
            obj.main_pct                    = LG.gear_load_split.main_pct;
            obj.nose_pct                    = LG.gear_load_split.nose_pct;
            obj.nose_tire_fraction_of_main  = LG.nose_tire_fraction_of_main;
        end

        function tipback_angle = get_tipback_angle(obj)
            x_le_mac_wing = 23.3;   % ft
            x_le_mac_ht   = 39.8;   % ft
            x_le_mac_vt   = 38.8; % ft
            x_le_mac_strake = 12; % ft
            L_eng = PropL2.engine_length_AB(obj.weights.prop.T_SL, obj.weights.design_mach);

            x_cg_wing = WeightsL2.compute_cg_x_loc_wing(x_le_mac_wing, obj.weights.geom.cbar_wing);
            x_cg_HT   = WeightsL2.compute_cg_x_loc_wing(x_le_mac_ht, GeometryBase.compute_mac(obj.weights.geom.c_root_ht, obj.weights.geom.lambda_ht));
            x_cg_VT   = WeightsL2.compute_cg_x_loc_wing(x_le_mac_vt, GeometryBase.compute_mac(obj.weights.geom.c_root_vt, obj.weights.geom.lambda_vt));
            x_cg_fus  = WeightsL2.compute_cg_x_loc_fuselage(obj.weights.geom.L_fus);
            x_cg_eng  = WeightsL2.compute_cg_x_loc_engine(obj.weights.geom.L_fus - L_eng, L_eng);
            x_cg_strake = WeightsL2.compute_cg_x_loc_wing(x_le_mac_strake, obj.weights.geom.cbar_strake);
            x_cg_lg_nose = 15.5264; % ft
            x_cg_lg_main = 30.5677; % ft
            x_cg_lg = (x_cg_lg_nose + x_cg_lg_main*2)/3;

            component_weight_vector = [obj.weights.W_wings, obj.weights.W_tail.HT, obj.weights.W_tail.VT, obj.weights.W_fuselage, obj.weights.W_landing_gear, obj.weights.W_installed_engine, obj.weights.W_strake]; % Assume these all sit on the longitudinal axis.
            component_weight_x_locs = [x_cg_wing, x_cg_HT, x_cg_VT, x_cg_fus, x_cg_lg, x_cg_eng, x_cg_strake];
            cg_x = StabControlBase.compute_weighted_cg(component_weight_vector, component_weight_x_locs);
            cg_y = 0; % Assumed zero due to focus on longitidunal static stability (for now, 9/28/2026)
            cg_loc = [cg_x, cg_y];

            % construct main gear location as vector from origin (nose)
            maingear_loc = [x_cg_lg_main, -4.3668]; % ft (measured from longitudinal)

            % Compute the tipback angle
            tipback_angle = landinggearL2.compute_tipback_angle(cg_loc, maingear_loc);
        end

        function isTipBackAngleSatisfied = check_tipback_angle(obj, tipback_angle)
            isTipBackAngleSatisfied = landinggearL2.check_tipback_angle(tipback_angle);
            fprintf('\nTipback angle: %.1f deg', tipback_angle);
            if (isTipBackAngleSatisfied == true)
                fprintf('\nTipback angle satisfied\n')
            else
                warning('Tipback angle is outside 15<x<25 deg')
            end
        end

        % ================================================================== %
        % DERIVED-property getters: read obj's own inputs + the injected
        % weights object, recomputed live on every read.
        % ================================================================== %

        function val = get.W_main_total(obj)
        %W_MAIN_TOTAL  Total static load on the main gear [lbf].
        %   [Raymer 6th ed. Ch.11 p.344 prose]
            val = (obj.main_pct / 100) * obj.requireWTO();
        end

        function val = get.W_nose_total(obj)
        %W_NOSE_TOTAL  Total static load on the nose gear [lbf].
            val = (obj.nose_pct / 100) * obj.requireWTO();
        end

        function val = get.W_w_main(obj)
        %W_W_MAIN  Static load on ONE main wheel [lbf] -- Table 11.1's W_w.
            val = obj.W_main_total / obj.N_MAIN_WHEELS;
        end

        function val = get.W_w_nose(obj)
        %W_W_NOSE  Static load on the nose wheel [lbf].
            val = obj.W_nose_total / obj.N_NOSE_WHEELS;
        end

        function val = get.tire_diameter_main(obj)
        %TIRE_DIAMETER_MAIN  Main-tire diameter [in].
        %   [Raymer 6th ed. Table 11.1, p.344, Jet fighter/trainer row]
            c = landinggearL2.lookup_tire_sizing_coeffs(obj.aircraft_category_table_row);
            val = landinggearL2.tire_diameter(c.A_d, c.B_d, obj.W_w_main);
        end

        function val = get.tire_width_main(obj)
        %TIRE_WIDTH_MAIN  Main-tire width [in].
        %   [Raymer 6th ed. Table 11.1, p.344, Jet fighter/trainer row]
            c = landinggearL2.lookup_tire_sizing_coeffs(obj.aircraft_category_table_row);
            val = landinggearL2.tire_width(c.A_w, c.B_w, obj.W_w_main);
        end

        function val = get.tire_diameter_nose(obj)
        %TIRE_DIAMETER_NOSE  Nose-tire diameter [in] = decided fraction of
        %   the main-tire diameter [Raymer 6th ed. Table 11.1 page prose].
            val = obj.nose_tire_fraction_of_main * obj.tire_diameter_main;
        end

        function val = get.tire_width_nose(obj)
        %TIRE_WIDTH_NOSE  Nose-tire width [in] = decided fraction of the
        %   main-tire width.
            val = obj.nose_tire_fraction_of_main * obj.tire_width_main;
        end

        function val = bay_volume(obj) %#ok<MANU,STOUT>
        %BAY_VOLUME  NOT IMPLEMENTED -- documented citation GAP (original
        %   step-9 subsystems design, item 11). No textbook formula for
        %   tire+strut bay-volume packaging was found anywhere in this repo:
        %   Raymer's Ch.11 covers tire/strut/shock-absorber SIZE, not a
        %   bay-VOLUME packaging estimate the way Nicolai's Ch.8 fuel/avionics
        %   sections give one. Errors rather than fabricating a
        %   geometric-envelope assumption.
            error('F16LandingGearL2:bayVolumeNotAvailable', ...
                ['No textbook bay-volume (tire+strut stowage) packaging ' ...
                 'formula was found anywhere in this repository -- Raymer ' ...
                 'Ch.11 covers tire/strut/shock-absorber SIZE only. Not ' ...
                 'implemented, not guessed. Tire/strut SIZE ' ...
                 '(tire_diameter_main/tire_width_main/etc.) is unaffected. ' ...
                 'See examples/F16A/inputs/f16a_L2.json ' ...
                 '.subsystems._TODO_gear_bay_volume_packaging for the full ' ...
                 'gap record.']);
        end

    end

    methods (Access = private)

        function W_TO = requireWTO(obj)
        %REQUIREWTO  Return obj.weights.W_TO, erroring if not yet set.
        %   Mirrors F16WeightsL2.requireWTO / F16GeomL1.requireWTO's
        %   established convention for a sizing-loop STATE quantity that
        %   must not silently resolve to NaN.
            W_TO = obj.weights.W_TO;
            if ~isfinite(W_TO) || W_TO <= 0
                error('F16LandingGearL2:WTONotSet', ...
                    ['Tire sizing needs the injected weights object''s W_TO, ' ...
                     'which is not yet set (currently %g). Assign it from ' ...
                     'the sizing loop''s current TOGW iterate first.'], W_TO);
            end
        end

    end

end
