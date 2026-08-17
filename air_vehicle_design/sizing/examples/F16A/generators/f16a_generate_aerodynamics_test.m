function [T, A] = f16a_generate_aerodynamics_test()
%F16A_GENERATE_AERODYNAMICS_TEST  F-16A aerodynamics at L1, L2 and L3.
%   T = f16a_generate_aerodynamics_test() builds the three aerodynamics tiers
%   from the f16a_L{1,2,3}.json spec files and the cascaded geometry that
%   f16a_generate_geometry_test returns, then sweeps them over Brandt's own
%   five Mach rows and tabulates the result against him. Altitude is the
%   requirements cruise altitude; the takeoff and landing rows are at sea level.
%   The table prints to the console and is written beside this file as
%   mds/f16a_generate_aerodynamics_test.md.
%
%   ONE ROW PER QUANTITY AND TIER, FIVE VALUES PER CELL. Each Mach-dependent
%   cell lists the sweep in order, comma separated, so a quantity can be read
%   across Mach on one line. The Mach-independent quantities come after the
%   sweep with a single value per cell. The tier rides in the row label,
%   "CD0 [L1, -]", and the Fidelity column is removed, so its width goes to
%   the value cells instead.
%
%   THE MACH POINTS ARE BRANDT'S EXACT ROWS, not rounded copies of them. Rows 2
%   and 3 of his Aero!A5:E10 table sit at Mcrit and M_wave, which print as 0.87
%   and 1.05 in the workbook but are 0.872737 and 1.054749. Both are read live
%   off the Brandt object, so this sweep lands on the same conditions his table
%   does.
%
%   THE REFERENCE COLUMN IS BRANDT'S OWN MODEL, not his tabulated "F-16 Actual
%   Values" box. Every reference value comes from the live BrandtAerodynamics
%   object (the "Jet3 Aerodynamic Analysis" Aero-tab table and that tab's
%   design-point cells), so the comparison is model against model.
%   KNOWN GAP IN THAT REFERENCE: the live chain reads CDmin_sub = 0.01643 where
%   the workbook's Aero!G3 is 0.01691 (-2.8%), because BrandtGeometry gives
%   S_wet = 1332.56 ft^2 against the 1371.09 that cell implies. Every CD0 row
%   below therefore compares against a slightly low reference. Logged in
%   VnV/BrandtF16A/todo.md (2026-08-12), open.
%
%   The rows follow BrandtAerodynamics's own property set wherever this
%   framework has an equivalent method; the quantities it does not model get
%   their own N/A section rather than being dropped. L1 is geometry-free, so it
%   gets the cascaded wing AR and leading-edge sweep as scalars; L2 and L3 get
%   the matching geometry object. The geometry cascade table prints first,
%   because this function calls that generator. Informational only: this is not
%   a test, and no value here may backfill a unit test.
%
%   SOURCES: [Brandt] F-16A.xls Aero and Miss tabs, via VnV/BrandtF16A.
%   [Raymer] Aircraft Design 6th ed., ch. 12. [Mattingly] Aircraft Engine
%   Design 2nd ed., Eq. 2.9. [Nicolai] Fundamentals of Aircraft and Airship
%   Design Vol. I, Eq. 2.1 and ch. 9. [Roskam] Airplane Design Vol. I and
%   Part II Eq. 7.10.

[~, G] = f16a_generate_geometry_test();
req    = jsondecode(fileread(f16a_requirements_path()));
ctrl   = f16a_control_surfaces();
brandt = brandt_aero_reference();

MACH_SWEEP = [0.1, brandt.Mcrit, brandt.M_wave, 1.5, 2.0];   % Brandt Aero!A6:A10
alt        = req.cruise.altitude_ft;
nM         = numel(MACH_SWEEP);

a1 = F16AeroL1(f16a_spec_path(1));
a1.AR            = G.AR_wing;         % cascaded wing, not the JSON default
a1.Lambda_LE_deg = G.LE_sweep_wing;
a2 = F16AeroL2(G.L2, f16a_spec_path(2), ctrl);
a3 = F16AeroL3(G.L3, f16a_spec_path(3), ctrl);
aero = {a1, a2, a3};
lvl  = {'L1', 'L2', 'L3'};

field = AircraftState(0, 0.2);        % sea-level takeoff / landing sample

