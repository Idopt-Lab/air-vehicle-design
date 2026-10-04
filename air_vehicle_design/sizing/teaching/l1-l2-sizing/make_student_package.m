function make_student_package(opts)
%MAKE_STUDENT_PACKAGE  Build the zippable AOE 4065 sizing package.
%
%   MAKE_STUDENT_PACKAGE() does everything:
%     1. copies the framework (src/ plus the B777 and F16A examples) into
%        student_package/framework/, with the exclusions listed below
%     2. converts every mlx_src/*.m plain-text Live Script into a real .mlx
%        inside the package
%     3. runs a smoke test on the package, standing outside the repo path
%     4. writes student_package.zip next to the package folder
%
%   MAKE_STUDENT_PACKAGE(steps = ["framework" "mlx"]) runs only those steps.
%   Valid steps: "framework", "mlx", "guide", "smoke", "zip".
%
%   WHAT IS EXCLUDED, AND WHY
%     VnV/                   55 MB of Brandt spreadsheet ground truth; the
%                            course does not use it
%     */sanity_checks/       needs VnV
%     F16A/generators/       cross-fidelity demos, not part of the lesson
%     */studies/             superseded by lecture/ and lab/, and the only
%                            place the out-of-scope T-S material lives
%     f16_brandt_stack.m     these three construct VnV Brandt classes
%     f16_sizing_brandt_L1.m
%     f16_sizing_brandt_L2.m
%     */output/              generated artefacts
%     docs/, temp_Casey/     not needed to run anything
%     *.asv, *.autosave      MATLAB autosave litter
%
%   Run it from anywhere. The .mlx step needs the MATLAB desktop.

    arguments
        opts.steps (1,:) string = ["framework", "mlx", "guide", "smoke", "zip"]
    end

    here    = fileparts(mfilename('fullpath'));      % .../sizing/teaching/l1-l2-sizing
    sizing  = fileparts(fileparts(here));            % .../air_vehicle_design/sizing
    pkg     = fullfile(here, 'student_package');
    fw      = fullfile(pkg, 'framework');

    assert(isfolder(fullfile(sizing, 'src')) && isfolder(fullfile(sizing, 'examples')), ...
        'make_student_package:badRoot', ...
        ['Expected the sizing root at %s, but it has no src/ and examples/. ', ...
         'This file must live at sizing/teaching/<lesson>/make_student_package.m.'], sizing);

    fprintf('\n==== AOE 4065 sizing package ====\n');
    fprintf('source : %s\n', sizing);
    fprintf('target : %s\n\n', pkg);

    if ismember("framework", opts.steps), copy_framework(sizing, fw); end
    if ismember("mlx",       opts.steps), build_mlx(here, pkg);       end
    if ismember("guide",     opts.steps), build_guide(here, pkg);     end
    if ismember("smoke",     opts.steps), smoke_test(pkg);            end
    if ismember("zip",       opts.steps), zip_package(here, pkg);     end

    fprintf('\n==== done ====\n');
end

