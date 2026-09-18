classdef TtpaGeom < GeometryBase
%TTPAGEOM  Tier-1 preliminary geometry model for a piston-prop aircraft.
%
%   Low-fidelity geometry model for preliminary aircraft sizing.
%   Input properties define the aircraft specification. Derived geometry
%   is implemented as Dependent properties so values remain consistent
%   with the current design inputs.
%
%   Inheritance:
%       GeometryBase -> TtpaGeom
%
%   Abstract interface implemented:
%       get_S_ref()
%       get_S_wet()

% ===================================================================== %
% INPUTS — mutable design/specification data
% ===================================================================== %

properties

    %% Wing Geometry
    S_ref       = 134       % ft^2   Wing reference area
    AR          = 8         % -       Wing aspect ratio
    lambda      = 0.4       % -       Wing taper ratio
    tc_root     = 0.12      % -       Wing root thickness ratio
    tc_tip      = 0.08      % -       Wing tip thickness ratio

    %% Horizontal Tail
    V_ht        = 0.8       % -       Horizontal tail volume coefficient
    l_ht        = 15        % ft      Horizontal tail moment arm
    AR_ht       = 5.5       % -       Horizontal tail aspect ratio
    lambda_ht   = 0.75      % -       Horizontal tail taper ratio
    sweep_c4_ht = 10        % deg     Horizontal tail quarter-chord sweep

    %% Vertical Tail
    V_vt        = 0.065     % -       Vertical tail volume coefficient
    l_vt        = 17        % ft      Vertical tail moment arm
    AR_vt       = 1.3       % -       Vertical tail aspect ratio
    lambda_vt   = 0.55      % -       Vertical tail taper ratio
    sweep_c4_vt = 30        % deg     Vertical tail quarter-chord sweep

    %% Fuselage Geometry
    % These may eventually be replaced by a more detailed fuselage
    % sizing model.
    L_fuse      = NaN       % ft      Fuselage length
    D_fuse      = 4.0       % ft      Fuselage maximum diameter

end


% ===================================================================== %
% DERIVED — computed live from the input properties
% ===================================================================== %

properties (Dependent)

    %% Wing
    b               % ft      Wing span
    c_root          % ft      Wing root chord
    c_tip           % ft      Wing tip chord
    mac             % ft      Wing mean aerodynamic chord
    y_mac           % ft      Span-wise location of MAC
    sweep_le        % deg     Wing leading-edge sweep
    V_wf            % ft^3    Wing fuel volume

    %% Horizontal Tail
    S_ht            % ft^2    Horizontal tail reference area
    b_ht            % ft      Horizontal tail span
    c_root_ht       % ft      Horizontal tail root chord
    c_tip_ht        % ft      Horizontal tail tip chord
    mac_ht          % ft      Horizontal tail mean aerodynamic chord
    y_mac_ht        % ft      Horizontal tail MAC location

    %% Vertical Tail
    S_vt            % ft^2    Vertical tail reference area
    b_vt            % ft      Vertical tail span
    c_root_vt       % ft      Vertical tail root chord
    c_tip_vt        % ft      Vertical tail tip chord
    mac_vt          % ft      Vertical tail mean aerodynamic chord
    y_mac_vt        % ft      Vertical tail MAC location

    %% Fuselage / Total
    S_wet_fuse      % ft^2    Fuselage wetted area
    S_wet           % ft^2    Total aircraft wetted area

end


