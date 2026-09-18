%% sensitivity of the converged answer to the UNCITED modelling choices
clear; clc
warning('off','TtpaProp:BhpOutOfRange');
p = ttpa_requirements_path();
base = fileread(p);
J0 = jsondecode(base);

o.W_TO_guess=5000; o.design_point_mode="selected"; o.tol_rel=1e-6; o.max_iter=200;
o.relax_W=0.5; o.relax_P=0.5;
o.WS_sweep=linspace(J0.constraints.wing_loading_range_psf(1), ...
                    J0.constraints.wing_loading_range_psf(2), ...
                    J0.constraints.wing_loading_points);
o.selected.WS=J0.constraints.design_point.wing_loading_psf;
o.selected.WP=J0.constraints.design_point.power_loading_lb_per_hp;

tmp = fullfile(tempdir,'ttpa_sens.json');

    function r = runwith(J, tmp, o)
        fid=fopen(tmp,'w'); fwrite(fid, jsonencode(J)); fclose(fid);
        prop=TtpaProp(tmp); geom=TtpaGeom(tmp,prop); aero=TtpaAero(tmp,geom);
        wts=TtpaWeights(tmp,geom,prop);
        miss=MissionProfileReader.read_profile(tmp,'std_mission');
        cons=ConstraintSetImporter.read_conditions(tmp);
        obj=struct('aero',aero,'prop',prop,'wts',wts,'geom',geom,'miss',miss,'cons',cons);
        r=sizing_loop(obj,o);
    end

r0 = runwith(J0, tmp, o);
fprintf('BASELINE                       W_TO %8.1f  CD0 %.5f  OEW %7.1f  S_ref %6.2f\n\n', ...
        r0.W_TO, r0.CD0, r0.W_OEW, r0.S_ref);

show = @(lbl,r) fprintf('%-30s W_TO %8.1f (%+5.2f%%)  CD0 %.5f (%+5.2f%%)\n', ...
    lbl, r.W_TO, 100*(r.W_TO-r0.W_TO)/r0.W_TO, r.CD0, 100*(r.CD0-r0.CD0)/r0.CD0);

fprintf('--- 1. nacelle length factor (baseline 2.0, UNCITED) ---\n');
for k = [1.5 1.75 2.25 2.5]
    J=J0; J.geometry.nacelle.length_over_engine_length=k;
    show(sprintf('  k_nacelle = %.2f',k), runwith(J,tmp,o));
end

fprintf('\n--- 2. nacelle diameter (baseline 2.8, Raymer 10.4 range 2.6-2.8) ---\n');
for k = [2.6 2.7]
    J=J0; J.geometry.nacelle.diameter_ft=k;
    show(sprintf('  d_nacelle = %.2f ft',k), runwith(J,tmp,o));
end

fprintf('\n--- 3. tail-cone closure (baseline 0.5 x 0.5 ft, ASSUMED) ---\n');
for k = [0.0 1.0 1.5]
    J=J0; J.geometry.fuselage.tailcone_end_width_ft=k;
         J.geometry.fuselage.tailcone_end_height_ft=k;
    show(sprintf('  cone end = %.1f x %.1f ft',k,k), runwith(J,tmp,o));
end

fprintf('\n--- 4. fuselage nose/cabin split (baseline 8.2/9.0, total 31.6 FIXED) ---\n');
for nl = [6.2 7.2 9.2 10.2]
    J=J0; J.geometry.fuselage.nose_length_ft=nl;
         J.geometry.fuselage.constant_length_ft=31.6-14.4-nl;
    show(sprintf('  nose %.1f / cabin %.1f ft',nl,31.6-14.4-nl), runwith(J,tmp,o));
end

fprintf('\n--- 5. Cfe (baseline 0.0045 light TWIN; 0.0055 is the SINGLE row) ---\n');
for k = [0.0040 0.0050 0.0055]
    J=J0; J.aerodynamics.Cfe=k;
    show(sprintf('  Cfe = %.4f',k), runwith(J,tmp,o));
end

fprintf('\n--- 6. fuel density only affects the POST-convergence volume check ---\n');
g = r0;
for d = [44.9 47.8]
    V = 34.7913;  % ft^3 at the converged wing
    fprintf('  rho_fuel %.1f lb/ft^3 -> capacity %6.0f lbf vs %4.0f needed, %+3.0f%% spare\n', ...
            d, V*d, r0.W_fuel, 100*(V*d-r0.W_fuel)/r0.W_fuel);
end

delete(tmp);
fprintf('\nSENSITIVITY COMPLETE\n');
