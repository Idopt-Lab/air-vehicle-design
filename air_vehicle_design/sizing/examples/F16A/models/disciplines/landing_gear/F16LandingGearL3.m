classdef F16LandingGearL3 < handle
%F16LANDINGGEARL3  F-16A Block 10/15 Level-3 landing-gear student class.
%
%   F-16-ONLY, NO ABSTRACT BASE TIER -- same rationale as F16LandingGearL2
%   (see that class's header). Identical equations to F16LandingGearL2
%   (Raymer 6th ed. Ch.11 Table 11.1 statistical tire sizing + the 90/10
%   gear load split): tire sizing depends only on W_TO and the gear-load
%   split, neither of which changes with geometry fidelity, so this class
%   REUSES F16LandingGearL2's Static low-level methods (tire_diameter,
%   tire_width, lookup_tire_sizing_coeffs) directly rather than duplicating
%   the Table 11.1 switch-case.
%
%   < handle IS REQUIRED -- same rationale as F16LandingGearL2 (see that
%   class's header): genuine mutable design-variable state, no Base tier to
%   inherit handle semantics from transitively.
%
%   Kept as a separate class from F16LandingGearL2 (rather than reusing it
%   outright) only to match the subplan's Files-to-Create table, which lists
%   both, and the JSON's parallel f16a_L3.json .subsystems.landing_gear
%   block / companion doc -- JUDGMENT CALL, flagged: today the two classes'
%   equations are IDENTICAL, and L3 carries no geometry injection either
%   (see F16LandingGearL2.md "no geometry input" note), because bay_volume
%   (item 11) errors regardless of which geometry tier might eventually
%   supply a fuselage envelope for it.
%
%   CONSTRUCTOR: F16LandingGearL3(json_path, weights). Both REQUIRED.
%
%   SOURCES: same as F16LandingGearL2 -- see that class's header.
%
%   Companion doc: examples/F16A/models/disciplines/landing_gear/F16LandingGearL3.md

    properties (Constant)
        N_MAIN_WHEELS = 2   % F-16 standard tricycle gear: two main wheels [judgment call -- see F16LandingGearL2's class header]
        N_NOSE_WHEELS = 1   % F-16 standard tricycle gear: one nose wheel
    end

    % ======================================================================= %
    % INPUTS (4) + 1 injected object -- plain mutable properties, set once by
    % the constructor. Authoritative table: F16LandingGearL3.md §2.
    % ======================================================================= %
    properties
        aircraft_category_table_row = 'Jet fighter/trainer'  % [Raymer 6th ed. Table 11.1, p.344; f16a_L3.json .subsystems.landing_gear.tire_sizing.aircraft_category_table_row]
        main_pct = 90   % [Raymer 6th ed. Ch.11 p.344 prose; f16a_L3.json .subsystems.landing_gear.gear_load_split.main_pct]
        nose_pct = 10   % [same source; .gear_load_split.nose_pct]
        nose_tire_fraction_of_main = 0.80   % [f16a_L3.json .subsystems.landing_gear.nose_tire_fraction_of_main]

        % ----- Injected collaborator (NOT numeric spec data) --------------- %
        weights   % (1,1) WeightsBase -- supplies W_TO
    end

    % ======================================================================= %
    % DERIVED (8) -- same rationale as F16LandingGearL2 (see that class's
    % header note on Dependent vs. plain-method): zero-extra-arg quantities
    % that read only the inputs/injected weights collaborator above.
    % bay_volume stays a plain METHOD, not Dependent (deliberately errors).
    % ======================================================================= %
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

        function obj = F16LandingGearL3(json_path, weights)
        %F16LANDINGGEARL3  Construct from a required unified L3 input JSON
        %   path (f16a_spec_path(3)), reading its .subsystems.landing_gear
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

        % ================================================================== %
        % DERIVED-property getters: read obj's own inputs + the injected
        % weights object, recomputed live on every read. Equations reused
        % directly from F16LandingGearL2's Static methods.
        % ================================================================== %

        function val = get.W_main_total(obj)
            val = (obj.main_pct / 100) * obj.requireWTO();
        end

        function val = get.W_nose_total(obj)
            val = (obj.nose_pct / 100) * obj.requireWTO();
        end

        function val = get.W_w_main(obj)
            val = obj.W_main_total / obj.N_MAIN_WHEELS;
        end

        function val = get.W_w_nose(obj)
            val = obj.W_nose_total / obj.N_NOSE_WHEELS;
        end

        function val = get.tire_diameter_main(obj)
            c = F16LandingGearL2.lookup_tire_sizing_coeffs(obj.aircraft_category_table_row);
            val = F16LandingGearL2.tire_diameter(c.A_d, c.B_d, obj.W_w_main);
        end

        function val = get.tire_width_main(obj)
            c = F16LandingGearL2.lookup_tire_sizing_coeffs(obj.aircraft_category_table_row);
            val = F16LandingGearL2.tire_width(c.A_w, c.B_w, obj.W_w_main);
        end

        function val = get.tire_diameter_nose(obj)
            val = obj.nose_tire_fraction_of_main * obj.tire_diameter_main;
        end

        function val = get.tire_width_nose(obj)
            val = obj.nose_tire_fraction_of_main * obj.tire_width_main;
        end

        function val = bay_volume(obj) %#ok<MANU,STOUT>
        %BAY_VOLUME  NOT IMPLEMENTED -- same documented citation GAP as
        %   F16LandingGearL2 (subplan item 11). Errors with its OWN error
        %   identifier (not a reused F16LandingGearL2 id) so a test/caller
        %   can distinguish which class's gap fired.
            error('F16LandingGearL3:bayVolumeNotAvailable', ...
                ['No textbook bay-volume (tire+strut stowage) packaging ' ...
                 'formula was found anywhere in this repository -- Raymer ' ...
                 'Ch.11 covers tire/strut/shock-absorber SIZE only. Not ' ...
                 'implemented, not guessed. Tire/strut SIZE ' ...
                 '(tire_diameter_main/tire_width_main/etc.) is unaffected. ' ...
                 'See docs/subplans/09_subsystems.md Equations & Citations ' ...
                 'Sec.11 and examples/F16A/inputs/f16a_L3.json ' ...
                 '.subsystems._TODO_gear_bay_volume_packaging for the full ' ...
                 'gap record.']);
        end

    end

    methods (Access = private)

        function W_TO = requireWTO(obj)
        %REQUIREWTO  Return obj.weights.W_TO, erroring if not yet set.
            W_TO = obj.weights.W_TO;
            if ~isfinite(W_TO) || W_TO <= 0
                error('F16LandingGearL3:WTONotSet', ...
                    ['Tire sizing needs the injected weights object''s W_TO, ' ...
                     'which is not yet set (currently %g). Assign it from ' ...
                     'the sizing loop''s current TOGW iterate first.'], W_TO);
            end
        end

    end

end