% ── evaluate every tier over the sweep ─────────────────────────────────── %
[CD0, K1, K2, CD, CLa, CLminD] = deal(nan(3, nM));
[CD0_b, K1_b, K2_b, LDmax_b, CD_b, CL] = deal(nan(1, nM));
for k = 1:nM
    st    = AircraftState(alt, MACH_SWEEP(k));
    br    = brandt.run(MACH_SWEEP(k));                  % Brandt's model, same Mach
    CL(k) = a1.compute_CL(G.W_TO, st.q, G.S_ref);       % [Nicolai Eq. 2.1]

    CD0_b(k) = br.CD0;  K1_b(k) = br.K1;  K2_b(k) = br.K2;  LDmax_b(k) = br.LD_max;
    CD_b(k)  = a1.compute_CD(br.CD0, br.K1, br.K2, CL(k));   % Brandt coefficients, same form

    for i = 1:3
        p = aero{i}.drag_polar(st);
        CD0(i,k) = p.CD0;
        K1(i,k)  = p.K1;
        K2(i,k)  = p.K2;
        CD(i,k)  = aero{i}.compute_CD(p.CD0, p.K1, p.K2, CL(k));   % [Mattingly Eq. 2.9]
        CLa(i,k)    = CL_alpha(aero{i}, MACH_SWEEP(k));
        CLminD(i,k) = CL_minD(aero{i}, MACH_SWEEP(k));
    end
end
CDi     = CD - CD0;
LD      = CL ./ CD;
CL_opt  = sqrt(CD0 ./ K1);
LD_max  = 0.5 ./ sqrt(CD0 .* K1);

mach_list = strjoin(compose('%.6g', MACH_SWEEP), ', ');

% ── Mach-dependent rows: one per quantity and tier, five values per cell ─ %
T = ComparisonReport.section(sprintf('DRAG POLAR vs MACH at %g ft -- each cell is M = %s', alt, mach_list));
for i = 1:3
    T = [T; cmp('CD0', '-', lvl{i}, CD0(i,:), CD0_b, '%.5f', 'Brandt Aero!C6:C10')]; %#ok<AGROW>
    T = [T; cmp('K1',  '-', lvl{i}, K1(i,:),  K1_b,  '%.4f', 'Brandt Aero!D6:D10')]; %#ok<AGROW>
    T = [T; cmp('K2',  '-', lvl{i}, K2(i,:),  K2_b,  '%.5f', 'Brandt Aero!E6:E10')]; %#ok<AGROW>
end

T = [T; ComparisonReport.section(sprintf('1-G LEVEL FLIGHT -- W_TO = %g lbf, S_ref = %.1f ft^2, M = %s', G.W_TO, G.S_ref, mach_list))];
T = [T; cmp('CL', '-', 'L1->L3', CL, NaN, '%.4f', '-', ...
    'W_TO/(q*S_ref). At the lowest Mach this exceeds CLmax, i.e. level flight is not possible there.')];
for i = 1:3
    T = [T; cmp('CDi', '-', lvl{i}, CDi(i,:), CD_b - CD0_b, '%.5f', 'Brandt Aero!D6:E10 at the same CL')]; %#ok<AGROW>
    T = [T; cmp('CD',  '-', lvl{i}, CD(i,:),  CD_b,         '%.5f', 'Brandt Aero!C6:E10 at the same CL')]; %#ok<AGROW>
    T = [T; cmp('L/D', '-', lvl{i}, LD(i,:),  CL ./ CD_b,   '%.2f', 'Brandt Aero!C6:E10 at the same CL')]; %#ok<AGROW>
end

T = [T; ComparisonReport.section(sprintf('BEST-RANGE POINT -- CL_opt = sqrt(CD0/K1), L/D_max = 0.5/sqrt(CD0*K1), M = %s', mach_list))];
for i = 1:3
    T = [T; cmp('CL_opt',  '-', lvl{i}, CL_opt(i,:), sqrt(CD0_b ./ K1_b), '%.4f', 'Brandt Aero!G15 basis')]; %#ok<AGROW>
    T = [T; cmp('L/D_max', '-', lvl{i}, LD_max(i,:), LDmax_b,             '%.2f', 'Brandt Aero!G15 basis')]; %#ok<AGROW>
end

T = [T; ComparisonReport.section(sprintf('LIFT-CURVE SLOPE AND CAMBER TERM -- M = %s', mach_list))];
for i = 1:3
    T = [T; cmp('CL_alpha', '1/rad', lvl{i}, CLa(i,:), brandt.CL_alpha_wing*180/pi, '%.4f', 'Brandt Aero!A15', ...
        'Raymer Eq. 12.6 is subsonic. AeroL2.CL_alpha clamps M at 0.99, so the supersonic entries repeat the M=0.99 answer.')]; %#ok<AGROW>
    T = [T; cmp('CL_minD', '-', lvl{i}, CLminD(i,:), brandt.CL0, '%.5f', 'Brandt Aero!G20 (his CL0)', ...
        'Scales with CL_alpha, so it inherits that row''s M=0.99 clamp.')]; %#ok<AGROW>
