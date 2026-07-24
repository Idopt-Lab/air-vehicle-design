function T_all = geometry_brandt_comparison()
%GEOMETRY_BRANDT_COMPARISON  F-16A Block 10 — Geometry vs Brandt ground truth.
%
%   NOT A TEST. No pass/fail assertions, not part of run_all_tests. A pure
%   reporting script: loads the F-16A L1/L2 input JSONs (f16a_spec_path(1)/(2)),
%   runs the actual F16GeomL1/F16GeomL2 methods and GeomL2 static toolbox
%   calls, and compares against the `geometry` section of
%   VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json — the Brandt-DIRECT
%   ground truth (NOT F16Baseline.m's older T.O.-manual-based figures, which
%   fidelity_comparison.m uses instead).
%
%   Where a physical quantity has multiple implementation options (e.g.
%   wing/HT/VT S_wet via Roskam Eq. 12.1 vs Brandt's own uniform-tc formula;
%   fuselage S_wet via Roskam Eq. 12.3 vs Brandt low-fi vs Brandt high-fi),
%   each option gets its own row — never just the "official" one.
%
%   Outputs (written to the same directory as this script):
%     geometry_brandt_comparison.json  — full table + metadata
%     geometry_brandt_comparison.md    — rendered markdown table
%
%   REFERENCE SOURCES:
%     [Brandt]  S. Brandt, F-16A.xls workbook, via the geometry section of
%               VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json
%               and f16a_geometry.json
%     [Roskam]  J. Roskam, Airplane Design Vol. II, DARcorp., 1997 (Eq. 12.1, 12.3)
%     [Raymer]  D.P. Raymer, Aircraft Design 6th/7th ed., AIAA (Sec 7.3; Table 4.1/6.4/6.5)

script_dir  = fileparts(mfilename('fullpath'));
sizing_root = fileparts(fileparts(script_dir));
gt_path     = fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth', 'f16a_ground_truth.json');
frames_path = fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth', 'f16a_geometry.json');
gt          = jsondecode(fileread(gt_path)).geometry;   % geometry section of the unified ground-truth file
J_frames    = jsondecode(fileread(frames_path));

% W_TO sourced directly from the Brandt JSON (f16a_geometry.json, already
% loaded above as J_frames) rather than F16Baseline.m -- that file is the
% older T.O.-manual-based ground truth this script deliberately avoids
% elsewhere (see header comment) and is slated for removal.
W_TO = J_frames.mission.W_TO_lb;   % 31,377 lbf  [Brandt Main! mission W_TO_lb]

g1 = F16GeomL1(f16a_spec_path(1));
g2 = F16GeomL2(f16a_spec_path(2));

% ════════════════════════════════════════════════════════════════════════ %
%  COMPUTE — run the actual toolbox code
% ════════════════════════════════════════════════════════════════════════ %

% ── L1 statistical regression ──────────────────────────────────────────── %
sw_l1   = g1.get_S_wet(W_TO);
lfus_l1 = g1.get_L_fus(W_TO);

% ── Wing/HT/VT S_wet: two formula options each ─────────────────────────── %
sw_wing_roskam = g2.get_S_wet_wing();                                        % OFFICIAL: Roskam Eq. 12.1
sw_wing_brandt = GeomL2.compute_wet_planform(g2.S_exposed_wing, g2.tc_wing); % alternate: Brandt uniform-tc
sw_ht_roskam   = g2.get_S_wet_HT();
sw_ht_brandt   = GeomL2.compute_wet_planform(g2.S_exposed_ht, g2.tc_ht);
sw_vt_roskam   = g2.get_S_wet_VT();
sw_vt_brandt   = GeomL2.compute_wet_planform(g2.S_exposed_vt, g2.tc_vt);

% ── Fuselage S_wet: three formula options ──────────────────────────────── %
sw_fus_roskam = g2.get_S_wet_fuselage();                                                            % OFFICIAL: Roskam Eq. 12.3
sw_fus_lowfi  = GeomL2.compute_s_wet_fus_brandt_lowfi(g2.W_max_fuselage, g2.H_max_fuselage, g2.L_fuselage);
fr            = J_frames.fuselage.frames;
sw_fus_highfi = GeomL2.compute_s_wet_fus_brandt_highfi( ...
    [fr.x_ft], [fr.z_chine_ft], [fr.z_ft], [fr.w_ft], [fr.h_ft]);

