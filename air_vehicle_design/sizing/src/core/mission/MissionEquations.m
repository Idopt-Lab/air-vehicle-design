classdef MissionEquations
%MISSIONEQUATIONS  Low-level, cited mission-fuel math shared across fidelities.
%
%   A static toolbox (never instantiated), the mission analogue of the
%   discipline L-toolboxes (AeroL1, PropL2, ...). Holds only the closed-form,
%   textbook-cited pieces that both the L1 (Breguet + Roskam-fraction) and L2
%   (Brandt master-equation) segment classes reuse:
%     - Breguet range / endurance weight-fraction forms (Roskam Part I),
%     - the afterburner TSFC blend + an installed/AB/degrade TSFC selector that
%       adapts to whatever the injected propulsion object actually exposes,
%     - Roskam Table 2.1 mission-phase fixed fuel fractions + the canonical
%       aircraft_category -> table-row-name translation.
%
%   It holds NO discipline data: CL/CD come from the injected aero object's own
%   compute_CL/compute_CD, TSFC and thrust lapse from the injected prop object.

    properties (Constant)
        %NM_TO_FT  Nautical-mile-to-foot conversion, Brandt/Casey convention.
        %   Brandt-F16-A.xls and BrandtMission.m use 6080 ft/nm (not the 6076.12
        %   international value); the CAP profile ranges were back-converted from
        %   the sheet's raw-ft figures at 6080, so use 6080 for round-trip parity.
        NM_TO_FT = 6080.0
    end

    methods (Static)

        function wf = breguet_range_wf(tsfc_per_hr, range_ft, v_fts, LD)
        %BREGUET_RANGE_WF  Cruise/dash segment weight fraction W_end/W_start.
        %   [Roskam, Airplane Design Part I, Eq. 2.10]:
        %     R = (V / c_j) (L/D) ln(W_start/W_end)
        %   solved for the fraction, with the segment time t = R/V:
        %     W_end/W_start = exp( -c_j * (R/V) / (L/D) ).
        %   c_j is TSFC [1/hr]; R [ft] and V [ft/s] give R/V [s], /3600 -> [hr].
            arguments
                tsfc_per_hr (1,1) double
                range_ft    (1,1) double {mustBeNonnegative}
                v_fts       (1,1) double {mustBePositive}
                LD          (1,1) double {mustBePositive}
            end
            t_hr = (range_ft / v_fts) / 3600;
            wf   = exp(-tsfc_per_hr * t_hr / LD);
        end

        function wf = breguet_endurance_wf(tsfc_per_hr, time_min, LD)
        %BREGUET_ENDURANCE_WF  Loiter/combat segment weight fraction W_end/W_start.
        %   [Roskam, Airplane Design Part I, Eq. 2.12]:
        %     E = (1 / c_j) (L/D) ln(W_start/W_end)
        %   solved for the fraction:
        %     W_end/W_start = exp( -c_j * E / (L/D) ),  E [hr] = time_min/60.
            arguments
                tsfc_per_hr (1,1) double
                time_min    (1,1) double {mustBeNonnegative}
                LD          (1,1) double {mustBePositive}
            end
            wf = exp(-tsfc_per_hr * (time_min / 60) / LD);
        end

        function cT = select_tsfc(prop, state, percent_ab)
        %SELECT_TSFC  Effective TSFC [1/hr] at a flight state and AB setting,
        %   adapting to what the injected propulsion object exposes.
        %
        %   Dry/mil basis: the installed value (compute_TSFC_installed) if the
        %   prop provides one, else the plain get_TSFC (PropulsionBase contract).
        %   Afterburner (percent_ab > 0): blended with the AB TSFC
        %     cT = cT_dry + (percent_ab/100) * (cT_ab - cT_dry)
        %   [the Brandt Miss-tab blend, readme_mission.md], using the installed
        %   AB value if available, else the uninstalled AB value, else -- when the
        %   prop has no afterburner model at all (F16PropL1) -- degrading to the
        %   dry value. The degrade case is reported so the comparison report can
        %   flag it; it is NOT silently equated to full mil fuel.
            cT_dry = MissionEquations.dry_tsfc(prop, state);
            if percent_ab <= 0
                cT = cT_dry;
                return
            end
            cT_ab = MissionEquations.ab_tsfc(prop, state, cT_dry);
            cT = cT_dry + (percent_ab / 100) * (cT_ab - cT_dry);
        end

        function tf = has_ab_model(prop)
        %HAS_AB_MODEL  True if the prop exposes any afterburner TSFC method.
            tf = ismethod(prop, 'compute_TSFC_AB_installed') ...
                || ismethod(prop, 'compute_TSFC_AB');
        end

        function wf = roskam_fixed_fraction(aircraft_category, phase)
        %ROSKAM_FIXED_FRACTION  Mission-phase fuel-weight fraction W_end/W_start
        %   for a constant-fraction segment.
        %   [Roskam, Airplane Design Part I, Table 2.1, p.12, fighter row].
        %   Climb is the mean of Roskam's 0.90-0.96 range (= 0.93). The canonical
        %   aircraft_category selects the row via to_roskam_row (Roskam prints
        %   'fighter'); do not rename the row to match the key.
            row   = MissionEquations.to_roskam_row(aircraft_category);
            phase = lower(string(phase));
            switch row
                case "fighter"
                    switch phase
                        case "startup", wf = 0.990;   % engine start / warm-up
                        case "taxi",    wf = 0.990;
                        case "takeoff", wf = 0.990;
                        case "climb",   wf = 0.93;    % mean of Roskam 0.90-0.96
                        case "descent", wf = 0.990;
                        case "landing", wf = 0.995;   % landing, taxi-back, shutdown
                        otherwise
                            error('MissionEquations:unknownPhase', ...
                                ['No Roskam Table 2.1 fixed fuel fraction for phase ', ...
                                 '"%s" (fighter row).'], phase);
                    end
                otherwise
                    error('MissionEquations:unsupportedCategory', ...
                        ['Roskam Table 2.1 fixed fractions are implemented only for ', ...
                         'the fighter row; category "%s" (row "%s") is not supported.'], ...
                        aircraft_category, row);
            end
        end

        function row = to_roskam_row(aircraft_category)
        %TO_ROSKAM_ROW  Translate the canonical aircraft_category flag to the row
        %   name Roskam Part I Table 2.1/2.2 actually prints. Mirrors
        %   AeroL1.to_CLmax_table_row: the row name is the textbook's, not the key.
            switch lower(string(aircraft_category))
                case {"jet_fighter", "fighter"}
                    row = "fighter";
                otherwise
                    error('MissionEquations:unknownCategory', ...
                        ['No Roskam Table 2.1/2.2 row mapping for aircraft_category ', ...
                         '"%s". Only jet_fighter is implemented.'], aircraft_category);
            end
        end

        function a = select_alpha(prop, state, percent_ab)
        %SELECT_ALPHA  Thrust lapse alpha (normalized to the AB SLS thrust T_SL)
        %   at a flight state and AB setting, blended by percent_ab:
        %     alpha = alpha_mil + (percent_ab/100) * (alpha_AB - alpha_mil)
        %   [Brandt Miss-tab run(alt,M,pct/100).alpha_AB_ref blend]. alpha_mil is
        %   thrust_lapse_mil_on_AB_scale (mil power on the AB scale), alpha_AB is
        %   thrust_lapse (full AB). T_available = T_SL * alpha (no *n_engines --
        %   T_SL is already the total AB thrust and alpha is total-normalized).
            a_mil = prop.thrust_lapse_mil_on_AB_scale(state);
            if percent_ab <= 0
                a = a_mil;
                return
            end
            a_ab = prop.thrust_lapse(state);
            a = a_mil + (percent_ab / 100) * (a_ab - a_mil);
        end

    end

    methods (Static, Access = private)

        function cT = dry_tsfc(prop, state)
            if ismethod(prop, 'compute_TSFC_installed')
                cT = prop.compute_TSFC_installed(state);
            else
                cT = prop.get_TSFC(state);
            end
        end

        function cT = ab_tsfc(prop, state, cT_dry_fallback)
            if ismethod(prop, 'compute_TSFC_AB_installed')
                cT = prop.compute_TSFC_AB_installed(state);
            elseif ismethod(prop, 'compute_TSFC_AB')
                cT = prop.compute_TSFC_AB(state);
            else
                cT = cT_dry_fallback;   % no AB model (F16PropL1) -> degrade to mil
            end
        end

    end

end
