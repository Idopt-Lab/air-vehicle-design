function data = extract_brandt(xlsPath)
%EXTRACT_BRANDT  Read the cells of the Brandt F-16A workbook used to seed F16Baseline.m.
%   data = extract_brandt(xlsPath) opens the Brandt "Jet Designer/Jet3" workbook
%   READ-ONLY with macros disabled, pulls the specific cells transcribed into
%   baseline/F16Baseline.m, prints them, and returns them in a struct so the
%   hand-entered baseline can be re-verified at any time.
%
%   This is an AUDIT/REPRODUCIBILITY tool only. It is NOT on the runtime or test
%   path: the baseline file is standalone and never reads Excel at run time.
%
%   Requires Microsoft Excel (Windows COM automation via actxserver).
%
%   Example:
%     d = extract_brandt("C:\...\Tasks\MATLAB_Grader\Brandt F-16A.xls");
%
%   Citation: S. Brandt et al., "Introduction to Aeronautics: A Design Perspective",
%   "Jet Designer / Jet3" workbook (Brandt F-16A.xls).

    if nargin < 1 || strlength(xlsPath) == 0
        xlsPath = "C:\Users\John Freeman\Desktop\Academics\VRMastersProgram\Tasks\MATLAB_Grader\Brandt F-16A.xls";
    end
    assert(isfile(xlsPath), "Workbook not found: %s", xlsPath);

    excel = actxserver("Excel.Application");
    cleanup = onCleanup(@() quitExcel(excel));   %#ok<NASGU> ensures Excel closes on error
    excel.Visible = false;
    excel.DisplayAlerts = false;
    try, excel.AutomationSecurity = 3; catch, end   % msoAutomationSecurityForceDisable

    wb = excel.Workbooks.Open(char(xlsPath), false, true);   % UpdateLinks=0, ReadOnly=true
    c = onCleanup(@() closeWb(wb));  %#ok<NASGU>

    get = @(sheet, a1) wb.Sheets.Item(sheet).Range(a1).Value;

    data = struct();

    % --- Weights ("Wt") ---
    data.weights.TOGW       = get("Wt", "B38");   % Total@Takeoff
    data.weights.OEW        = get("Wt", "B12");   % Empty
    data.weights.W_fuel     = get("Wt", "B6");    % Fuel
    data.weights.W_landing  = get("Wt", "B41");   % Total for Lndg
    data.weights.perm_pay   = get("Wt", "B32");   % Perm Payload
    data.weights.exp_pay    = get("Wt", "B33") + get("Wt", "B34");

    % --- Aero summary ("Main") ---
    data.aero.S_ref     = get("Main", "L2");
    data.aero.S_wet     = get("Main", "L3");
    data.aero.Mcrit     = get("Main", "L4");
    data.aero.length    = get("Main", "L6");
    data.aero.CL_alpha  = get("Main", "L7");
    data.aero.CLmax_clean    = get("Main", "L8");
    data.aero.CLmax_takeoff  = get("Main", "L9");
    data.aero.CLmax_landing  = get("Main", "L10");
    data.aero.CLmax_a2a      = get("Main", "L11");
    data.aero.Cfe_used  = get("Main", "O1");
    data.aero.WtoS_act  = get("Main", "P13");

    % --- Drag polar: Brandt MODEL ("Aero"!A6:E10) ---
    data.polar_model  = cell2mat(get("Aero", "A6:E10"));   % [Mach CDmin CDo k1 k2]
    % --- Drag polar: F-16 ACTUAL VALUES ("Aero"!M6:Q10) ---
    data.polar_actual = cell2mat(get("Aero", "M6:Q10"));   % [Mach CDmin CDo k1 k2]
    % --- Cfe table ("Aero"!J18:K26) ---
    data.cfe_table    = get("Aero", "J18:K26");

    % --- Engine deck ("Main") ---
    data.engine.T_mil  = get("Main", "C29");
    data.engine.T_max  = get("Main", "D29");
    data.engine.TSFC_mil = get("Main", "C30");
    data.engine.TSFC_max = get("Main", "D30");

    % --- Component wetted areas ("Geom" sheet) ---
    % Whole-aircraft total (Geom!B19) = fus(D23) + nacelle(B4) + wing(B14)
    %   + strake(B15) + HT(B16) + VT(B17) + flaps(K21=40); verified to
    %   reproduce B19=1371.0946 to 1e-6. Strake and flaps have no analog
    %   in this framework's 5-component (wing/HT/VT/fus/duct) breakdown.
    data.geom_wet.fus_simple   = get("Geom", "B3");    % 1/3 cone + 2/3 cylinder approx
    data.geom_wet.nacelle      = get("Geom", "B4");    % "Exposed Engine Nacelles", full cylinder approx
    data.geom_wet.wing         = get("Geom", "B14");   % "Exposed Wing Wetted Area"
    data.geom_wet.strake       = get("Geom", "B15");   % "Strake Wetted Area" — not modeled here
    data.geom_wet.ht           = get("Geom", "B16");   % "Exposed Pitch Trim Surface Wetted Area"
    data.geom_wet.vt           = get("Geom", "B17");   % "Exposed Vertical Tail  Wetted Area"
    data.geom_wet.total        = get("Geom", "B19");   % "Whole Aircraft Swet"
    data.geom_wet.fus_accurate = get("Geom", "D23");   % "More Accurate Fuselage Swet"
    data.geom_wet.flaps        = 40;                   % Geom!K21 "Swet, sq ft" — not modeled here

    printSummary(data);
