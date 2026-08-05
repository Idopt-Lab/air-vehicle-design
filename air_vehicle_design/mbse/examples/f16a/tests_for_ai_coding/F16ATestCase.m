classdef (Abstract) F16ATestCase < matlab.unittest.TestCase
    %F16ATESTCASE Shared machinery for the F-16A machinery suites (D-055).
    %   Base class for the suites in this folder. It holds the three things
    %   they all repeated:
    %
    %     * REPORTING -- verifyNoOffenders / verifyNotVacuous, so an assertion
    %       is one line and still names every offender.
    %     * TRAVERSAL -- walkComponents, the only architecture walk in this
    %       folder and the only one that handles variant components.
    %     * INTROSPECTION -- stereotype and profile readers that absorb the
    %       R2026a quirks tabulated in docs/08_agent_team.md, once.
    %
    %   A subclass sets Model and Profile in its TestClassSetup. A suite that
    %   reads no model (F16ARequirementsTest) leaves both empty and uses the
    %   reporting helpers only.
    %
    %   F16APhysicalTradeGuardsTest deliberately does NOT inherit this: it
    %   opens no artifact and must keep running on a checkout with no models.

    properties
        Model     % System Composer model under test; empty if the suite reads none
        Profile   % short name of that model's stereotype profile
    end

    properties (Constant)
        % Vendor / programme tokens a technology-neutral name must not carry.
        % Case-SENSITIVE on purpose: "ConventionalTrapWing" contains "pW".
        VendorTokens = ["F100","F110","PW","GE","LWF","Analog"];
    end

    methods (Access = protected)

        % ----------------------------------------------------------- reporting

        function verifyNoOffenders(testCase, offenders, headline)
            % Assert nothing offended, and name whatever did.
            offenders = reshape(string(offenders), 1, []);
            testCase.verifyEmpty(offenders, ...
                string(headline) + ": " + strjoin(offenders, "; ") + ".");
        end

        function verifyNotVacuous(testCase, population, what)
            % A sweep over an empty population passes without checking
            % anything. Every sweep names the population it needs so it cannot.
            n = population;
            if ~isnumeric(n); n = numel(n); end
            testCase.verifyGreaterThan(n, 0, ...
                "Nothing to check: " + what + " -- the assertion this guards " + ...
                "would otherwise pass vacuously.");
        end

        function verifyRequirementsLinked(testCase, reqSet, ids)
            % Every id exists in reqSet and carries at least one inbound link.
            missing  = strings(1,0);
            unlinked = strings(1,0);
            for id = reshape(string(ids), 1, [])
                r = find(reqSet, Id=char(id));
                if isempty(r); missing(end+1) = id; continue; end %#ok<AGROW>
                if isempty(r.inLinks()); unlinked(end+1) = id; end %#ok<AGROW>
            end
            testCase.verifyNoOffenders(missing,  "Requirement not found");
            testCase.verifyNoOffenders(unlinked, "No Implement link for");
        end

        % ----------------------------------------------------------- traversal

        function [comps, paths] = walkComponents(testCase)
            % Every component of Model, with a parallel array of slash paths
            % for failure messages. Variant ROLE wrappers are included; drop
            % them with stereotypableParts where a stereotype is required.
            [comps, paths] = testCase.descend(testCase.Model.Architecture, "");
        end

        function [comps, paths] = descend(testCase, arch, prefix)
            comps = {};
            paths = strings(1,0);
            for c = arch.Components
                here = prefix + string(c.Name);
                comps{end+1} = c;      %#ok<AGROW>
                paths(end+1) = here;   %#ok<AGROW>
                [sub, subPaths] = testCase.descendInto(c, here + "/");
                comps = [comps, sub];        %#ok<AGROW>
                paths = [paths, subPaths];   %#ok<AGROW>
            end
        end

        function [comps, paths] = descendInto(testCase, comp, prefix)
            % The one place that knows about variants. getChoices is the only
            % accessor that reaches a choice on a SAVED model, so a plain
            % recursion over .Architecture.Components silently skips every
            % candidate (docs/08_agent_team.md, R2026a API findings).
            if ~isa(comp, "systemcomposer.arch.VariantComponent")
                [comps, paths] = testCase.descend(comp.Architecture, prefix);
                return
            end
            comps = {};
            paths = strings(1,0);
            for ch = reshape(testCase.choicesOf(comp), 1, [])
                here = prefix + string(ch.Name);
                comps{end+1} = ch;     %#ok<AGROW>
                paths(end+1) = here;   %#ok<AGROW>
                [sub, subPaths] = testCase.descend(ch.Architecture, here + "/");
                comps = [comps, sub];        %#ok<AGROW>
                paths = [paths, subPaths];   %#ok<AGROW>
            end
        end

        function [parts, paths] = stereotypableParts(testCase)
            % The walk minus the variant role wrappers, which cannot carry a
            % stereotype at all (D-013).
            [comps, allPaths] = testCase.walkComponents();
            keep = false(1, numel(comps));
            for i = 1:numel(comps)
                keep(i) = ~isa(comps{i}, "systemcomposer.arch.VariantComponent");
            end
            parts = comps(keep);
            paths = allPaths(keep);
        end

        function choices = choicesOf(~, comp)
            % Empty for anything that is not a variant, so a caller reports
            % "0 choices" instead of erroring out of its test.
            try choices = getChoices(comp); catch, choices = []; end
        end

        function active = activeChoiceOf(~, comp)
            try active = getActiveChoice(comp); catch, active = []; end
        end

        % ------------------------------------------------------ names & values

        function s = shortName(~, qualified)
            % Last token of "<profile>.<stereotype>.<property>" (a bare name
            % is returned unchanged).
            parts = split(string(qualified), ".");
            s = parts(end);
        end

        function names = namesOf(~, comps)
            % Accepts an object array or a cell array -- Component and
            % VariantComponent are different classes, so walks return cells.
            names = strings(1, numel(comps));
            for i = 1:numel(comps)
                if iscell(comps); names(i) = string(comps{i}.Name);
                else;             names(i) = string(comps(i).Name);
                end
            end
        end

        function names = appliedStereotypes(testCase, elem)
            % Short names of the stereotypes applied to one element.
            % getStereotypes returns '<profile>.<stereotype>' entries.
            qualified = reshape(string(getStereotypes(elem)), 1, []);
            names = strings(1, numel(qualified));
            for i = 1:numel(qualified)
                names(i) = testCase.shortName(qualified(i));
            end
        end

        function tf = hasProp(~, elem, qualified)
            % hasProperty ERRORS, rather than returning false, when the named
            % stereotype is not applied. Either way the element lacks it.
            try tf = logical(hasProperty(elem, char(qualified))); catch, tf = false; end
        end

        function s = propText(~, elem, qualified)
            % A stereotype property as plain text. String AND enumeration
            % properties read back as a QUOTED MATLAB expression, so the
            % quotes come off here once for the whole folder
            % (docs/08_agent_team.md). "" when unreadable, so a comparison
            % against it fails instead of propagating <missing>.
            try s = strtrim(erase(string(getProperty(elem, char(qualified))), "'"));
            catch, s = "";
            end
            if ~isscalar(s) || ismissing(s); s = ""; end
        end

        function s = propOf(testCase, elem, stereotype, property)
            % propText for a property of THIS model's profile.
            s = testCase.propText(elem, ...
                testCase.Profile + "." + stereotype + "." + property);
        end

        function v = propNum(~, elem, qualified)
            % NaN when the property cannot be read -- which fails the range
            % check it feeds, so nothing is swallowed.
            try v = str2double(string(getProperty(elem, char(qualified)))); catch, v = NaN; end
        end

        function tf = propBool(testCase, elem, qualified)
            % Copes with the value arriving as a logical, as "true"/"false",
            % or as a quoted expression, without caring which.
            tf = ismember(lower(testCase.propText(elem, qualified)), ["true","1"]);
        end

        % ------------------------------------------------- profile declarations

        function profs = profilesOf(testCase)
            % Profiles applied to Model. The fallbacks cover a session where
            % the .xml has not been pulled in yet. An empty result is left
            % empty: callers assert non-empty so the profile checks cannot
            % pass vacuously.
            profs = testCase.Model.Profiles;
            if ~isempty(profs); return; end
            try
                profs = systemcomposer.profile.Profile.find(testCase.Profile);
            catch
                try profs = systemcomposer.profile.Profile.load(testCase.Profile);
                catch, profs = [];
                end
            end
        end

        function names = profileStereotypeNames(testCase)
            names = strings(1,0);
            profs = testCase.profilesOf();
            for i = 1:numel(profs)
                st = profs(i).Stereotypes;
                for j = 1:numel(st)
                    names(end+1) = testCase.shortName(string(st(j).Name)); %#ok<AGROW>
                end
            end
            names = unique(names);
        end

        function names = declaredPropertyNames(testCase, stereotypeShortName)
            % Properties DECLARED by the profile, independent of whether
            % anything applies them. Name a stereotype to filter to it.
            arguments
                testCase
                stereotypeShortName string = ""
            end
            names = strings(1,0);
            profs = testCase.profilesOf();
            for i = 1:numel(profs)
                st = profs(i).Stereotypes;
                for j = 1:numel(st)
                    if stereotypeShortName ~= "" && ...
                            testCase.shortName(string(st(j).Name)) ~= stereotypeShortName
                        continue
                    end
                    props = st(j).Properties;
                    for k = 1:numel(props)
                        names(end+1) = testCase.shortName(string(props(k).Name)); %#ok<AGROW>
                    end
                end
            end
            names = unique(names);
        end

    end
end
