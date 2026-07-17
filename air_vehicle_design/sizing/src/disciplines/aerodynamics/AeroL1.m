classdef AeroL1
%AEROL1  Level-1 aerodynamics static toolbox.
%
%   Call as AeroL1.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16AeroL1, etc.) inherit
%   from AeroModelL1 and call these statics to implement each abstract method.
%
%   TWO TIERS of statics:
%     High-level  — take the student object (obj) and return a computed result.
%                   Student implementations are a single delegation line.
%     Low-level   — pure math; take only scalars/arrays.  AeroL2/L3 also call
%                   these for the shared K1/K2 equations.
%
%   EQUATIONS:
%     CD0 = Cf * (S_wet / S_ref)
%       Raymer, "Aircraft Design: A Conceptual Approach," 6th ed., §12.3
%     e_osw (Λ_LE < 30°):  1.78*(1-0.045*AR^0.68) - 0.64       Eq. 12.48
%     e_osw (Λ_LE ≥ 30°):  4.61*(1-0.045*AR^0.68)*cos(Λ)^0.15 - 3.1  Eq. 12.49
%     K1 subsonic:   1/(pi*AR*e)                                 Eq. 12.50
%     K1 supersonic: AR*beta*cos(Λ_LE)/(4*AR*beta - 2)          Eq. 12.51
%     K2 subsonic:   -2*K1_sub*CL_minD                          Brandt §4.3
%     K2 supersonic: 0
%     LD_max = K_LD * sqrt(AR_wet)                              Raymer Eq. 3.12
%     AR_wet = b^2 / S_wet                                      Raymer Eq. 3.11

