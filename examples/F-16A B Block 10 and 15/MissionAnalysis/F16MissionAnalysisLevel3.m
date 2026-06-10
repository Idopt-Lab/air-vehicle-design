classdef F16MissionAnalysisLevel3 < MissionAnalysisModel
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here

     properties

          missiondata % This is all the mission_obj information. Altitudes, aerodynamics, etc.
          mission_fuel
          mission_states
          eps
     end

     methods
          % Constructor
          % Constructor
          function obj = F16MissionAnalysisLevel3(Chosen_Mission)
               obj.missiondata = MissionAnalysisModel.get_mission_data(Chosen_Mission);
               obj.mission_states = obj.generate_mission_states;
          end

          % Compute mission fuel
          function [total_fuel_used, fuel_fraction, CL_array, CD_array, CDi_array, CD0_array] = get_mission_fuel(mission_obj, constraint_obj, design, geometry_obj, propulsion_obj, weight_obj, aero_obj)
               % This is where we actually compute the fuel for the mission
               % AR = design.geom.wings.Main.AspectRatio;
               AR = geometry_obj.mainwings.AR;

               % W_S = 104.59;
               W_S = constraint_obj.optimal_WS;
               W_TO = weight_obj.W_TO;
               T_W = constraint_obj.min_TW; % Desired thrust-to-weight ratio (figure out how to get this naturally later)
               S_ref = geometry_obj.mainwings.S_ref;
               T0 = propulsion_obj.T0;

               t_SL_dry = design.propulsion.ThrustseaLevellbf.Dry;
               t_SL_wet = design.propulsion.ThrustseaLevellbf.Wet;
               TSFC_sl_perhour_dry = design.propulsion.TSFCseaLevelperHour.Dry;
               TSFC_sl_perhour_wet = design.propulsion.TSFCseaLevelperHour.Wet;
               E_dry = design.propulsion.E.Dry;
               E_wet = design.propulsion.E.Wet;
               F1_dry = design.propulsion.F1.Dry;
               F1_wet = design.propulsion.F1.Wet;
               F2_dry = design.propulsion.F2.Dry;
               F2_wet = design.propulsion.F2.Wet;
               TR = 1.0;

               % Automate segment extraction
               segmentnames = fields(mission_obj.missiondata);
               fuelburnedarray = zeros(1,length(segmentnames));
               W_array = zeros(1, length(segmentnames));

               W_array(1) = W_TO;

               % Initialize aerodynamic coefficient arrays
               segment_count = length(segmentnames)-1;
               CL_array = zeros(1, segment_count);
               CD0_array = zeros(1, segment_count);
               CDi_array = zeros(1, segment_count);
               CD_array = zeros(1, segment_count);

               for i=1:length(segmentnames)
                    currentsegment = segmentnames{i};
                    % Clip extra letters from segment name, but don't store
                    % the result permanently
                    currentsegment = erase(currentsegment, '_');
                    currentsegment = erase(currentsegment, {'1', '2', '3', '4', '5', '6', '7', '8', '9', '0'});

                    % Extract necessary info from current segment
                    % Checks if current segment is "meta" (artefact from
                    % table -> struct conversion.
                    if (currentsegment == "meta")
                         break
                    else
                         M = mission_obj.missiondata.(currentsegment).MachNumber;
                         alt = mission_obj.missiondata.(currentsegment).Altitudeft;
                         q = mission_obj.missiondata.(currentsegment).qlbfft2;
                         a = mission_obj.missiondata.(currentsegment).afts;
                         if (i>1)
                              CL_array(i) = aero_obj.CL(W_array(i-1), q, geometry_obj.mainwings.S_ref);
                         elseif (i==1)
                              CL_array(i) = aero_obj.CL(W_array(i), q, geometry_obj.mainwings.S_ref);
                         end

                         CD0_components = aero_obj.get_CD0([M, alt], design, geometry_obj, S_ref, propulsion_obj);
                         % CD0_components = CD0_components*10; % If you
                         % multiply the CD0 by 10, you get a weight value
                         % extremely close to the F16's.
                         if (M>=1.0)
                              CD0_wave = aero_obj.compute_CD0_wave(M, geometry_obj.mainwings.LE_sweep, geometry_obj.A_max, geometry_obj.design.total_length, geometry_obj.mainwings.S_ref);

                              CD0_array(i) = CD0_wave + CD0_components + aero_obj.CD0_LandP.total + aero_obj.CD0_misc.total;
                         elseif (0.8 <= M) && (M < 1.0) % Transonic
                              CD0_wave = aero_obj.compute_CD0_wave(M, geometry_obj.mainwings.LE_sweep, geometry_obj.A_max, geometry_obj.design.total_length, geometry_obj.mainwings.S_ref);

                              CD0_array(i) = (real(CD0_wave) + CD0_components + aero_obj.CD0_LandP.total + aero_obj.CD0_misc.total)/4;
                              % Raymer indicates it's a good idea to interpolate or take
                              % the average around here.
                         else
                              CD0_array(i) = CD0_components + aero_obj.CD0_LandP.total + aero_obj.CD0_misc.total;
                         end
                         cl_alpha = aero_obj.get_cl_alpha(M);
                         CL_alpha = aero_obj.get_CL_alpha(M, cl_alpha, geometry_obj.mainwings.AR, geometry_obj.mainwings.S_exposed, geometry_obj.mainwings.S_ref, aero_obj.F, geometry_obj.mainwings.QC_sweep);
                         CL_minD = aero_obj.get_CL_minD(CL_alpha, aero_obj.alpha_L0);

                         IsDryOrWet = mission_obj.missiondata.(currentsegment).DryOrWet;
                         if (IsDryOrWet == "Dry")
                              TSFC = propulsion_obj.get_TSFC([M, alt], IsDryOrWet, t_SL_dry, TSFC_sl_perhour_dry, E_dry, F1_dry, F2_dry, TR);
                         elseif (IsDryOrWet == "Wet")
                              TSFC = propulsion_obj.get_TSFC([M, alt], IsDryOrWet, t_SL_wet, TSFC_sl_perhour_wet, E_wet, F1_wet, F2_wet, TR);
                         end
                    end

                    if (currentsegment == "startup") || (currentsegment == "Startup")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_startup(W_array(i));
                    elseif (currentsegment == "taxi") || (currentsegment == "Taxi")
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_taxi(W_array(i-1));
                    elseif (currentsegment == "takeoff") || (currentsegment == "Takeoff")
                         e_osw = aero_obj.e_osw_TO;
                         aero_obj.K1 = aero_obj.compute_K1(M, geometry_obj.mainwings.AR, e_osw, geometry_obj.mainwings.LE_sweep);
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_takeoff(W_array(i-1));
                         CDi_array(i) = aero_obj.get_CDi([M, alt], geometry_obj.mainwings.S_ref, e_osw, geometry_obj.mainwings.AR, W_array(i));
                         CD_array(i) = aero_obj.get_CD(CD0_array(i), CDi_array(i), CL_array(i), CL_minD, aero_obj.airfoiltype, [M, alt], aero_obj.K1);

                    elseif (currentsegment == "climb") || (currentsegment == "Climb")
                         e_osw = aero_obj.e_osw_clean;
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_climb(W_TO, W_array(i-1), M, S_ref, CD0_array(i), e_osw, AR, TSFC, alt, T0);

                         aero_obj.K1 = aero_obj.compute_K1(M, geometry_obj.mainwings.AR, e_osw, geometry_obj.mainwings.LE_sweep);
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_climb(W_TO, W_array(i-1), M, S_ref, CD0_array(i), e_osw, AR, TSFC, alt, T0);
                         CDi_array(i) = aero_obj.get_CDi([M, alt], geometry_obj.mainwings.S_ref, e_osw, geometry_obj.mainwings.AR, W_array(i));
                         CD_array(i) = aero_obj.get_CD(CD0_array(i), CDi_array(i), CL_array(i), CL_minD, aero_obj.airfoiltype, [M, alt], aero_obj.K1);

                    elseif (currentsegment == "cruise") || (currentsegment == "Cruise")
                         e_osw = aero_obj.e_osw_clean;
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_cruise(W_array(i-1), TSFC, mission_obj.missiondata.Cruise.Rangeft, M, a, q, CD0_array(i), e_osw, AR, S_ref);

                         CDi_array(i) = aero_obj.get_CDi([M, alt], geometry_obj.mainwings.S_ref, e_osw, geometry_obj.mainwings.AR, W_array(i));
                         aero_obj.K1 = aero_obj.compute_K1(M, geometry_obj.mainwings.AR, e_osw, geometry_obj.mainwings.LE_sweep);
                         CD_array(i) = aero_obj.get_CD(CD0_array(i), CDi_array(i), CL_array(i), CL_minD, aero_obj.airfoiltype, [M, alt], aero_obj.K1);
                    elseif (currentsegment == "dash") || (currentsegment == "Dash")
                         e_osw = aero_obj.e_osw_clean;
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_dash(W_array(i-1), S_ref, W_TO, q, CD0_array(i), e_osw, AR, TSFC, mission_obj.missiondata.Dash.Rangeft, M * a);

                         CDi_array(i) = aero_obj.get_CDi([M, alt, 0], geometry_obj.mainwings.S_ref, e_osw, geometry_obj.mainwings.AR, W_array(i));
                         aero_obj.K1 = aero_obj.compute_K1(M, geometry_obj.mainwings.AR, e_osw, geometry_obj.mainwings.LE_sweep);
                         CD_array(i) = aero_obj.get_CD(CD0_array(i), CDi_array(i), CL_array(i), CL_minD, aero_obj.airfoiltype, [M, alt], aero_obj.K1);
                    elseif (currentsegment == "combat") || (currentsegment == "Combat")
                         e_osw = aero_obj.e_osw_clean; % YOU SHOULD ABSOLUTELY USE THE COMBAT SLAT CONFIGURATION FOR THIS
                         CDi_array(i) = aero_obj.get_CDi([M, alt], geometry_obj.mainwings.S_ref, e_osw, geometry_obj.mainwings.AR, W_array(i));
                         aero_obj.K1 = aero_obj.compute_K1(M, geometry_obj.mainwings.AR, e_osw, geometry_obj.mainwings.LE_sweep);
                         CD_array(i) = aero_obj.get_CD(CD0_array(i), CDi_array(i), CL_array(i), CL_minD, aero_obj.airfoiltype, [M, alt], aero_obj.K1);
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_combat(W_array(i-1), mission_obj.missiondata.Combat.Timemin, TSFC, mission_obj.missiondata.Combat.PayloadDroplbf, CD0_array(i), e_osw, AR, W_TO, q, S_ref);
                    elseif (currentsegment == "loiter") || (currentsegment == "Loiter")
                         e_osw = aero_obj.e_osw_TO;
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_loiter(W_TO, W_array(i-1), S_ref, q, CD0_array(i), e_osw, AR, mission_obj.missiondata.Loiter.Timemin, TSFC);

                         CDi_array(i) = aero_obj.get_CDi([M, alt], geometry_obj.mainwings.S_ref, e_osw, geometry_obj.mainwings.AR, W_array(i));
                         aero_obj.K1 = aero_obj.compute_K1(M, geometry_obj.mainwings.AR, e_osw, geometry_obj.mainwings.LE_sweep);
                         CD_array(i) = aero_obj.get_CD(CD0_array(i), CDi_array(i), CL_array(i), CL_minD, aero_obj.airfoiltype, [M, alt], aero_obj.K1);
                    elseif (currentsegment == "landing") || (currentsegment == "Landing")
                         e_osw = aero_obj.e_osw_L;
                         [W_array(i), fuelburnedarray(i)] = MissionAnalysisLevel3.segment_landing(W_array(i-1), W_TO);

                         CDi_array(i) = aero_obj.get_CDi([M, alt], geometry_obj.mainwings.S_ref, e_osw, geometry_obj.mainwings.AR, W_array(i));
                         aero_obj.K1 = aero_obj.compute_K1(M, geometry_obj.mainwings.AR, e_osw, geometry_obj.mainwings.LE_sweep);
                         CD_array(i) = aero_obj.get_CD(CD0_array(i), CDi_array(i), CL_array(i), CL_minD, aero_obj.airfoiltype, [M, alt], aero_obj.K1);
                    elseif (currentsegment == "descent") || (currentsegment == "Descent")
                         % Not implemented yet
                    elseif (currentsegment == "meta")
                         % Loop complete
                    else
                         error("Couldn't identify mission segment name. (Startup, Taxi, Takeoff, Climb, Cruise, Dash, Combat, Loiter, Landing).")
                    end
               end
               total_fuel_used = sum(fuelburnedarray);
               mission_obj.mission_fuel = fuelburnedarray;
               fuel_fraction = total_fuel_used * 1.06 / W_TO;
          end
     end

     methods (Access = private)
          % Generate mission state vector
          function state_vector = generate_mission_states(mission_obj)
               % State vector = [Mach, altitude, alpha, instantaneous weight] (per segment)
               segment_names = fieldnames(mission_obj.missiondata);
               segment_count = length(segment_names);
               state_vector = zeros(2, segment_count-1); % Trim the last column because it's just "meta"

               % Extract Mach number & altitude from each segment
               for i=1:segment_count-1
                    segment_name = segment_names{i};
                    state_vector(1,i) = mission_obj.missiondata.(segment_name).MachNumber;
                    state_vector(2,i) = mission_obj.missiondata.(segment_name).Altitudeft;
               end
          end
     end
end