% ── Duct / nacelle ──────────────────────────────────────────────────────── %
sw_duct    = g2.get_S_wet_duct();
D_nacelle  = g2.D_inlet;   % = D_exit, computed via sqrt(T_AB_SLS_lb/1900)

% ── Exposed areas (full JSON-to-property pipeline) ─────────────────────── %
exp_wing = g2.S_exposed_wing;
exp_ht   = g2.S_exposed_ht;
exp_vt   = g2.S_exposed_vt;

% ── Sweep-conversion headline check ─────────────────────────────────────── %
qc_sweep_wing = g2.QC_sweep_wing;

% ── Totals ────────────────────────────────────────────────────────────── %
% total_official: call g2.get_S_wet() directly rather than re-summing the
% five official components by hand -- get_S_wet() IS that sum (verified by
% TestGeomL2's testTotalSwetEqualsSum), so this also doubles as a live check
% that get_S_wet()'s own aggregation hasn't drifted from the individual
% component methods used elsewhere in this script.
total_official     = g2.get_S_wet();
% total_brandt_style has no single method call -- it mixes the Brandt
% uniform-tc wing/HT/VT formula with the Brandt high-fi fuselage formula,
% a combination get_S_wet() doesn't compute (it always uses the official
% Roskam formulas) -- so this one stays a manual sum.
total_brandt_style = sw_wing_brandt + sw_ht_brandt + sw_vt_brandt + sw_fus_highfi + sw_duct;

% ── L_fus vs Brandt's total-aircraft-length figure (different quantities) %
L_fus_computed = g2.L_fus;

% ════════════════════════════════════════════════════════════════════════ %
%  BUILD TABLE
% ════════════════════════════════════════════════════════════════════════ %

T = table();

T = [T; srow('[WING / HT / VT WETTED AREA — TWO FORMULA OPTIONS EACH]')];
T = [T; grow('Wing S_wet, Roskam Eq.12.1 [OFFICIAL] [ft^2]', 'L2', sw_wing_roskam, gt.lifting_surface_S_wet_ft2.wing.value, 'Brandt Geom!B14', '%.4f', 'get_S_wet_wing()')];
T = [T; grow('Wing S_wet, Brandt uniform-tc [alt]  [ft^2]', 'L2', sw_wing_brandt, gt.lifting_surface_S_wet_ft2.wing.value, 'Brandt Geom!B14', '%.4f', 'compute_wet_planform() -- same formula Brandt uses, near-exact match expected')];
T = [T; grow('HT   S_wet, Roskam Eq.12.1 [OFFICIAL] [ft^2]', 'L2', sw_ht_roskam, gt.lifting_surface_S_wet_ft2.pitch_control_HT.value, 'Brandt Geom!B16', '%.4f', 'get_S_wet_HT()')];
T = [T; grow('HT   S_wet, Brandt uniform-tc [alt]  [ft^2]', 'L2', sw_ht_brandt, gt.lifting_surface_S_wet_ft2.pitch_control_HT.value, 'Brandt Geom!B16', '%.4f', 'compute_wet_planform() -- same formula Brandt uses, near-exact match expected')];
T = [T; grow('VT   S_wet, Roskam Eq.12.1 [OFFICIAL] [ft^2]', 'L2', sw_vt_roskam, gt.lifting_surface_S_wet_ft2.vertical_tail.value, 'Brandt Geom!B17', '%.4f', 'get_S_wet_VT()')];
T = [T; grow('VT   S_wet, Brandt uniform-tc [alt]  [ft^2]', 'L2', sw_vt_brandt, gt.lifting_surface_S_wet_ft2.vertical_tail.value, 'Brandt Geom!B17', '%.4f', 'compute_wet_planform() -- same formula Brandt uses, near-exact match expected')];
T = [T; grow('Strake S_wet -- NOT MODELED           [ft^2]', 'N/A', NaN, gt.lifting_surface_S_wet_ft2.strake.value, 'Brandt Geom!B15', '%.4f', 'No strake component exists in GeomL2''s get_S_wet aggregation')];

