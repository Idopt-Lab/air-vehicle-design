function [T, P] = f16a_generate_propulsion_test()
%F16A_GENERATE_PROPULSION_TEST  F-16A propulsion at the eight constraint conditions.
%   The tiers are built from the f16a_L{1,2}.json spec files and evaluated at
%   every condition in f16a_requirements.json; the reference column is a live
%   BrandtEngine run at the same condition and power setting, so the comparison
%   is model against model. The cascaded geometry and aerodynamics that
%   f16a_generate_aerodynamics_test returns supply the design wing loading and
%   the drag for the required-thrust section. Each cell holds the eight values
%   in condition order, and the tier rides in the row label, so the Fidelity
%   column is dropped. Propulsion has no L3 tier: every L2 value below is also
%   the L3 value. Informational only, like the geometry and aerodynamics
%   generators: this is not a test, and no value here may backfill a unit test.
%   The table prints to the console and is written as
%   mds/f16a_generate_propulsion_test.md.
%
%   SOURCES: [Brandt] F-16A.xls Engn(s) and Consts tabs, via VnV/BrandtF16A.
%   [Mattingly] Aircraft Engine Design 2nd ed., Eq. 2.54, 3.12 + 3.55, D.6.
%   [Martins] AE481 course notes (metabook), Eq. 10.9. [Raymer] Aircraft Design
%   6th ed., Table 3.3 and ch. 5.

[~, A] = f16a_generate_aerodynamics_test();
G      = A.G;
cond   = ConstraintSetImporter.read_conditions(f16a_requirements_path());
brandt = brandt_engine_reference();

p1 = F16PropL1(f16a_spec_path(1));
p2 = F16PropL2(f16a_spec_path(2));

nC    = numel(cond);
names = strings(1, nC);
[alt, mach, AB_p] = deal(nan(1, nC));
for k = 1:nC
    names(k) = string(cond(k).name);
    [alt(k), mach(k), AB_p(k)] = condition_point(cond(k));
end

% ── evaluate Brandt and both tiers at every condition ──────────────────── %
[a_b, a_AB_b, a_mil_b, T_b, TSFC_b]      = deal(nan(1, nC));
[a_L1, T_L1, TSFC_L1]                    = deal(nan(1, nC));
[a_L2, a_AB_L2, a_mil_L2, T_L2, TSFC_L2] = deal(nan(1, nC));
for k = 1:nC
    st = AircraftState(alt(k), mach(k));
    r  = brandt.run(alt(k), mach(k), AB_p(k));
    a_b(k) = r.alpha_AB_ref;  T_b(k) = r.T;  TSFC_b(k) = r.TSFC;
    a_AB_b(k)  = brandt.thrust_AB(alt(k), mach(k))  / brandt.T_sl_AB;
    a_mil_b(k) = brandt.thrust_dry(alt(k), mach(k)) / brandt.T_sl_dry;

    a_L1(k)    = p1.get_thrust_lapse(st);           % [Martins Eq. 10.9]
    T_L1(k)    = p1.T_SL * a_L1(k);
    TSFC_L1(k) = p1.get_TSFC(st);                   % [Raymer Table 3.3]

    a_AB_L2(k)  = p2.compute_thrust_lapse_AB(st);   % [Mattingly Eq. 2.54a]
    a_mil_L2(k) = p2.compute_thrust_lapse_mil(st);  % [Mattingly Eq. 2.54b]
    if AB_p(k) > 0
        a_L2(k)    = p2.thrust_lapse(st);
        TSFC_L2(k) = p2.compute_TSFC_AB_installed(st);
    else
        a_L2(k)    = p2.thrust_lapse_mil_on_AB_scale(st);
        TSFC_L2(k) = p2.compute_TSFC_installed(st);
    end
    T_L2(k) = p2.T_SL * a_L2(k);
end

% ── required SLS thrust, from the cascaded geometry and aerodynamics ───── %
WS_design = G.W_TO / G.S_ref;
aero_of   = {A.L1, A.L2, A.L3};
prop_of   = {p1, p2, p2};              % the L3 rung pairs F16AeroL3 with F16PropL2
TW_req    = nan(3, nC);
for i = 1:3
    set_i = ConstraintAnalysis.build_constraints(aero_of{i}, prop_of{i}, ...
        f16a_requirements_path(), F16ConstraintSet.constraint_map());
    for j = 1:numel(set_i)
        k = find(names == set_i{j}.name, 1);
        if ~isa(set_i{j}, 'Only_WbyS')                    % a W/S wall makes no thrust demand
            TW_req(i,k) = set_i{j}.required_TW(WS_design);
        end
    end
end
T_req = TW_req * G.W_TO;

lvl       = {'L1', 'L2'};
cond_list = strjoin(names, ' | ');