% ------------------------------------------------------------------------
function copy_framework(sizing, fw)
%COPY_FRAMEWORK  Copy only the part of the framework the two classes use.
%
%   Students open lecture/ and lab/. They never open framework/. Every file
%   in there that the course does not touch is navigational noise, so the
%   copy is pruned to the disciplines that are actually loaded.
%
%   PRUNED, and why:
%     *.md                     companion docs. Every equation keeps its
%                              citation in the .m file's own comments; the
%                              expanded write-ups live in the course repo.
%                              57 files, 373 kB, zero runtime value.
%     stability_control/       no lecture or lab script constructs one
%     subsystems/
%     landing_gear/            nothing the course runs references it, and
%                              WeightsL2.compute_weight_landing_gear is
%                              self-contained (a weight-ratio lookup, not
%                              the landing-gear discipline)
%     the whole Level-3 tier   the course teaches L1 and L2 only
%     TSDiagram, ControlSurfaceSizer   T-S is a separate lesson; the
%                              control-surface sizer is not in either loop
%     reporting/               used only by the excluded sanity checks
%
%   NOT pruned even though a static dependency scan calls them unreachable:
%   every class under src/constraints/ and src/core/mission/segments/.
%   Those are built DYNAMICALLY from a ConstraintType dictionary and a
%   segment-type switch, so matlab.codetools.requiredFilesAndProducts cannot
%   see them. Deleting them passes a static audit and then fails at run time.
%   This is why the prune is verified by the smoke test, not by the scan.

    fprintf('[framework]\n');
    if isfolder(fw), rmdir(fw, 's'); end
    mkdir(fw);

    srcSkipDirs = ["stability_control", "subsystems", "reporting", "landing_gear"];
    srcSkipFiles = [ ...
        "StabControlBase.m", "SubsystemsBase.m", ...
        "TSDiagram.m", "ControlSurfaceSizer.m", ...
        "AeroL3.m", "AeroModelL3.m", ...
        "GeomL3.m", "GeometryModelL3.m", ...
        "WeightsL3.m", "WeightsModelL3.m", ...
        "TailL2.m"];
    copy_tree(fullfile(sizing, 'src'), fullfile(fw, 'src'), ...
              srcSkipDirs, srcSkipFiles);

    copy_tree(fullfile(sizing, 'examples', 'B777'), ...
              fullfile(fw, 'examples', 'B777'), ...
              ["studies", "sanity_checks", "output"], strings(0));

    f16SkipDirs = ["sanity_checks", "generators", "studies", "output", ...
                   "sandc", "subsystems", "landing_gear"];
    f16SkipFiles = [ ...
        "f16_brandt_stack.m", "f16_sizing_brandt_L1.m", "f16_sizing_brandt_L2.m", ...
        "F16AeroL3.m", "F16GeomL3.m", "F16WeightsL3.m", ...
        "F16GeomBrandtAlt.m", "F16TailL2.m", ...
        "f16_sizing_L3.m", "f16a_stations_path.m", ...
        "f16a_L3.json", "F16_geom_stations.json"];
    copy_tree(fullfile(sizing, 'examples', 'F16A'), ...
              fullfile(fw, 'examples', 'F16A'), ...
              f16SkipDirs, f16SkipFiles);

    write_framework_readme(fw);

    f = dir_recursive(fw);
    nm = sum(endsWith(string({f.name}), ".m"));
    fprintf('      %d files (%d .m), %.1f MB\n', numel(f), nm, folder_mb(fw));
end

% ------------------------------------------------------------------------
function copy_tree(src, dst, skipDirs, skipFiles)
    arguments
        src, dst
        skipDirs  (1,:) string = strings(0)
        skipFiles (1,:) string = strings(0)
    end
    if ~isfolder(src)
        error('make_student_package:missingSource', 'No such folder: %s', src);
    end
    if ~isfolder(dst), mkdir(dst); end

    items = dir(src);
    for k = 1:numel(items)
        it = items(k);
        if any(strcmp(it.name, {'.', '..'})), continue; end
        s = fullfile(src, it.name);
        d = fullfile(dst, it.name);
        if it.isdir
            if any(strcmpi(it.name, skipDirs)), continue; end
            copy_tree(s, d, skipDirs, skipFiles);
        else
            [~, ~, ext] = fileparts(it.name);
            if any(strcmpi(ext, {'.asv', '.autosave', '.md'})), continue; end
            if any(strcmpi(it.name, skipFiles)), continue; end
            copyfile(s, d);
        end
    end
end