T = [T; srow('[FUSELAGE WETTED AREA — THREE FORMULA OPTIONS]')];
T = [T; grow('Fuselage S_wet, Roskam Eq.12.3 [OFFICIAL] [ft^2]', 'L2', sw_fus_roskam, gt.fuselage_S_wet.high_fi_ft2, 'Brandt Geom!D23', '%.4f', 'get_S_wet_fuselage() -- equivalent-diameter cylinder model; compared vs Brandt''s high-fi (closest formula family)')];
T = [T; grow('Fuselage S_wet, Brandt low-fi [alt]   [ft^2]', 'L2', sw_fus_lowfi, gt.fuselage_S_wet.low_fi_ft2, 'Brandt Geom!B3', '%.4f', 'compute_s_wet_fus_brandt_lowfi() -- reproduces Brandt''s own "1/3-cone+2/3-cyl" formula')];
T = [T; grow('Fuselage S_wet, Brandt high-fi [alt]  [ft^2]', 'L2', sw_fus_highfi, gt.fuselage_S_wet.high_fi_ft2, 'Brandt Geom!D23', '%.4f', 'compute_s_wet_fus_brandt_highfi() -- reproduces Brandt''s own frame-integration formula')];

T = [T; srow('[DUCT / NACELLE]')];
T = [T; grow('Duct S_wet (inlet-to-exit frustum)     [ft^2]', 'L2', sw_duct, gt.nacelle.S_wet_ft2, 'Brandt Geom!B4 (nacelle)', '%.4f', 'DIFFERENT quantity: exposed inlet-to-exit frustum vs Brandt''s full-cylinder nacelle -- large %Diff expected, not a bug')];
T = [T; grow('Nacelle diameter D=sqrt(T_AB_SLS/1900) [ft]', 'L2', D_nacelle, gt.nacelle.diameter_ft, 'Brandt Engn(s) tab', '%.6f', 'Same formula as Brandt -- should match near-exactly (positive control)')];

T = [T; srow('[EXPOSED LIFTING-SURFACE AREAS]')];
T = [T; grow('Wing exposed area  [ft^2]', 'L2', exp_wing, gt.lifting_surface_exposed_areas.wing.exposed_S_ft2, 'Brandt Geom!7', '%.4f', 'compute_S_exposed_horizontal() via F16GeomL2 constructor')];
T = [T; grow('HT   exposed area  [ft^2]', 'L2', exp_ht, gt.lifting_surface_exposed_areas.pitch_control_HT.exposed_S_ft2, 'Brandt Geom!8', '%.4f', 'compute_S_exposed_horizontal() via F16GeomL2 constructor')];
T = [T; grow('VT   exposed area  [ft^2]', 'L2', exp_vt, gt.lifting_surface_exposed_areas.vertical_tail.exposed_S_ft2, 'Brandt Geom!10', '%.4f', 'compute_S_exposed_vertical() via F16GeomL2 constructor')];
T = [T; grow('Strake exposed area -- NOT MODELED [ft^2]', 'N/A', NaN, gt.lifting_surface_exposed_areas.strake.exposed_S_ft2, 'Brandt Geom!9', '%.4f', 'No strake component exists in this framework')];

T = [T; srow('[SWEEP-ANGLE CONVERSION — HEADLINE BUG-FIX CHECK]')];
T = [T; grow('Wing QC (25%c) sweep [deg]', 'L2', qc_sweep_wing, gt.wing_sweep_25pct_chord_deg.value, 'readme_geom.md Table 3', '%.4f', ...
    ['HEADLINE: was hardcoded 37 deg (bug), now computed ~32.2 deg via convert_sweep. No single Brandt cell for ' ...
     '"wing QC sweep" exists in the comparison JSON; 28.153 deg is the closest available figure but reflects Brandt''s ' ...
     'EXPOSED-PANEL-based sweep definition, not our full-planform convert_sweep definition -- the ~4 deg gap is an ' ...
     'expected, informative definitional difference (per IO''s handoff notes), NOT a bug to chase down in this pass.'])];

