classdef TtpaWeights < WeightsBase
%TTPAWEIGHTS  Test Twin Propeller Aircraft Level-2 weight model.
%
%   IHW3a
%   In IHW1 and IHW2 the whole empty weight was one line, OEW =
%   0.911*W_TO^0.947, a statistical regression on light propeller airplanes.
%   It is a good first estimate, but it knows ONLY the takeoff weight: double
%   the wing area, fit a bigger engine, stretch the tails, and it returns the
%   same number. Inside a sizing loop that is fatal, because the loop exists
%   to work out what the airplane weighs after it has been laid out.
%
%   ------------------------------------------------------------------
%   TWO BUILD-UPS, the lecture's "Empty weight II" and "Empty weight III",
%   selected by J.weights.method.
%
%   "table_15_2"  -- EMPTY WEIGHT II.  [Raymer Table 15.2, General Aviation]
%       W_wing      = 2.5   * S_exposed_wing        lb/ft^2 x EXPOSED area
%       W_ht        = 2.0   * S_ht                  lb/ft^2 x area
%       W_vt        = 2.0   * S_vt                  lb/ft^2 x area
%       W_fuselage  = 1.4   * S_wet_fuselage        lb/ft^2 x WETTED area
%       W_gear      = 0.057 * W_TO                  fraction of TOGW
%       W_engines   = 1.4   * W_bare_all_engines    x bare engine weight
%       W_all_else  = 0.10  * W_TO                  fraction of TOGW
%
%   "raymer_ga_III"  -- EMPTY WEIGHT III.  The same build-up with TWO rows
%   replaced by the Raymer Sec. 15.3.3 general-aviation statistical
%   equations:
%
%       W_wing      = 0.036 S_w^0.758 W_fw^0.0035 (A/cos^2 L)^0.6 q^0.006
%                     lambda^0.04 (100 t/c)^-0.3 (N_z W_dg)^0.49   [Eq. 15.46]
%       W_engines   = 2.575 W_en^0.922 N_en                         [Eq. 15.52]
%
%   WHY EMPTY WEIGHT III EXISTS. Table 15.2's wing row is an areal density
%   times an area, so it contains NO ASPECT RATIO. The sizing-refinement
%   lecture shows the consequence directly: run an aspect-ratio trade study
%   on that model and it concludes that more aspect ratio is always better,
%   which is not what real airplanes do. Only a wing weight that carries AR
%   produces the genuine structures-against-aerodynamics minimum. Equation
%   15.46 carries (A/cos^2 Lambda)^0.6. Use "raymer_ga_III" for any AR trade
%   study; "table_15_2" is fine at fixed AR.
%
%   Equation 15.52 is a second, free improvement: it INCLUDES THE PROPELLER
%   AND THE ENGINE MOUNTS, which the Table 15.2 factor of 1.4 does not model
%   at all. Under "table_15_2" this airplane carries no propeller weight.
%
%   The other five rows stay at Table 15.2 under both methods. Swapping them
%   would need a dozen new inputs - strut lengths, tank counts, uninstalled
%   avionics weight - for a few percent, and the lecture's point is
%   specifically about the wing.
%
%   ------------------------------------------------------------------
%   THE OLD REGRESSION IS STILL HERE, as OEW_statistical. It is a
%   CROSS-CHECK, not the model. Two independent methods that agree within a
%   few percent are evidence the geometry is right.
%
%   OEW(W_TO) TAKES THE WEIGHT AS AN ARGUMENT and evaluates every
%   W_TO-dependent term at the PASSED value, never at obj.W_TO. The sizing
%   loop calls it at a trial weight that is not yet the object's weight, so
%   reading obj.W_TO inside would silently return the previous iterate.
%
%   INJECTED GEOMETRY AND PROPULSION
%   TtpaWeights(json_path, geom, prop). Build prop, then geom, then aero,
%   then weights - see ttpa_disciplines.

    properties
        W_TO                 = NaN   % lbf, candidate gross takeoff weight
        W_energy             = NaN   % lbf, total internal fuel weight
        W_payload_expendable = 0     % lbf, expendable payload (stores)
        W_payload_fixed      = 1200  % lbf, fixed payload, including crew
    end

    properties (SetAccess = immutable)
        geom                         % injected TtpaGeom
        prop                         % injected TtpaProp

        method                       % <- J.weights.method

        % --- Raymer Table 15.2, General Aviation column ---
        rho_wing
        rho_ht
        rho_vt
        rho_fuselage
        f_landing_gear
        f_installed_engine
        f_all_else_empty

        % --- Raymer Sec. 15.3.3 inputs (method "raymer_ga_III") ---
        N_z                          % <- J.weights.ultimate_load_factor
        q_cruise                     % lbf/ft^2, derived from the cruise segment

        % --- IHW1 regression, kept as a cross-check ---
        k_OEW_statistical
        n_OEW_statistical

        % --- post-sizing fuel-volume check ---
        rho_fuel
    end

    methods

        %% Constructor
        function obj = TtpaWeights(json_path, geom, prop)
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
                geom (1,1) GeometryBase
                prop (1,1) PropulsionBase2
            end

            obj.geom = geom;
            obj.prop = prop;

            J = jsondecode(fileread(json_path));
            W = J.weights;

            obj.W_payload_fixed      = W.W_payload_fixed;
            obj.W_payload_expendable = W.W_payload_expendable;

            obj.rho_wing           = W.unit_weight_wing_psf;
            obj.rho_ht             = W.unit_weight_horizontal_tail_psf;
            obj.rho_vt             = W.unit_weight_vertical_tail_psf;
            obj.rho_fuselage       = W.unit_weight_fuselage_psf;
            obj.f_landing_gear     = W.landing_gear_fraction;
            obj.f_installed_engine = W.installed_engine_factor;
            obj.f_all_else_empty   = W.all_else_empty_fraction;

            obj.k_OEW_statistical = W.statistical_OEW_coefficient;
            obj.n_OEW_statistical = W.statistical_OEW_exponent;

            obj.rho_fuel = W.fuel_density_lb_per_ft3;

            if isfield(W, 'method') && ~isempty(W.method)
                obj.method = string(W.method);
            else
                obj.method = "table_15_2";
            end
            if isfield(W, 'ultimate_load_factor') && ~isempty(W.ultimate_load_factor)
                obj.N_z = W.ultimate_load_factor;
            else
                obj.N_z = NaN;
            end

            % Cruise dynamic pressure, for the Raymer Sec. 15.3.3 equations.
            % DERIVED from the cruise segment rather than repeated as its own
            % input, so there is only one place the cruise condition lives.
            obj.q_cruise = TtpaWeights.cruise_q_(J);
        end


        %% Operating Empty Weight - the model
        function oew = OEW(obj, W_TO)
        %OEW  Operating empty weight [lbf] at a candidate takeoff weight.
        %   Use OEW_breakdown for the individual rows; this returns only the
        %   total, which is all the WeightsBase contract promises and all the
        %   sizing loop needs. Every W_TO-dependent term is evaluated at the
        %   PASSED W_TO, not at obj.W_TO.
            arguments
                obj
                W_TO (1,1) double {mustBePositive}
            end

            bd = obj.OEW_breakdown(W_TO);
            oew = bd.total;
        end


        %% Operating Empty Weight - itemised
        function bd = OEW_breakdown(obj, W_TO)
        %OEW_BREAKDOWN  The seven rows of the component build-up [lbf].
        %
        %   bd = OEW_breakdown(obj, W_TO) returns a struct with
        %       .wing .horizontal_tail .vertical_tail .fuselage
        %       .landing_gear .installed_engine .all_else_empty .total
        %   plus .method and, for reporting, .engine_bare_each /
        %   .engine_bare_total.
            arguments
                obj
                W_TO (1,1) double {mustBePositive}
            end

            [W_bare_total, W_bare_each] = obj.prop.engine_weight();
            bd.method            = obj.method;
            bd.engine_bare_each  = W_bare_each;
            bd.engine_bare_total = W_bare_total;

            % ---- rows that are the same under both methods ----------------
            % Raymer Table 15.2 asks for EXPOSED PLANFORM area on the tail
            % rows and WETTED area on the fuselage row.
            %
            % KNOWN APPROXIMATION ON THE TWO TAIL ROWS. The wing row uses the
            % true exposed area. The tail rows use the THEORETICAL area,
            % because that is what the volume-coefficient method produces -
            % Raymer defines horizontal-tail area to the aircraft centreline -
            % and an exposed tail area would need a fuselage width at the tail
            % station, which the cabin-driven fuselage model does not carry.
            % The tails are therefore slightly overweight: about 9 lbf on the
            % horizontal tail at the converged design, under 0.4 percent of
            % OEW. Documented rather than silently assumed.
            bd.horizontal_tail = obj.rho_ht       * obj.geom.S_ht;
            bd.vertical_tail   = obj.rho_vt       * obj.geom.S_vt;
            bd.fuselage        = obj.rho_fuselage * obj.geom.S_wet_fuselage;
            bd.landing_gear    = obj.f_landing_gear   * W_TO;
            bd.all_else_empty  = obj.f_all_else_empty * W_TO;

            % ---- the two rows the method selects --------------------------
            switch obj.method

                case "table_15_2"
                    % [Raymer Table 15.2, General Aviation]
                    bd.wing             = obj.rho_wing * obj.geom.S_exposed_wing;
                    bd.installed_engine = obj.f_installed_engine * W_bare_total;

                case "raymer_ga_III"
                    bd.wing             = obj.wing_weight_raymer_ga_(W_TO);
                    % [Raymer Eq. 15.52] includes the propeller and the mounts
                    bd.installed_engine = 2.575 * W_bare_each^0.922 * obj.prop.n_engines;

                otherwise
                    error('TtpaWeights:UndefinedMethod', ...
                        ['Weight method "%s" is not defined. Use ', ...
                         '"table_15_2" (Empty weight II) or "raymer_ga_III" ', ...
                         '(Empty weight III).'], obj.method);
            end

            bd.total = bd.wing + bd.horizontal_tail + bd.vertical_tail ...
                     + bd.fuselage + bd.landing_gear ...
                     + bd.installed_engine + bd.all_else_empty;
        end


        %% Operating Empty Weight - the IHW1 cross-check
        function oew = OEW_statistical(obj, W_TO)
        %OEW_STATISTICAL  The IHW1 empty-weight regression [lbf].
        %       OEW = 0.911 * W_TO^0.947
        %   Nicolai light-propeller-airplane trend, the model IHW1 and IHW2
        %   used. KEPT ONLY AS A CROSS-CHECK. It is not called by the sizing
        %   loop and must not be: it cannot see the geometry, so a loop built
        %   on it would converge on weight alone.
            arguments
                obj
                W_TO (1,1) double {mustBePositive}
            end
            oew = obj.k_OEW_statistical * W_TO ^ obj.n_OEW_statistical;
        end


        %% Payload
        function W = payload(obj)
        %PAYLOAD  Total payload [lbf]. The number the closure solves for.
            W = obj.W_payload_fixed + obj.W_payload_expendable;
        end

    end


    methods (Access = private)

        function W = wing_weight_raymer_ga_(obj, W_dg)
        %WING_WEIGHT_RAYMER_GA_  Statistical GA wing weight [lbf].
        %
        %   [Raymer Eq. 15.46, general aviation, British units]
        %
        %     W = 0.036 S_w^0.758 W_fw^0.0035 (A/cos^2 Lambda)^0.6 q^0.006
        %         lambda^0.04 (100 t/c)^-0.3 (N_z W_dg)^0.49
        %
        %   S_w      trapezoidal reference area [ft^2]
        %   W_fw     weight of fuel in the WING [lbf]
        %   A        aspect ratio           <- THE TERM THAT MATTERS
        %   Lambda   quarter-chord sweep
        %   q        dynamic pressure at cruise [lbf/ft^2]
        %   lambda   taper ratio
        %   t/c      root thickness ratio
        %   N_z      ultimate load factor
        %   W_dg     design gross weight [lbf]
        %
        %   Raymer's note "ignore W_fw term if W_fw = 0" is handled by
        %   defaulting the exponent term to 1 when no fuel weight has been
        %   set yet. The exponent is 0.0035, so at 1000 lbf of fuel the term
        %   is 1.024 - it changes the wing weight by two percent and can
        %   never drive anything. The aspect-ratio term, at exponent 0.6, is
        %   what this equation is here for.
            g = obj.geom;

            if isfinite(obj.W_energy) && obj.W_energy > 0
                W_fw_term = obj.W_energy ^ 0.0035;
            else
                W_fw_term = 1;            % Raymer: ignore the term
            end

            A_over_cos2 = g.AR / cosd(g.sweep_qc_deg)^2;

            W = 0.036 ...
              * g.S_ref^0.758 ...
              * W_fw_term ...
              * A_over_cos2^0.6 ...
              * obj.q_cruise^0.006 ...
              * g.taper^0.04 ...
              * (100 * g.tc_root)^(-0.3) ...
              * (obj.N_z * W_dg)^0.49;
        end

    end


    methods (Static, Access = private)

        function q = cruise_q_(J)
        %CRUISE_Q_  Dynamic pressure at the cruise condition [lbf/ft^2].
        %   Derived from the mission profile's cruise segment, so the cruise
        %   condition is stated once in the requirements file and read from
        %   there by everything that needs it.
            q = NaN;
            if ~isfield(J, 'missions'), return; end
            f = fieldnames(J.missions);
            for i = 1:numel(f)
                p = J.missions.(f{i});
                if ~isstruct(p) || ~isfield(p, 'segments'), continue; end
                segs = json_as_struct_array(p.segments);
                for k = 1:numel(segs)
                    if strcmpi(string(segs(k).type), "cruise")
                        st = get_state(segs(k).alt_ft);
                        V  = segs(k).ktas * 6076.115 / 3600;
                        q  = 0.5 * st.rho * V^2;
                        return;
                    end
                end
            end
        end

    end

end
