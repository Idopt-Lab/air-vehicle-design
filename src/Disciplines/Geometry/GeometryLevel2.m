classdef GeometryLevel2 < GeometryBase
    % Level II geometry: Roskam S_wet regression + exposed-surface wetted areas.
    %
    % Adds computed wing exposed and wetted areas from explicit span and chord
    % geometry (Brandt/Raymer methods) rather than purely regression-based.
    %
    % Usage:
    %   geom = GeometryLevel2(aircraft_type, W_TO, S_ref, b, AR, tc_wing);
    %   geom.S_wet_wing
    %   geom.L_fus

    properties
        aircraft_type
        b           % wingspan (ft)
        AR          % aspect ratio
        lambda      % wing taper ratio
        tc_wing     % thickness-to-chord ratio of wing
        cbar        % mean aerodynamic chord (ft)
        L_fus       % fuselage length (ft)
        S_wet_wing  % wetted area of exposed wing (ft²)
        S_wet_body  % wetted area of fuselage/body (ft²)
        S_HT        % horizontal tail area (ft²) — set by sizing loop
        S_VT        % vertical tail area (ft²)   — set by sizing loop
    end

    methods
        function obj = GeometryLevel2(aircraft_type, W_TO, S_ref_in, b, AR, tc_wing, lambda)
            if nargin < 7; lambda = 0.3; end
            obj.aircraft_type = aircraft_type;
            obj.S_ref   = S_ref_in;
            obj.b       = b;
            obj.AR      = AR;
            obj.lambda  = lambda;
            obj.tc_wing = tc_wing;

            % Regression-based total S_wet
            [obj.S_wet, ~, ~] = GeometryLevel1.get_design_S_wet(aircraft_type, W_TO);

            % Fuselage length
            [obj.L_fus, ~, ~] = GeometryLevel1.get_fus_len(aircraft_type, W_TO);

            % Wing root chord and MAC
            c_root   = 2*S_ref_in / (b*(1 + lambda));
            c_tip    = lambda * c_root;
            obj.cbar = (2/3)*c_root*(1 + lambda + lambda^2)/(1 + lambda);

            % Wing wetted area
            S_exp          = GeometryLevel2.get_S_exposed_wing(c_tip, c_root, b/2);
            obj.S_wet_wing = GeometryLevel2.get_S_wet_wing(S_exp, tc_wing);
        end
    end

    methods (Static)

        function [S_wet, c, d] = get_design_S_wet(aircraft_type, W_TO)
            % Same regression as Level I; available as static for direct calls.
            [S_wet, c, d] = GeometryLevel1.get_design_S_wet(aircraft_type, W_TO);
        end

        function output = get_S_exposed_wing(tip_length, exposed_rc, exposed_halfspan)
            % Brandt, "Geom" sheet, cell H7
            output = exposed_halfspan * (exposed_rc + tip_length);
        end

        function S_wet_wing = get_S_wet_wing(S_exposed, tc)
            if tc <= 0.05
                S_wet_wing = GeometryLevel2.compute_S_wet_wing_lowtc(S_exposed);
            else
                S_wet_wing = GeometryLevel2.compute_S_wet_wing_hightc(S_exposed, tc);
            end
        end

        function S_wet_body = compute_S_wet_body(A_top, A_side)
            S_wet_body = 3.4*(A_top + A_side)/2;  % Raymer, 6th ed, eq 7.13
        end

        function output = compute_S_wet_wing_lowtc(S_exposed)
            output = 2.003*S_exposed;  % Raymer, 6th ed, eq 7.11
        end

        function output = compute_S_wet_wing_hightc(S_exposed, tc)
            output = S_exposed*(1.977 + 0.52*tc);
        end

        function [c_HT, c_VT] = est_tail_propers(aircraft_type)
            % Raymer tail volume coefficient historical values
            switch aircraft_type
                case "sailplane";                       c_HT=0.50; c_VT=0.02;
                case "homebuilt";                       c_HT=0.50; c_VT=0.04;
                case "general aviation - single engine";c_HT=0.70; c_VT=0.04;
                case "general aviation - twin engine";  c_HT=0.80; c_VT=0.07;
                case "agricultural";                    c_HT=0.50; c_VT=0.04;
                case "twin turboprop";                  c_HT=0.90; c_VT=0.08;
                case "flying boat";                     c_HT=0.70; c_VT=0.06;
                case "jet trainer";                     c_HT=0.70; c_VT=0.06;
                case "jet fighter";                     c_HT=0.40; c_VT=0.07;
                case {"military cargo","military bomber"}; c_HT=1.00; c_VT=0.08;
                case "jet transport";                   c_HT=1.00; c_VT=0.09;
                otherwise; error("Unrecognized aircraft type: %s", aircraft_type)
            end
        end

        function [HT, VT] = tab_tail_AR_lambda(aircraft_type, ~)
            switch aircraft_type
                case "fighter"
                    HT.AR=3; HT.lambda=0.2; VT.AR=0.6; VT.lambda=0.2;
                case "sailplane"
                    HT.AR=6; HT.lambda=0.3; VT.AR=1.5; VT.lambda=0.4;
                otherwise
                    HT.AR=3; HT.lambda=0.3; VT.AR=1.3; VT.lambda=0.3;
            end
        end

    end

end
