function make_student_package(opts)
%MAKE_STUDENT_PACKAGE  Build the zippable AOE 4065 aerodynamics and wing design package.
%
%   MAKE_STUDENT_PACKAGE() does everything:
%     1. mlx        converts mlx_src/*.m (plain-text Live Code) into real .mlx
%                   files inside student_package/ -- START_HERE, lecture/, and
%                   the lab STUB only
%     2. instructor converts the lab SOLUTION into instructor_package/, which
%                   is NOT in the zip (the lab is the graded assignment)
%     3. smoke      runs every lecture source, the lab solution and
%                   check_lesson_numbers with the repository removed from the
%                   path, so the package must stand alone
%     4. zip        writes aero-wing-design.zip next to this file and checks
%                   that no SOLUTION file is inside it
%
%   The package has no copy of the sizing framework. The cross-check
%   against it is instructor-only: crosscheck_framework.m, next to this file.
%
%   MAKE_STUDENT_PACKAGE(steps = ["mlx" "zip"]) runs only those steps.
%   Valid steps: "mlx", "instructor", "smoke", "zip".
%
%   MAKE_STUDENT_PACKAGE(steps = "mlx", only = ["L01_baseline_737" "L03_wing_in_cruise"])
%   converts only those Live Scripts (base names). Use it while a reviewer
%   has other built .mlx files open in the Editor.
%
%   Run it from anywhere. The .mlx steps need the MATLAB desktop.

    arguments
        opts.steps (1,:) string {mustBeMember(opts.steps, ...
            ["mlx", "instructor", "smoke", "zip"])} = ...
            ["mlx", "instructor", "smoke", "zip"]
        opts.only  (1,:) string = strings(1, 0)
    end

    here   = fileparts(mfilename('fullpath'));       % .../sizing/teaching/aero-wing-design
    sizing = fileparts(fileparts(here));             % .../air_vehicle_design/sizing
    pkg    = fullfile(here, 'student_package');
    inst   = fullfile(here, 'instructor_package');

    assert(isfolder(fullfile(sizing, 'src')) && isfolder(fullfile(sizing, 'examples')), ...
        'make_student_package:badRoot', ...
        ['Expected the sizing root at %s, but it has no src/ and examples/. ', ...
         'This file must live at sizing/teaching/<lesson>/make_student_package.m.'], sizing);

    fprintf('\n==== AOE 4065 aerodynamics and wing design package ====\n');
    fprintf('source : %s\n', sizing);
    fprintf('target : %s\n\n', pkg);

    if ismember("mlx",        opts.steps), build_mlx(here, pkg, opts.only);         end
    if ismember("instructor", opts.steps), build_instructor(here, inst, opts.only); end
    if ismember("smoke",      opts.steps), smoke_test(here, pkg);        end
    if ismember("zip",        opts.steps), zip_package(here, pkg);       end

    fprintf('\n==== done ====\n');
end

% ------------------------------------------------------------------------
function build_mlx(here, pkg, only)
    fprintf('[Live Scripts]\n');
    jobs = { ...
        fullfile(here, 'mlx_src', 'START_HERE.m'),                pkg ; ...
        fullfile(here, 'mlx_src', 'lecture'),                     fullfile(pkg, 'lecture') ; ...
        fullfile(here, 'mlx_src', 'lab', 'LAB01_pick_the_AR.m'),  fullfile(pkg, 'lab') };
    run_jobs(jobs, only);
    % A solution must never be inside the student package
    leaked = dir(fullfile(pkg, '**', '*SOLUTION*'));
    if ~isempty(leaked)
        error('make_student_package:solutionLeak', ...
            'A SOLUTION file is inside student_package: %s', ...
            fullfile(leaked(1).folder, leaked(1).name));
    end
end

% ------------------------------------------------------------------------
function build_instructor(here, inst, only)
    fprintf('[instructor package (not zipped)]\n');
    run_jobs({fullfile(here, 'mlx_src', 'lab', 'LAB01_SOLUTION.m'), inst}, only);
end

function run_jobs(jobs, only)
    for k = 1:size(jobs, 1)
        src = jobs{k,1};  outDir = jobs{k,2};
        if ~isfolder(outDir), mkdir(outDir); end
        if isfolder(src)
            f = dir(fullfile(src, '*.m'));
            for j = 1:numel(f)
                convert_if_selected(fullfile(src, f(j).name), outDir, only);
            end
        else
            convert_if_selected(src, outDir, only);
        end
    end
end

function convert_if_selected(srcFile, outDir, only)
    [~, base] = fileparts(srcFile);
    if isempty(only) || ismember(string(base), only)
        convert_one(srcFile, outDir);
    end
end

% ------------------------------------------------------------------------
function convert_one(srcFile, outDir)
%CONVERT_ONE  Plain-text Live Code (.m) -> binary .mlx.
%   Uses openDocument/saveAs. Do NOT use matlab.internal.liveeditor.openAndSave
%   for a plain-text Live Code source: it copies the text verbatim into a
%   file with an .mlx extension.
    [~, base] = fileparts(srcFile);
    out = fullfile(outDir, [base '.mlx']);

    % Guard: an .mlx that changed after the last build was edited by hand
    % (for example during a review in the Live Editor). Rebuilding would
    % overwrite those edits, so stop and say what to do.
    check_not_edited(out);

    % A Live Script open in the editor locks its file, and saveAs then fails
    % with a misleading permissions message. Do not close a tab that someone
    % may be reviewing: stop and ask instead.
    stop_if_open(out);
    stop_if_open(srcFile);
    if isfile(out), delete(out); end

    [toConvert, tmpDir] = with_images(srcFile);
    doc = matlab.desktop.editor.openDocument(char(toConvert));
    doc.saveAs(char(out));
    doc.close();
    if tmpDir ~= "", rmdir(tmpDir, 's'); end
    record_stamp(out);

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
function [f, tmpDir] = with_images(srcFile)
%WITH_IMAGES  Embed the images that a source refers to, in a temporary copy.
%   A source line  %[text] ![alt](text:image:ID)  needs an appendix block
%   %[text:image:ID] with the base64 image data. The image files live in
%   mlx_src/images/ (listed in images.json), so the tracked .m sources stay
%   small and readable. Returns the source itself when it has no images.
    tmpDir = "";
    txt = fileread(srcFile);
    tok = regexp(txt, '\]\(text:image:(\w+)\)', 'tokens');
    if isempty(tok), f = srcFile; return; end
    ids = unique(string(cellfun(@(c) c{1}, tok, 'UniformOutput', false)));

    imgDir = fullfile(fileparts(mfilename('fullpath')), 'mlx_src', 'images');
    man    = jsondecode(fileread(fullfile(imgDir, 'images.json')));
    blocks = strings(0, 1);
    for id = ids
        assert(isfield(man, id), 'make_student_package:unknownImage', ...
            '%s refers to image "%s", which is not in mlx_src/images/images.json.', srcFile, id);
        e    = man.(id);
        p    = fullfile(imgDir, e.file);
        info = imfinfo(p);
        fid  = fopen(p);  bytes = fread(fid, inf, '*uint8');  fclose(fid);
        [~, ~, ext] = fileparts(p);
        mime = "image\/jpeg";  if strcmpi(ext, '.png'), mime = "image\/png"; end
        w = e.width;  h = round(info.Height*w/info.Width);
        blocks(end+1, 1) = "%[text:image:" + id + "]";                         %#ok<AGROW>
        blocks(end+1, 1) = "%   data: {""align"":""baseline"",""height"":" + h + ...
            ",""src"":""data:" + mime + ";base64," + matlab.net.base64encode(bytes) + ...
            """,""width"":" + w + "}";                                           %#ok<AGROW>
        blocks(end+1, 1) = "%---";                                               %#ok<AGROW>
    end

    tmpDir = string(tempname);  mkdir(tmpDir);
    [~, base] = fileparts(srcFile);
    f = fullfile(tmpDir, base + ".m");
    writelines([string(strip(txt, 'right')); blocks], f);
end

% ------------------------------------------------------------------------
function f = stamp_file()
    % Kept next to this file, not in the package, so it is never zipped.
    % Gitignored in teaching/aero-wing-design/.gitignore.
    f = fullfile(fileparts(mfilename('fullpath')), '.mlx_build_stamps.mat');
end

function check_not_edited(out)
    if ~isfile(out) || ~isfile(stamp_file()), return; end
    S   = load(stamp_file(), 'stamps');
    key = matlab.lang.makeValidName(char(out), 'ReplacementStyle', 'hex');
    if ~isfield(S.stamps, key), return; end
    d = dir(out);
    if abs(d.datenum - S.stamps.(key)) > 1/86400          % more than 1 s
        error('make_student_package:editedMlx', ...
            ['%s was changed after the last build (edited in the Live Editor?).\n', ...
             'Rebuilding would overwrite those edits. Copy the edits into the ', ...
             'plain-text source in mlx_src/ first, then delete this .mlx and rebuild.'], out);
    end
end

function record_stamp(out)
    stamps = struct();
    if isfile(stamp_file()), S = load(stamp_file(), 'stamps'); stamps = S.stamps; end
    key = matlab.lang.makeValidName(char(out), 'ReplacementStyle', 'hex');
    d = dir(out);
    stamps.(key) = d.datenum;
    save(stamp_file(), 'stamps');
end

% ------------------------------------------------------------------------
function n = check_rendering(srcFile, mlxFile)
%CHECK_RENDERING  Catch markup that silently fails to render (see l1-l2-sizing).
%   1. $$...$$ display equations (not supported: use one $...$ on its own line)
%   2. Markdown table rows (not supported: use a MATLAB table)
%   3. a bare * inside $...$ (Markdown eats it: write ^{\ast})
%   4. a SINGLE backslash before r or n, or before a LaTeX spacing/special
%      character (, ; ! & { } : or a space). In plain-text Live Code text
%      lines, \r and \n become line breaks (\right -> "ight", \rho -> "ho"),
%      and Markdown drops the backslash of \, \& and so on. Write every LaTeX
%      backslash as \\ -- the form the Live Editor itself writes.
    n = struct('empty_eq', 0, 'md_table', 0, 'bare_star', 0, 'md_escape', 0, 'total', 0);
    txt = string(splitlines(string(fileread(srcFile))));
    txt = txt(startsWith(txt, "%[text]"));
    n.md_table  = sum(startsWith(strtrim(extractAfter(txt, "%[text]")), "|"));
    n.bare_star = sum(~cellfun(@isempty, regexp(txt, '\$[^$]*\^\*', 'once')));
    body = regexprep(txt, ' \\$', '');                    % a final " \" ends a list: allowed
    body = strrep(body, '\\', '');                        % a double backslash is correct
    n.md_escape = sum(cellfun(@numel, regexp(body, '\\[rn,;!&{}: ]')));
    % 5. an unescaped _ inside $...$. Markdown can read two of them as
    %    *emphasis* and drop both: (L/D)_{max} = K_{LD} lost its subscripts.
    %    Write \_ inside math, as the Live Editor does.
    math = regexp(txt, '\$[^$]+\$', 'match');
    math = [math{:}];
    n.md_escape = n.md_escape + sum(cellfun(@numel, regexp(string(math), '(?<!\\)_')));
    % 6. an unescaped [ or ] inside $...$ ([...][...] can parse as a link).
    n.md_escape = n.md_escape + sum(cellfun(@numel, regexp(string(math), '(?<!\\)[\[\]]')));
    % 7. a final " \" ends a list. On a line that is not a list item it shows
    %    as a literal backslash; and a list whose last item lacks it runs on.
    isItem = ~cellfun(@isempty, regexp(txt, '^%\[text\] (- |\d+\. )', 'once'));
    isEnd  = endsWith(txt, " \");
    n.md_escape = n.md_escape + sum(isEnd & ~isItem);
    lastItem = isItem & ~[isItem(2:end); false];
    n.md_escape = n.md_escape + sum(lastItem & ~isEnd);
    % 8. math inside **bold** does not render: write **text** $math$ **text**.
    %    Pair the ** markers in order (1-2, 3-4, ...) and look inside each pair.
    for t = txt(:)'
        k = strfind(t, "**");
        for j = 1:2:numel(k) - 1
            n.md_escape = n.md_escape + contains(extractBetween(t, k(j) + 2, k(j+1) - 1), "$");
        end
    end
    try
        tmp = tempname; mkdir(tmp);
        unzip(mlxFile, tmp);
        doc = string(fileread(fullfile(tmp, 'matlab', 'document.xml')));
        n.empty_eq = count(doc, "<w:r><w:t/></w:r></w:customXml>");
        rmdir(tmp, 's');
    catch
        % cannot inspect: leave at 0 rather than fail the build
    end
    n.total = n.empty_eq + n.md_table + n.bare_star + n.md_escape;
    if n.total > 0
        warning('make_student_package:renderingProblem', ...
            '%s: %d empty equation box(es), %d Markdown table row(s), %d bare * in math, %d backslash escape(s).', ...
            srcFile, n.empty_eq, n.md_table, n.bare_star, n.md_escape);
    end
end

% ------------------------------------------------------------------------
function stop_if_open(f)
    try
        docs = matlab.desktop.editor.getAll;
    catch
        return          % no desktop, so nothing can be holding a lock
    end
    for k = 1:numel(docs)
        if strcmpi(docs(k).Filename, char(f))
            error('make_student_package:fileOpen', ...
                ['%s is open in the Editor. Close it first (save it, if you changed it; ', ...
                 'a saved edit to a built .mlx must then be copied into mlx_src/). ', ...
                 'To rebuild other scripts only, use the "only" option.'], f);
        end
    end
end

% ------------------------------------------------------------------------
function smoke_test(here, pkg)
%SMOKE_TEST  Run the material with only the package on the path.
%   Each script runs in its own function workspace (run_isolated), with
%   figures hidden. The lab STUB is not run: it stops at error("TODO 1").
    fprintf('[smoke test]\n');
    oldPath = path;  oldDir = pwd;  oldVis = get(0, 'DefaultFigureVisible');
    cleanup = onCleanup(@() restore_state(oldPath, oldDir, oldVis)); %#ok<NASGU>

    restoredefaultpath;                         % prove the package stands alone
    cd(pkg);  addpath(pkg);  setup_aero_path();
    set(0, 'DefaultFigureVisible', 'off');

    src = fullfile(here, 'mlx_src');
    scripts = [fullfile(src, "START_HERE.m"); ...
               fullfile(src, "lecture", ["L01_baseline_737.m"; "L02_airfoil_2D.m"; ...
                  "L03_wing_in_cruise.m"; "L04_low_speed.m"; "L05_nicolai_trends.m"]); ...
               fullfile(src, "lab", "LAB01_SOLUTION.m")];

    for k = 1:numel(scripts)
        t = tic;
        ws = run_isolated(scripts(k));
        close all force
        [~, nm] = fileparts(scripts(k));
        fprintf('      %-28s ok  (%.1f s)\n', nm, toc(t));
        switch nm
            case "START_HERE"
                LD = ws.smoke{4, 1};
                assert(abs(LD - 18.1) < 0.2, 'make_student_package:smokeLD', ...
                    'START_HERE cruise L/D is %.2f, expected about 18.1', LD);
            case "L05_nicolai_trends"
                G = ws.scoreGrid;
                agree = sum(cellfun(@(s) strcmp(strtrim(extractBefore(s, "|")), ...
                    strtrim(extractAfter(s, "|"))), cellstr(G{:,:})), 'all');
                assert(isequal(size(G), [6 6]) && agree == 30, 'make_student_package:smokeTrends', ...
                    'L05: grid %dx%d with %d cells agreeing, expected 6x6 and 30', size(G, 1), size(G, 2), agree);
            case "LAB01_SOLUTION"
                assert(ws.answer{1, 1} == 9, 'make_student_package:smokeLab', ...
                    'Lab: best AR %.2f, expected 9.0', ws.answer{1, 1});
        end
    end

    % Every number quoted in the text, re-derived
    addpath(here);
    assert(check_lesson_numbers(string(pkg)), 'make_student_package:quotedNumbers', ...
        'check_lesson_numbers found a quoted number that the code no longer gives.');
end

function ws = run_isolated(scriptFile)
    evalc('run(char(scriptFile))');         % runs in this function's workspace; output not echoed
    names = who;
    ws = struct();
    for k = 1:numel(names)
        if ~ismember(names{k}, {'scriptFile', 'ws', 'names', 'k'})
            ws.(names{k}) = eval(names{k});
        end
    end
end

function restore_state(oldPath, oldDir, oldVis)
    path(oldPath);  cd(oldDir);  set(0, 'DefaultFigureVisible', oldVis);
end

% ------------------------------------------------------------------------
function zip_package(here, pkg)
%ZIP_PACKAGE  Archive the package under the lesson name (aero-wing-design/).
    fprintf('[zip]\n');
    [~, lesson] = fileparts(here);

    stage = tempname;
    mkdir(stage);
    cleaner = onCleanup(@() rmdir(stage, 's')); %#ok<NASGU>
    copyfile(pkg, fullfile(stage, lesson));
    % Editor autosave files (from a review in the Live Editor) never ship
    junk = [dir(fullfile(stage, lesson, '**', '*.asv')); dir(fullfile(stage, lesson, '**', '*.autosave'))];
    for k = 1:numel(junk), delete(fullfile(junk(k).folder, junk(k).name)); end

    out = fullfile(here, [lesson '.zip']);
    if isfile(out), delete(out); end
    entries = zip(out, lesson, stage);

    assert(~any(contains(entries, "SOLUTION", 'IgnoreCase', true)), ...
        'make_student_package:solutionInZip', 'The zip contains a solution file.');
    d = dir(out);
    fprintf('      %s  (%.2f MB, %d files)\n', out, d.bytes/1e6, numel(entries));
    fprintf('      unpacks to:  %s%s\n', lesson, filesep);
end