end

% ── Mach-independent quantities ────────────────────────────────────────── %
T = [T; ComparisonReport.section('MACH-INDEPENDENT -- Oswald e, flapped area, equivalent skin friction')];
for i = 1:3
    T = [T; cmp('e_osw',     '-',    lvl{i}, oswald(aero{i}),       brandt.e0,        '%.4f', 'Brandt Aero!G12')]; %#ok<AGROW>
    T = [T; cmp('S_flapped', 'ft^2', lvl{i}, flapped_area(aero{i}), brandt.S_flapped, '%.3f', 'Brandt Aero!L31')]; %#ok<AGROW>
end
T = [T; cmp('Cfe', '-', 'L2', a2.Cfe, brandt.Cfe_eff, '%.5f', 'Brandt JSON Cfe (back-calculated)')];

T = [T; ComparisonReport.section('MAXIMUM LIFT COEFFICIENT -- clean / takeoff / landing')];
for i = 1:3
    T = [T; cmp('CLmax clean',   '-', lvl{i}, aero{i}.get_CLmax([]),  brandt.CLmax_clean,   '%.4f', 'Brandt Aero!H25')]; %#ok<AGROW>
    T = [T; cmp('CLmax takeoff', '-', lvl{i}, aero{i}.get_CLmax_TO(), brandt.CLmax_takeoff, '%.4f', 'Brandt Aero!H27')]; %#ok<AGROW>
    T = [T; cmp('CLmax landing', '-', lvl{i}, aero{i}.get_CLmax_L(),  brandt.CLmax_landing, '%.4f', 'Brandt Aero!H29')]; %#ok<AGROW>
end

T = [T; ComparisonReport.section(sprintf('HIGH-LIFT + GEAR DRAG -- clean CD0 plus the flap/gear increment, M %.1f at sea level', field.mach))];
for i = 1:3
    CD0_field = aero{i}.drag_polar(field).CD0;
    dCD0_TO   = delta_CD0(aero{i}, 'get_Delta_CD0_TO', field);
    T = [T; cmp('Delta_CD0 takeoff', '-', lvl{i}, dCD0_TO, NaN, '%.5f', '-')]; %#ok<AGROW>
    T = [T; cmp('CD0 takeoff',       '-', lvl{i}, CD0_field + dCD0_TO, brandt.CD0_takeoff, '%.5f', 'Brandt Miss!CD0_TO')]; %#ok<AGROW>
    T = [T; cmp('Delta_CD0 landing', '-', lvl{i}, delta_CD0(aero{i}, 'get_Delta_CD0_L', field), NaN, '%.5f', '-')]; %#ok<AGROW>
end

% ── Brandt properties this framework has no method for ─────────────────── %
T = [T; ComparisonReport.section('NOT MODELED HERE -- BrandtAerodynamics properties with no framework equivalent')];
T = [T; cmp('Mcrit',              '-',     '', NaN, brandt.Mcrit,          '%.4f', 'Brandt Aero!A12')];
T = [T; cmp('M_wave',             '-',     '', NaN, brandt.M_wave,         '%.4f', 'Brandt Aero!G8')];
T = [T; cmp('M_LE_super',         '-',     '', NaN, brandt.M_LE_super,     '%.4f', 'Brandt Aero!F9')];
T = [T; cmp('e_wing',             '-',     '', NaN, brandt.e_wing,         '%.4f', 'Brandt Aero!A19')];
T = [T; cmp('e_pitch',            '-',     '', NaN, brandt.e_pitch,        '%.4f', 'Brandt Aero!A28')];
T = [T; cmp('CL_alpha pitch',     '1/deg', '', NaN, brandt.CL_alpha_pitch, '%.5f', 'Brandt Aero!A23')];
T = [T; cmp('CL_alpha total',     '1/deg', '', NaN, brandt.CL_alpha_total, '%.5f', 'Brandt Aero!A32')];
T = [T; cmp('Downwash de/dalpha', '-',     '', NaN, brandt.downwash,       '%.4f', 'Brandt Aero!A40')];

meta = struct( ...
    'title',         'F-16A -- Aerodynamics from the JSON Inputs and the Cascaded Geometry', ...
    'aircraft',      'F-16A Block 10/15', ...
    'generated',     char(datetime('now', 'Format', 'yyyy-MM-dd')), ...
    'condition',     sprintf('Brandt''s own Mach rows [%s] at %g ft; takeoff and landing rows at sea level.', mach_list, alt), ...
    'referenceDesc', ['the live BrandtAerodynamics model (VnV/BrandtF16A), i.e. his own "Jet3 Aerodynamic ' ...
                      'Analysis" Aero-tab output. NOT his tabulated "F-16 Actual Values" box.'], ...
    'secondDesc',    'N/A -- this report has one reference source.');