% ── the table ──────────────────────────────────────────────────────────── %
T = ComparisonReport.section(sprintf('FLIGHT CONDITIONS -- every cell below holds these %d in order: %s', nC, cond_list));
T = [T; cmp('Altitude',     'ft', '', alt,  NaN, '%.0f', '-', '', '')];
T = [T; cmp('Mach',         '-',  '', mach, NaN, '%.3f', '-', ...
    'Takeoff uses mach_liftoff; Landing is power-off and carries no Mach, so it takes the nominal M 0.1 state LandingConstraint uses.', '')];
T = [T; cmp('AB fraction',  '-',  '', AB_p, NaN, '%.0f', '-', ...
    'From power_setting: AB = 1, mil = 0. Takeoff always runs at full AB; Landing is power-off.', '')];

T = [T; ComparisonReport.section('THRUST LAPSE -- alpha on the AB thrust scale, then the AB and mil bases separately')];
T = [T; cmp('alpha', '-', lvl{1}, a_L1, a_b, '%.4f', 'Brandt Engn(s) T/(T_AB_SLS)', ...
    'L1 alpha = sigma^0.6 has no Mach term and no AB/mil split, so one curve answers every condition.')];
T = [T; cmp('alpha', '-', lvl{2}, a_L2, a_b, '%.4f', 'Brandt Engn(s) T/(T_AB_SLS)', ...
    'The power setting selects the lapse, the same dispatch MasterEquationConstraint uses: AB -> thrust_lapse, mil -> thrust_lapse_mil_on_AB_scale.')];
T = [T; cmp('alpha_AB',  '-', lvl{2}, a_AB_L2,  a_AB_b,  '%.4f', 'Brandt Engn(s) AB branch', ...
    'Below TR = 1.0 Mattingly gives alpha_AB = delta_0 with no Mach term, where Brandt subtracts 0.1*sqrt(M).')];
T = [T; cmp('alpha_mil', '-', lvl{2}, a_mil_L2, a_mil_b, '%.4f', 'Brandt Engn(s) dry branch', ...
    'Below TR Mattingly gives 0.6*delta_0, where Brandt subtracts 0.3*M.')];

T = [T; ComparisonReport.section('INSTALLED THRUST AVAILABLE -- T = T_SL * alpha at the condition')];
T = [T; cmp('T', 'lbf', lvl{1}, T_L1, T_b, '%.0f', 'Brandt Engn(s) run_T_lb')];
T = [T; cmp('T', 'lbf', lvl{2}, T_L2, T_b, '%.0f', 'Brandt Engn(s) run_T_lb')];

T = [T; ComparisonReport.section('TSFC -- installed, 1/hr')];
T = [T; cmp('TSFC', '1/hr', lvl{1}, TSFC_L1, TSFC_b, '%.4f', 'Brandt Engn(s) run_TSFC', ...
    'L1 reads a categorical cruise/loiter table with no AB row, so it stays flat where Brandt blends dry and AB.')];
T = [T; cmp('TSFC', '1/hr', lvl{2}, TSFC_L2, TSFC_b, '%.4f', 'Brandt Engn(s) run_TSFC', ...
    'Mattingly x 1.08; the AB conditions use Eq. 3.55b, the mil conditions Eq. 3.55a.')];

T = [T; ComparisonReport.section(sprintf('REQUIRED SLS THRUST -- what each condition demands at the cascaded W/S = %.1f lbf/ft^2, W_TO = %g lbf', WS_design, G.W_TO))];
for i = 1:3
    tier = sprintf('L%d', i);
    T = [T; cmp('T/W required', '-', tier, TW_req(i,:), NaN, '%.4f', '-', ...
        'From the real constraint objects, fed this tier''s aerodynamics and the cascaded geometry. Landing is a W/S wall, so it demands no thrust.')]; %#ok<AGROW>
    T = [T; cmp('T_SL required', 'lbf', tier, T_req(i,:), p2.T_SL, '%.0f', 'Brandt Main!D29; T.O. 1F-16A-1 Sec. I', ...
        'A positive %Diff means the condition asks for more thrust than the F100 gives.', '')]; %#ok<AGROW>
end

T = [T; ComparisonReport.section('ENGINE CONSTANTS -- spec data echoed both sides, so these must match')];
T = [T; cmp('T_SL wet', 'lbf', 'L2', p2.T_SL,     brandt.T_sl_AB,  '%.0f', 'Brandt Main!D29', '', '')];
T = [T; cmp('T_SL mil', 'lbf', 'L2', p2.T_SL_mil, brandt.T_sl_dry, '%.0f', 'Brandt Main!C29', '', '')];
T = [T; cmp('TR',       '-',   'L2', p2.TR,       brandt.TR,       '%.4f', 'Brandt Engn(s)!S1', ...
    'Mattingly Eq. D.6 with T_t4_SLS unknown, which defaults it to T_t4_max.', '')];