% These are tables for tabulations.
     properties (Constant)
          CLmax_table = AeroL1.build_CLmax_table()    % Useful for designs with and without high-lift devices
          Delta_CD0   = AeroL1.build_DeltaCD0_table() % For designs with high-lift devices
     end

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % Student implementations delegate with one line, e.g.:
        %   function polar = drag_polar(obj, state)
        %       polar = AeroL1.drag_polar(obj, state);
        %   end
        % ================================================================== %

        function polar = drag_polar(obj, state)
        %DRAG_POLAR  Assemble L1 drag polar from the student object's properties.
        %   Returns struct(CD0, K1, K2).
            M      = state.mach;
            cd0    = AeroL1.get_CD0(obj);
            e      = AeroL1.oswald_eff(obj.AR, obj.Lambda_LE_deg);
            k1_sub = AeroL1.K1_subsonic(e, obj.AR);
            k2     = AeroL1.K2_value(k1_sub, obj.CL_minD, M);
            if M < 1
                k1 = k1_sub;
            else
                k1 = AeroL1.K1_supersonic(M, obj.AR, obj.Lambda_LE_deg);
            end
            polar = struct('CD0', cd0, 'K1', k1, 'K2', k2);
        end

        function CLmax = get_CLmax(obj)
        %GET_CLMAX  Historical CLmax from aircraft-type lookup.
            CLmax = AeroL1.lookup_CLmax(obj.aircraft_category);
        end

        function e = get_e_osw(obj)
        %GET_E_OSW  Oswald efficiency from obj.AR and obj.Lambda_LE_deg.
            e = AeroL1.oswald_eff(obj.AR, obj.Lambda_LE_deg);
        end

        function val = get_CD0(obj)
        %GET_CD0  CD0 = Cf * S_wet / S_ref.
            val = AeroL1.CD0_from_Cf(AeroL1.lookup_Cf(obj.aircraft_category), ...
                                     obj.S_wet, obj.S_ref);
        end

        function val = get_K1(obj, M)
        %GET_K1  Induced-drag factor; subsonic or supersonic form.
            e = AeroL1.oswald_eff(obj.AR, obj.Lambda_LE_deg);
            if M < 1
                val = AeroL1.K1_subsonic(e, obj.AR);
            else
                val = AeroL1.K1_supersonic(M, obj.AR, obj.Lambda_LE_deg);
            end
        end

        function val = get_K2(obj, K1_sub, M)
        %GET_K2  Polar-offset term; zero at M >= 1.
            val = AeroL1.K2_value(K1_sub, obj.CL_minD, M);
        end

        function val = compute_K(e_osw, AR)
        %COMPUTE_K  Subsonic induced-drag factor K = 1/(pi*e_osw*AR).
            val = AeroL1.K1_subsonic(e_osw, AR);
        end

        function val = compute_LD_max(K_LD, AR_wet)
        %COMPUTE_LD_MAX  Statistical LD_max = K_LD * sqrt(AR_wet).  Raymer Eq. 3.12.
            val = K_LD * sqrt(AR_wet);
        end

        function val = compute_AR_wet(b, S_wet)
        %COMPUTE_AR_WET  Wetted aspect ratio AR_wet = b^2 / S_wet.  Raymer Eq. 3.11.
            val = b^2 / S_wet;
        end

        function val = compute_CL_minD(airfoil_type, CL_min)
        %COMPUTE_CL_MIND  CL at minimum drag.
        %   Cambered: caller supplies CL_min.  Uncambered/symmetric: 0.
            if strcmp(airfoil_type, 'cambered')
                val = CL_min;
            else
                val = 0;
            end
        end

        % ================================================================== %
        % LOW-LEVEL: pure math — scalars/arrays only, no object access.
        % AeroL2/L3 and student classes may call these directly.
        % ================================================================== %

        function e = oswald_eff(AR, Lambda_LE_deg)
        %OSWALD_EFF  Raymer 6th ed. Eq. 12.48 (Λ < 30°) or Eq. 12.49 (Λ ≥ 30°).
        % TODO: Consider moving to AeroL2 since it takes wing geometry (AR,
        % Lambda_LE_deg) rather than just an aircraft category. Kept here because
        % it is called by AeroL1, AeroL2, and AeroL3 drag_polar paths.
            if Lambda_LE_deg < 30
                e = 1.78 * (1 - 0.045 * AR^0.68) - 0.64;
            else
                e = 4.61 * (1 - 0.045 * AR^0.68) * cosd(Lambda_LE_deg)^0.15 - 3.1;
            end
        end

        function K1 = K1_subsonic(e_osw, AR)
        %K1_SUBSONIC  K1 = 1/(pi*AR*e)  [Raymer 6th ed. Eq. 12.50].
            K1 = 1 / (pi * AR * e_osw);
        end

        function K1 = K1_supersonic(M, AR, Lambda_LE_deg)
        %K1_SUPERSONIC  Linearized supersonic K1  [Raymer 6th ed. Eq. 12.51].
        %   Valid for M > 1.
            if M <= 1
                error('AeroL1:subsonicMach', ...
                    'K1_supersonic called with M=%.3f; use K1_subsonic for M<1.', M);
            end
            beta = sqrt(M^2 - 1);
            K1   = AR * beta * cosd(Lambda_LE_deg) / (4 * AR * beta - 2);
        end

        function K2 = K2_value(K1_sub, CL_minD, M)
        %K2_VALUE  Polar-offset term.
        %   K2 = -2*K1_sub*CL_minD  (subsonic)   [Brandt et al. §4.3]
        %   K2 = 0                  (M >= 1)
            if M >= 1
                K2 = 0;
            else
                K2 = -2 * K1_sub * CL_minD;
            end
        end

        function CD0 = CD0_from_Cf(Cf, S_wet, S_ref)
        %CD0_FROM_CF  CD0 = Cf * S_wet / S_ref  [Raymer 6th ed. §12.3].
            CD0 = Cf * S_wet / S_ref;
        end

        function Cf = lookup_Cf(aircraft_category)
        %LOOKUP_CF  Type-based wetted-area friction coefficient.
        %   Source: Raymer 6th ed. Table 12.3.
            switch aircraft_category
                case 'jet_fighter',    Cf = 0.0035;
                case 'military_cargo', Cf = 0.0035;
                case 'transport_jet',  Cf = 0.0030;
                case 'business_jet',   Cf = 0.0030;
                case 'general_aviation_single', Cf = 0.0055;
                case 'general_aviation_twin',   Cf = 0.0045;
                case 'sailplane',               Cf = 0.0020;
                otherwise
                    error('AeroL1:unknownCategory', ...
                        'Unknown aircraft_category "%s". Add it to AeroL1.lookup_Cf.', ...
                        aircraft_category);
            end
        end

        function CLmax = lookup_CLmax(aircraft_category)
        %LOOKUP_CLMAX  Clean CLmax by aircraft type (historical, no HLD).
        %   Source: Roskam, "Airplane Design Vol. I," Table 3.3.
            switch aircraft_category
                case 'jet_fighter',    CLmax = 0.90;
                case 'military_cargo', CLmax = 1.20;
                case 'transport_jet',  CLmax = 1.30;
                case 'business_jet',   CLmax = 1.10;
                case 'general_aviation_single', CLmax = 1.30;
                case 'general_aviation_twin',   CLmax = 1.20;
                case 'sailplane',               CLmax = 1.40;
                otherwise
                    error('AeroL1:unknownCategory', ...
                        'Unknown aircraft_category "%s". Add it to AeroL1.lookup_CLmax.', ...
                        aircraft_category);
            end
        end

        function val = lookup_K_LD(aircraft_category)
        %LOOKUP_K_LD  K_LD factor for statistical LD_max estimate.
        %   LD_max = K_LD * sqrt(AR_wet)  [Raymer 6th ed. p. 40, Eq. 3.12].
            switch aircraft_category
                case 'jet_fighter',    val = 14;
                case 'military_cargo', val = 13;
                case 'transport_jet',  val = 15.5;
                case 'business_jet',   val = 15.5;
                case 'general_aviation_single', val = 11;
                case 'general_aviation_twin',   val = 11;
                case 'sailplane',               val = 15;
                otherwise
                    error('AeroL1:unknownCategory', ...
                        'Unknown aircraft_category "%s". Add it to AeroL1.lookup_K_LD.', ...
                        aircraft_category);
            end
        end

    end