% ------------------------------------------------------------------------
function build_mlx(here, pkg)
    fprintf('[Live Scripts]\n');
    jobs = { ...
        fullfile(here, 'mlx_src', 'START_HERE.m'),                     pkg ; ...
        fullfile(here, 'mlx_src', 'lecture'),                          fullfile(pkg, 'lecture') ; ...
        fullfile(here, 'mlx_src', 'lab', 'LAB00_warmup_L1_loop.m'),    fullfile(pkg, 'lab') ; ...
        fullfile(here, 'mlx_src', 'lab', 'LAB01_write_the_L2_loop.m'), fullfile(pkg, 'lab') ; ...
        fullfile(here, 'mlx_src', 'lab', 'LAB01_SOLUTION.m'),          fullfile(pkg, 'lab', 'solution') };

    for k = 1:size(jobs, 1)
        src = jobs{k,1};  outDir = jobs{k,2};
        if ~isfolder(outDir), mkdir(outDir); end
        if isfolder(src)
            f = dir(fullfile(src, '*.m'));
            for j = 1:numel(f)
                convert_one(fullfile(src, f(j).name), outDir);
            end
        else
            convert_one(src, outDir);
        end
    end
end

% ------------------------------------------------------------------------
function convert_one(srcFile, outDir)
    [~, base] = fileparts(srcFile);
    out = fullfile(outDir, [base '.mlx']);

    % A Live Script left open in the editor holds a lock on its file, and
    % saveAs then fails with a misleading "check the folder permissions".
    % Close anything already pointing at either path first.
    close_if_open(out);
    close_if_open(srcFile);

    if isfile(out), delete(out); end

    doc = matlab.desktop.editor.openDocument(char(srcFile));
    doc.saveAs(char(out));
    doc.close();

    assert(isfile(out), 'make_student_package:mlxFailed', 'Could not write %s', out);
    fid = fopen(out);  magic = fread(fid, 4, '*uint8').';  fclose(fid);
    assert(isequal(double(magic), [80 75 3 4]), ...
        'make_student_package:notBinaryMlx', '%s is not a binary .mlx file.', out);

    n = check_rendering(srcFile, out);
    if n.total == 0
        fprintf('      %s.mlx\n', base);
    else
        fprintf('      %s.mlx   <-- %d RENDERING PROBLEM(S)\n', base, n.total);
    end
end

% ------------------------------------------------------------------------
function n = check_rendering(srcFile, mlxFile)
%CHECK_RENDERING  Catch markup that silently fails to render.
%
%   The Live Editor accepts a SUBSET of Markdown and LaTeX, and it fails
%   quietly: unsupported markup is stripped and the raw text is left behind.
%   Three failures have actually happened in this package, so each is now a
%   build-time check:
%
%     1. $$...$$ display equations. Not supported. The parser reads them as
%        two adjacent EMPTY inline equations and leaves the LaTeX as plain
%        text. Use a single $...$ on its own line instead.
%     2. Markdown tables. Not supported. The pipe rows render verbatim.
%        Use a real MATLAB table, which displays properly and is live data.
%     3. A bare * inside $...$. Markdown emphasis runs first and eats it, so
%        (W/S)^* renders as (W/S)^. Write ^{\ast}.
%
%   Checked against the generated .mlx, not the source, because what matters
%   is what the student sees.

    n = struct('empty_eq', 0, 'md_table', 0, 'bare_star', 0, 'total', 0);

    src = string(fileread(srcFile));
    txt = string(splitlines(src));
    txt = txt(startsWith(txt, "%[text]"));

    n.md_table  = sum(startsWith(strtrim(extractAfter(txt, "%[text]")), "|"));
    n.bare_star = sum(~cellfun(@isempty, regexp(txt, '\$[^$]*\^\*', 'once')));

    % An empty equation box is the fingerprint of $$...$$ in the output.
    try
        tmp = tempname; mkdir(tmp);
        unzip(mlxFile, tmp);
        doc = string(fileread(fullfile(tmp, 'matlab', 'document.xml')));
        n.empty_eq = count(doc, "<w:r><w:t/></w:r></w:customXml>");
        rmdir(tmp, 's');
    catch
        % cannot inspect: leave at 0 rather than fail the build
    end

    n.total = n.empty_eq + n.md_table + n.bare_star;
    if n.total > 0
        warning('make_student_package:renderingProblem', ...
            ['%s: %d empty equation box(es) from $$...$$, %d Markdown table ', ...
             'row(s), %d bare * inside math. None of these render in the Live ', ...
             'Editor. See check_rendering in make_student_package.m.'], ...
            srcFile, n.empty_eq, n.md_table, n.bare_star);
    end
