classdef ComparisonReport
%COMPARISONREPORT  Shared builder/renderer for the *_brandt_comparison reports.
%
%   ONE renderer for all four discipline comparison reports (geometry,
%   aerodynamics, propulsion, weights) so their console/.json/.md outputs are
%   identical in shape by construction.
%
%   THE COLUMN SCHEME (identical in every report):
%
%     Parameter | Fidelity | Computed | Reference | %Diff | 2nd Source |
%     Divergence | Cite | Notes
%
%     Parameter   what was computed, with units
%     Fidelity    which tier produced it -- 'L1'/'L2'/'L3', 'N/A', or '--' for
%                 a reported-but-rejected variant
%     Computed    the framework's value
%     Reference   the primary ground-truth value (Brandt today)
%     %Diff       (Computed - Reference)/Reference, signed
%     2nd Source  the report's second ground truth, named in its preamble.
%                 Where the two sources disagree the L3 tier follows the
%                 physical one; this column makes that visible.
%     Divergence  three states -- see `row`'s help below
%     Cite        where the Reference value comes from (cell / document)
%     Notes       why the numbers differ, in words
%
%   These reports are INFORMATIONAL ONLY. No pass/fail assertions, not part of
%   run_all_tests, and no value may ever backfill a unit test's expected value
%   (CLAUDE.md's two-tier rule).

    methods (Static)

        function T = row(name, fidelity, computed, reference, cite, numfmt, notes, second, divergence)
        %ROW  One comparison row.
        %
        %   name       parameter label, units included
        %   fidelity   'L1' / 'L2' / 'L3' / 'L2/L3' / 'N/A' / '--' / 'spec'
        %   computed   framework value; NaN renders 'N/A'
        %   reference  primary ground-truth value; NaN renders 'N/A' and blanks %Diff
        %   cite       provenance of `reference`
        %   numfmt     sprintf format for the numeric columns, e.g. '%.4f'
        %   notes      OPTIONAL free text
        %   second     OPTIONAL second source: numeric (formatted with numfmt) or
        %              a char/string passed through verbatim. NaN/omitted -> 'N/A'
        %   divergence OPTIONAL annotation:
        %       'BY DESIGN'    same KIND of quantity as the reference, but expected
        %                      to differ -- a different formula family, or a locked
        %                      decision to follow a physical/T.O. value where the
        %                      reference uses its own. The %Diff is meaningful and
        %                      should be sanity-checked for magnitude.
        %       'DEFINITIONAL' a different kind of quantity altogether (uninstalled
        %                      vs installed engine weight; an exposed inlet-to-exit
        %                      duct vs a full-cylinder nacelle; a minimum bound vs a
        %                      central estimate). The %Diff is NOT an error measure
        %                      -- do not chase it.
        %       ''             a genuine agreement check; a large %Diff here IS
        %                      worth chasing.
            arguments
                name       {mustBeTextScalar}
                fidelity   {mustBeTextScalar}
                computed   (1,1) double
                reference  (1,1) double
                cite       {mustBeTextScalar}
                numfmt     {mustBeTextScalar}
                notes      {mustBeTextScalar} = ''
                second                        = NaN
                divergence {mustBeTextScalar} = ''
            end

            comp_s = ComparisonReport.fmt(computed, numfmt);
            ref_s  = ComparisonReport.fmt(reference, numfmt);

            if isnan(reference) || isnan(computed)
                err_s = ' - ';
            elseif reference ~= 0
                err_s = sprintf('%+.2f%%', 100*(computed - reference)/reference);
            else
                err_s = 'N/A';
            end

            if isnumeric(second)
                second_s = ComparisonReport.fmt(second, numfmt);
            else
                second_s = char(second);
            end

            T = table({char(name)}, {char(fidelity)}, {comp_s}, {ref_s}, {err_s}, {second_s}, ...
                      {char(divergence)}, {char(cite)}, {char(notes)}, ...
                'VariableNames', ComparisonReport.COLUMNS);
        end

        function T = section(label)
        %SECTION  Section separator row; renders as a bold full-width heading.
            T = table({char(label)}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, {'---'}, ...
                'VariableNames', ComparisonReport.COLUMNS);
        end

        function show(T, meta)
        %SHOW  Print the standard console block.
            BAR = repmat('=', 1, 110);
            fprintf('\n%s\n', BAR);
            fprintf('  %s\n', upper(meta.title));
            if isfield(meta, 'condition') && ~isempty(meta.condition)
                fprintf('  %s  |  Generated %s\n', meta.condition, meta.generated);
            else
                fprintf('  Generated %s\n', meta.generated);
            end
            fprintf('  Reference: %s\n', meta.referenceDesc);
            fprintf('  2nd source: %s\n', meta.secondDesc);
            fprintf('%s\n\n', BAR);
            disp(T);
        end

        function writeJson(T, out_path, meta)
        %WRITEJSON  Serialize the table plus metadata.
            data.generated     = meta.generated;
            data.aircraft      = meta.aircraft;
            data.title         = meta.title;
            data.condition     = ComparisonReport.getfielddefault(meta, 'condition', '');
            data.referenceDesc = meta.referenceDesc;
            data.secondDesc    = meta.secondDesc;
            data.rows          = ComparisonReport.toRows(T);

            fid = fopen(out_path, 'w');
            fprintf(fid, '%s', jsonencode(data, 'PrettyPrint', true));
            fclose(fid);
        end

        function writeMarkdown(T, out_path, meta)
        %WRITEMARKDOWN  Render the standard markdown report.
        %   Preamble order is fixed across all four reports: title, generated +
        %   condition, reference, second source, the not-a-test warning, the
        %   Divergence legend, then any report-specific paragraphs, then the
        %   table.
            fid = fopen(out_path, 'w');

            fprintf(fid, '# %s\n\n', meta.title);

            if isfield(meta, 'condition') && ~isempty(meta.condition)
                fprintf(fid, 'Generated %s. %s\n\n', meta.generated, meta.condition);
            else
                fprintf(fid, 'Generated %s.\n\n', meta.generated);
            end

            fprintf(fid, '**Reference** (the `Reference` and `%%Diff` columns): %s\n\n', meta.referenceDesc);
            fprintf(fid, '**2nd Source** (the `2nd Source` column): %s\n\n', meta.secondDesc);

            fprintf(fid, ['This is a **comparison report, not a test** — no pass/fail assertions, not part of ' ...
                '`run_all_tests`, and **nothing here may ever be used to backfill a unit test''s expected ' ...
                'value**. Where a quantity has more than one valid implementation, each option gets its own ' ...
                'row, and rejected variants are reported too so the decisions stay auditable.\n\n']);

            fprintf(fid, ['**Reading the `Divergence` column.** `BY DESIGN` — the framework computes the *same ' ...
                'kind* of quantity as the reference but is *expected* to differ (a different formula family, ' ...
                'or a locked decision to follow a physical/T.O. value); a large %%Diff there is the correct ' ...
                'answer, not a defect, though its magnitude is worth a sanity check. `DEFINITIONAL` — the two ' ...
                'sides are *different kinds of quantity altogether*, so the %%Diff is not an error measure at ' ...
                'all; do not chase it. **Blank** — a genuine agreement check, where a large %%Diff **is** worth ' ...
                'chasing.\n\n']);

            if isfield(meta, 'preamble') && ~isempty(meta.preamble)
                for k = 1:numel(meta.preamble)
                    fprintf(fid, '%s\n\n', meta.preamble{k});
                end
            end

            fprintf(fid, '| %s |\n', strjoin(ComparisonReport.MD_HEADERS, ' | '));
            fprintf(fid, '|%s\n', repmat('---|', 1, numel(ComparisonReport.MD_HEADERS)));

            esc = @(s) strrep(s, '|', '\|');
            for r = 1:height(T)
                name = T.Parameter{r};
                if strcmp(T.Computed{r}, '---')
                    fprintf(fid, '| **%s** |%s\n', esc(name), repmat(' |', 1, numel(ComparisonReport.MD_HEADERS)-1));
                else
                    fprintf(fid, '| %s | %s | %s | %s | %s | %s | %s | %s | %s |\n', ...
                        esc(name), T.Fidelity{r}, T.Computed{r}, T.Reference{r}, T.PctDiff{r}, ...
                        T.SecondSource{r}, T.Divergence{r}, esc(T.Cite{r}), esc(T.Notes{r}));
                end
            end

            if isfield(meta, 'footer') && ~isempty(meta.footer)
                fprintf(fid, '\n');
                for k = 1:numel(meta.footer)
                    fprintf(fid, '%s\n\n', meta.footer{k});
                end
            end

            fclose(fid);
        end

    end

    methods (Static, Access = private)

        function s = fmt(v, numfmt)
            if isnan(v)
                s = 'N/A';
            else
                s = sprintf(numfmt, v);
            end
        end

        function v = getfielddefault(s, f, d)
            if isfield(s, f); v = s.(f); else; v = d; end
        end

        function rows = toRows(T)
            n = height(T);
            for r = n:-1:1   % reverse iteration pre-allocates the struct array
                rows(r).parameter    = T.Parameter{r};
                rows(r).fidelity     = T.Fidelity{r};
                rows(r).computed     = T.Computed{r};
                rows(r).reference    = T.Reference{r};
                rows(r).pctDiff      = T.PctDiff{r};
                rows(r).secondSource = T.SecondSource{r};
                rows(r).divergence   = T.Divergence{r};
                rows(r).cite         = T.Cite{r};
                rows(r).notes        = T.Notes{r};
            end
        end

    end

    properties (Constant, Access = private)
        COLUMNS = {'Parameter', 'Fidelity', 'Computed', 'Reference', 'PctDiff', 'SecondSource', ...
                   'Divergence', 'Cite', 'Notes'}
        MD_HEADERS = {'Parameter', 'Fidelity', 'Computed', 'Reference', '%Diff', ...
                      '2nd Source', 'Divergence', 'Cite', 'Notes'}
    end

end