T = [T; srow('[TOTALS]')];
T = [T; grow('S_wet total, L1 statistical regression [ft^2]', 'L1', sw_l1, gt.whole_aircraft_S_wet_ft2.raw_buggy_total, 'Brandt Main!L3 (raw)', '%.2f', 'Roskam Vol.I Table 3.5 regression -- coarse by design')];
T = [T; grow('S_wet total, L2 OFFICIAL formula set    [ft^2]', 'L2', total_official, gt.whole_aircraft_S_wet_ft2.corrected_total, 'readme_geom.md Sec 6.2 (corrected)', '%.2f', 'wing+HT+VT (Roskam Eq.12.1) + fuselage (Roskam Eq.12.3) + duct')];
T = [T; grow('S_wet total, L2 OFFICIAL vs RAW BUGGY  [ft^2]', 'L2', total_official, gt.whole_aircraft_S_wet_ft2.raw_buggy_total, 'Brandt Geom!B19 (raw, double-counts strake)', '%.2f', 'Brandt''s own raw total double-counts the strake term (documented Excel bug, readme_geom.md Sec 6.2) -- corrected_total row above is the intended comparison target')];
T = [T; grow('S_wet total, Brandt-style formula set   [ft^2]', 'L2', total_brandt_style, gt.whole_aircraft_S_wet_ft2.corrected_total, 'readme_geom.md Sec 6.2 (corrected)', '%.2f', 'wing+HT+VT (Brandt uniform-tc) + fuselage (Brandt high-fi) + duct -- closer to Brandt''s own methodology')];

T = [T; srow('[OTHER GEOMETRY OUTPUTS]')];
T = [T; grow('Fuselage length L_fus [ft]', 'L2', L_fus_computed, NaN, 'f16a_L2.json .geometry (Brandt Main!B32)', '%.4f', 'Passthrough of the same Brandt Main-tab input the constructor reads -- reported for completeness, not an independent check')];
T = [T; grow('L_fus vs Brandt TOTAL aircraft length [ft]', 'L2', L_fus_computed, gt.aircraft_length_ft.value, 'Brandt Geom!B21', '%.4f', 'DIFFERENT quantity: fuselage length only (46.5 ft) vs Brandt''s total aircraft length incl. nose probe/pitot (48.30 ft) -- the ~3.7% gap is expected, not a bug')];
T = [T; grow('L1 fuselage length regression L_fus [ft]', 'L1', lfus_l1, L_fus_computed, 'F16GeomL2.L_fus (Brandt)', '%.4f', 'Raymer 6th ed. Table 6.3 statistical regression vs the Brandt-sourced L2 spec value')];
T = [T; grow('Max cross-section area Amax -- NOT MODELED [ft^2]', 'N/A', NaN, gt.Amax_ft2.value, 'Brandt Geom!B20/H47', '%.4f', 'No max-cross-section-area computation exists anywhere in GeomL1/GeomL2')];

% ════════════════════════════════════════════════════════════════════════ %
%  DISPLAY
% ════════════════════════════════════════════════════════════════════════ %

now_str = char(datetime('now', 'Format', 'yyyy-MM-dd'));
BAR     = repmat('=', 1, 110);

fprintf('\n%s\n', BAR);
fprintf('  F-16A BLOCK 10 -- GEOMETRY vs BRANDT GROUND TRUTH\n');
fprintf('  W_TO = %.0f lbf [Brandt B38]  |  Generated %s\n', W_TO, now_str);
fprintf('  Source: VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json [.geometry] (Brandt-direct, NOT F16Baseline.m)\n');
fprintf('%s\n\n', BAR);

disp(T);

fprintf('  NOTES\n');
fprintf('  Wing/HT/VT S_wet: OFFICIAL = Roskam Eq.12.1 (variable root/tip tc); alt = Brandt''s own\n');
fprintf('    uniform-tc formula (compute_wet_planform) -- the alt option matches Brandt near-exactly\n');
fprintf('    by construction (it IS Brandt''s formula fed Brandt''s own inputs).\n');
fprintf('  Fuselage S_wet: OFFICIAL = Roskam Eq.12.3 (equivalent-diameter cylinder); two Brandt\n');
fprintf('    alternates (low-fi ''1/3-cone+2/3-cyl'', high-fi frame-integration) are also available.\n');
fprintf('  Duct/nacelle %%Diff is large by definition (different physical quantities), not a bug.\n');
fprintf('  Wing QC sweep: the historical 37 deg hardcoded bug is fixed (now ~32.2 deg); see that\n');
fprintf('    row''s Notes for why the ~28.15 deg Brandt comparison figure isn''t an exact match target.\n');
fprintf('  Whole-aircraft S_wet total: Brandt''s own RAW total (Geom!B19) double-counts the strake\n');
fprintf('    wetted area (documented Excel bug) -- the CORRECTED total is the intended comparison target.\n');
fprintf('\n%s\n\n', BAR);

% ════════════════════════════════════════════════════════════════════════ %
%  EXPORT
% ════════════════════════════════════════════════════════════════════════ %

out_json = fullfile(script_dir, 'geometry_brandt_comparison.json');
out_md   = fullfile(script_dir, 'geometry_brandt_comparison.md');

