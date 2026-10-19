function crosscheck = crosscheck_framework()
%CROSSCHECK_FRAMEWORK  Compare the lesson helpers with the sizing framework.
%
%   crosscheck = CROSSCHECK_FRAMEWORK() runs the 737 MAX 8 baseline through
%   the lesson helpers (student_package/helpers, SI) and through the
%   matching static methods of the course sizing framework (sizing/src,
%   English units), and returns one table row per equation.
%
%   INSTRUCTOR ONLY. This file is not in the student package. It needs the
%   Aerospace Toolbox: the framework's AircraftState uses atmosisa.
%
%   TODO (Casey): run this function and review FRAMEWORK_FINDINGS.md. Two
%   codes that implement the same printed equation must give the same
%   number. The "Reason" column gives the known cause of each difference;
%   FRAMEWORK_FINDINGS.md has the equation and page for each one. Any
%   framework fix is a change to sizing/src and needs approval first; this
%   lesson does not change src/.
%
%   The SI inputs are converted to English units at the call
%   (1 ft = 0.3048 m exactly).

    here   = fileparts(mfilename('fullpath'));       % .../sizing/teaching/aero-wing-design
    sizing = fileparts(fileparts(here));             % .../air_vehicle_design/sizing
    pkg    = fullfile(here, 'student_package');
    assert(isfolder(fullfile(sizing, 'src')), 'crosscheck_framework:badRoot', ...
        'Expected the sizing framework at %s.', fullfile(sizing, 'src'));
    assert(exist('atmosisa', 'file') > 0, 'crosscheck_framework:noAerospaceToolbox', ...
        'The framework''s AircraftState needs the Aerospace Toolbox (atmosisa).');

    oldPath = path;
    cleaner = onCleanup(@() path(oldPath)); %#ok<NASGU>
    addpath(pkg);  setup_aero_path();
    addpath(genpath(fullfile(sizing, 'src')));

    ac = b737_baseline();  o3 = aero_737(ac, 3);  p = o3.planform;
    ft = 0.3048;  ft2 = ft^2;  ft3 = ft^3;
    D  = sqrt(ac.fus_w*ac.fus_h);
    st = AircraftState(ac.H_cruise/ft, ac.M_cruise);                  % framework atmosphere

    R = cell(0, 4);      % one row per check: quantity, lesson, framework, reason
    R(end+1,:) = {"span b (m)  [R Eq. 7.5]", ...
        p.b, GeometryBase.compute_span(ac.AR, ac.S/ft2)*ft, "same"};
    R(end+1,:) = {"root chord (m)  [R Eq. 7.6]", ...
        p.c_root, GeometryBase.compute_root_chord(ac.S/ft2, p.b/ft, ac.lambda)*ft, "same"};
    R(end+1,:) = {"MAC (m)  [R Eq. 7.8]", ...
        p.MAC, GeometryBase.compute_mac(p.c_root/ft, ac.lambda)*ft, "same"};
    Re_lesson = o3.atm.rho*o3.V*p.MAC/o3.atm.mu;
    Re_fw     = AeroL2.compute_Re(st, p.MAC/ft);
    R(end+1,:) = {"wing Re on the MAC  [R Eq. 12.25]", ...
        Re_lesson, Re_fw, "atmosisa vs. isa_si; Sutherland constants"};
    R(end+1,:) = {"C_f turbulent  [N Eqs. 2.22, 2.25 = R Eq. 12.27]", ...
        skin_friction(Re_lesson, ac.M_cruise, p.MAC, ac.k_rough), AeroL2.Cf_turbulent(Re_lesson, ac.M_cruise), ...
        "same (cut-off not active)"};
    R(end+1,:) = {"FF wing  [R Eq. 12.30]", ...
        form_factor("surface", ac.tc, ac.xc_m, p.sweep_maxt, ac.M_cruise), ...
        AeroL3.FF_surface(ac.tc, ac.xc_m, p.sweep_maxt, ac.M_cruise), "same"};
    R(end+1,:) = {"FF fuselage  [R Eq. 12.31]", ...
        form_factor("body", ac.fus_l/D), AeroL3.FF_body(ac.fus_l, D), ...
        "framework: prior-edition form 1 + 60/f^3 + f/400"};
    cla  = ac.cla2d*180/pi;  beta = sqrt(1 - ac.M_cruise^2);
    F    = 1.07*(1 + D/p.b)^2;                                        % R Eq. 12.9
    [CLa_R, info] = cl_alpha_raymer(o3.A_eff, ac.M_cruise, p.sweep_maxt, o3.eta, p.S_exp/ac.S, D/p.b);
    R(end+1,:) = {"C_L alpha (per rad)  [R Eq. 12.6]", CLa_R, ...
        AeroL2.CL_alpha(o3.A_eff, p.sweep_maxt, ac.M_cruise, p.S_exp/ft2, ac.S/ft2, F, cla/beta), ...
        sprintf("framework does not limit (S_exp/S)F = %.2f to 0.98", info.SF)};
    R(end+1,:) = {"e, Raymer fits  [R Eqs. 12.48, 12.49]", ...
        oswald_raymer(o3.A_eff, p.sweep_LE), AeroL2.oswald_eff(o3.A_eff, p.sweep_LE), ...
        "framework: Eq. 12.48 only below 30 deg (no interpolation)"};
    R(end+1,:) = {"C_L max clean  [R Eq. 12.15]", ...
        clmax_wing("raymer12_15", ac.clmax2d, ac.sweep_c4), AeroL2.CLmax_clean(ac.clmax2d, ac.sweep_c4), "same"};
    R(end+1,:) = {"wing fuel volume (m^3)  [Roskam Eq. 6.2]", ...
        o3.V_wing, SubsystemsL2.compute_wing_fuel_volume_roskam(ac.S/ft2, p.b/ft, ac.tc, ac.tc, ac.lambda)*ft3, "same"};
    % The framework has no transport wing-weight equation (R Eq. 15.25), so
    % the lesson's wing_weight_raymer has nothing to compare with.

    lesson = [R{:,2}]';  framework = [R{:,3}]';
    crosscheck = table(string(R(:,1)), lesson, framework, round(100*(framework./lesson - 1), 3), string(R(:,4)), ...
        'VariableNames', ["Quantity", "Lesson_SI", "Framework_SI", "Difference_pct", "Reason"]);
    if nargout == 0
        disp(crosscheck);
        clear crosscheck
    end
end