methods

    % ================================================================= %
    % Accessors required by GeometryBase
    % ================================================================= %

    function val = get_S_ref(obj)
    %GET_S_REF  Wing reference area [ft^2].
        val = obj.S_ref;
    end


    function val = get_S_wet(obj, ~)
    %GET_S_WET  Total aircraft wetted area [ft^2].
        val = obj.S_wet;
    end


    % ================================================================= %
    % Derived wing geometry
    % ================================================================= %

    function v = get.b(obj)
    %GET.B  Wing span [ft].
        v = GeometryBase.compute_span(obj.AR, obj.S_ref);
    end


    function v = get.c_root(obj)
    %GET.C_ROOT  Wing root chord [ft].
        v = GeometryBase.compute_root_chord( ...
            obj.S_ref, obj.b, obj.lambda);
    end


    function v = get.c_tip(obj)
    %GET.C_TIP  Wing tip chord [ft].
        v = GeometryBase.compute_tip_chord( ...
            obj.c_root, obj.lambda);
    end


    function v = get.mac(obj)
    %GET.MAC  Wing mean aerodynamic chord [ft].
        v = GeometryBase.compute_mac( ...
            obj.c_root, obj.lambda);
    end


    function v = get.y_mac(obj)
    %GET.Y_MAC  Span-wise location of wing MAC [ft].
        v = obj.b * (1 + 2*obj.lambda) / ...
            (6 * (1 + obj.lambda));
    end


    function v = get.sweep_le(obj)
    %GET.SWEEP_LE  Wing leading-edge sweep [deg].
    %
    %   Piston-prop aircraft are assumed unswept at the quarter chord.
        v = atand( ...
            4 * 0.25 * (1 - obj.lambda) / ...
            (obj.AR * (1 + obj.lambda)));
    end


    function v = get.V_wf(obj)
    %GET.V_WF  Approximate wing fuel volume [ft^3].
        tau = obj.tc_tip / obj.tc_root;

        v = 0.54 * obj.S_ref^2 / obj.b * obj.tc_root * ...
            (1 - obj.lambda * sqrt(tau) + ...
             obj.lambda^2 * tau) / ...
            (1 - obj.lambda^2);
    end


    % ================================================================= %
    % Derived horizontal tail geometry
    % ================================================================= %

    function v = get.S_ht(obj)
    %GET.S_HT  Horizontal tail reference area [ft^2].
        v = obj.V_ht * obj.S_ref * obj.mac / obj.l_ht;
    end


    function v = get.b_ht(obj)
    %GET.B_HT  Horizontal tail span [ft].
        v = GeometryBase.compute_span(obj.AR_ht, obj.S_ht);
    end


    function v = get.c_root_ht(obj)
    %GET.C_ROOT_HT  Horizontal tail root chord [ft].
        v = GeometryBase.compute_root_chord( ...
            obj.S_ht, obj.b_ht, obj.lambda_ht);
    end


    function v = get.c_tip_ht(obj)
    %GET.C_TIP_HT  Horizontal tail tip chord [ft].
        v = GeometryBase.compute_tip_chord( ...
            obj.c_root_ht, obj.lambda_ht);
    end


    function v = get.mac_ht(obj)
    %GET.MAC_HT  Horizontal tail mean aerodynamic chord [ft].
        v = GeometryBase.compute_mac( ...
            obj.c_root_ht, obj.lambda_ht);
    end


    function v = get.y_mac_ht(obj)
    %GET.Y_MAC_HT  Span-wise location of horizontal tail MAC [ft].
        v = obj.b_ht * (1 + 2*obj.lambda_ht) / ...
            (6 * (1 + obj.lambda_ht));
    end


    % ================================================================= %
    % Derived vertical tail geometry
    % ================================================================= %

    function v = get.S_vt(obj)
    %GET.S_VT  Vertical tail reference area [ft^2].
        v = obj.V_vt * obj.S_ref * obj.b / obj.l_vt;
    end


    function v = get.b_vt(obj)
    %GET.B_VT  Vertical tail span [ft].
        v = GeometryBase.compute_span(obj.AR_vt, obj.S_vt);
    end


    function v = get.c_root_vt(obj)
    %GET.C_ROOT_VT  Vertical tail root chord [ft].
        v = GeometryBase.compute_root_chord( ...
            obj.S_vt, obj.b_vt, obj.lambda_vt);
    end


    function v = get.c_tip_vt(obj)
    %GET.C_TIP_VT  Vertical tail tip chord [ft].
        v = GeometryBase.compute_tip_chord( ...
            obj.c_root_vt, obj.lambda_vt);
    end


    function v = get.mac_vt(obj)
    %GET.MAC_VT  Vertical tail mean aerodynamic chord [ft].
        v = GeometryBase.compute_mac( ...
            obj.c_root_vt, obj.lambda_vt);
    end


    function v = get.y_mac_vt(obj)
    %GET.Y_MAC_VT  Span-wise location of vertical tail MAC [ft].
        v = obj.b_vt * (1 + 2*obj.lambda_vt) / ...
            (6 * (1 + obj.lambda_vt));
    end


    % ================================================================= %
    % Derived fuselage geometry
    % ================================================================= %

    function v = get.S_wet_fuse(obj)
    %GET.S_WET_FUSE  Approximate fuselage wetted area [ft^2].
    %
    %   Fuselage is approximated as a cylinder.
        if isnan(obj.L_fuse)
            v = NaN;
        else
            v = pi * obj.D_fuse * obj.L_fuse;
        end
    end


    % ================================================================= %
    % Total wetted area
    % ================================================================= %

    function v = get.S_wet(obj)
    %GET.S_WET  Total aircraft wetted area [ft^2].
    %
    %   Low-fidelity approximation:
    %       Wing       = 2*S_ref
    %       HT         = 2*S_ht
    %       VT         = 2*S_vt
    %       Fuselage   = pi*D*L

        if isnan(obj.L_fuse)
            v = NaN;
            return
        end

        S_wet_wing = 2 * obj.S_ref;
        S_wet_ht   = 2 * obj.S_ht;
        S_wet_vt   = 2 * obj.S_vt;
        S_wet_fuse = obj.S_wet_fuse;

        v = S_wet_wing + S_wet_ht + ...
            S_wet_vt + S_wet_fuse;
    end

end

end