end

% ------------------------------------------------------------------------
function write_framework_readme(fw)
%WRITE_FRAMEWORK_README  A map, so nobody has to guess what matters in here.
    txt = [ ...
"# framework/ — you do not need to open this"                                   newline ...
""                                                                              newline ...
"This is the AOE 4065 sizing framework. The lecture and lab scripts call into"  newline ...
"it; you are not asked to read or edit any of it."                              newline ...
""                                                                              newline ...
"It is already pruned. The full framework is about twice this size — the"       newline ...
"stability-and-control, subsystems and landing-gear disciplines, the whole"     newline ...
"Level-3 tier, the T–S diagram and the validation data are all left out,"       newline ...
"because this course does not use them."                                        newline ...
""                                                                              newline ...
"## If you are curious, read these six files, in this order"                    newline ...
""                                                                              newline ...
"| # | File | Why |"                                                            newline ...
"|---|---|---|"                                                                 newline ...
"| 1 | `src/sizing/SizingSteps.m` | 73 lines. The weight closure and the under-relaxation step. The whole method is in here. |" newline ...
"| 2 | `src/sizing/SizingLoopL1.m` | The one-state loop. |"                     newline ...
"| 3 | `src/sizing/SizingLoopL2.m` | The two-state loop — the one you write in the lab. |" newline ...
"| 4 | `src/constraints/ConstraintAnalysis.m` | Turns requirements into a design point. |" newline ...
"| 5 | `examples/B777/models/disciplines/aero/B777AeroL1.m` | A concrete discipline model, for shape. |" newline ...
"| 6 | `examples/B777/inputs/b777_requirements.json` | What the aircraft must DO, as data. |" newline ...
""                                                                              newline ...
"## How the discipline models are organised"                                    newline ...
""                                                                              newline ...
"Three layers, which is worth knowing even if you never edit them:"             newline ...
""                                                                              newline ...
"- `src/base/*Base.m` — abstract. Declares what every model of that kind must answer." newline ...
"- `src/disciplines/<x>/<X>ModelL<N>.m` — abstract, per fidelity level."        newline ...
"- `examples/<aircraft>/models/disciplines/...` — the concrete aircraft class."  newline ...
""                                                                              newline ...
"Alongside them sit the **static equation toolboxes**, `src/disciplines/<x>/<X>L<N>.m`." newline ...
"Those hold the textbook equations, each with its citation in a comment. A"     newline ...
"concrete class is mostly one-line delegations into a toolbox. That split is"   newline ...
"deliberate: the equations are shared between aircraft and between fidelity"    newline ...
"levels, so they live in exactly one place."                                    newline ...
""                                                                              newline ...
"## Citations"                                                                  newline ...
""                                                                              newline ...
"Every equation cites its source in the comment above it — Raymer chapter and"  newline ...
"equation, Roskam part and equation, Mattingly, Nicolai, or the Martins"        newline ...
"metabook. Search for `Raymer` or `metabook` in any `.m` file."                 newline ...
""                                                                              newline ...
"The longer companion write-ups (`*.md` next to each class) are not shipped"    newline ...
"here, to keep this folder navigable. They are in the course repository."       newline];
    fid = fopen(fullfile(fw, 'README.md'), 'w');
    fwrite(fid, strjoin(txt, ''));
    fclose(fid);
end