% The tier rides in the Parameter label, so the Fidelity column is dropped
% rather than left duplicating it. The renderer follows whichever standard
% columns the table carries.
T = removevars(T, 'Fidelity');

meta.preamble = { sprintf(['**Every Mach-dependent cell holds five values, in the order M = %s.** Those are ' ...
    'Brandt''s own `Aero!A5:E10` rows, read live off the Brandt object rather than transcribed, so rows 2 ' ...
    'and 3 sit at his exact Mcrit and M_wave instead of the 0.87 and 1.05 the workbook prints.'], mach_list) };

ComparisonReport.show(T, meta);

out_md = fullfile(fileparts(mfilename('fullpath')), 'mds', 'f16a_generate_aerodynamics_test.md');
ComparisonReport.writeMarkdown(T, out_md, meta);
fprintf('  Markdown -> %s\n\n', out_md);

% The three aero objects and the geometry they were built on, for a downstream
% discipline to consume. First consumer: f16a_generate_propulsion_test. The
% table rides along as A.T, for fidelity_comparison.
A = struct('L1', a1, 'L2', a2, 'L3', a3, 'G', G, 'T', T);

end

% ─── local helpers ──────────────────────────────────────────────────────── %

function T = cmp(name, unit, level, computed, reference, numfmt, cite, notes)
%CMP  One comparison row. The tier and the unit are folded into the Parameter
%   label, "CD0 [L1, -]", so the Fidelity column can be dropped and its width
%   goes to the value cells. An empty level leaves the label carrying the unit
%   alone, for a row where no tier applies. See ComparisonReport.row for the
%   rest of the column semantics, including the multi-value cells this report
%   uses for the Mach sweep.
    if nargin < 8; notes = ''; end
    if isempty(level)
        label    = sprintf('%s [%s]', name, unit);
        fidelity = 'N/A';
    else
        label    = sprintf('%s [%s, %s]', name, level, unit);
        fidelity = level;
    end
    T = ComparisonReport.row(label, fidelity, computed, reference, cite, numfmt, notes);
end

function aero = brandt_aero_reference()
%BRANDT_AERO_REFERENCE  The live Brandt Aero-tab model, which supplies both the
%   Mach sweep points and every Reference value here. Self-contained path add,
%   same as fidelity_comparison.
    if isempty(which('BrandtAerodynamics'))
        sizing_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
        vnv = fullfile(sizing_root, 'VnV', 'BrandtF16A');
        addpath(vnv);
        addpath(fullfile(vnv, 'GroundTruth'));
    end
    geom = BrandtGeometry();         geom.analyze();
    aero = BrandtAerodynamics(geom); aero.analyze();
end

function val = CL_alpha(aero, M)
%CL_ALPHA  Finite-wing lift slope [1/rad]. L1 owns no geometry, so it has none.
    if ismethod(aero, 'get_CL_alpha'); val = aero.get_CL_alpha(M); else; val = NaN; end
end

function val = CL_minD(aero, M)
%CL_MIND  CL at minimum drag, the framework's analog of Brandt's CL0.
    if ~isprop(aero, 'alpha_L0'); val = NaN; return; end
    val = AeroL2.compute_CL_minD(CL_alpha(aero, M), aero.alpha_L0);
end

function val = oswald(aero)
%OSWALD  Raymer Eq. 12.48/12.49 span efficiency; no L1 method (no geometry).
    if ismethod(aero, 'get_e_osw'); val = aero.get_e_osw(); else; val = NaN; end
end

function val = flapped_area(aero)
%FLAPPED_AREA  Wing area in the flaperon span band [Roskam Part II Eq. 7.10].
    if ~isprop(aero, 'eta_flap_out'); val = NaN; return; end
    val = AeroL2.compute_S_flapped_ratio(aero.eta_flap_out, aero.eta_flap_in, aero.taper) * aero.S_ref;
end

function val = delta_CD0(aero, method, state)
%DELTA_CD0  Read a flap/gear CD0 increment. Only L3 makes the gear-down term
%   Reynolds-dependent, so only L3 takes the flight state.
%   Same dispatch TakeoffConstraint/LandingConstraint use.
    m = findobj(metaclass(aero).MethodList, 'Name', method);
    if numel(m.InputNames) >= 2
        val = aero.(method)(state);
    else
        val = aero.(method)();
    end
end
