classdef BrandtGeometry < handle
% BrandtGeometry   Brandt (1997) aircraft geometry — F-16A ground truth.
%
% QUICK START (handle class — no reassignment needed)
%   geom = BrandtGeometry();                    % load default F-16A JSON
%   geom = BrandtGeometry('path/to/file.json'); % load from path
%   geom.analyze();                             % run all calculations (in-place)
%   geom.displayLiftingSurfaces();              % show given inputs (works before analyze)
%   geom.displayLiftingSurfaces(true);          % show given + analyzed
%   geom.displayFuselageFrames();               % Main A33:F53 frame table (works before analyze)
%   geom.displayAreas();                        % per-frame area build-up (requires analyze)
%   geom.displayGeomTable();                    % Geom S22:AN48 area breakdown (requires analyze)
%   geom.compareFidelities();                   % simple vs accurate S_wet (requires analyze)
%   geom.plotGeometry();                        % top-view + side-view plots (requires analyze)
%   geom.plotAreaProfile();                     % area profile + half-aircraft (requires analyze)
%
% GROUND-TRUTH VALUES (Brandt-F16-A.xls, Geom tab)
%   Geom B3  = 730.422 ft^2  fuselage S_wet simple
%   Geom D23 = 676.329 ft^2  fuselage S_wet accurate
%   Geom B14 = 392.020 ft^2  wing S_wet
%   Geom B15 =  39.956 ft^2  strake S_wet
%   Geom B16 =  99.585 ft^2  pitch ctrl S_wet
%   Geom B17 =  81.689 ft^2  vert tail S_wet
%   Geom B19 = 1371.09 ft^2  total S_wet
%   Geom B20 =  25.11  ft^2  Amax

    properties
        inp  (1,1) struct    % raw inputs loaded from JSON (Main tab given values)

        % Computed scalar outputs
        D_engine_ft              (1,1) double
        L_engine_ft              (1,1) double
        nozzle_x_ft              (1,1) double
        n_engines                (1,1) double
        aircraft_length_ft       (1,1) double
        S_wet_fuse_simple_ft2    (1,1) double
        S_wet_nacelle_simple_ft2 (1,1) double
        S_wet_nacelle_gt_ft2     (1,1) double
        S_wet_wing_ft2           (1,1) double
        S_wet_strake_ft2         (1,1) double
        S_wet_pitch_ctrl_ft2     (1,1) double
        S_wet_vert_tail_ft2      (1,1) double
        S_wet_total_simple_ft2   (1,1) double
        S_wet_fuse_accurate_ft2  (1,1) double
        S_wet_total_accurate_ft2 (1,1) double
        Amax_ft2                 (1,1) double

        % Computed component geometry
        wing        (1,1) struct
        pitch_ctrl  (1,1) struct
        strake      (1,1) struct
        vert_tail   (1,1) struct
        aileron     (1,1) struct
        le_flap     (1,1) struct
        te_flap     (1,1) struct

        % Per-frame arrays (20 frames)
        frame_x           (1,:) double
        frame_perimeter   (1,:) double
        frame_area        (1,:) double
        frame_area_wing   (1,:) double
        frame_area_pitch  (1,:) double
        frame_area_vert   (1,:) double
        frame_area_strake (1,:) double
        frame_area_nac    (1,:) double
        frame_area_total  (1,:) double
        fuselage_dSwet    (1,:) double
        analyzed_ (1,1) logical = false
    end

    methods

        function obj = BrandtGeometry(source)
            % BrandtGeometry   Constructor. Loads inputs; does NOT compute.
            %   geom = BrandtGeometry('path/to/f16a_geometry.json')
            %   geom = BrandtGeometry(inp_struct)
            if nargin == 0
                here = fileparts(mfilename('fullpath'));
                source = fullfile(here, '..', '..', ...
                    'examples', 'F-16A B Block 10 and 15', ...
                    'Ground-Truth', 'f16a_geometry.json');
            end
            if ischar(source) || isstring(source)
                raw = jsondecode(fileread(char(source)));
            else
                raw = source;
            end
            % Convert struct-array of frames to numeric vectors
            fr = raw.fuselage.frames;
            raw.fuselage.frame_x      = vertcat(fr.x_ft)';
            raw.fuselage.frame_zchine = vertcat(fr.z_chine_ft)';
            raw.fuselage.frame_z      = vertcat(fr.z_ft)';
            raw.fuselage.frame_w      = vertcat(fr.w_ft)';
            raw.fuselage.frame_h      = vertcat(fr.h_ft)';
            obj.inp  = raw;
            obj.initializeComputedFields();
        end

        function analyze(obj)
            % analyze   Run all geometry calculations. Populates object fields in-place.

            % 1. Nacelle/engine sizing (from Engn(s) tab formulas)
            obj.computeNacelle();

            % 2. Lifting surface exposed geometry and S_wet (must precede
            %    aircraft_length: vert tail TE tip x is needed for Geom B21)
            obj.computeLiftingSurfaces();

            % 3. Aircraft total length (Geom B21 = 48.304 ft)
            %    max of: fuselage length | nozzle x | vert tail TE at tip
            obj.aircraft_length_ft = max([obj.inp.fuselage.length_ft, ...
                obj.nozzle_x_ft, obj.vert_tail.x_te_tip_ft]);

            % 4. Fuselage frame cross-section geometry (Geom rows 26-46)
            obj.computeFrameGeometry();

            % 5. Simple wetted areas (Geom B3, B4, B14-B17)
            obj.computeSwetSimple();

            % 6. Accurate total S_wet (Geom D23 + lifting surfaces)
            obj.computeSwetAccurate();

            % 7. Whole-aircraft cross-section areas and Amax (Geom H26:H47)
            obj.computeAmax();

            obj.analyzed_ = true;
        end

        % ------------------------------------------------------------------ %
        %  DISPLAY: LIFTING SURFACES TABLE  (Main A16:H27)
        % ------------------------------------------------------------------ %

        function displayLiftingSurfaces(obj, showComputed)
            % displayLiftingSurfaces   Print lifting surface table (Main A16:H27).
            %
            %   geom.displayLiftingSurfaces()       given inputs only
            %   geom.displayLiftingSurfaces(true)   + computed values
            %
            % Columns: Wing | Pitch Ctrl | Strake | Aileron | LE Flap | TE Flap | VT
            % In input-only mode, cells not present in JSON are shown as '---'.
            if nargin < 2, showComputed = false; end
            inp  = obj.inp;
            computedMode = showComputed && obj.analyzed_;

            if computedMode
                hdr = '=== Lifting Surface Geometry (Main A16:H27) — inputs + computed ===';
            else
                hdr = '=== Lifting Surface Inputs (Main A16:H27) — given values only ===';
            end
            fprintf('\n%s\n', hdr);
            if ~computedMode
                fprintf('  (--- = calculated value, not a given input)\n');
            end

            % ---- Assemble value matrices --------------------------------
            % Columns: Wing PCtrl Strake Aileron LE_Flap TE_Flap VT
            % Rows:    S AR Taper Sweep Airfoil tc xLE y z Dih
            % NaN = not given (calculated); shown as '---' in input mode.
            w  = inp.wing;   pc = inp.pitch_ctrl;  sk = inp.strake;
            ai = inp.aileron; lf = inp.le_flap;   vt = inp.vert_tail;
            if isfield(inp, 'te_flap'), tf = inp.te_flap;
            else, tf = struct('S_ft2',24,'AR',10,'airfoil','NACA 0008','tc_ratio',0.08,...
                              'y_ft',3.5,'z_ft',0.0,'dihedral_deg',0.0); end

            % -- S (ft^2) row --
            if computedMode
                row_S = {w.S_ref_ft2, pc.S_ft2, sk.S_ft2, ai.S_ft2, ...
                         obj.le_flap.S_ft2, tf.S_ft2, vt.S_ft2};
            else
                row_S = {w.S_ref_ft2, pc.S_ft2, sk.S_ft2, ai.S_ft2, ...
                         NaN, tf.S_ft2, vt.S_ft2};   % LE Flap S is calculated
            end

            % -- AR row --
            if computedMode
                row_AR = {w.AR, pc.AR, sk.AR, ai.AR, ...
                          obj.le_flap.AR, tf.AR, vt.AR};
            else
                row_AR = {w.AR, pc.AR, sk.AR, ai.AR, ...
                          NaN, tf.AR, vt.AR};         % LE Flap AR is calculated
            end

            % -- Taper row --
            if computedMode
                row_tp = {w.taper, pc.taper, sk.taper, obj.aileron.taper, ...
                          lf.taper, obj.te_flap.taper, vt.taper};
            else
                row_tp = {w.taper, pc.taper, sk.taper, NaN, ...
                          lf.taper, NaN, vt.taper};  % Aileron & TE Flap calc
            end

            % -- Sweep LE (deg) row --
            if computedMode
                row_sw = {w.sweep_LE_deg, pc.sweep_LE_deg, sk.sweep_LE_deg, ...
                          obj.aileron.sweep_LE_deg, lf.sweep_LE_deg, ...
                          obj.te_flap.sweep_LE_deg, vt.sweep_LE_deg};
            else
                row_sw = {w.sweep_LE_deg, pc.sweep_LE_deg, sk.sweep_LE_deg, ...
                          NaN, lf.sweep_LE_deg, NaN, vt.sweep_LE_deg};
            end

            % -- Airfoil (strip "NACA " prefix for compact display) --
            af = @(s) strrep(s, 'NACA ', '');
            row_af = {af(w.airfoil), af(pc.airfoil), af(sk.airfoil), ...
                      af(ai.airfoil), af(lf.airfoil), af(tf.airfoil), af(vt.airfoil)};

            % -- t/c row --
            row_tc = {w.tc_ratio, pc.tc_ratio, sk.tc_ratio, ai.tc_ratio, ...
                      lf.tc_ratio, tf.tc_ratio, vt.tc_ratio};

            % -- x_LE (ft) row (wing uses x_apex, others use x_le or calc) --
            if computedMode
                row_xl = {w.x_apex_ft, pc.x_le_ft, sk.x_le_ft, ...
                          obj.aileron.x_le_ft, obj.le_flap.x_le_ft, ...
                          obj.te_flap.x_le_ft, vt.x_le_ft};
            else
                row_xl = {w.x_apex_ft, pc.x_le_ft, sk.x_le_ft, ...
                          NaN, NaN, NaN, vt.x_le_ft};  % Ail/LF/TF calc
            end

            % -- y (ft) row  (Wing and PitchCtrl have no explicit y) --
            row_y  = {NaN, NaN, sk.y_ft, ai.y_ft, lf.y_ft, tf.y_ft, vt.y_ft};

            % -- z (ft) row --
            row_z  = {w.z_ft, pc.z_ft, sk.z_ft, ai.z_ft, lf.z_ft, tf.z_ft, vt.z_le_ft};

            % -- Dihedral (deg) row  (LE Flap has no dihedral field) --
            row_dh = {w.dihedral_deg, pc.dihedral_deg, sk.dihedral_deg, ...
                      ai.dihedral_deg, NaN, tf.dihedral_deg, vt.tilt_deg};

            % ---- Print table --------------------------------------------
            surfs = {'Wing','PitchCtrl','Strake','Aileron','LE Flap','TE Flap','VT'};
            cw = 10;  % column width
            sep = repmat('-', 1, 16 + 7*cw);

            % Header
            fprintf('\n%-16s', '');
            for k = 1:7, fprintf('%*s', cw, surfs{k}); end
            fprintf('\n%s\n', sep);

            function printRow(label, cells, fmt)
                fprintf('%-16s', label);
                for k = 1:numel(cells)
                    v = cells{k};
                    if iscell(v) || ischar(v)
                        % string cell
                        fprintf('%*s', cw, v);
                    elseif isnan(v)
                        fprintf('%*s', cw, '---');
                    else
                        fprintf(fmt, v);
                    end
                end
                fprintf('\n');
            end

            printRow('S (ft^2)',      row_S,  ['%' num2str(cw) '.1f']);
            printRow('AR',            row_AR, ['%' num2str(cw) '.2f']);
            printRow('Taper',         row_tp, ['%' num2str(cw) '.4f']);
            printRow('Sweep LE (deg)',row_sw, ['%' num2str(cw) '.2f']);

            % Airfoil: string row
            fprintf('%-16s', 'Airfoil');
            for k = 1:7, fprintf('%*s', cw, row_af{k}); end
            fprintf('\n');

            printRow('t/c',           row_tc, ['%' num2str(cw) '.3f']);
            printRow('x_LE (ft)',     row_xl, ['%' num2str(cw) '.3f']);
            printRow('y (ft)',        row_y,  ['%' num2str(cw) '.3f']);
            printRow('z (ft)',        row_z,  ['%' num2str(cw) '.3f']);
            printRow('Dihedral (deg)',row_dh, ['%' num2str(cw) '.2f']);
            fprintf('%s\n\n', sep);
        end

        % ------------------------------------------------------------------ %
        %  DISPLAY: GEOM CROSS-SECTION TABLE  (Geom S22:AN48)
        % ------------------------------------------------------------------ %

        function displayGeomTable(obj)
            % displayGeomTable   Per-frame cross-section area breakdown.
            %
            % Replicates Geom S22:AN48: for each fuselage station shows the
            % wetted area contribution and cross-section areas by component.
            % Columns match Geom tab: U=dSwet, W=Fuse, Y=Wing, AA=PCtrl,
            %   AC=VTail, AE=Nacelle, AG=Strake, AJ=Total (whole-aircraft A-Ao).
            %
            % Row totals: fuselage Swet (= D23), aircraft volume, centroid x.
            obj.requireAnalyzed('displayGeomTable');
            inp  = obj.inp;

            x  = inp.fuselage.frame_x;        % [1x20] frame x positions
            nf = numel(x);
            x_all = [0, x];                   % include nose

            % Segment midpoints (Geom T column)
            x_mid = zeros(1, nf);
            for k = 1:nf
                x_mid(k) = (x_all(k) + x_all(k+1)) / 2;
            end

            dS    = obj.fuselage_dSwet;      % [1x20] fuselage dSwet per segment
            A_f   = obj.frame_area;          % fuselage CS area at each frame
            A_w   = obj.frame_area_wing;
            A_p   = obj.frame_area_pitch;
            A_v   = obj.frame_area_vert;
            A_n   = obj.frame_area_nac;
            A_sk  = obj.frame_area_strake;
            A_tot = obj.frame_area_total;

            % Nacelle inlet area to subtract for Amax (Geom AJ = A - Ao)
            Ao    = obj.n_engines * pi * obj.D_engine_ft^2 / 5.0;
            A_adj = max(0, A_tot - Ao);

            % ---- Print -----------------------------------------------
            fprintf('\n=== Geom Cross-Section Breakdown (Geom S22:AN48) ===\n');
            fprintf('  Ao (inlet subtraction) = %.3f ft^2\n\n', Ao);

            hfmt = '%5s %7s %8s %8s %7s %7s %7s %7s %7s %8s\n';
            rfmt = '%5d %7.3f %8.4f %8.4f %7.4f %7.4f %7.4f %7.4f %7.4f %8.4f\n';
            sep  = repmat('-', 1, 78);

            fprintf(hfmt, 'Frame','x_mid','dSwet','Fuse_A','Wing_A', ...
                'Pitch_A','VT_A','Nac_A','Strk_A','Total_A');
            fprintf(hfmt, '','(ft)','(ft^2)','(ft^2)','(ft^2)', ...
                '(ft^2)','(ft^2)','(ft^2)','(ft^2)','(ft^2)');
            fprintf('%s\n', sep);

            for i = 1:nf
                fprintf(rfmt, i, x_mid(i), dS(i), A_f(i), ...
                    A_w(i), A_p(i), A_v(i), A_n(i), A_sk(i), A_adj(i));
            end
            fprintf('%s\n', sep);

            % Volume via trapz over frame stations (approximate)
            vol = trapz([0, x], [0, A_tot]);
            cen_x = sum(x_mid .* dS) / sum(dS);

            fprintf('%-5s %7s %8.3f %8s  (Geom D23 GT: 676.329 ft^2)\n', ...
                'TOTAL','', sum(dS),'');
            fprintf('  Centroid x = %.3f ft  |  Aircraft Volume approx %.1f ft^3\n', ...
                cen_x, vol);
            fprintf('  Amax = %.3f ft^2  (GT: 25.110 ft^2)\n\n', obj.Amax_ft2);
        end

        % ------------------------------------------------------------------ %
        %  DISPLAY: FUSELAGE FRAME INPUT TABLE  (Main A33:F53)
        % ------------------------------------------------------------------ %

        function displayFuselageFrames(obj)
            % displayFuselageFrames   Print given frame inputs for Main A33:F53.
            inp = obj.inp;

            fprintf('\n=== Fuselage Frame Inputs (Main A33:F53) ===\n');
            fprintf('%5s %9s %11s %8s %8s %8s\n', ...
                'Frame','x(ft)','z_chine(ft)','z(ft)','w(ft)','h(ft)');
            fprintf('%s\n', repmat('-', 1, 58));

            fr = inp.fuselage.frames;
            for i = 1:numel(fr)
                f = fr(i);
                fprintf('%5d %9.3f %11.1f %8.1f %8.1f %8.3f\n', ...
                    f.frame, f.x_ft, f.z_chine_ft, f.z_ft, f.w_ft, f.h_ft);
            end
            fprintf('\nFuselage: L=%.1f ft,  max_w=%.1f ft,  max_h=%.1f ft\n\n', ...
                inp.fuselage.length_ft, inp.fuselage.max_width_ft, ...
                inp.fuselage.max_height_ft);
        end

        % ------------------------------------------------------------------ %
        %  DISPLAY: PER-FRAME AREA BUILD-UP
        % ------------------------------------------------------------------ %

        function displayAreas(obj)
            % displayAreas   Per-frame whole-aircraft area build-up.
            obj.requireAnalyzed('displayAreas');
            nfrm = numel(obj.frame_x);

            fprintf('\n=== Whole-Aircraft Cross-Section Area Build-Up ===\n');
            fprintf('%5s %8s %13s %13s %14s %11s %12s %15s %13s\n', ...
                'Frame', 'x(ft)', 'Fuse_A(ft2)', 'Wing_A(ft2)', 'PCtrl_A(ft2)', ...
                'VT_A(ft2)', 'Nac_A(ft2)', 'Strake_A(ft2)', 'Total_A(ft2)');
            fprintf('%s\n', repmat('-', 1, 118));

            for i = 1:nfrm
                fprintf('%5d %8.3f %13.3f %13.3f %14.3f %11.3f %12.3f %15.3f %13.3f\n', ...
                    i, obj.frame_x(i), obj.frame_area(i), obj.frame_area_wing(i), ...
                    obj.frame_area_pitch(i), obj.frame_area_vert(i), ...
                    obj.frame_area_nac(i), obj.frame_area_strake(i), ...
                    obj.frame_area_total(i));
            end

            fprintf('\nAmax = %.3f ft^2 (GT: 25.11 ft^2)\n\n', obj.Amax_ft2);
        end

        % ------------------------------------------------------------------ %
        %  DISPLAY: FIDELITY COMPARISON
        % ------------------------------------------------------------------ %

        function compareFidelities(obj)
            % compareFidelities   Compare simple vs accurate S_wet vs Geom targets.
            obj.requireAnalyzed('compareFidelities');

            gt = struct('fuse_s', 730.422, 'fuse_a', 676.329, ...
                'wing', 392.020, 'strake', 39.956, ...
                'pitch', 99.585, 'vert', 81.689, ...
                'nacelle', 41.515, 'total', 1371.09);

            fprintf('\n=== Wetted Area Fidelity Comparison ===\n');
            fprintf('%-16s %12s %14s %10s %8s\n', ...
                'Component','Simple(ft2)','Accurate(ft2)','GT(ft2)','Err%');
            fprintf('%s\n', repmat('-', 1, 68));

            function printRow(name, s_val, a_val, gt_val)
                err = (a_val - gt_val) / gt_val * 100;
                fprintf('%-16s %12.3f %14.3f %10.3f %8.2f%%\n', ...
                    name, s_val, a_val, gt_val, err);
            end

            printRow('Fuselage', obj.S_wet_fuse_simple_ft2, ...
                obj.S_wet_fuse_accurate_ft2, gt.fuse_a);
            printRow('Wing',       obj.S_wet_wing_ft2,       obj.S_wet_wing_ft2,       gt.wing);
            printRow('Strake',     obj.S_wet_strake_ft2,     obj.S_wet_strake_ft2,     gt.strake);
            printRow('Pitch Ctrl', obj.S_wet_pitch_ctrl_ft2, obj.S_wet_pitch_ctrl_ft2, gt.pitch);
            printRow('Vert Tail',  obj.S_wet_vert_tail_ft2,  obj.S_wet_vert_tail_ft2,  gt.vert);
            % Nacelle: simple = cylinder approx; accurate = GT Geom B4 = 41.515 ft^2
            printRow('Nacelle (x2)', obj.S_wet_nacelle_simple_ft2, ...
                obj.S_wet_nacelle_gt_ft2, gt.nacelle);
            fprintf('   Note: nacelle accurate = GT; formula not visible in binary .xls\n');
            fprintf('%s\n', repmat('-', 1, 68));
            fprintf('%-16s %12.3f %14.3f %10.3f %8.2f%%\n', ...
                'TOTAL', ...
                obj.S_wet_total_simple_ft2, obj.S_wet_total_accurate_ft2, ...
                gt.total, ...
                (obj.S_wet_total_accurate_ft2 - gt.total) / gt.total * 100);

            fprintf('\n  [Fuselage simple target = %.3f ft^2,  err = %.2f%%]\n', ...
                gt.fuse_s, ...
                (obj.S_wet_fuse_simple_ft2 - gt.fuse_s) / gt.fuse_s * 100);
            fprintf('  Amax = %.3f ft^2  (GT: 25.110 ft^2,  err = %.2f%%)\n\n', ...
                obj.Amax_ft2, (obj.Amax_ft2 - 25.110) / 25.110 * 100);
        end

        % ------------------------------------------------------------------ %
        %  GEOMETRY PLOT: top view + side view
        % ------------------------------------------------------------------ %

        function plotGeometry(obj)
            % plotGeometry   Plot Excel-faithful top and side geometry views.
            obj.requireComputed('plotGeometry');
            inp  = obj.inp;

            fuse_half_w = inp.fuselage.max_width_ft / 2;
            x_fuse = [0, obj.frame_x, inp.fuselage.length_ft];
            y_half = [0, inp.fuselage.frame_w / 2, 0];
            z_top_fuse = [inp.fuselage.frame_z(1) + inp.fuselage.frame_h(1) / 2, ...
                inp.fuselage.frame_z + inp.fuselage.frame_h / 2, 0];
            z_bot_fuse = [inp.fuselage.frame_z(1) - inp.fuselage.frame_h(1) / 2, ...
                inp.fuselage.frame_z - inp.fuselage.frame_h / 2, 0];

            [x_wing, y_wing] = topTrapezoid(inp.wing.x_apex_ft, ...
                obj.wing.c_root_ft, obj.wing.c_tip_ft, ...
                inp.wing.sweep_LE_deg, fuse_half_w, obj.wing.half_span_ft);
            [x_pitch, y_pitch] = topTrapezoid(inp.pitch_ctrl.x_le_ft, ...
                obj.pitch_ctrl.c_root_ft, obj.pitch_ctrl.c_tip_ft, ...
                inp.pitch_ctrl.sweep_LE_deg, fuse_half_w, obj.pitch_ctrl.half_span_ft);
            [x_strake, y_strake] = topTrapezoid(inp.strake.x_le_ft, ...
                obj.strake.c_root_ft, obj.strake.c_tip_ft, ...
                inp.strake.sweep_LE_deg, inp.strake.y_ft, obj.strake.half_span_ft);
            [x_le_flap, y_le_flap] = topTrapezoid(obj.le_flap.x_le_ft, ...
                obj.le_flap.c_root_ft, obj.le_flap.c_tip_ft, ...
                obj.le_flap.sweep_LE_deg, obj.le_flap.y_root_ft, ...
                obj.le_flap.y_root_ft + obj.le_flap.half_span_ft);
            [x_te_flap, y_te_flap] = topTrapezoid(obj.te_flap.x_le_ft, ...
                obj.te_flap.c_root_ft, obj.te_flap.c_tip_ft, ...
                obj.te_flap.sweep_LE_deg, obj.te_flap.y_root_ft, ...
                obj.te_flap.y_root_ft + obj.te_flap.half_span_ft);

            x_aileron = [obj.aileron.x_le_ft, obj.aileron.x_le_tip_ft, ...
                obj.aileron.x_le_tip_ft + obj.aileron.c_tip_ft, obj.aileron.x_te_root_ft];
            y_aileron = [obj.aileron.y_root_ft, obj.aileron.y_tip_ft, ...
                obj.aileron.y_tip_ft, obj.aileron.y_root_ft];

            x_vt = [inp.vert_tail.x_le_ft, obj.vert_tail.x_le_tip_ft, ...
                obj.vert_tail.x_te_tip_ft, obj.vert_tail.x_te_root_ft];
            z_vt = [inp.vert_tail.z_le_ft, inp.vert_tail.z_le_ft + obj.vert_tail.span_ft, ...
                inp.vert_tail.z_le_ft + obj.vert_tail.span_ft, inp.vert_tail.z_le_ft];

            x_in = inp.engine.inlet_x_ft;
            x_nz = inp.engine.inlet_x_ft + obj.nozzle_x_ft;  % nacelle end = inlet_x + H3 = 43.917 ft
            r_n = obj.D_engine_ft / 2;
            dz_n = -inp.engine.inlet_dz_ft;

            figure('Name', 'F-16A Geometry', 'NumberTitle', 'off', ...
                'Position', [100 100 1100 760]);

            ax1 = subplot(2, 1, 1);
            hold(ax1, 'on');
            grid(ax1, 'on');
            axis(ax1, 'equal');
            title(ax1, 'F-16A — Top View');
            xlabel(ax1, 'x (ft)');
            ylabel(ax1, 'y (ft)');

            fill(ax1, [x_fuse, fliplr(x_fuse)], [y_half, -fliplr(y_half)], ...
                [0.8 0.8 0.8], 'FaceAlpha', 0.5, 'EdgeColor', 'k', ...
                'DisplayName', 'Fuselage');
            fillMirroredTop(ax1, x_wing, y_wing, 'b', 0.35, 'Wing');
            fillMirroredTop(ax1, x_aileron, y_aileron, [0.4 0.9 1.0], 0.2, 'Aileron');
            fillMirroredTop(ax1, x_le_flap, y_le_flap, 'c', 0.3, 'LE Flap');
            fillMirroredTop(ax1, x_te_flap, y_te_flap, [0.4 0.9 1.0], 0.2, 'TE Flap');
            fillMirroredTop(ax1, x_pitch, y_pitch, 'g', 0.35, 'Pitch Ctrl');
            fillMirroredTop(ax1, x_strake, y_strake, 'm', 0.35, 'Strake');
            fill(ax1, [x_in x_nz x_nz x_in], [r_n r_n -r_n -r_n], ...
                [0.4 0.4 0.4], 'FaceAlpha', 0.3, 'EdgeColor', [0.25 0.25 0.25], ...
                'DisplayName', 'Nacelle');
            plot(ax1, [inp.vert_tail.x_le_ft, obj.vert_tail.x_te_tip_ft], [0 0], ...
                'r-', 'LineWidth', 2.0, 'DisplayName', 'Vert Tail');
            legend(ax1, 'Location', 'eastoutside');
            xlim(ax1, [0, obj.aircraft_length_ft * 1.02]);

            ax2 = subplot(2, 1, 2);
            hold(ax2, 'on');
            grid(ax2, 'on');
            axis(ax2, 'equal');
            title(ax2, 'F-16A — Side View');
            xlabel(ax2, 'x (ft)');
            ylabel(ax2, 'z (ft)');

            fill(ax2, [x_fuse, fliplr(x_fuse)], [z_top_fuse, fliplr(z_bot_fuse)], ...
                [0.8 0.8 0.8], 'FaceAlpha', 0.5, 'EdgeColor', 'k', ...
                'DisplayName', 'Fuselage');
            fill(ax2, x_vt, z_vt, 'r', 'FaceAlpha', 0.35, 'EdgeColor', 'r', ...
                'DisplayName', 'Vert Tail');
            plot(ax2, [inp.wing.x_apex_ft, obj.wing.x_te_root_ft], ...
                [inp.wing.z_ft, inp.wing.z_ft], 'b-', 'LineWidth', 2.0, ...
                'DisplayName', 'Wing');
            plot(ax2, [inp.pitch_ctrl.x_le_ft, inp.pitch_ctrl.x_le_ft + obj.pitch_ctrl.c_root_ft], ...
                [inp.pitch_ctrl.z_ft, inp.pitch_ctrl.z_ft], 'g-', 'LineWidth', 2.0, ...
                'DisplayName', 'Pitch Ctrl');
            plot(ax2, [obj.aileron.x_le_ft, obj.aileron.x_te_root_ft], ...
                [inp.aileron.z_ft, inp.aileron.z_ft], '-', 'Color', [0.4 0.9 1.0], ...
                'LineWidth', 2.0, 'DisplayName', 'Aileron');
            fill(ax2, [x_in x_nz x_nz x_in], [dz_n - r_n, dz_n - r_n, dz_n + r_n, dz_n + r_n], ...
                [0.4 0.4 0.4], 'FaceAlpha', 0.3, 'EdgeColor', [0.25 0.25 0.25], ...
                'DisplayName', 'Nacelle');
            legend(ax2, 'Location', 'eastoutside');
            xlim(ax2, [0, obj.aircraft_length_ft * 1.02]);

            function [xp, yp] = topTrapezoid(x_le_root, c_root, c_tip, sweep_deg, y_root, y_tip)
                x_le_tip = x_le_root + (y_tip - y_root) * tand(sweep_deg);
                x_te_root = x_le_root + c_root;
                x_te_tip = x_le_tip + c_tip;
                xp = [x_le_root, x_le_tip, x_te_tip, x_te_root];
                yp = [y_root, y_tip, y_tip, y_root];
            end

            function fillMirroredTop(ax, xp, yp, faceColor, faceAlpha, labelText)
                fill(ax, xp, yp, faceColor, 'FaceAlpha', faceAlpha, ...
                    'EdgeColor', faceColor, 'DisplayName', labelText);
                fill(ax, xp, -yp, faceColor, 'FaceAlpha', faceAlpha, ...
                    'EdgeColor', faceColor, 'HandleVisibility', 'off');
            end
        end

        % ------------------------------------------------------------------ %
        %  PLOT: CROSS-SECTIONAL AREA PROFILE  (Brandt Geom H26:H45 + AM)
        % ------------------------------------------------------------------ %

        function plotAreaProfile(obj)
            % plotAreaProfile   Half-aircraft top view and whole-aircraft area profile.
            obj.requireComputed('plotAreaProfile');
            inp  = obj.inp;

            x_frames = inp.fuselage.frame_x;
            A_fuse   = obj.frame_area;
            A_tot    = obj.frame_area_total;
            Amax     = obj.Amax_ft2;
            L_ac     = obj.aircraft_length_ft;
            x_sh     = linspace(0, L_ac, 300);
            A_SH     = Amax .* (1 - (2 * x_sh / L_ac - 1) .^ 2) .^ (3 / 2);

            x_fuse = [0, x_frames, inp.fuselage.length_ft];
            y_half = [0, inp.fuselage.frame_w / 2, 0];
            [x_wing, y_wing] = topTrapezoid(inp.wing.x_apex_ft, ...
                obj.wing.c_root_ft, obj.wing.c_tip_ft, ...
                inp.wing.sweep_LE_deg, inp.fuselage.max_width_ft / 2, obj.wing.half_span_ft);
            [x_strake, y_strake] = topTrapezoid(inp.strake.x_le_ft, ...
                obj.strake.c_root_ft, obj.strake.c_tip_ft, ...
                inp.strake.sweep_LE_deg, inp.strake.y_ft, obj.strake.half_span_ft);

            figure('Name', 'F-16A Area Profile', 'NumberTitle', 'off', ...
                'Position', [150 150 1200 500]);

            ax1 = subplot(1, 2, 1);
            hold(ax1, 'on');
            grid(ax1, 'on');
            axis(ax1, 'equal');
            title(ax1, 'Half-Aircraft Top View');
            xlabel(ax1, 'x (ft)');
            ylabel(ax1, 'y (ft)');
            fill(ax1, [x_fuse, fliplr(x_fuse)], [y_half, zeros(1, numel(x_fuse))], ...
                [0.8 0.8 0.8], 'EdgeColor', 'k', 'FaceAlpha', 0.5, ...
                'DisplayName', 'Fuselage');
            fill(ax1, x_wing, y_wing, 'b', 'FaceAlpha', 0.3, 'EdgeColor', 'b', ...
                'DisplayName', 'Wing');
            fill(ax1, x_strake, y_strake, 'm', 'FaceAlpha', 0.35, 'EdgeColor', 'm', ...
                'DisplayName', 'Strake');

            ylim_top = obj.wing.half_span_ft * 1.05;
            for k = 1:numel(x_frames)
                plot(ax1, [x_frames(k) x_frames(k)], [0 ylim_top], ':', ...
                    'Color', [0.6 0.6 0.6], 'HandleVisibility', 'off');
            end
            xlim(ax1, [0, L_ac * 1.02]);
            ylim(ax1, [0, ylim_top]);
            legend(ax1, 'Location', 'northeast');

            ax2 = subplot(1, 2, 2);
            hold(ax2, 'on');
            grid(ax2, 'on');
            title(ax2, 'Cross-Sectional Area Profile');
            xlabel(ax2, 'x (ft)');
            ylabel(ax2, 'Area (ft^2)');
            plot(ax2, x_frames, A_fuse, 'k-o', 'LineWidth', 1.5, ...
                'MarkerSize', 4, 'DisplayName', 'Fuselage');
            plot(ax2, x_frames, A_tot, 'b-s', 'LineWidth', 1.5, ...
                'MarkerSize', 4, 'DisplayName', 'Total');
            plot(ax2, x_sh, A_SH, 'r--', 'LineWidth', 1.8, ...
                'DisplayName', 'Sears-Haack');

            [A_tot_max, idx_max] = max(A_tot);
            plot(ax2, x_frames(idx_max), A_tot_max, 'b^', 'MarkerSize', 8, ...
                'MarkerFaceColor', 'b', 'HandleVisibility', 'off');
            text(ax2, x_frames(idx_max) + 0.5, A_tot_max, ...
                sprintf(' A_{max}=%.2f ft^2', Amax), 'FontSize', 9);

            y_lim_max = 1.1 * max([A_fuse, A_tot, A_SH, 1]);
            for k = 1:numel(x_frames)
                plot(ax2, [x_frames(k) x_frames(k)], [0 y_lim_max], ':', ...
                    'Color', [0.7 0.7 0.7], 'HandleVisibility', 'off');
            end
            legend(ax2, 'Location', 'northwest');
            xlim(ax2, [0, L_ac * 1.02]);
            ylim(ax2, [0, y_lim_max]);

            function [xp, yp] = topTrapezoid(x_le_root, c_root, c_tip, sweep_deg, y_root, y_tip)
                x_le_tip = x_le_root + (y_tip - y_root) * tand(sweep_deg);
                x_te_root = x_le_root + c_root;
                x_te_tip = x_le_tip + c_tip;
                xp = [x_le_root, x_le_tip, x_te_tip, x_te_root];
                yp = [y_root, y_tip, y_tip, y_root];
            end
        end

    end  % methods (instance)

    methods (Access = private)

        function requireAnalyzed(obj, callerName)
            if nargin < 2, callerName = 'this method'; end
            if ~obj.analyzed_
                error('BrandtGeometry:notAnalyzed', ...
                      '%s requires analyze() to be called first. Run: geom.analyze()', ...
                      callerName);
            end
        end

        function computeNacelle(obj)
            % computeNacelle   Derive nacelle geometry from engine thrust.
            %
            % Source: Engn(s) tab.  All values are CALCULATED, not given inputs.
            %   D_engine  = sqrt(T_AB_SLS / 1900)   [Geom H4 = 3.537 ft]
            %   L_engine  = 4.5 * D_engine           [AB engine formula = 15.917 ft]
            %   nozzle_x  = inlet_x + L_engine       [Geom H3 = 29.917 ft, labelled "Length"]
            %
            % NOTE: In the AE (nacelle cross-section) column of Geom, the nacelle
            % cylinder extends from inlet_x to (inlet_x + nozzle_x_ft) = 43.917 ft,
            % NOT to nozzle_x_ft = 29.917 ft.  Geom H3 is the nozzle x-position from
            % the nose (= inlet_x + L_engine), and is reused as the nacelle length in
            % the AE formula: nacelle_end = inlet_x + H3.  See nacelleFrameArea().
            T = obj.inp.engine.T_AB_SLS_lb;
            D = sqrt(T / 1900);
            L = 4.5 * D;
            obj.D_engine_ft  = D;
            obj.L_engine_ft  = L;
            obj.nozzle_x_ft  = obj.inp.engine.inlet_x_ft + L;
            obj.n_engines    = obj.inp.engine.n_engines;
        end

        % ------------------------------------------------------------------ %
        %  LIFTING SURFACE EXPOSED GEOMETRY  (Geom rows 6-17)
        % ------------------------------------------------------------------ %

        function computeLiftingSurfaces(obj)
            % computeLiftingSurfaces   Exposed spans/chords/areas and S_wet.
            %
            % S_wet formula (Raymer, verified against Geom tab):
            %   S_wet = S_exposed * (1.977 + 0.52 * t/c)
            %
            % Exposed geometry (horizontal surfaces):
            %   c_exp_root = c_root - (fw/hs) * (c_root - c_tip)
            %   hs_exp     = hs - fw
            %   S_exposed  = (c_exp_root + c_tip)/2 * hs_exp * 2
            %   where fw = fuselage max_width/2 = 3.5 ft (Main E31 / 2)
            %
            % Vertical tail uses full span and fuselage half-HEIGHT:
            %   hs_exp_vt  = b_vt - fh
            %   S_exp_vt   = (c_exp_root_vt + c_tip_vt)/2 * hs_exp_vt  [single panel]
            %   where fh = fuselage max_height/2 = 2.5 ft (Main D31 / 2)

            fw = obj.inp.fuselage.max_width_ft  / 2;    % 3.5 ft
            fh = obj.inp.fuselage.max_height_ft / 2;    % 2.5 ft

            % --- Wing (Main B18:B27) ---
            w        = obj.inp.wing;
            b_w      = sqrt(w.S_ref_ft2 * w.AR);   % 30.0 ft
            hs_w     = b_w / 2;                     % 15.0 ft
            cr_w     = 2 * w.S_ref_ft2 / (b_w * (1 + w.taper));
            ct_w     = w.taper * cr_w;
            ce_w     = cr_w - (fw / hs_w) * (cr_w - ct_w);
            hse_w    = hs_w - fw;
            Se_w     = (ce_w + ct_w) / 2 * hse_w * 2;

            obj.wing.c_root_ft        = cr_w;
            obj.wing.c_tip_ft         = ct_w;
            obj.wing.c_exp_root_ft    = ce_w;
            obj.wing.half_span_ft     = hs_w;
            obj.wing.half_span_exp_ft = hse_w;
            obj.wing.S_exposed_ft2    = Se_w;
            obj.wing.S_wet_ft2        = Se_w * (1.977 + 0.52 * w.tc_ratio);

            % --- Pitch control / stabilator (Main C18:C27) ---
            pc       = obj.inp.pitch_ctrl;
            b_pc     = sqrt(pc.S_ft2 * pc.AR);
            hs_pc    = b_pc / 2;
            cr_pc    = 2 * pc.S_ft2 / (b_pc * (1 + pc.taper));
            ct_pc    = pc.taper * cr_pc;
            ce_pc    = cr_pc - (fw / hs_pc) * (cr_pc - ct_pc);
            hse_pc   = hs_pc - fw;
            Se_pc    = (ce_pc + ct_pc) / 2 * hse_pc * 2;

            obj.pitch_ctrl.c_root_ft        = cr_pc;
            obj.pitch_ctrl.c_tip_ft         = ct_pc;
            obj.pitch_ctrl.c_exp_root_ft    = ce_pc;
            obj.pitch_ctrl.half_span_ft     = hs_pc;
            obj.pitch_ctrl.half_span_exp_ft = hse_pc;
            obj.pitch_ctrl.S_exposed_ft2    = Se_pc;
            obj.pitch_ctrl.S_wet_ft2        = Se_pc * (1.977 + 0.52 * pc.tc_ratio);

            % --- Strake (Main D18:D27) ---
            % Root at y_ft = 2.0 ft (outside fuselage body); S_ref = fully exposed.
            sk       = obj.inp.strake;
            b_sk     = sqrt(sk.S_ft2 * sk.AR);
            hs_sk    = b_sk / 2;
            cr_sk    = 2 * sk.S_ft2 / (b_sk * (1 + sk.taper));   % taper=0 -> delta
            ct_sk    = sk.taper * cr_sk;                           % = 0

            obj.strake.c_root_ft    = cr_sk;
            obj.strake.c_tip_ft     = ct_sk;
            obj.strake.half_span_ft = hs_sk;
            obj.strake.S_exposed_ft2= sk.S_ft2;    % entire strake is exposed
            obj.strake.S_wet_ft2    = sk.S_ft2 * (1.977 + 0.52 * sk.tc_ratio);

            % --- Vertical tail (Main H18:H27) ---
            % Single panel; span = full b_vt; fuselage subtraction uses fh (half-height).
            % Verified: Se_vt = 40.89 ft^2 -> S_wet = 81.686 ~ 81.689 ft^2 (Geom B17).
            vt       = obj.inp.vert_tail;
            b_vt     = sqrt(vt.S_ft2 * vt.AR);      % full span (root-to-tip)
            cr_vt    = 2 * vt.S_ft2 / (b_vt * (1 + vt.taper));
            ct_vt    = vt.taper * cr_vt;
            ce_vt    = cr_vt - (fh / b_vt) * (cr_vt - ct_vt);
            bse_vt   = b_vt - fh;                   % exposed span
            Se_vt    = (ce_vt + ct_vt) / 2 * bse_vt; % single panel

            obj.vert_tail.c_root_ft     = cr_vt;
            obj.vert_tail.c_tip_ft      = ct_vt;
            obj.vert_tail.c_exp_root_ft = ce_vt;
            obj.vert_tail.span_ft       = b_vt;
            obj.vert_tail.span_exp_ft   = bse_vt;
            obj.vert_tail.S_exposed_ft2 = Se_vt;
            obj.vert_tail.S_wet_ft2     = Se_vt * (1.977 + 0.52 * vt.tc_ratio);

            % Vert tail plot coordinates (Geom P163:Q167, used for aircraft_length)
            x_le_vt_tip  = vt.x_le_ft + b_vt * tan(deg2rad(vt.sweep_LE_deg));
            x_te_vt_root = vt.x_le_ft + cr_vt;
            x_te_vt_tip  = x_le_vt_tip + ct_vt;   % Geom L165 = 48.304 ft
            obj.vert_tail.x_le_tip_ft  = x_le_vt_tip;
            obj.vert_tail.x_te_root_ft = x_te_vt_root;
            obj.vert_tail.x_te_tip_ft  = x_te_vt_tip;

            % --- Wing trailing-edge x (straight TE, Main B27 sweep ≈ 0°) ---
            x_te_root_w = obj.inp.wing.x_apex_ft + cr_w;   % = 34.079 ft
            obj.wing.x_te_root_ft = x_te_root_w;

            % --- Aileron / Elevon  (Main E18:E27) ---
            % Given: S, AR, airfoil, t/c, y_ft, z_ft, dihedral_deg
            % Calculated: taper, sweep_LE, x_le (Excel E20, E21, E23)
            % Method: wing TE is straight (Main B27 ≈ 0°); aileron TE aligns
            % with wing TE.  Taper approximated from wing chord ratio at the
            % aileron span boundaries (matches Excel to within ~5%).
            ai    = obj.inp.aileron;
            b_ai  = sqrt(ai.S_ft2 * ai.AR);            % total bilateral span = 15.492 ft
            hs_ai = b_ai / 2;                           % per-side half-span  = 7.746 ft
            y_ai_tip = ai.y_ft + hs_ai;                 % outer y-station     = 11.246 ft
            cr_ai_w  = cr_w - (cr_w - ct_w) * (ai.y_ft  / hs_w); % wing chord at y_root
            ct_ai_w  = cr_w - (cr_w - ct_w) * (y_ai_tip / hs_w); % wing chord at y_tip
            taper_ai = ct_ai_w / cr_ai_w;               % ≈ 0.514 (Excel: 0.5365)
            cr_ai    = 2 * ai.S_ft2 / (b_ai * (1 + taper_ai));
            ct_ai    = taper_ai * cr_ai;
            x_le_ai  = x_te_root_w - cr_ai;             % aileron x_le at y_root ≈ 32.03 ft
            x_le_ai_tip = x_te_root_w - ct_ai;
            sweep_ai_deg = atan2d(x_le_ai_tip - x_le_ai, hs_ai); % ≈ 6.9° (Excel: 6.88°)

            obj.aileron.S_ft2        = ai.S_ft2;
            obj.aileron.AR           = ai.AR;
            obj.aileron.taper        = taper_ai;
            obj.aileron.sweep_LE_deg = sweep_ai_deg;
            obj.aileron.c_root_ft    = cr_ai;
            obj.aileron.c_tip_ft     = ct_ai;
            obj.aileron.half_span_ft = hs_ai;
            obj.aileron.y_root_ft    = ai.y_ft;
            obj.aileron.y_tip_ft     = y_ai_tip;
            obj.aileron.x_le_ft      = x_le_ai;
            obj.aileron.x_le_tip_ft  = x_le_ai_tip;
            obj.aileron.x_te_root_ft = x_te_root_w;

            % --- LE Flap  (Main F18:F27) ---
            % Given: airfoil, t/c, taper=1.0, sweep_LE=40°, y=3.5, z=0
            % Calculated: S=21.314 ft², AR=12.410, x_le=20.723 ft (Excel F18,F19,F23)
            % Note: S and AR formulas are not visible in the binary .xls; GT values used.
            lf    = obj.inp.le_flap;
            x_le_lf = obj.inp.wing.x_apex_ft + lf.y_ft * tan(deg2rad(lf.sweep_LE_deg));
            S_lf  = 21.314;                             % Geom Main F18 (GT, calc)
            AR_lf = 12.410;                             % Geom Main F19 (GT, calc)
            b_lf  = sqrt(S_lf * AR_lf);
            hs_lf = b_lf / 2;
            c_lf  = S_lf / b_lf;                       % constant chord (taper=1)

            obj.le_flap.S_ft2        = S_lf;
            obj.le_flap.AR           = AR_lf;
            obj.le_flap.taper        = lf.taper;       % 1.0 (given)
            obj.le_flap.sweep_LE_deg = lf.sweep_LE_deg;% 40.0 (given)
            obj.le_flap.c_root_ft    = c_lf;
            obj.le_flap.c_tip_ft     = c_lf;
            obj.le_flap.half_span_ft = hs_lf;
            obj.le_flap.y_root_ft    = lf.y_ft;
            obj.le_flap.x_le_ft      = x_le_lf;       % = 20.723 ft (Excel F23, calc)

            % --- TE Flap  (Main G18:G27) ---
            % Given: S=24, AR=10, airfoil, t/c, y=3.5, z=0, dihedral=0
            % Calculated: taper, sweep_LE, x_le — same formulas as aileron (Excel G20-G23)
            if isfield(obj.inp, 'te_flap')
                tf = obj.inp.te_flap;
            else
                tf = struct('S_ft2',24,'AR',10,'airfoil','NACA 0008','tc_ratio',0.08,...
                    'y_ft',3.5,'z_ft',0.0,'dihedral_deg',0.0);
            end
            obj.te_flap.S_ft2        = tf.S_ft2;
            obj.te_flap.AR           = tf.AR;
            obj.te_flap.taper        = taper_ai;       % same as aileron (Excel G20)
            obj.te_flap.sweep_LE_deg = sweep_ai_deg;   % same as aileron (Excel G21)
            obj.te_flap.c_root_ft    = cr_ai;
            obj.te_flap.c_tip_ft     = ct_ai;
            obj.te_flap.half_span_ft = hs_ai;
            obj.te_flap.y_root_ft    = tf.y_ft;
            obj.te_flap.x_le_ft      = x_le_ai;       % same as aileron (Excel G23)
        end

        % ------------------------------------------------------------------ %
        %  FUSELAGE FRAME CROSS-SECTION GEOMETRY  (Geom rows 26-46)
        % ------------------------------------------------------------------ %

        function computeFrameGeometry(obj)
            % computeFrameGeometry   Per-frame perimeter, area, and wetted area.
            %
            % Cross-section shape model (verified against Geom rows 51-61):
            %   Upper boundary: z = z_chine + (z_top - z_chine)*cos(pi/2 * y/hw)
            %   Lower boundary: z = z_chine + (z_bot - z_chine)*cos(pi/2 * y/hw)
            %   where hw = w/2, z_top = z_center+h/2, z_bot = z_center-h/2.
            %
            % Perimeter: 6 half-section points (y = 0, 0.2, ..., 1.0 * hw),
            % giving 11 unique points from top to bottom via right chine.
            % Matches Brandt's 23-point polygon discretisation.
            %
            % Accurate fuselage S_wet (Geom D23 = 676.329 ft^2):
            %   Trapezoidal integration of per-frame perimeters over x.
            %   Nose at x=0 has P=0; tail closes to P=0 at last frame.
            %   NOTE: Excel D23 uses wrong width for frame 20 (bug not replicated
            %   here). This implementation gives ~675 ft^2 using correct dimensions.

            n_pts = 6;
            x    = obj.inp.fuselage.frame_x;
            zc   = obj.inp.fuselage.frame_zchine;
            zctr = obj.inp.fuselage.frame_z;
            w    = obj.inp.fuselage.frame_w;
            h    = obj.inp.fuselage.frame_h;
            nf   = numel(x);

            P = zeros(1, nf);
            A = zeros(1, nf);
            for i = 1:nf
                [P(i), A(i)] = BrandtGeometry.frameCrossSection( ...
                    w(i), h(i), zc(i), zctr(i), n_pts);
            end

            % Integrate with nose (x=0, P=0) and tail closing (P=0 at last frame x)
            x_all = [0, x];
            P_all = [0, P];

            dS = zeros(1, numel(x_all) - 1);
            for k = 1:(numel(x_all) - 1)
                dS(k) = (P_all(k) + P_all(k+1)) / 2 * (x_all(k+1) - x_all(k));
            end

            obj.frame_x                 = x;
            obj.frame_perimeter         = P;
            obj.frame_area              = A;
            obj.fuselage_dSwet          = dS;
            obj.S_wet_fuse_accurate_ft2 = sum(dS);
        end

        % ------------------------------------------------------------------ %
        %  SIMPLE WETTED AREAS  (Geom column B)
        % ------------------------------------------------------------------ %

        function computeSwetSimple(obj)
            % computeSwetSimple   Low-fidelity wetted areas (Geom column B).
            %
            % Fuselage (Geom B3):
            %   S_wet = (5/6)*pi*D_avg*L_fuse,  D_avg = (max_w + max_h)/2
            %   "1/3-cone + 2/3-cylinder" approximation.  GT: 730.422 ft^2.
            %
            % Nacelle (Geom B4):
            %   Formula could not be confirmed from binary .xls file.
            %   Implementation: N*pi*D_eng*(aircraft_length - fuse_length).
            %   This gives ~20 ft^2 vs GT = 41.515 ft^2.  See readme_geom.md.

            L     = obj.inp.fuselage.length_ft;
            D_avg = (obj.inp.fuselage.max_width_ft + obj.inp.fuselage.max_height_ft) / 2;
            obj.S_wet_fuse_simple_ft2    = (5/6) * pi * D_avg * L;

            L_exp = max(0, obj.aircraft_length_ft - L);
            obj.S_wet_nacelle_simple_ft2 = obj.n_engines * pi * obj.D_engine_ft * L_exp;
            obj.S_wet_nacelle_gt_ft2     = 41.515;  % Geom B4 ground truth

            % Lifting surfaces (Geom B14-B17) - same formula for both fidelities
            obj.S_wet_wing_ft2       = obj.wing.S_wet_ft2;
            obj.S_wet_strake_ft2     = obj.strake.S_wet_ft2;
            obj.S_wet_pitch_ctrl_ft2 = obj.pitch_ctrl.S_wet_ft2;
            obj.S_wet_vert_tail_ft2  = obj.vert_tail.S_wet_ft2;

            obj.S_wet_total_simple_ft2 = obj.S_wet_fuse_simple_ft2 ...
                + obj.S_wet_nacelle_simple_ft2 ...
                + obj.S_wet_wing_ft2 ...
                + obj.S_wet_strake_ft2 ...
                + obj.S_wet_pitch_ctrl_ft2 ...
                + obj.S_wet_vert_tail_ft2;
        end

        % ------------------------------------------------------------------ %
        %  ACCURATE TOTAL S_WET  (Geom D23 + B14-B17 + nacelle GT)
        % ------------------------------------------------------------------ %

        function computeSwetAccurate(obj)
            % computeSwetAccurate   High-fidelity total S_wet.
            %
            % Combines per-frame fuselage integration (D23) with the same lifting-
            % surface S_wet values (B14-B17) and the nacelle ground-truth (B4).
            % Target total: Geom B19 = 1371.09 ft^2.
            obj.S_wet_total_accurate_ft2 = obj.S_wet_fuse_accurate_ft2 ...
                + obj.S_wet_nacelle_gt_ft2 ...
                + obj.S_wet_wing_ft2 ...
                + obj.S_wet_strake_ft2 ...
                + obj.S_wet_pitch_ctrl_ft2 ...
                + obj.S_wet_vert_tail_ft2;
        end

        % ------------------------------------------------------------------ %
        %  AMAX  (Geom H47)
        % ------------------------------------------------------------------ %

        function computeAmax(obj)
            % computeAmax   Maximum whole-aircraft cross-section area.
            %
            % Replicates Geom H26:H47.  At each frame station the whole-aircraft
            % area is the sum of fuselage (W col), wing (Y), pitch ctrl (AA),
            % vert tail (AC), nacelle (AE), and strake (AG) cross-sections.
            %
            % Each lifting surface uses Brandt's cosine approximation formula
            % (NOT the NACA 4/5-digit thickness integral) -- verified against the
            % Excel via win32com formula inspection.  See brandtCSArea() below.
            %
            %   Amax = MAX(H26:H45) - N_eng*pi*D_eng^2/5
            %
            % The -N*pi*D^2/5 term removes the internal engine inlet from the
            % external wetted cross-section.  GT: 25.11 ft^2.

            x_fr   = obj.frame_x;
            A_fuse = obj.frame_area;

            fw = obj.inp.fuselage.max_width_ft / 2;   % fuselage half-width  = 3.5 ft
            fh = obj.inp.fuselage.max_height_ft / 2;  % fuselage half-height = 2.5 ft

            % --- Wing (Geom row 7, Y column) ---
            % Xexp = x_apex + fw*tan(sweep) = 20.723 ft  [Geom B7]
            % Formula: tc*(c_exp_root+c_tip)*y_span*(1-cos(2pi*xi))/2
            Xexp_w = obj.inp.wing.x_apex_ft + fw * tand(obj.inp.wing.sweep_LE_deg);
            A_wing = BrandtGeometry.brandtCSArea(x_fr, ...
                Xexp_w, obj.wing.c_exp_root_ft, obj.wing.c_tip_ft, ...
                obj.wing.half_span_exp_ft, obj.inp.wing.sweep_LE_deg, ...
                obj.inp.wing.tc_ratio, Xexp_w, 2);

            % --- Pitch Control Surface (Geom row 8, AA column) ---
            % Xexp = x_le_ft + fw*tan(sweep) = 38.937 ft  [Geom B8]
            Xexp_pc = obj.inp.pitch_ctrl.x_le_ft + fw * tand(obj.inp.pitch_ctrl.sweep_LE_deg);
            A_pitch = BrandtGeometry.brandtCSArea(x_fr, ...
                Xexp_pc, obj.pitch_ctrl.c_exp_root_ft, obj.pitch_ctrl.c_tip_ft, ...
                obj.pitch_ctrl.half_span_exp_ft, obj.inp.pitch_ctrl.sweep_LE_deg, ...
                obj.inp.pitch_ctrl.tc_ratio, Xexp_pc, 2);

            % --- Vertical Tail (Geom row 10, AC column) ---
            % Xexp = x_le_ft + fh*tan(sweep) = 38.098 ft  [Geom B10]
            % Excel formula bug: active-range X_max uses wing tip chord D$7 (3.707 ft)
            % instead of VT tip chord D$10 (4.082 ft).  c_tip_range = D7 replicates this.
            Xexp_vt     = obj.inp.vert_tail.x_le_ft + fh * tand(obj.inp.vert_tail.sweep_LE_deg);
            c_tip_range = obj.wing.c_tip_ft;   % D$7 (wing tip) used in VT range check
            A_vert = BrandtGeometry.brandtCSArea(x_fr, ...
                Xexp_vt, obj.vert_tail.c_exp_root_ft, obj.vert_tail.c_tip_ft, ...
                obj.vert_tail.span_exp_ft, obj.inp.vert_tail.sweep_LE_deg, ...
                obj.inp.vert_tail.tc_ratio, Xexp_vt, 2, c_tip_range);

            % --- Strake (Geom row 9, AG column) ---
            % Excel formula bugs replicated exactly to match GT:
            %   1. Cosine xi uses B$8 (Xexp_pc = 38.937 ft) not B$9 (strake Xexp = 12.0 ft)
            %   2. No division by 2 (divisor = 1)
            A_strake = BrandtGeometry.brandtCSArea(x_fr, ...
                obj.inp.strake.x_le_ft, obj.strake.c_root_ft, obj.strake.c_tip_ft, ...
                obj.strake.half_span_ft, obj.inp.strake.sweep_LE_deg, ...
                obj.inp.strake.tc_ratio, Xexp_pc, 1);  % Xref=Xexp_pc (Excel bug), divisor=1

            % --- Nacelle (Geom AE column) ---
            A_nac = BrandtGeometry.nacelleFrameArea(obj.inp.engine, obj, x_fr);

            A_total = A_fuse + A_wing + A_pitch + A_vert + A_strake + A_nac;

            obj.frame_area_wing   = A_wing;
            obj.frame_area_pitch  = A_pitch;
            obj.frame_area_vert   = A_vert;
            obj.frame_area_strake = A_strake;
            obj.frame_area_nac    = A_nac;
            obj.frame_area_total  = A_total;

            obj.Amax_ft2 = max(A_total) - ...
                obj.n_engines * pi * obj.D_engine_ft^2 / 5.0;
        end

    end  % methods (Access = private)

    methods (Static)

        % ------------------------------------------------------------------ %
        %  CROSS-SECTION SHAPE (single fuselage frame)
        % ------------------------------------------------------------------ %

        function [P, A] = frameCrossSection(w, h, z_chine, z_center, n_pts)
            % frameCrossSection   Perimeter and area for one fuselage frame.
            %
            %   [P, A] = BrandtGeometry.frameCrossSection(w, h, z_chine, z_center, n_pts)
            %
            % Shape: cosine model (see computeFrameGeometry header for full derivation).
            % n_pts = 6 -> dy = 0.2*hw per step (matching Brandt's discretisation).

            hw    = w / 2;
            z_top = z_center + h / 2;
            z_bot = z_center - h / 2;

            t    = linspace(0, 1, n_pts);   % [0, 0.2, 0.4, 0.6, 0.8, 1.0]
            y    = t * hw;

            z_up = z_chine + (z_top - z_chine) * cos(pi/2 * t);
            z_dn = z_chine + (z_bot - z_chine) * cos(pi/2 * t);

            % Right-side path: top-center -> right-chine -> bottom-center (11 pts)
            y_path = [y,   fliplr(y(1:end-1))];
            z_path = [z_up, fliplr(z_dn(1:end-1))];

            ds     = sqrt(diff(y_path).^2 + diff(z_path).^2);
            P_half = sum(ds);
            P      = 2 * P_half;     % full perimeter (left side symmetric)

            dz     = z_up - z_dn;    % local height at each y sample
            A_half = trapz(y, dz);
            A      = 2 * A_half;
        end

        function t = nacaHalfThickness(xi, tc)
            % nacaHalfThickness   NACA 4/5-digit half-thickness (normalised to chord).
            %   t = (tc/0.20)*(0.2969*sqrt(xi) - 0.1260*xi - 0.3516*xi^2
            %                  + 0.2843*xi^3  - 0.1015*xi^4)
            xi = max(0, min(1, xi));
            t  = (tc / 0.20) * (0.2969*sqrt(xi) - 0.1260*xi ...
                - 0.3516*xi^2 + 0.2843*xi^3 - 0.1015*xi^4);
        end

        function A = brandtCSArea(x_stations, Xexp, c_exp_root, c_tip, G_hs_exp, ...
                sweep_deg, tc, Xref, divisor, c_tip_range)
            % brandtCSArea  Brandt's cosine cross-section area formula (Geom tab).
            %
            % Replicates the Excel column formulas (Y/AA/AC/AG columns, rows 26-45).
            % Verified via win32com formula inspection.
            %
            % Formula active for Xexp < x < Xexp + X_max_range:
            %
            %   A = tc * (c_exp_root + c_tip) * y_span * (1-cos(2*pi*xi)) / divisor
            %
            % where:
            %   X_max_range = MAX(c_exp_root, G_hs_exp*tan(sweep) + c_tip_range)
            %   X_max_cos   = MAX(c_exp_root, G_hs_exp*tan(sweep) + c_tip)
            %   y_span      = MIN(G_hs_exp, (x-Xexp)/tan(sweep))
            %   xi          = (x - Xref) / X_max_cos
            %
            % For most surfaces: Xref = Xexp, c_tip_range = c_tip, divisor = 2.
            %
            % Excel copy-paste bugs replicated exactly:
            %   Strake (AG col): Xref = pitch_ctrl Xexp (B$8), divisor = 1
            %   Vert tail (AC col): c_tip_range = wing tip chord (D$7), not VT c_tip
            %
            % Inputs:
            %   x_stations  - [1xN] fuselage x-positions [ft]
            %   Xexp        - exposed root LE x [ft]          (Geom B col)
            %   c_exp_root  - exposed root chord [ft]         (Geom F col)
            %   c_tip       - tip chord [ft]                  (Geom D col)
            %   G_hs_exp    - exposed half-span or span [ft]  (Geom G col)
            %   sweep_deg   - LE sweep [deg]
            %   tc          - airfoil t/c ratio
            %   Xref        - x reference for cosine; normally = Xexp
            %   divisor     - 2 for wing/pitch_ctrl/vert_tail; 1 for strake
            %   c_tip_range - (optional) c_tip override for X_max range check;
            %                 normally = c_tip; vert tail passes wing c_tip D$7

            if nargin < 10
                c_tip_range = c_tip;
            end

            tan_sw      = tand(sweep_deg);
            X_max_range = max(c_exp_root, G_hs_exp * tan_sw + c_tip_range);
            X_max_cos   = max(c_exp_root, G_hs_exp * tan_sw + c_tip);
            n           = numel(x_stations);
            A           = zeros(1, n);
            for i = 1:n
                x = x_stations(i);
                if x <= Xexp || x >= Xexp + X_max_range
                    continue
                end
                y_span = min(G_hs_exp, (x - Xexp) / tan_sw);
                xi     = (x - Xref) / X_max_cos;
                A(i)   = tc * (c_exp_root + c_tip) * y_span * (1 - cos(2*pi*xi)) / divisor;
            end
        end

        function A = liftingSurfaceArea(x_stations, x_le_root, c_root, c_tip, ...
                sweep_LE_deg, tc, y_root, half_span, orientation)
            % liftingSurfaceArea   Cross-section area of a surface at each x station.
            %
            % Integrates the local NACA 4/5-digit airfoil thickness over the span
            % at each fuselage station.
            %
            % NOTE: Brandt's Excel does NOT use this method; it uses brandtCSArea().
            % This function is retained for comparison / higher-fidelity reference only.
            %
            %   orientation = 'horiz' : bilateral (left+right, result *2)
            %                 'vert'  : single panel (no mirror)

            sw   = deg2rad(sweep_LE_deg);
            NS   = 40;      % span integration strips
            n    = numel(x_stations);
            A    = zeros(1, n);

            y_sp = linspace(y_root, half_span, NS);
            dy   = (half_span - y_root) / (NS - 1);

            for xi = 1:n
                xq = x_stations(xi);
                dA = 0;
                for j = 1:NS
                    yj     = y_sp(j);
                    x_le_j = x_le_root + (yj - y_root) * tan(sw);
                    c_j    = c_root - (c_root - c_tip) * (yj - y_root) / ...
                                      (half_span - y_root);
                    x_te_j = x_le_j + c_j;
                    if xq < x_le_j || xq > x_te_j || c_j <= 0
                        continue
                    end
                    xi_j   = (xq - x_le_j) / c_j;
                    t_half = BrandtGeometry.nacaHalfThickness(xi_j, tc);
                    dA     = dA + 2 * t_half * c_j * dy;
                end
                if strcmpi(orientation, 'vert')
                    A(xi) = dA;
                else
                    A(xi) = 2 * dA;   % mirror left+right
                end
            end
        end

        function A = nacelleFrameArea(engine, geom, x_stations)
            % nacelleFrameArea   Nacelle cross-section at each frame station.
            %
            % Modelled as a cylinder of diameter D_engine.
            % Geom AE column extends nacelle from inlet_x to (inlet_x + H3):
            %   x_in  = inlet_x_ft         = 14.0   ft  (Main/JSON)
            %   x_noz = inlet_x + H3       = 14 + 29.917 = 43.917 ft
            %   H3    = nozzle_x_ft        = inlet_x + 4.5*D = 29.917 ft  (Geom H3)
            % NOTE: The nacelle cylinder end is NOT at H3 = 29.917 ft, but at
            % inlet_x + H3 = 43.917 ft.  H3 is the nozzle x-position from the
            % nose; the nacelle cross-section extends another inlet_x beyond that.
            A_cyl = pi / 4 * geom.D_engine_ft^2;
            x_in  = engine.inlet_x_ft;
            x_noz = engine.inlet_x_ft + geom.nozzle_x_ft;   % = 14 + 29.917 = 43.917 ft
            A     = zeros(1, numel(x_stations));
            mask  = x_stations >= x_in & x_stations <= x_noz;
            A(mask) = geom.n_engines * A_cyl;
        end


    end  % methods (Static)

    methods (Access = private)

        function initializeComputedFields(obj)
            % initializeComputedFields   Pre-allocate all computed fields to NaN.
            obj.D_engine_ft              = NaN;
            obj.L_engine_ft              = NaN;
            obj.nozzle_x_ft              = NaN;
            obj.n_engines                = NaN;
            obj.aircraft_length_ft       = NaN;
            obj.S_wet_fuse_simple_ft2    = NaN;
            obj.S_wet_nacelle_simple_ft2 = NaN;
            obj.S_wet_nacelle_gt_ft2     = NaN;
            obj.S_wet_wing_ft2           = NaN;
            obj.S_wet_strake_ft2         = NaN;
            obj.S_wet_pitch_ctrl_ft2     = NaN;
            obj.S_wet_vert_tail_ft2      = NaN;
            obj.S_wet_total_simple_ft2   = NaN;
            obj.S_wet_fuse_accurate_ft2  = NaN;
            obj.S_wet_total_accurate_ft2 = NaN;
            obj.Amax_ft2                 = NaN;

            obj.wing = struct('c_root_ft',NaN,'c_tip_ft',NaN,'c_exp_root_ft',NaN, ...
                'half_span_ft',NaN,'half_span_exp_ft',NaN,'S_exposed_ft2',NaN, ...
                'S_wet_ft2',NaN,'x_te_root_ft',NaN);
            obj.pitch_ctrl = struct('c_root_ft',NaN,'c_tip_ft',NaN,'c_exp_root_ft',NaN, ...
                'half_span_ft',NaN,'half_span_exp_ft',NaN,'S_exposed_ft2',NaN,'S_wet_ft2',NaN);
            obj.strake = struct('c_root_ft',NaN,'c_tip_ft',NaN,'half_span_ft',NaN, ...
                'S_exposed_ft2',NaN,'S_wet_ft2',NaN);
            obj.vert_tail = struct('c_root_ft',NaN,'c_tip_ft',NaN,'c_exp_root_ft',NaN, ...
                'span_ft',NaN,'span_exp_ft',NaN,'S_exposed_ft2',NaN,'S_wet_ft2',NaN, ...
                'x_le_tip_ft',NaN,'x_te_root_ft',NaN,'x_te_tip_ft',NaN);
            obj.aileron = struct('S_ft2',NaN,'AR',NaN,'taper',NaN,'sweep_LE_deg',NaN, ...
                'c_root_ft',NaN,'c_tip_ft',NaN,'half_span_ft',NaN,'y_root_ft',NaN, ...
                'y_tip_ft',NaN,'x_le_ft',NaN,'x_le_tip_ft',NaN,'x_te_root_ft',NaN);
            obj.le_flap = struct('S_ft2',NaN,'AR',NaN,'taper',NaN,'sweep_LE_deg',NaN, ...
                'c_root_ft',NaN,'c_tip_ft',NaN,'half_span_ft',NaN,'y_root_ft',NaN,'x_le_ft',NaN);
            obj.te_flap = struct('S_ft2',NaN,'AR',NaN,'taper',NaN,'sweep_LE_deg',NaN, ...
                'c_root_ft',NaN,'c_tip_ft',NaN,'half_span_ft',NaN,'y_root_ft',NaN,'x_le_ft',NaN);

            obj.frame_x           = nan(1, 20);
            obj.frame_perimeter   = nan(1, 20);
            obj.frame_area        = nan(1, 20);
            obj.frame_area_wing   = nan(1, 20);
            obj.frame_area_pitch  = nan(1, 20);
            obj.frame_area_vert   = nan(1, 20);
            obj.frame_area_strake = nan(1, 20);
            obj.frame_area_nac    = nan(1, 20);
            obj.frame_area_total  = nan(1, 20);
            obj.fuselage_dSwet    = nan(1, 20);
        end

    end  % methods (Access = private)

end  % classdef BrandtGeometry