% ------------------------------------------------------------------------
function close_if_open(f)
%CLOSE_IF_OPEN  Close an editor document for this file, if one exists.
    try
        docs = matlab.desktop.editor.getAll;
    catch
        return          % no desktop, so nothing can be holding a lock
    end
    target = lower(char(f));
    for k = 1:numel(docs)
        if strcmpi(docs(k).Filename, target)
            try
                docs(k).closeNoPrompt();
            catch
                try, docs(k).close(); catch, end
            end
        end
    end
end

% ------------------------------------------------------------------------
function build_guide(here, pkg)
%BUILD_GUIDE  Render the diagrams and compile the written guide.
%   Shells out to the guide_src build script. Skipped with a warning when
%   the toolchain (pdflatex) is not on this machine, so the rest of the
%   package still builds.
    fprintf('[guide]\n');
    gsrc = fullfile(here, 'guide_src');
    bat  = fullfile(gsrc, 'build_guide.sh');
    if ~isfile(bat)
        warning('make_student_package:noGuideScript', ...
            'No %s. Skipping the guide.', bat);
        return
    end
    % Pick a bash that understands Windows drive-letter paths. On this
    % machine plain "bash" resolves to the WSL stub in WindowsApps, which
    % cannot see C:\..., so prefer Git for Windows when it is installed.
    candidates = ["C:\Program Files\Git\bin\bash.exe", ...
                  "C:\Program Files (x86)\Git\bin\bash.exe"];
    sh = "bash";
    for k = 1:numel(candidates)
        if isfile(candidates(k)), sh = candidates(k); break; end
    end

    fwd = @(p) strrep(char(p), '\', '/');
    cmd = sprintf('"%s" "%s" "%s" "%s"', sh, ...
        fwd(bat), fwd(gsrc), fwd(fullfile(pkg, 'guide')));
    [st, out] = system(cmd);
    disp(out);
    if st ~= 0
        warning('make_student_package:guideFailed', ...
            'The guide build returned %d. The package is still usable.', st);
    end
end

% ------------------------------------------------------------------------
function smoke_test(pkg)
    fprintf('[smoke test]\n');
    oldPath = path;  oldDir = pwd;
    cleanup = onCleanup(@() restore_state(oldPath, oldDir)); %#ok<NASGU>

    restoredefaultpath;                       % prove the package stands alone
    cd(pkg);
    addpath(pkg);
    setup_sizing_path();

    [a, p, w, g, m, c] = build_b777_stack();
    r1 = SizingLoopL1(a, p, w, g, m, c).run(700000);
    assert(r1.converged && abs(r1.W_TO - 740125) < 5000, ...
        'make_student_package:smokeB777', 'B777 L1 gave %.1f lbf', r1.W_TO);
    fprintf('      B777  SizingLoopL1  W_TO = %.0f lbf  (%d iters)\n', r1.W_TO, r1.n_iter);

    [a, p, w, g, m, c, t] = build_f16_stack_L2();
    r2 = SizingLoopL2(a, p, w, g, m, c, t).run(30000, 20000);
    assert(r2.converged, 'make_student_package:smokeF16', 'F-16 L2 did not converge');
    fprintf('      F-16A SizingLoopL2  W_TO = %.0f lbf  (%d iters)\n', r2.W_TO, r2.n_iter);
end

function restore_state(oldPath, oldDir)
    path(oldPath);  cd(oldDir);
end

% ------------------------------------------------------------------------
function zip_package(here, pkg)
    fprintf('[zip]\n');
    out = fullfile(here, 'student_package.zip');
    if isfile(out), delete(out); end
    zip(out, pkg);
    d = dir(out);
    fprintf('      %s  (%.1f MB)\n', out, d.bytes/1e6);
end

% ------------------------------------------------------------------------
function f = dir_recursive(root)
    f = dir(fullfile(root, '**', '*'));
    f = f(~[f.isdir]);
end

function mb = folder_mb(root)
    f = dir_recursive(root);
    mb = sum([f.bytes]) / 1e6;
end