methods (Static, Access = private)

          function quantity = normalize_DeltaCD0_quantity(quantity)

               quantity = lower(strtrim(string(quantity)));
               quantity = replace(quantity, "-", "_");
               quantity = replace(quantity, " ", "_");

               if any(quantity == ["all", "data", "table"])
                    quantity = "all";

               elseif any(quantity == ["dcd0", ...
                         "delta_cd0", ...
                         "delta_c_d0", ...
                         "cd0_increment"])
                    quantity = "Delta_CD0";

               elseif any(quantity == ["e", ...
                         "e_osw", ...
                         "eosw", ...
                         "oswald", ...
                         "oswald_efficiency"])
                    quantity = "e_osw";
               end
          end


          function flapconfig = normalize_flapconfig(flapconfig)

               flapconfig = lower(strtrim(string(flapconfig)));
               flapconfig = replace(flapconfig, "-", "_");
               flapconfig = replace(flapconfig, " ", "_");
               flapconfig = replace(flapconfig, "/", "_");

               if any(flapconfig == ["clean", "none", "no_flaps"])
                    flapconfig = "clean";

               elseif any(flapconfig == ["takeoff", ...
                         "takeoff_flaps", ...
                         "take_off", ...
                         "take_off_flaps", ...
                         "to_flaps"])
                    flapconfig = "takeoff_flaps";

               elseif any(flapconfig == ["landing", ...
                         "landing_flaps", ...
                         "land_flaps"])
                    flapconfig = "landing_flaps";

               elseif any(flapconfig == ["landing_gear", ...
                         "gear", ...
                         "lg",...
                         "geardown"])
                    flapconfig = "landing_gear";
               end
          end

          function T = build_CLmax_table()

               row = @(aircraftType, CL_clean, CL_TO, CL_L) table( ...
                    string(aircraftType), ...
                    {CL_clean}, ...
                    {CL_TO}, ...
                    {CL_L}, ...
                    'VariableNames', {'AircraftType', 'CL_max_clean', 'CL_max_TO', 'CL_max_L'});

               T = [
                    row("homebuilt",                    [1.2 1.8], [1.2 1.8], [1.2 2.0])
                    row("single_engine_propeller",      [1.3 1.9], [1.3 1.9], [1.6 2.3])
                    row("twin_engine_propeller",        [1.2 1.8], [1.4 2.0], [1.6 2.5])
                    row("agricultural",                 [1.3 1.9], [1.3 1.9], [1.3 1.9])
                    row("business_jet",                 [1.4 1.8], [1.6 2.2], [1.6 2.6])
                    row("regional_tbp",                 [1.5 1.9], [1.7 2.1], [1.9 3.3])
                    row("transport_jet",                [1.2 1.8], [1.6 2.2], [1.8 2.8])
                    row("military_trainer",             [1.2 1.8], [1.4 2.0], [1.6 2.2])
                    row("fighter",                      [1.2 1.8], [1.4 2.0], [1.6 2.6])
                    row("mil_patrol_bomb_transport",    [1.2 1.8], [1.6 2.2], [1.8 3.0])
                    row("flying_boat_amphibious_float", [1.2 1.8], [1.6 2.2], [1.8 3.4])
                    row("supersonic_cruise",            [1.2 1.8], [1.6 2.0], [1.8 2.2])
                    ];
          end

          function condition = normalize_CL_condition(condition)

               condition = lower(strtrim(string(condition)));
               condition = replace(condition, "-", "_");
               condition = replace(condition, " ", "_");

               if any(condition == ["", "all"])
                    condition = "";

               elseif any(condition == ["clean", ...
                         "clmax", ...
                         "cl_max", ...
                         "cl_max_clean"])
                    condition = "clean";

               elseif any(condition == ["to", ...
                         "takeoff", ...
                         "take_off", ...
                         "clmax_to", ...
                         "cl_max_to", ...
                         "cl_max_takeoff"])
                    condition = "takeoff";

               elseif any(condition == ["l", ...
                         "land", ...
                         "landing", ...
                         "clmax_l", ...
                         "cl_max_l", ...
                         "cl_max_landing"])
                    condition = "landing";
               end
          end

          function output = build_DeltaCD0_table()

               row = @(flapconfig, DeltaCD0, e_osw) table( ...
                    string(flapconfig), ...
                    {DeltaCD0}, ...
                    {e_osw}, ...
                    'VariableNames', {'FlapConfig', 'Delta_CD0', 'e_osw'});

               output = [
                    row("clean",          [0.000 0.000], [0.80 0.85])
                    row("takeoff_flaps",  [0.010 0.020], [0.75 0.80])
                    row("landing_flaps",  [0.055 0.075], [0.70 0.75])
                    row("landing_gear",   [0.015 0.025], NaN)
                    ];
          end


     end

end
