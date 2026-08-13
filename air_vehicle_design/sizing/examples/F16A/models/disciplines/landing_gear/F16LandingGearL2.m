classdef F16LandingGearL2 < handle
%F16LANDINGGEARL2  F-16A Block 10/15 Level-2 landing-gear student class.
%
%   F-16-ONLY, NO ABSTRACT BASE TIER (docs/subplans/09_subsystems.md Files to
%   Create): not every airframe has conventional landing gear (e.g.
%   seaplanes), so this class does not get a generic src/disciplines/ home
%   the way Geometry/Aerodynamics/Propulsion/Weights/Subsystems do. It still
%   follows the toolbox-static-equations pattern where that makes sense --
%   the high-level instance methods below read obj's own inputs and the
%   injected weights object, then delegate to Static low-level methods that
%   take only scalars, mirroring e.g. GeomL2's high-level/low-level split.
%
%   < handle IS REQUIRED (matlab-oop-expert review, 2026-08-03): this class
%   has genuine mutable design-variable state (main_pct, nose_pct,
%   nose_tire_fraction_of_main, aircraft_category_table_row) that an
%   optimizer/sizing loop mutates in place, exactly like every other
%   discipline object in this framework -- but unlike those, this class has
%   no abstract Base tier to inherit `< handle` from transitively. Without
%   it, this would silently be a MATLAB VALUE class: passing an instance into
%   a function and mutating a property there would not propagate back to the
%   caller, breaking the "optimizer mutates the object in place" doctrine
%   CLAUDE.md's "Optimization-ready property design" section assumes
%   throughout. Every OTHER stateful discipline class in examples/F16A/
%   inherits `< handle` transitively via its Base/Model tier; this class and
%   F16LandingGearL3 are the only two with no such tier, so they must state
%   it directly.
%
%   METHOD: Raymer 6th ed. Ch.11 statistical tire sizing (Table 11.1, p.344)
%   off the per-wheel static load, itself derived from the gear load split
%   (90% main / 10% nose, Raymer p.344 prose) applied to W_TO -- already a
%   plain STATE property on the injected weights object
%   (F16WeightsL1.m:74-ish "candidate gross takeoff weight... mutated in
%   place by the sizing loop").
%
%   TWO-WHEEL MAIN GEAR ASSUMPTION: the F-16 uses a standard tricycle
%   arrangement -- one nose wheel, two main wheels -- so the per-wheel main
%   load W_w that Table 11.1 wants is HALF the total main-gear load. This is
%   ordinary tricycle-gear configuration knowledge (not a subplan-pinned
%   citation), documented here as a judgment call rather than left silent.
%
%   GEAR BAY VOLUME -- NOT IMPLEMENTED. See bay_volume: documented citation
%   GAP (subplan item 11). Tire/strut SIZE (diameter/width) is fully
%   implemented and unaffected.
%
%   DEPENDENCY INJECTION: weights -- (1,1) WeightsBase. Only W_TO is read.
%   Geometry is deliberately NOT injected: no equation implemented here
%   reads it (bay_volume errors regardless of any fuselage envelope), and
%   CLAUDE.md's "no feature beyond what the current step requires" rule
%   argues against wiring an unused collaborator in anticipation of a future
%   citation. Add it when item 11 is resolved, not before.
%
%   CONSTRUCTOR: F16LandingGearL2(json_path, weights). Both REQUIRED.
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

    % ======================================================================= %
    % INPUTS (5) + 1 injected object -- plain mutable properties, set once by
    % the constructor. Authoritative table: F16LandingGearL2.md §2.
    % ======================================================================= %
    properties
        aircraft_category_table_row = 'Jet fighter/trainer'  % selects lookup_tire_sizing_coeffs [Raymer 6th ed. Table 11.1, p.344; f16a_L2.json .subsystems.landing_gear.tire_sizing.aircraft_category_table_row]
        main_pct = 90   % % of W_TO carried by the main gear [Raymer 6th ed. Ch.11 p.344 prose; f16a_L2.json .subsystems.landing_gear.gear_load_split.main_pct]
        nose_pct = 10   % % of W_TO carried by the nose gear [same source; .gear_load_split.nose_pct]
        nose_tire_fraction_of_main = 0.80   % decided point value within Raymer's stated 60-100% range [f16a_L2.json .subsystems.landing_gear.nose_tire_fraction_of_main]

        % ----- Injected collaborator (NOT numeric spec data) --------------- %
        weights   % (1,1) WeightsBase -- supplies W_TO
    end

    % ======================================================================= %
    % DERIVED (8) -- zero-extra-arg quantities that read ONLY the inputs/
    % injected weights collaborator above. Dependent getters, recomputed live
    % on every read -- never a cached/frozen value (CLAUDE.md "Optimization-
    % ready property design"; mirrors F16GeomL2/F16WeightsL2). bay_volume
    % stays a plain METHOD, not Dependent: it deliberately errors (item 11's
    % citation gap), and a Dependent getter must never be allowed to throw --
    % MATLAB's own object display/introspection machinery evaluates every
    % Dependent property's getter eagerly (e.g. `disp(obj)`), so an always-
    % erroring member would break ordinary object display if it were
    % Dependent.
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
            c = F16LandingGearL2.lookup_tire_sizing_coeffs(obj.aircraft_category_table_row);
            val = F16LandingGearL2.tire_diameter(c.A_d, c.B_d, obj.W_w_main);
        end

        function val = get.tire_width_main(obj)
        %TIRE_WIDTH_MAIN  Main-tire width [in].
        %   [Raymer 6th ed. Table 11.1, p.344, Jet fighter/trainer row]
            c = F16LandingGearL2.lookup_tire_sizing_coeffs(obj.aircraft_category_table_row);
            val = F16LandingGearL2.tire_width(c.A_w, c.B_w, obj.W_w_main);
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
        %BAY_VOLUME  NOT IMPLEMENTED -- documented citation GAP (subplan
        %   item 11). No textbook formula for tire+strut bay-volume
        %   packaging was found anywhere in this repo: Raymer's Ch.11 covers
        %   tire/strut/shock-absorber SIZE, not a bay-VOLUME packaging
        %   estimate the way Nicolai's Ch.8 fuel/avionics sections give one.
        %   Errors rather than fabricating a geometric-envelope assumption.
            error('F16LandingGearL2:bayVolumeNotAvailable', ...
                ['No textbook bay-volume (tire+strut stowage) packaging ' ...
                 'formula was found anywhere in this repository -- Raymer ' ...
                 'Ch.11 covers tire/strut/shock-absorber SIZE only. Not ' ...
                 'implemented, not guessed. Tire/strut SIZE ' ...
                 '(tire_diameter_main/tire_width_main/etc.) is unaffected. ' ...
                 'See docs/subplans/09_subsystems.md Equations & Citations ' ...
                 'Sec.11 and examples/F16A/inputs/f16a_L2.json ' ...
                 '.subsystems._TODO_gear_bay_volume_packaging for the full ' ...
                 'gap record.']);
        end

        % ================================================================== %
        % LOW-LEVEL: pure math/lookups -- scalars/strings only.
        % ================================================================== %

    end

    methods (Static)

        function d = tire_diameter(A, B, W_w)
        %TIRE_DIAMETER  Static tire diameter [in].
        %   [Raymer 6th ed. Table 11.1, p.344]  D = A * W_w^B.
            arguments
                A   (1,1) double {mustBePositive}
                B   (1,1) double {mustBePositive}
                W_w (1,1) double {mustBePositive}
            end
            d = A * W_w^B;
        end

        function w = tire_width(A, B, W_w)
        %TIRE_WIDTH  Static tire width [in].
        %   [Raymer 6th ed. Table 11.1, p.344]  Width = A * W_w^B.
            arguments
                A   (1,1) double {mustBePositive}
                B   (1,1) double {mustBePositive}
                W_w (1,1) double {mustBePositive}
            end
            w = A * W_w^B;
        end

        function c = lookup_tire_sizing_coeffs(table_row)
        %LOOKUP_TIRE_SIZING_COEFFS  Diameter/width coefficient pairs by
        %   aircraft category. [Raymer 6th ed. Table 11.1 "Statistical Tire
        %   Sizing," p.344]. Full 4-row table, reproduced verbatim -- do not
        %   read A_d/A_w from a mismatched row (each row's diameter and
        %   width coefficients must travel together).
            switch table_row
                case 'General aviation'
                    c = struct('A_d', 1.51, 'B_d', 0.349, 'A_w', 0.7150, 'B_w', 0.312);
                case 'Business twin'
                    c = struct('A_d', 2.69, 'B_d', 0.251, 'A_w', 1.170,  'B_w', 0.216);
                case 'Transport/bomber'
                    c = struct('A_d', 1.63, 'B_d', 0.315, 'A_w', 0.1043, 'B_w', 0.480);
                case 'Jet fighter/trainer'
                    c = struct('A_d', 1.59, 'B_d', 0.302, 'A_w', 0.0980, 'B_w', 0.467);
                otherwise
                    error('F16LandingGearL2:unknownTireCategory', ...
                        ['Unknown tire-sizing table row "%s". Known rows ' ...
                         '(Raymer 6th ed. Table 11.1): General aviation, ' ...
                         'Business twin, Transport/bomber, Jet fighter/trainer.'], ...
                        table_row);
            end
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
