classdef SubsystemsL3
%SUBSYSTEMSL3  Level-3 subsystems static toolbox.
%
%   Call as SubsystemsL3.method(...); never instantiated. F16SubsystemsL3
%   delegates here.
%
%   L3 differs from L2 in one respect: the fuselage raw-volume term (Raymer
%   Eq. 7.14) is fed A_top/A_side from GeomL3's frame-integrated station table
%   instead of GeomL2's envelope-ellipse approximation. Every other equation
%   is level-agnostic and is reused from SubsystemsL2, not duplicated.
%
%   Companion doc: src/disciplines/subsystems/SubsystemsL3.md

    methods (Static)

        function result = fuel_volume_check(fuel_vol_required, fuel_vol_available)
            %FUEL_VOLUME_CHECK  Compares fuel_volume(obj) (fuselage-internal
            %   packaged + wing-internal, never just one) against
            %   obj.fuel_weight_source.W_energy, converted to a required volume
            %   via fuel_volume_from_weight. Errors if W_energy is not yet set.
                if (isnan(fuel_vol_required) || isnan(fuel_vol_available))
                    error("fuel_volume_check: NaN in argument")
                else
                    result = struct('available_vol_ft3', fuel_vol_available, ...
                            'required_vol_ft3', fuel_vol_required, ...
                            'sufficient', fuel_vol_available >= fuel_vol_required);
                end
        end

        % ================================================================== %
        % LOW-LEVEL: originates here -- frame-table integration.
        % ================================================================== %

        function [A_top, A_side] = compute_frame_integrated_projected_areas(frames_normalized, L_fus, W_max, H_max)
        %COMPUTE_FRAME_INTEGRATED_PROJECTED_AREAS  Top-view and side-view
        %   projected areas [ft^2] of the fuselage, by trapezoidal
        %   integration of GeomL3's per-frame width/height profile, feeding
        %   Raymer Eq. 7.14's A_top/A_side inputs.
        %
        %   frames_normalized is the (N,3) table on GeometryModelL3, columns
        %   [x/L, w/W_max, h/H_max]. Denormalized via GeomL3.denormalize_frames
        %   (reused, not duplicated). A (0,0,0) nose station is prepended
        %   before integrating.
        %
        %   No separate textbook equation number: a definitional trapezoidal
        %   integration to obtain the A_top/A_side quantities Raymer Eq. 7.14
        %   calls for. The 3.4/(4L) formula remains the cited Raymer equation.
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

        function val = compute_volume_from_control_stations(frame_x, frame_w, frame_h)
        %COMPUTE_VOLUME_FROM_CONTROL_STATIONS  Internal volume [ft^3] of a body
        %   from its station table. Plots cross-section area against station x,
        %   measured downstream from the nose, and takes the area under that
        %   curve. Raymer gives this as more accurate than Eq. 7.14.
        %   [Raymer 6th ed. Fig. 7.38, p. 207; worked example Fig. 7.5, p. 171]
        %
        %   Areas come from GeomL3.compute_frame_cs_area, the same cosine
        %   section the wetted-area path uses, so the two agree on body shape.
        %   The leading (0, 0) station closes the nose to a point. A body that
        %   does not close to a point needs a different first station.
        %
        %   F-16A fuselage: 764.0820 ft^3 over 20 stations, against Brandt's
        %   745.6994 ft^3 [Brandt F-16A.xls, trapz(Geom!C26:C45, fuselage CS
        %   area)]. The +2.47 % is the L3 fuselage length, 47.5 ft against
        %   Brandt's 46.5 ft, which is a deliberate tier difference. Station
        %   areas match Brandt to 7.11e-15 ft^2.
            arguments
                frame_x double {mustBeVector}
                frame_w double {mustBeVector, mustBePositive}
                frame_h double {mustBeVector, mustBePositive}
            end
            nf = numel(frame_x);
            if ~isequal(nf, numel(frame_w), numel(frame_h))
                error('SubsystemsL3:frameVectorLengthMismatch', ...
                    ['frame_x/frame_w/frame_h must all be the same length ' ...
                     '(one entry per station); got %d, %d, %d.'], ...
                    nf, numel(frame_w), numel(frame_h));
            end
            A   = GeomL3.compute_frame_cs_area(frame_w(:), frame_h(:));
            val = trapz([0; frame_x(:)], [0; A]);
        end
 
 
        % ================================================================== %
        % AVIONICS EQUIPMENT STATISTICS [Nicolai & Carichner Table 8.8, p.212]
        % Supply exactly ONE input; pass [] for the other.
        %   compute_radar_weight(1200, [])   weight from power
        %   compute_radar_weight([], 3.5)    weight from volume
        % Mod (09/07/2026) (Claude)
        % ================================================================== %

        function W = compute_radar_weight(power_W, volume_ft3)
        %COMPUTE_RADAR_WEIGHT  Weight [lbf] from power [W] OR volume [ft^3].
            W = SubsystemsL3.compute_avionics_weight_statistical('radar', power_W, volume_ft3);
        end

        function P = compute_radar_power(weight_lb, volume_ft3)
        %COMPUTE_RADAR_POWER  Power [W] from weight [lbf] OR volume [ft^3].
            P = SubsystemsL3.compute_avionics_power_statistical('radar', weight_lb, volume_ft3);
        end

        function V = compute_radar_volume(power_W, weight_lb)
        %COMPUTE_RADAR_VOLUME  Volume [ft^3] from power [W] OR weight [lbf].
            V = SubsystemsL3.compute_avionics_volume_statistical('radar', power_W, weight_lb);
        end

        function W = compute_doppler_nav_weight(power_W, volume_ft3)
        %COMPUTE_DOPPLER_NAV_WEIGHT  Weight [lbf] from power [W] OR volume [ft^3].
            W = SubsystemsL3.compute_avionics_weight_statistical('doppler_nav', power_W, volume_ft3);
        end

        function P = compute_doppler_nav_power(weight_lb, volume_ft3)
        %COMPUTE_DOPPLER_NAV_POWER  Power [W] from weight [lbf] OR volume [ft^3].
            P = SubsystemsL3.compute_avionics_power_statistical('doppler_nav', weight_lb, volume_ft3);
        end

        function V = compute_doppler_nav_volume(power_W, weight_lb)
        %COMPUTE_DOPPLER_NAV_VOLUME  Volume [ft^3] from power [W] OR weight [lbf].
            V = SubsystemsL3.compute_avionics_volume_statistical('doppler_nav', power_W, weight_lb);
        end

        function W = compute_inertial_nav_weight(power_W, volume_ft3)
        %COMPUTE_INERTIAL_NAV_WEIGHT  Weight [lbf] from power [W] OR volume [ft^3].
            W = SubsystemsL3.compute_avionics_weight_statistical('inertial_nav', power_W, volume_ft3);
        end

        function P = compute_inertial_nav_power(weight_lb, volume_ft3)
        %COMPUTE_INERTIAL_NAV_POWER  Power [W] from weight [lbf] OR volume [ft^3].
            P = SubsystemsL3.compute_avionics_power_statistical('inertial_nav', weight_lb, volume_ft3);
        end

        function V = compute_inertial_nav_volume(power_W, weight_lb)
        %COMPUTE_INERTIAL_NAV_VOLUME  Volume [ft^3] from power [W] OR weight [lbf].
            V = SubsystemsL3.compute_avionics_volume_statistical('inertial_nav', power_W, weight_lb);
        end

        function W = compute_tacan_weight(power_W, volume_ft3)
        %COMPUTE_TACAN_WEIGHT  Weight [lbf] from power [W] OR volume [ft^3].
            W = SubsystemsL3.compute_avionics_weight_statistical('tacan', power_W, volume_ft3);
        end

        function P = compute_tacan_power(weight_lb, volume_ft3)
        %COMPUTE_TACAN_POWER  Power [W] from weight [lbf] OR volume [ft^3].
            P = SubsystemsL3.compute_avionics_power_statistical('tacan', weight_lb, volume_ft3);
        end

        function V = compute_tacan_volume(power_W, weight_lb)
        %COMPUTE_TACAN_VOLUME  Volume [ft^3] from power [W] OR weight [lbf].
            V = SubsystemsL3.compute_avionics_volume_statistical('tacan', power_W, weight_lb);
        end

        function W = compute_receiver_weight(power_W, volume_ft3)
        %COMPUTE_RECEIVER_WEIGHT  Weight [lbf] from power [W] OR volume [ft^3].
            W = SubsystemsL3.compute_avionics_weight_statistical('receiver', power_W, volume_ft3);
        end

        function P = compute_receiver_power(weight_lb, volume_ft3)
        %COMPUTE_RECEIVER_POWER  Power [W] from weight [lbf] OR volume [ft^3].
            P = SubsystemsL3.compute_avionics_power_statistical('receiver', weight_lb, volume_ft3);
        end

        function V = compute_receiver_volume(power_W, weight_lb)
        %COMPUTE_RECEIVER_VOLUME  Volume [ft^3] from power [W] OR weight [lbf].
            V = SubsystemsL3.compute_avionics_volume_statistical('receiver', power_W, weight_lb);
        end

        function W = compute_transmitter_weight(power_W, volume_ft3)
        %COMPUTE_TRANSMITTER_WEIGHT  Weight [lbf] from power [W] OR volume [ft^3].
            W = SubsystemsL3.compute_avionics_weight_statistical('transmitter', power_W, volume_ft3);
        end

        function P = compute_transmitter_power(weight_lb, volume_ft3)
        %COMPUTE_TRANSMITTER_POWER  Power [W] from weight [lbf] OR volume [ft^3].
            P = SubsystemsL3.compute_avionics_power_statistical('transmitter', weight_lb, volume_ft3);
        end

        function V = compute_transmitter_volume(power_W, weight_lb)
        %COMPUTE_TRANSMITTER_VOLUME  Volume [ft^3] from power [W] OR weight [lbf].
            V = SubsystemsL3.compute_avionics_volume_statistical('transmitter', power_W, weight_lb);
        end

        function W = compute_identification_weight(power_W, volume_ft3)
        %COMPUTE_IDENTIFICATION_WEIGHT  Weight [lbf] from power [W] OR volume [ft^3].
            W = SubsystemsL3.compute_avionics_weight_statistical('identification', power_W, volume_ft3);
        end

        function P = compute_identification_power(weight_lb, volume_ft3)
        %COMPUTE_IDENTIFICATION_POWER  Power [W] from weight [lbf] OR volume [ft^3].
            P = SubsystemsL3.compute_avionics_power_statistical('identification', weight_lb, volume_ft3);
        end

        function V = compute_identification_volume(power_W, weight_lb)
        %COMPUTE_IDENTIFICATION_VOLUME  Volume [ft^3] from power [W] OR weight [lbf].
            V = SubsystemsL3.compute_avionics_volume_statistical('identification', power_W, weight_lb);
        end

        function W = compute_computer_weight(power_W, volume_ft3)
        %COMPUTE_COMPUTER_WEIGHT  Weight [lbf] from power [W] OR volume [ft^3].
            W = SubsystemsL3.compute_avionics_weight_statistical('computer', power_W, volume_ft3);
        end

        function P = compute_computer_power(weight_lb, volume_ft3)
        %COMPUTE_COMPUTER_POWER  Power [W] from weight [lbf] OR volume [ft^3].
            P = SubsystemsL3.compute_avionics_power_statistical('computer', weight_lb, volume_ft3);
        end

        function V = compute_computer_volume(power_W, weight_lb)
        %COMPUTE_COMPUTER_VOLUME  Volume [ft^3] from power [W] OR weight [lbf].
            V = SubsystemsL3.compute_avionics_volume_statistical('computer', power_W, weight_lb);
        end

        function W = compute_ecm_weight(power_W, volume_ft3)
        %COMPUTE_ECM_WEIGHT  Weight [lbf] from power [W] OR volume [ft^3].
            W = SubsystemsL3.compute_avionics_weight_statistical('ecm', power_W, volume_ft3);
        end

        function P = compute_ecm_power(weight_lb, volume_ft3)
        %COMPUTE_ECM_POWER  Power [W] from weight [lbf] OR volume [ft^3].
            P = SubsystemsL3.compute_avionics_power_statistical('ecm', weight_lb, volume_ft3);
        end

        function V = compute_ecm_volume(power_W, weight_lb)
        %COMPUTE_ECM_VOLUME  Volume [ft^3] from power [W] OR weight [lbf].
            V = SubsystemsL3.compute_avionics_volume_statistical('ecm', power_W, weight_lb);
        end

        % ---- Generic solvers the per-system methods delegate to ----------- %

        function W = compute_avionics_weight_statistical(system, power_W, volume_ft3)
        %COMPUTE_AVIONICS_WEIGHT_STATISTICAL  Weight [lbf]. The fitted direction.
        %   [Nicolai & Carichner Table 8.8, p.212]
            c = SubsystemsL3.lookup_avionics_coeffs(system);
            if SubsystemsL3.is_given(power_W)
                W = SubsystemsL3.eval_fit(c.wp, power_W);
            elseif SubsystemsL3.is_given(volume_ft3)
                W = SubsystemsL3.eval_fit(c.wv, SubsystemsL3.to_fit_volume(c, volume_ft3));
            else
                error('SubsystemsL3:oneInputRequired', ...
                    'Supply power [W] or volume [ft^3]; pass [] for the other.');
            end
        end

        function P = compute_avionics_power_statistical(system, weight_lb, volume_ft3)
        %COMPUTE_AVIONICS_POWER_STATISTICAL  Power [W], by inverting the
        %   weight-from-power fit. From volume it chains volume -> weight ->
        %   power: Table 8.8 fits no direct volume-to-power relation.
            c = SubsystemsL3.lookup_avionics_coeffs(system);
            if ~SubsystemsL3.is_given(weight_lb)
                weight_lb = SubsystemsL3.compute_avionics_weight_statistical(system, [], volume_ft3);
            end
            P = SubsystemsL3.solve_fit(c.wp, weight_lb, 'power');
        end

        function V = compute_avionics_volume_statistical(system, power_W, weight_lb)
        %COMPUTE_AVIONICS_VOLUME_STATISTICAL  Volume [ft^3], by inverting the
        %   weight-from-volume fit. From power it chains power -> weight ->
        %   volume: Table 8.8 fits no direct power-to-volume relation.
            c = SubsystemsL3.lookup_avionics_coeffs(system);
            if ~SubsystemsL3.is_given(weight_lb)
                weight_lb = SubsystemsL3.compute_avionics_weight_statistical(system, power_W, []);
            end
            V = SubsystemsL3.from_fit_volume(c, SubsystemsL3.solve_fit(c.wv, weight_lb, 'volume'));
        end

        function c = lookup_avionics_coeffs(system)
        %LOOKUP_AVIONICS_COEFFS  Table 8.8 coefficients, verbatim, plus each
        %   row's own volume unit. Weight [lbf], power [W].
        %   'pow': Wt = a*X^b.   'lin': Wt = a + b*X.
        %   [Nicolai & Carichner Table 8.8, p.212]
            switch system
                case 'radar'           % less antenna
                    c = SubsystemsL3.row('pow', 0.431, 0.777, 'pow', 38.21, 0.873, 'ft3');
                case 'doppler_nav'
                    c = SubsystemsL3.row('pow', 0.408, 0.868, 'pow', 29.67, 0.662, 'ft3');
                case 'inertial_nav'
                    c = SubsystemsL3.row('pow', 0.465, 0.848, 'pow', 51.85, 0.738, 'ft3');
                case 'tacan'
                    c = SubsystemsL3.row('lin', 13.61, 0.104, 'pow', 0.311, 0.704, 'in3');
                case 'receiver'
                    c = SubsystemsL3.row('lin', 6.3,   0.17,  'pow', 44.5,  0.737, 'ft3');
                case 'transmitter'
                    c = SubsystemsL3.row('pow', 0.73,  0.610, 'lin', 6.4,   40.2,  'ft3');
                case 'identification'
                    c = SubsystemsL3.row('pow', 0.607, 0.724, 'pow', 0.069, 0.868, 'in3');
                case 'computer'
                    c = SubsystemsL3.row('pow', 2.246, 0.630, 'pow', 0.123, 0.817, 'in3');
                case 'ecm'
                    c = SubsystemsL3.row('pow', 0.429, 0.771, 'pow', 0.055, 0.912, 'in3');
                otherwise
                    error('SubsystemsL3:unknownAvionicsSystem', ...
                        ['Unknown avionics system "%s". Known systems (Nicolai & ' ...
                         'Carichner Table 8.8): radar, doppler_nav, inertial_nav, ' ...
                         'tacan, receiver, transmitter, identification, computer, ' ...
                         'ecm.'], system);
            end
        end

    end

    methods (Static, Access = private)

        function c = row(fp, ap, bp, fv, av, bv, v_unit)
        %ROW  One Table 8.8 row: both fits plus the row's volume unit.
            c = struct('wp',     struct('form', fp, 'a', ap, 'b', bp), ...
                       'wv',     struct('form', fv, 'a', av, 'b', bv), ...
                       'v_unit', v_unit);
        end

        function tf = is_given(x)
        %IS_GIVEN  An input counts as supplied when it is a finite scalar.
            tf = ~isempty(x) && isscalar(x) && isfinite(x);
        end

        function x_fit = to_fit_volume(c, volume_ft3)
        %TO_FIT_VOLUME  ft^3 -> the row's own unit. 1728 in^3 per ft^3.
            arguments
                c                struct
                volume_ft3 (1,1) double {mustBePositive}
            end
            if strcmp(c.v_unit, 'in3')
                x_fit = volume_ft3 * 1728;
            else
                x_fit = volume_ft3;
            end
        end

        function volume_ft3 = from_fit_volume(c, x_fit)
        %FROM_FIT_VOLUME  The row's own unit -> ft^3.
            if strcmp(c.v_unit, 'in3')
                volume_ft3 = x_fit / 1728;
            else
                volume_ft3 = x_fit;
            end
        end

        function y = eval_fit(f, x)
        %EVAL_FIT  Evaluate one Table 8.8 fit.
            arguments
                f       struct
                x (1,1) double {mustBePositive}
            end
            if strcmp(f.form, 'pow')
                y = f.a * x^f.b;
            else
                y = f.a + f.b * x;
            end
        end

        function x = solve_fit(f, y, what)
        %SOLVE_FIT  Invert one Table 8.8 fit for its independent variable.
            arguments
                f       struct
                y (1,1) double {mustBePositive}
                what    char
            end
            if strcmp(f.form, 'pow')
                x = (y / f.a)^(1 / f.b);
            else
                x = (y - f.a) / f.b;
            end
            if x <= 0
                error('SubsystemsL3:fitOutOfRange', ...
                    ['Weight %.4g lbf inverts to a non-positive %s. The fit ' ...
                     'has no meaning at or below its intercept.'], y, what);
            end
        end

    end
end