meta = struct( ...
    'title',         'F-16A -- Propulsion from the JSON Inputs at the Eight Constraint Conditions', ...
    'aircraft',      'F-16A Block 10/15', ...
    'generated',     char(datetime('now', 'Format', 'yyyy-MM-dd')), ...
    'condition',     sprintf('The %d conditions of f16a_requirements.json, in order: %s.', nC, cond_list), ...
    'referenceDesc', 'the live BrandtEngine model (VnV/BrandtF16A), run at the same altitude, Mach and afterburner fraction as the framework.', ...
    'secondDesc',    'N/A -- this report has one reference source.');

meta.preamble = { ...
    sprintf(['**Every cell holds %d values, in the order %s.** The Altitude, Mach and AB-fraction ' ...
     'rows at the top of the table give the flight point of each one.'], nC, cond_list), ...
    ['**There is no L3 propulsion tier, by decision.** The L3 rung pairs `F16AeroL3` with `F16PropL2`, ' ...
     'so every L2 row here is also the L3 result. Only the required-thrust section has a genuine L3 row, ' ...
     'because its aerodynamics differ.'], ...
    ['**These are two different engine models.** The framework uses Mattingly Eq. 2.54 and Eq. 3.55; ' ...
     'Brandt uses his own `Engn(s)` formulas. A large %Diff is frequently the correct answer -- read the ' ...
     'Notes column before treating one as an error.'] };

% The tier rides in the Parameter label, so the Fidelity column is dropped and
% its width goes to the value cells.
T = removevars(T, 'Fidelity');

ComparisonReport.show(T, meta);

out_md = fullfile(fileparts(mfilename('fullpath')), 'mds', 'f16a_generate_propulsion_test.md');
ComparisonReport.writeMarkdown(T, out_md, meta);
fprintf('  Markdown -> %s\n\n', out_md);

% The two propulsion objects, plus the aerodynamics and geometry they were run
% beside, for a downstream discipline to consume. First consumer:
% f16a_generate_weights_test. The table rides along as P.T, for
% fidelity_comparison.
P = struct('L1', p1, 'L2', p2, 'A', A, 'T', T);

end

% ─── local helpers ──────────────────────────────────────────────────────── %

function T = cmp(name, unit, level, computed, reference, numfmt, cite, notes, divergence)
%CMP  One comparison row, with the tier and the unit folded into the Parameter
%   label. DIVERGENCE DEFAULTS TO 'BY DESIGN', because almost every row here
%   puts the framework's Mattingly model against Brandt's own Engn(s) model; the
%   rows that are genuine agreement checks pass '' explicitly.
    if nargin < 8; notes      = ''; end
    if nargin < 9; divergence = 'BY DESIGN'; end
    if isempty(level)
        label    = sprintf('%s [%s]', name, unit);
        fidelity = 'N/A';
    else
        label    = sprintf('%s [%s, %s]', name, level, unit);
        fidelity = level;
    end
    T = ComparisonReport.row(label, fidelity, computed, reference, cite, numfmt, notes, NaN, divergence);
end

function [alt, mach, AB_p] = condition_point(c)
%CONDITION_POINT  Flight point and afterburner fraction of one condition.
%   Takeoff carries mach_liftoff and always runs at full AB; Landing is
%   power-off and carries no Mach at all, so it takes the same nominal M 0.1
%   sea-level state LandingConstraint.fromCondition builds.
    alt = c.altitude_ft;
    if given(c, 'mach')
        mach = c.mach;
    elseif given(c, 'mach_liftoff')
        mach = c.mach_liftoff;
    else
        mach = 0.1;
    end
    if given(c, 'power_setting')
        AB_p = double(strcmp(c.power_setting, 'AB'));
    else
        AB_p = double(strcmp(c.name, 'Takeoff'));
    end
end

function tf = given(c, f)
%GIVEN  True if this condition carries field f. The conditions go into one
%   struct array, which fills the fields a condition does not have with [], so
%   isfield alone is not sufficient.
    tf = isfield(c, f) && ~isempty(c.(f));
end

function eng = brandt_engine_reference()
%BRANDT_ENGINE_REFERENCE  The live Brandt Engn(s) model, which supplies every
%   reference value here. Self-contained path add, same as fidelity_comparison.
    if isempty(which('BrandtEngine'))
        sizing_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
        vnv = fullfile(sizing_root, 'VnV', 'BrandtF16A');
        addpath(vnv);
        addpath(fullfile(vnv, 'GroundTruth'));
    end
    eng = BrandtEngine();
    eng.analyze();
end
