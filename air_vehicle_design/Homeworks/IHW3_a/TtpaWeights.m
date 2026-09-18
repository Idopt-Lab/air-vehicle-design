classdef TtpaWeights < WeightsBase
%TTPAWEIGHTS  Test Twin Propeller Aircraft Level-2 weight model.
%
%   IHW3a UPDATE
%   This is the class that changes most. In IHW1 and IHW2 the whole empty
%   weight was one line:
%
%       oew = 0.911 * W_TO^0.947;
%
%   a statistical regression on light propeller airplanes. It is a good
%   first estimate and it is what closed the IHW1 mission analysis at
%   W_TO = 5354 lbf. But it knows ONLY the takeoff weight. Double the wing
%   area, fit a bigger engine, stretch the tails - it returns the same
%   number. Inside a sizing loop that is fatal, because the loop exists
%   precisely to work out what the airplane weighs after it has been laid
%   out, and an empty weight that ignores the layout makes the loop's
%   geometry pointless.
%
%   So IHW3a replaces it with the Raymer Table 15.2 component build-up:
%
%       [Raymer Table 15.2, General Aviation column]
%         W_wing      = 2.5   * S_exposed_wing        lb/ft^2 x EXPOSED area
%         W_ht        = 2.0   * S_ht                  lb/ft^2 x EXPOSED area
%         W_vt        = 2.0   * S_vt                  lb/ft^2 x EXPOSED area
%         W_fuselage  = 1.4   * S_wet_fuselage        lb/ft^2 x WETTED area
%         W_gear      = 0.057 * W_TO                  fraction of TOGW
%         W_engines   = 1.4   * W_bare_all_engines    x bare engine weight
%         W_all_else  = 0.10  * W_TO                  fraction of TOGW
%
%         OEW = sum of the seven
%
%   Note which multiplier each row takes. The first three are EXPOSED
%   PLANFORM area; the fuselage row is the only WETTED one. Getting those
%   two the wrong way round is the classic error with this table.
%
%   Note also that the General Aviation column is not the fighter column:
%   the installed-engine factor is 1.4, not 1.3, and all-else-empty is
%   0.10, not 0.17.
%
%   The bare engine weight comes from the propulsion model, which scales it
%   from P_SL through Raymer Table 10.4. So the empty weight now depends on
%   BOTH states of the sizing loop - on W_TO through three of the seven
%   rows, and on P_SL through the engine row - and on the geometry the loop
%   has just laid out through the other three.
%
%   THE OLD REGRESSION IS STILL HERE, as OEW_statistical. It is a
%   CROSS-CHECK, not the model. Two independent methods that agree within a
%   few percent are evidence the geometry is right; if they diverge, the
%   geometry is the thing to look at first.
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
        W_TO                 = NaN   % lbf, candidate gross takeoff weight; NaN until the sizing loop sets it
        W_energy             = NaN   % lbf, total internal fuel weight; NaN until mission analysis sets it
        W_payload_expendable = 0     % lbf, expendable payload (stores)
        W_payload_fixed      = 1200  % lbf, fixed payload, including crew
    end

    properties (SetAccess = immutable)
        geom                         % injected TtpaGeom
        prop                         % injected TtpaProp

        % --- Raymer Table 15.2, General Aviation column ---
        rho_wing                     % <- J.weights.unit_weight_wing_psf
        rho_ht                       % <- J.weights.unit_weight_horizontal_tail_psf
        rho_vt                       % <- J.weights.unit_weight_vertical_tail_psf
        rho_fuselage                 % <- J.weights.unit_weight_fuselage_psf
        f_landing_gear               % <- J.weights.landing_gear_fraction
        f_installed_engine           % <- J.weights.installed_engine_factor
        f_all_else_empty             % <- J.weights.all_else_empty_fraction

        % --- IHW1 regression, kept as a cross-check ---
        k_OEW_statistical            % <- J.weights.statistical_OEW_coefficient
        n_OEW_statistical            % <- J.weights.statistical_OEW_exponent

        % --- post-sizing fuel-volume check ---
        rho_fuel                     % <- J.weights.fuel_density_lb_per_ft3
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
        end


        %% Operating Empty Weight - the model
        function oew = OEW(obj, W_TO)
        %OEW  Operating empty weight [lbf] at a candidate takeoff weight.
        %
        %   The Raymer Table 15.2 General Aviation component build-up. Use
        %   OEW_breakdown if the individual rows are wanted; this returns
        %   only the total, because that is all the WeightsBase contract
        %   promises and all the sizing loop needs.
        %
        %   Every W_TO-dependent term is evaluated at the PASSED W_TO, not
        %   at obj.W_TO.
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
        %   and, for reporting, .engine_bare_each and .engine_bare_total.
        %
        %   [Raymer Table 15.2, General Aviation column throughout]
            arguments
                obj
                W_TO (1,1) double {mustBePositive}
            end

            % Areal-density rows. The first three multiply EXPOSED PLANFORM
            % area; the fuselage row multiplies WETTED area.
            bd.wing            = obj.rho_wing     * obj.geom.S_exposed_wing;
            bd.horizontal_tail = obj.rho_ht       * obj.geom.S_ht;
            bd.vertical_tail   = obj.rho_vt       * obj.geom.S_vt;
            bd.fuselage        = obj.rho_fuselage * obj.geom.S_wet_fuselage;

            % Fraction-of-TOGW rows, at the PASSED weight
            bd.landing_gear   = obj.f_landing_gear   * W_TO;
            bd.all_else_empty = obj.f_all_else_empty * W_TO;

            % Installed engines: the Table 15.2 factor times the BARE
            % engine weight, which the propulsion model scales from P_SL
            % through Raymer Table 10.4.
            [W_bare_total, W_bare_each] = obj.prop.engine_weight();
            bd.engine_bare_each  = W_bare_each;
            bd.engine_bare_total = W_bare_total;
            bd.installed_engine  = obj.f_installed_engine * W_bare_total;

            bd.total = bd.wing + bd.horizontal_tail + bd.vertical_tail ...
                     + bd.fuselage + bd.landing_gear ...
                     + bd.installed_engine + bd.all_else_empty;
        end


        %% Operating Empty Weight - the IHW1 cross-check
        function oew = OEW_statistical(obj, W_TO)
        %OEW_STATISTICAL  The IHW1 empty-weight regression [lbf].
        %
        %       OEW = 0.911 * W_TO^0.947
        %
        %   Nicolai light-propeller-airplane trend, the model IHW1 and IHW2
        %   used. KEPT ONLY AS A CROSS-CHECK on the component build-up. It
        %   is not called by the sizing loop and must not be: it cannot see
        %   the geometry, so a loop built on it would converge on weight
        %   alone and the wing, the tails and the engine would have no
        %   effect on the answer.
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

end