end

% -------------------------------------------------------------------------------------
function printSummary(data)
    fprintf("\n--- Brandt F-16A extracted values (for F16Baseline.m audit) ---\n");
    fprintf("Weights: TOGW=%.1f  OEW=%.1f  Fuel=%.1f  Landing=%.1f  PermPay=%.0f  ExpPay=%.0f\n", ...
        data.weights.TOGW, data.weights.OEW, data.weights.W_fuel, data.weights.W_landing, ...
        data.weights.perm_pay, data.weights.exp_pay);
    fprintf("Aero: S_ref=%.1f  S_wet=%.2f  Mcrit=%.4f  CLa=%.4f  Cfe_used=%.4f  WtoS_act=%.2f\n", ...
        data.aero.S_ref, data.aero.S_wet, data.aero.Mcrit, data.aero.CL_alpha, ...
        data.aero.Cfe_used, data.aero.WtoS_act);
    fprintf("CLmax: clean=%.4f  TO=%.4f  landing=%.4f  a2a=%.4f\n", ...
        data.aero.CLmax_clean, data.aero.CLmax_takeoff, data.aero.CLmax_landing, data.aero.CLmax_a2a);
    fprintf("Engine: T_mil=%.0f  T_max=%.0f  TSFC_mil=%.2f  TSFC_max=%.2f\n", ...
        data.engine.T_mil, data.engine.T_max, data.engine.TSFC_mil, data.engine.TSFC_max);
    fprintf("Geom Swet: wing=%.2f  HT=%.2f  VT=%.2f  fus_simple=%.2f  fus_accurate=%.2f  nacelle=%.2f  strake=%.2f  flaps=%.1f  total=%.2f\n", ...
        data.geom_wet.wing, data.geom_wet.ht, data.geom_wet.vt, data.geom_wet.fus_simple, ...
        data.geom_wet.fus_accurate, data.geom_wet.nacelle, data.geom_wet.strake, ...
        data.geom_wet.flaps, data.geom_wet.total);
    disp("Model polar [Mach CDmin CDo k1 k2]:");  disp(data.polar_model);
    disp("Actual polar [Mach CDmin CDo k1 k2] (note M=0.02 row is a known artifact):");
    disp(data.polar_actual);
end

function closeWb(wb)
    try, wb.Close(false); catch, end
end

function quitExcel(excel)
    try, excel.Quit(); catch, end
    try, delete(excel); catch, end
end
