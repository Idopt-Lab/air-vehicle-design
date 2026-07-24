function data = mission_brandt_comparison()
%MISSION_BRANDT_COMPARISON  F-16A CAP mission (L1/L2/L3) vs Brandt Miss-tab
%   ground truth.
%
%   NOT A TEST. No pass/fail assertions, not part of run_all_tests -- a pure
%   reporting script, per CLAUDE.md's two-test-tier rule and
%   docs/subplans/07_mission_analysis.md's "Tests" section.
%
%   *** READ THIS BEFORE INTERPRETING THE OUTPUT ***
%   The CAP profile (examples/F16A/mission_profile.json, 10 segments) and
%   Brandt's own Miss-tab profile (VnV/BrandtF16A/BrandtMission.m /
%   GroundTruth/f16a_geometry.json, 14 segments) are TWO DIFFERENT MISSION
%   PROFILES BY DESIGN -- see subplan 07's "CAP mission profile vs. Brandt's
%   14-segment Miss-tab profile" section. CAP omits Accel/Egress as distinct
%   legs, and its Dash (M=1.60)/Combat (M=0.80, 25 kft) conditions differ
%   from Brandt's own Dash/Combat (M=0.87 both). A 10-25% difference in
%   total fuel is DOCUMENTED, EXPECTED PRECEDENT (temp_AI/docs/disciplines/
%   05_mission_analysis.md Sec.7), not a bug to chase down. This script
%   prints that caveat and NEVER asserts closeness -- it exists purely to
%   put both numbers side by side for a human reader.
%
%   Fills in the mission-level SUMMARY rows only (Total mission fuel, Final
%   W/W_TO after Loiter) in the pre-registered
%   examples/F16A/mission_brandt_comparison.json -- per-segment rows stay
%   "N/A (different profile)" (CAP and Brandt's Miss tab have different
%   segment sets, so a segment-by-segment mapping doesn't make sense; see
%   subplan 07). Two of the four pre-registered summary rows -- "Total
%   mission time" and "Landing ground roll distance" -- are marked
%   "N/A (not computed)" rather than fabricated: MissionL1/L2/L3's
%   get_mission_fuel breakdown struct (segment_names/fuel_used_lbf/
%   W_after_lbf/W_TO_lbf/total_fuel_used_lbf/Mff/W_fuel_lbf) does not
%   currently return a time or ground-roll-distance total at any fidelity
%   level -- see this pass's report to the coordinator for the full
%   finding (not fixed here; test-writer's role is reporting, not patching
%   src/ or examples/F16A/F16Mission*.m).
%
%   Outputs (written to the same directory as this script):
%     mission_brandt_comparison.json  — updated in place (Computed/PctDiff
%                                        fields for the 4 summary rows only)
%     mission_brandt_comparison.md    — rendered markdown table
%
%   *** SECOND FINDING, reported alongside the above: F16MissionL1/L2/L3's
%   compute_fuel(obj, aero, prop, W_TO) signature returns ONLY the scalar
%   W_fuel -- it discards the second "breakdown" struct that
%   MissionL1/L2/L3.get_mission_fuel produces (see e.g. F16MissionL1.m:
%   "W_fuel = MissionL1.get_mission_fuel(obj.missiondata, W_TO, aero,
%   prop);" -- only the first output is captured). This report needs the
%   per-segment breakdown (to find "W after Loiter"), so it calls the
%   static toolboxes (MissionL1/L2/L3.get_mission_fuel) directly rather
%   than going through F16MissionL1/L2/L3.compute_fuel -- a legitimate
%   pattern for a reporting script, but flagging that the Tier-3 concrete
%   classes have no way to expose the breakdown to a caller that only has
%   the object (e.g. a future sizing-loop diagnostic) without bypassing
%   compute_fuel entirely.
%
%   REFERENCE SOURCES:
%     [Brandt]  VnV/BrandtF16A/BrandtMission.m; readme_mission.md; the
%               pre-registered examples/F16A/mission_brandt_comparison.json
%               (independently re-verified against the live Brandt-F16-A.xls
%               Miss tab, 2026-07-24, per that file's own _verification_note)
%     [CAP]     examples/F16A/mission_profile.json (F-16A CAP profile)

script_dir = fileparts(mfilename('fullpath'));
json_path  = fullfile(script_dir, 'mission_brandt_comparison.json');
data       = jsondecode(fileread(json_path));

W_TO = data.W_TO_lbf;   % 31,377 lbf -- this file's own registered value

% ════════════════════════════════════════════════════════════════════════ %
%  COMPUTE — run the actual CAP profile through all three fidelity levels
% ════════════════════════════════════════════════════════════════════════ %

m1 = F16MissionL1();
m2 = F16MissionL2();
m3 = F16MissionL3();

a1 = F16AeroL1(); p1 = F16PropL1();
a2 = F16AeroL2(); p2 = F16PropL2();
% NOTE (see file header / this pass's report): no F16PropL3 exists in this
% repo yet (only F16PropL1/F16PropL2, confirmed by directory listing) --
% F16PropL2 stands in for the propulsion object at Mission L3 too.
a3 = F16AeroL3(); p3 = F16PropL2();

[Wfuel1, bd1] = MissionL1.get_mission_fuel(m1.missiondata, W_TO, a1, p1);
[Wfuel2, bd2] = MissionL2.get_mission_fuel(m2.missiondata, W_TO, a2, p2);
[Wfuel3, bd3] = MissionL3.get_mission_fuel(m3.missiondata, W_TO, a3, p3);

loiter_idx = find(bd1.segment_names == "Loiter", 1);
wfrac1 = bd1.W_after_lbf(loiter_idx) / W_TO;
wfrac2 = bd2.W_after_lbf(loiter_idx) / W_TO;
wfrac3 = bd3.W_after_lbf(loiter_idx) / W_TO;

brandt_fuel_lb   = 6000.43;   % Miss!O9 [pre-registered in this file]
brandt_final_wf  = 0.6685;    % Miss!O12 [pre-registered in this file]

pd_fuel  = 100 * ([Wfuel1, Wfuel2, Wfuel3] - brandt_fuel_lb) / brandt_fuel_lb;
pd_wfrac = 100 * ([wfrac1, wfrac2, wfrac3] - brandt_final_wf) / brandt_final_wf;

% ════════════════════════════════════════════════════════════════════════ %
%  UPDATE the pre-registered JSON rows (4 summary rows only; per-segment
%  rows marked N/A per subplan 07 -- different mission profiles)
% ════════════════════════════════════════════════════════════════════════ %

for i = 1:numel(data.rows)
    p = string(data.rows(i).parameter);

    if startsWith(p, "Total mission fuel")
        data.rows(i).Fidelity = 'L1 / L2 / L3 (CAP profile)';
        data.rows(i).Computed = sprintf('L1=%.1f | L2=%.1f | L3=%.1f lb', Wfuel1, Wfuel2, Wfuel3);
        data.rows(i).PctDiff  = sprintf('L1=%+.1f%% | L2=%+.1f%% | L3=%+.1f%%', pd_fuel(1), pd_fuel(2), pd_fuel(3));

    elseif startsWith(p, "Total mission time")
        data.rows(i).Computed = 'N/A (not computed by MissionL1/L2/L3 -- get_mission_fuel''s breakdown has no time/duration total)';
        data.rows(i).PctDiff  = 'N/A';

    elseif startsWith(p, "Landing ground roll distance")
        data.rows(i).Computed = 'N/A (not computed by MissionL1/L2/L3 -- ground-roll distance is a Constraints-discipline quantity, not produced by Mission)';
        data.rows(i).PctDiff  = 'N/A';

    elseif startsWith(p, "Final W/W_TO")
        data.rows(i).Fidelity = 'L1 / L2 / L3 (CAP profile)';
        data.rows(i).Computed = sprintf('L1=%.4f | L2=%.4f | L3=%.4f', wfrac1, wfrac2, wfrac3);
        data.rows(i).PctDiff  = sprintf('L1=%+.2f%% | L2=%+.2f%% | L3=%+.2f%%', pd_wfrac(1), pd_wfrac(2), pd_wfrac(3));

    elseif startsWith(p, "Fuel:") || startsWith(p, "Time:") || startsWith(p, "W/W_TO after")
        % Per-segment Brandt Miss-tab rows -- CAP has a different 10-segment
        % set (see subplan 07), so a segment-by-segment mapping is not
        % meaningful. Per this task's explicit instruction: leave these as
        % "N/A (different profile)", not a forced mapping.
        data.rows(i).Computed = 'N/A (different profile)';
        data.rows(i).PctDiff  = 'N/A (different profile)';
    end
end

% ════════════════════════════════════════════════════════════════════════ %
%  DISPLAY
% ════════════════════════════════════════════════════════════════════════ %

now_str = char(datetime('now', 'Format', 'yyyy-MM-dd'));
BAR     = repmat('=', 1, 110);

fprintf('\n%s\n', BAR);
fprintf('  F-16A CAP MISSION (L1/L2/L3) vs BRANDT MISS-TAB GROUND TRUTH\n');
fprintf('  W_TO = %.0f lbf  |  Generated %s\n', W_TO, now_str);
fprintf('%s\n\n', BAR);

fprintf('  *** CAP (10 segments) and Brandt''s Miss tab (14 segments) are DIFFERENT\n');
fprintf('  *** mission profiles BY DESIGN (subplan 07). Large disagreement below is\n');
fprintf('  *** EXPECTED, documented precedent -- NOT a pass/fail comparison, NOT a bug.\n\n');

fprintf('  Total mission fuel [lb]:      L1=%8.1f   L2=%8.1f   L3=%8.1f   |  Brandt (Miss tab) = %.2f\n', ...
    Wfuel1, Wfuel2, Wfuel3, brandt_fuel_lb);
fprintf('  %%Diff vs. Brandt:             L1=%+7.1f%%  L2=%+7.1f%%  L3=%+7.1f%%\n', pd_fuel(1), pd_fuel(2), pd_fuel(3));
fprintf('  Final W/W_TO after Loiter:    L1=%8.4f   L2=%8.4f   L3=%8.4f   |  Brandt (Miss tab) = %.4f\n', ...
    wfrac1, wfrac2, wfrac3, brandt_final_wf);
fprintf('  %%Diff vs. Brandt:             L1=%+7.2f%%  L2=%+7.2f%%  L3=%+7.2f%%\n\n', pd_wfrac(1), pd_wfrac(2), pd_wfrac(3));

fprintf('  Per-segment fuel burn [lb] (CAP profile, L3):\n');
for i = 1:numel(bd3.segment_names)
    fprintf('    %-10s  %8.2f\n', bd3.segment_names(i), bd3.fuel_used_lbf(i));
end
fprintf('\n%s\n\n', BAR);

% ════════════════════════════════════════════════════════════════════════ %
%  EXPORT
% ════════════════════════════════════════════════════════════════════════ %

fid = fopen(json_path, 'w');
fprintf(fid, '%s', jsonencode(data, 'PrettyPrint', true));
fclose(fid);
fprintf('  JSON     -> %s (updated in place)\n', json_path);

out_md = fullfile(script_dir, 'mission_brandt_comparison.md');
write_markdown(data, out_md, W_TO, now_str);
fprintf('  Markdown -> %s\n\n', out_md);

end

% ─── local helpers ───────────────────────────────────────────────────── %

function write_markdown(data, out_path, W_TO, now_str)
%WRITE_MARKDOWN  Render the comparison rows as a markdown file (same
%   parameter/Fidelity/Computed/Brandt/PctDiff/Source/Notes column layout
%   geometry_brandt_comparison.m's write_markdown uses).
    fid = fopen(out_path, 'w');
    fprintf(fid, '# F-16A CAP Mission (L1/L2/L3) vs Brandt Miss-Tab Ground Truth\n\n');
    fprintf(fid, 'Generated %s. W_TO = %.0f lbf.\n\n', now_str, W_TO);
    fprintf(fid, ['**CAP (10 segments) and Brandt''s Miss tab (14 segments) are DIFFERENT mission profiles ' ...
        'by design** (docs/subplans/07_mission_analysis.md). Large disagreement on total fuel is documented, ' ...
        'expected precedent (temp_AI/docs/disciplines/05_mission_analysis.md Sec.7) -- this table is ' ...
        '**informational only**, never a pass/fail comparison.\n\n']);
    fprintf(fid, '| Parameter | Fidelity | Computed | Brandt | %%Diff | Source | Notes |\n');
    fprintf(fid, '|---|---|---|---|---|---|---|\n');
    n = numel(data.rows);
    for r = 1:n
        row = data.rows(r);
        name = char(string(row.parameter));
        if strcmp(char(string(row.Computed)), '---')
            fprintf(fid, '| **%s** | | | | | | |\n', strrep(name, '|', '\|'));
        else
            fprintf(fid, '| %s | %s | %s | %s | %s | %s | %s |\n', ...
                strrep(name, '|', '\|'), char(string(row.Fidelity)), char(string(row.Computed)), ...
                char(string(row.Brandt)), char(string(row.PctDiff)), ...
                strrep(char(string(row.Source)), '|', '\|'), strrep(char(string(row.Notes)), '|', '\|'));
        end
    end
    fclose(fid);
end
