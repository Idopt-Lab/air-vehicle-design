function make_matlab_figures(outDir)
%MAKE_MATLAB_FIGURES  Render the plots the written guide embeds.
%
%   MAKE_MATLAB_FIGURES(outDir) writes PNG files into outDir. Run it from
%   anywhere; it finds and uses the built package in ../student_package.
%
%   Called by guide_src/build_guide.sh, so the guide never embeds a figure
%   that the code does not currently produce.

    arguments
        outDir (1,1) string = ""
    end

    here = fileparts(mfilename('fullpath'));
    pkg  = fullfile(fileparts(here), 'student_package');
    if outDir == ""
        outDir = fullfile(here, 'figures_matlab');
    end
    if ~isfolder(outDir), mkdir(outDir); end
    if ~isfolder(fullfile(pkg, 'framework'))
        error('make_matlab_figures:noPackage', ...
            ['The package framework is not built yet. Run ', ...
             'make_student_package(''steps'', "framework") first.']);
    end

    oldPath = path;  oldDir = pwd;
    cleanup = onCleanup(@() restore_state(oldPath, oldDir)); %#ok<NASGU>
    addpath(pkg);  cd(pkg);
    setup_sizing_path();

    % ---- the fixed-point / cobweb map, Boeing 777 -----------------------
    [aero, prop, wts, geom, miss, con] = build_b777_stack(); %#ok<ASGLU>
    [WS, TW] = con.optimal_point_continuous();

    fig = plot_cobweb(@build_b777_stack, WS, TW, ...
                      linspace(620e3, 900e3, 29), 700e3, 0.5, 10);
    exportgraphics(fig, fullfile(outDir, 'cobweb_b777.png'), 'Resolution', 200);
    close(fig);
    fprintf('wrote cobweb_b777.png\n');

    % ---- iteration history, F-16A: the aircraft where everything couples --
    T16 = trace_sizing_L2(@build_f16_stack_L2, 30000, 20000);

    fig = plot_sizing_history(T16, "F-16A");
    exportgraphics(fig, fullfile(outDir, 'history_f16.png'), 'Resolution', 150);
    close(fig);
    fprintf('wrote history_f16.png\n');

    fig = plot_weight_history(T16, "F-16A");
    exportgraphics(fig, fullfile(outDir, 'weights_f16.png'), 'Resolution', 150);
    close(fig);
    fprintf('wrote weights_f16.png\n');

    fig = plot_what_changed(T16, "F-16A, SizingLoopL2");
    exportgraphics(fig, fullfile(outDir, 'changed_f16.png'), 'Resolution', 150);
    close(fig);
    fprintf('wrote changed_f16.png\n');

    % ---- and the 777, where the tail resize turns out to be write-only ----
    T77 = trace_sizing_L2(@build_b777_stack, 700000, 200000, ...
                          'state', AircraftState(40000, 0.85));

    fig = plot_what_changed(T77, "B777-200LR, SizingLoopL2");
    exportgraphics(fig, fullfile(outDir, 'changed_b777.png'), 'Resolution', 150);
    close(fig);
    fprintf('wrote changed_b777.png\n');
end

function restore_state(p, d)
    path(p);  cd(d);  close all force
end