data.generated = now_str;
data.aircraft  = 'F-16A Block 10';
data.W_TO_lbf  = W_TO;
data.source    = 'VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json [.geometry]';
data.rows      = table_to_rows(T);

fid = fopen(out_json, 'w');
fprintf(fid, '%s', jsonencode(data, 'PrettyPrint', true));
fclose(fid);
fprintf('  JSON     -> %s\n', out_json);

write_markdown(T, out_md, W_TO, now_str);
fprintf('  Markdown -> %s\n\n', out_md);

T_all = T;

end

% ─── local helpers ───────────────────────────────────────────────────── %

function T = grow(name, fidelity, computed, expected, src, numfmt, notes)
%GROW  One-row comparison table: Fidelity / Computed / Brandt (expected) / %Diff / Source / Notes.
%   fidelity — which Geometry tier actually produced `computed` ('L1'/'L2'), or 'N/A' for a
%   quantity nothing currently models (Computed is NaN in that case too).
    if nargin < 7; notes = ''; end
    if isnan(computed)
        comp_s = 'N/A';
    else
        comp_s = sprintf(numfmt, computed);
    end
    if isnan(expected)
        exp_s = 'N/A';
        err_s = ' - ';
    else
        exp_s = sprintf(numfmt, expected);
        if isnan(computed)
            err_s = ' - ';
        elseif expected ~= 0
            err_s = sprintf('%+.2f%%', 100*(computed - expected)/expected);
        else
            err_s = 'N/A';
        end
    end
    T = table({fidelity}, {comp_s}, {exp_s}, {err_s}, {src}, {notes}, ...
        'VariableNames', {'Fidelity', 'Computed', 'Brandt', 'PctDiff', 'Source', 'Notes'}, ...
        'RowNames', {name});
end

function T = srow(label)
%SROW  Section separator row.
    T = table({'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, ...
        'VariableNames', {'Fidelity', 'Computed', 'Brandt', 'PctDiff', 'Source', 'Notes'}, ...
        'RowNames', {label});
end

function rows = table_to_rows(T)
%TABLE_TO_ROWS  Convert the comparison table to a struct array for jsonencode.
    n = height(T);
    for r = n:-1:1   % reverse iteration pre-allocates the struct array
        rows(r).parameter = T.Properties.RowNames{r};
        rows(r).Fidelity  = T.Fidelity{r};
        rows(r).Computed  = T.Computed{r};
        rows(r).Brandt    = T.Brandt{r};
        rows(r).PctDiff   = T.PctDiff{r};
        rows(r).Source    = T.Source{r};
        rows(r).Notes     = T.Notes{r};
    end
end

function write_markdown(T, out_path, W_TO, now_str)
%WRITE_MARKDOWN  Render the comparison table as a markdown file.
    fid = fopen(out_path, 'w');
    fprintf(fid, '# F-16A Block 10 — Geometry vs Brandt Ground Truth\n\n');
    fprintf(fid, 'Generated %s. W_TO = %.0f lbf [Brandt B38].\n\n', now_str, W_TO);
    fprintf(fid, ['Source: `VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json` [`.geometry`] ' ...
        '(Brandt-direct ground truth -- NOT `F16Baseline.m`, which is the older T.O.-manual-based ' ...
        'ground truth used by `fidelity_comparison.m`).\n\n']);
    fprintf(fid, ['This is a **comparison report**, not a test -- no pass/fail assertions. ' ...
        'Where a quantity has multiple implementation options, each option gets its own row.\n\n']);
    fprintf(fid, '| Parameter | Fidelity | Computed | Brandt | %%Diff | Source | Notes |\n');
    fprintf(fid, '|---|---|---|---|---|---|---|\n');
    n = height(T);
    for r = 1:n
        name = T.Properties.RowNames{r};
        if strcmp(T.Computed{r}, '---')
            fprintf(fid, '| **%s** | | | | | | |\n', strrep(name, '|', '\|'));
        else
            fprintf(fid, '| %s | %s | %s | %s | %s | %s | %s |\n', ...
                strrep(name, '|', '\|'), T.Fidelity{r}, T.Computed{r}, T.Brandt{r}, T.PctDiff{r}, ...
                strrep(T.Source{r}, '|', '\|'), strrep(T.Notes{r}, '|', '\|'));
        end
    end
    fclose(fid);
end
