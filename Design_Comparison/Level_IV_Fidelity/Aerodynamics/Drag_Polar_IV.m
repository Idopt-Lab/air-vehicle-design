function [DragResults] = Drag_Polar_IV(Designgeo_wings, Designgeo_fuselage, Designgeo_propulsion, Weight_Results, missiondata, Requirements)


% Unpack table info
AR = Designgeo_wings.Main("Aspect ratio");
L_fus = Designgeo_fuselage.Fuselage("Length (ft)");
D_fus = Designgeo_fuselage.Fuselage("Max width (ft)");
c_root = Designgeo_wings.Main("Root chord length (ft)");
b_W = Designgeo_wings.Main("Span (ft)");
Cbar_W = Designgeo_wings.Main("Mean geometric chord");
lambda = Designgeo_wings.Main("Taper ratio");
Lambda_qc = Designgeo_wings.Main("Taper ratio, qc");
tc_root = Designgeo_wings.Main("t/c");
c_VT = Designgeo_wings.VerticalTail("c_VT");
c_HT = Designgeo_wings.HorizontalTail("c_HT");
Cbar_HT = Designgeo_wings.HorizontalTail("Mean geometric chord");
Cbar_VT = Designgeo_wings.VerticalTail("Mean geometric chord");
% S_ref = Designgeo_wings.Main("Planform area (ft^2)");
S_ref = Weight_Results.S_ref;
S_wet = Weight_Results.S_wet;
S_VT = Weight_Results.S_VT;
S_HT = Weight_Results.S_HT;
eng_diam = Weight_Results.enginestats.D;

% Obtain requirements
% Max Mach
M_max.M = Requirements.MaxMach("Mach");
M_max.alt = Requirements.MaxMach("Altitude (ft)");
% Cruise
Cruise.M = Requirements.Cruise("Mach");
Cruise.alt = Requirements.Cruise("Altitude (ft)");
% Max alt
alt_max.M = Requirements.MaxAlt("Mach");
alt_max.alt = Requirements.MaxAlt("Altitude (ft)");

% Component drag buildup methhod.

%% -----------------------------------------------------------
% ESTIMATE COMPONENT DRAGS
% Some equation used in the Form Factor (FF) equations:
f = @(l, d, A_max) (l/(sqrt((4/pi)*A_max))); % Raymer, eq 12.33, 6th edition

% PAY ATTENTION HOW TO USE HOW TO USE
% HOW TO USE THIS HOW TO USE THIS VVVVVVVVVVVV
% VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
% THESE ARE CALLABLE FUNCTIONS VALID FOR THEIR CORRESPONDING COMPONENTS.
% SIMPLY PROVIDE THE REQUIRED DIMENSIONS FOR YOUR DESIGN'S PART AND USE THE
% FUNCTION'S OUTPUT.
% ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

%% -----------------------------------------------------------
% Flat-plate skin-friction coefficients
% Components: wings, tails, struts, pylons
FF_1 = @(x_c, t_c, M, Lambda_m) (1 + 0.6/(x_c)*(t_c) + 100*(t_c)^4)*(1.34*M^(0.18) * cos(Lambda_m)^0.28);
% Raymer, eq 12.30, 6th edition

% Components: Fuselage, smooth canopy
FF_2 = @(l, d, A_max) (0.9 + 5/(f(l,d,A_max)^(1.5)) + f(l,d,A_max)/400);
% Raymer, eq 12.31, 6th edition

% Components: Nacelle and smooth external store:
FF_3 = @(l, d, A_max) (1 + (0.35/f(l,d,A_max)));
% Raymer, eq 12.32, 6th edition

% Components: Boundary-layer diverters (double wedge, single wedge,
% respectively)
FF_doublewedge = @(d,l) (1 + (d/l)); % Raymer, eq 12.34, 6th edition
FF_singlewedge = @(d,l) (1 + ((2*d)/l)); % Raymer, eq 12.35, 6th edition


%% -----------------------------------------------------------
% Estimate the Reynolds number of the component
% Need cutoff Reynolds number
% l = reference length (fuselage)
% k = skin roughness value
k = 2.08*10^(-5); % smooth paint assumed. Raymer, table 12.5, 6th edition
R_cutoff_sub = @(ref_length) (38.21*(ref_length/k)^(1.053)); % Raymer, eq 12.28, 6th edition. Use when R_cutoff < R_component
R_cutoff_sup = @(ref_length, Mach) (44.62*(ref_length/k)^(1.053)*Mach^(1.16)); % Raymer, eq 12.29, 6th edition

% Compute the Reynolds number of each relevant component
alt = Cruise.alt;
M = Cruise.M;
[~, a_drag_polar, ~, rho_drag_polar] = atmosisa(alt*0.3048);
rho_drag_polar = rho_drag_polar*0.00194032033; % Convert from kg/m^3 to imperial
a_drag_polar = a_drag_polar*0.3048; % Convert from m/s to ft/s
V = a_drag_polar*M;
mu = 1.69*10^(-4); % Kinematic viscosity at desired conditions

R = @(ref_length, V) (rho_drag_polar*V*ref_length/mu); % Raymer, eq 12.25, 6th edition
% Ref length = characteristic length


%% -----------------------------------------------------------
% Skin friction coefficient - components
% Take the Reynolds number as an average, weighted on the percents of
% corresponding laminar and turbulent flow
% (E.G, 75% turbulent, 25% laminar - take the average, weighted based on the
% corresponding percent. Turbulent will have a higher weight in this
% example.)
% LAMINAR
Cf_lam = @(R) (1.328/(sqrt(R))); % eq 12.26, 6th ed
% TURBULENT
Cf_turb = @(R, Mach) (0.455/(((log(R)^(2.58))*(1 + 0.144*Mach^2))^(0.65)));
% eq 12.27, 6th ed

%% -----------------------------------------------------------
% Interference factors - components
% Estimates of aerodynamic interactions too complex to analytically model
% at this stage (I think). Use emperical estimates.
%
% External stores/nacelles:
% Q_nacelle = 1.5; %Directly on fuselage or wing
% Q_nacelle = 1.3; % <1 fuselage diameter away
% Q_nacelle = 1.0; % -> 1 fuselage diameter away
% Q_wingtip_missiles = 1.25; % Missiles mounted upon wingtips.
%
% High-wing, midwing, well-filleted low wing:
% Q_wing = 1.0; % Usually negligible
% Q_undiluted_low_wing = 1.4; % 1.1 -> 1.4
%
% Fuselage:
% Q_fuselage = 1.0;
%
% Boundary-layer diverter:
% Q_BLDiverter = 1.0;
%
% Tail surfaces:
% Q_tail = 1.03; % Clean v-tail
% Q_tail = 1.08; % H-tail
% Q_tail = 1.04 or 1.05; % Conventional configuration
%
% For a F-16. Using two configurations:
% 1: Clean (no armaments, no pylons, no drop-tanks)
% 2: Combat/patrol loadout (ordinance pylons, AA missiles, 2x drop tanks)
% Start with clean for simplicity's sake
Q_fuselage = 1.0;
Q_BLDiverter = 1.0;
Q_tail = 1.05;
Q_misc = 1.01; % Flat assumption for simplicity - all other things add 1% to drag.
Q_wing = 1.0;















%% -----------------------------------------------------------
% Assemble the drag of components
% Components: Fuselage, main wings, tail (VT, HT), air duct, BLDiverter

% Get Reynolds numbers
% Fuselage - ref length is just the total length
% Wing, tail - ref length = mean aerodynamic chord length
R_fuselage = R(L_fus, V);
R_mainwings = R(Cbar_W, V);
R_HT = R(Cbar_HT, V);
R_VT = R(Cbar_VT, V);

% Compute cutoff Reynolds numbers for each component
R_cutoff_fuselage = R_cutoff_sub(L_fus);
R_cutoff_mainwings = R_cutoff_sub(Cbar_W);
R_cutoff_HT = R_cutoff_sub(Cbar_HT); % Still need Cbar_HT
R_cutoff_VT = R_cutoff_sub(Cbar_VT); % Still need Cbar_VT

% Get skin friction drag coefficients for each component
% Laminar first:
Cf_fuselage_lam = Cf_lam(R_fuselage);
Cf_mainwings_lam = Cf_lam(R_mainwings);
Cf_HT_lam = Cf_lam(R_HT);
Cf_VT_lam = Cf_lam(R_VT);

% Turbulent:
Cf_fuselage_turb = Cf_turb(R_fuselage, M);
Cf_mainwings_turb = Cf_turb(R_mainwings, M);
Cf_HT_turb = Cf_turb(R_HT, M);
Cf_VT_turb = Cf_turb(R_VT, M);

% Check if should use cutoff or actual Reynolds number for turbulent.
if R_cutoff_fuselage < R_fuselage
     Cf_fuselage_turb = Cf_turb(R_cutoff_fuselage, M);
end

if R_cutoff_mainwings < R_mainwings
     Cf_mainwings_turb = Cf_turb(R_cutoff_mainwings, M);
end

if R_cutoff_HT < R_HT
     Cf_HT_turb = Cf_turb(R_cutoff_HT, M);
end

if R_cutoff_VT < R_VT
     Cf_VT_turb = Cf_turb(R_cutoff_VT, M);
end
% There's a better way of writing this lmao

% Need to get a weighted average of the flat-plate skin friction
% coefficient for each component.
% Sum the laminar and turbulent.
% Get % that's laminar.
% Compute the length of laminar flow? From characteristic length?
% Use R_cutoff since that... by deduction... is where the flow transitions
% to turbulent? Or where Laminar equations are invalid. Lol

% Component: Fuselage
Cf_fuselage = ((abs(R_fuselage - R_cutoff_fuselage))/R_cutoff_fuselage * Cf_fuselage_turb + (abs(R_fuselage - R_cutoff_fuselage))/R_cutoff_fuselage * Cf_fuselage_lam)/2;

% Component: Main wings
Cf_mainwings = ((abs(R_mainwings - R_cutoff_mainwings))/R_cutoff_mainwings * Cf_mainwings_turb + (abs(R_mainwings - R_cutoff_mainwings))/R_cutoff_mainwings * Cf_mainwings_lam)/2;

% Component: Tail (Horizontal, Vertical)
Cf_HT = ((abs(R_HT - R_cutoff_HT))/R_cutoff_HT * Cf_HT_turb + (abs(R_HT - R_cutoff_HT))/R_cutoff_HT * Cf_HT_lam)/2;
Cf_VT = ((abs(R_VT - R_cutoff_VT))/R_cutoff_VT * Cf_VT_turb + (abs(R_VT - R_cutoff_VT))/R_cutoff_VT * Cf_VT_lam)/2;


% Component S_wet
SW_wings = 2.1*S_ref; % Placeholder/assumption (wetted area is about twice the planform area
SW_HT = 2.1*S_HT;
SW_VT = 2.1*S_VT;
SW_struts = 0;
SW_pylons = 0; % Placeholder value of 0 temporary


% Next, get the form factor (FF)
% Wing
FF_wing = FF_1(0.5, 0.02, M, 40);

% Tail - Horizontal
FF_HT = FF_1(0.04, 0.04, M, 40);

% Tail - Vertical
FF_VT = FF_1(0.04, 0.04, M, 40);

% Fuselage
FF_fuselage = FF_2(L_fus, D_fus, pi*(D_fus/2)^2);


% Sum the products of Cf_components, FF_components, Q_components
Component_Fuselage = Cf_fuselage*Q_fuselage*S_wet;
Component_mainwings = Cf_mainwings*Q_wing*SW_wings;
Component_HT = Cf_HT*Q_tail*SW_HT;
Component_VT = Cf_VT*Q_tail*SW_VT;

Component_Drags = Component_Fuselage + Component_mainwings + Component_HT + Component_VT;



%% -----------------------------------------------------------
% Miscellaneous drags
% Tabulate from graphs of emperical data.
% Clean config: no pylons, external ordinance
% (D/q)_component / S_ref_mainwings = CD0_component

% Fuselage rear upsweep D/q
Dq_upsweep = @(u,A_max) (3.83*u^(2.5)*A_max); % eq 12.36

% "Base" areas drag area
Dq_base_sub = @(M, A_base) ((0.139 + 0.419*(M - 0.161)^2)*A_base); % eq 12.37
Dq_base_sup = @(M, A_base) ((0.064 + 0.042*(M - 3.84)^2)*A_base); % eq 12.38


% Windmilling engine drags
Dq_windmillingjet = @(A_engine_front_face) (0.3*A_engine_front_face); % eq 12.40


% CALCULATING DRAG AREAS
Dq_upsweep_value = Dq_upsweep(0, pi*(D_fus/2)^2);
Dq_windmillingjet_value = Dq_windmillingjet(pi*((eng_diam)/2)^2);
% Convert drag areas into parasite drag by dividing by S_ref_mainwings!

CD0_upsweep = Dq_upsweep_value/S_ref;
CD0_windmillingjet = Dq_windmillingjet_value/S_ref;


%% -----------------------------------------------------------
% Leakage and Protuberance drag
% Includes: rivets, control surface gaps, gun ports, anything from the
% manufacturing/assembly process.
% Usuyally given as a percentage of parasite drag
% Sources: Table 12.7, Raymer, 6th ed
Dq_gun = 0.20; % Protuberance drag of gun port (ft^2)
Dq_hook = 0.10; % Arresting hook (USAF) (ft^2)
% Dq_leakandprotuberance = CD0_total*0.10; % 10% of total parasite drag (non-stealth fighter)

% Calculating leakage and protuberance drags
CD0_gun = Dq_gun/S_ref;
CD0_hook = Dq_hook/S_ref;
% CD0_leakandprotuberance =

CD_LandP = CD0_gun + CD0_hook;
CD_misc = CD0_windmillingjet + CD0_upsweep;

%% -----------------------------------------------------------
% SUBSONIC
CD0_sub = Component_Drags/S_ref + CD_misc + CD_LandP;







%% -----------------------------------------------------------
% SUPERSONIC
% Similar to subsonic, but no form factor adjustments nor interference
% factors.
% incorporate wave drag.
% Setup
% Compute the Reynolds number of each relevant component
alt = M_max.alt;
M = M_max.M;
[~, a_drag_polar, ~, rho_drag_polar] = atmosisa(alt*0.3048);
rho_drag_polar = rho_drag_polar*0.00194032033; % Convert from kg/m^3 to imperial
a_drag_polar = a_drag_polar*0.3048; % Convert from m/s to ft/s
V = a_drag_polar*M;
mu = 1.69*10^(-4); % Kinematic viscosity at desired conditions

% R = @(ref_length) (rho_drag_polar*V*ref_length/mu); % Raymer, eq 12.25, 6th edition
% Ref length = characteristic length


% Compute reynolds numbers for components.
% Components: Fuselage, main wings, tail (horizontal, vertical)
R_fuselage_sup = R(L_fus, V);
R_mainwings_sup = R(b_W, V);
R_HT_sup = R(Cbar_HT, V);
R_VT_sup = R(Cbar_VT, V);


% Compute cutoff Reynolds numbers for each component
R_cutoff_fuselage_sup = R_cutoff_sup(L_fus, M);
R_cutoff_mainwings_sup = R_cutoff_sup(Cbar_W, M);
R_cutoff_HT_sup = R_cutoff_sup(Cbar_HT, M); % Still need Cbar_HT
R_cutoff_VT_sup = R_cutoff_sup(Cbar_VT, M); % Still need Cbar_VT

% Get skin friction drag coefficients for each component
% Laminar first:
Cf_fuselage_lam = Cf_lam(R_fuselage_sup);
Cf_mainwings_lam = Cf_lam(R_mainwings_sup);
Cf_HT_lam = Cf_lam(R_HT_sup);
Cf_VT_lam = Cf_lam(R_VT_sup);

% Turbulent:
Cf_fuselage_turb_sup = Cf_turb(R_fuselage_sup, M);
Cf_mainwings_turb_sup = Cf_turb(R_mainwings_sup, M);
Cf_HT_turb_sup = Cf_turb(R_HT_sup, M);
Cf_VT_turb_sup = Cf_turb(R_VT_sup, M);

% Check if should use cutoff or actual Reynolds number for turbulent.
if R_cutoff_fuselage_sup < R_fuselage_sup
     Cf_fuselage_turb_sup = Cf_turb(R_cutoff_fuselage_sup, M);
end

if R_cutoff_mainwings_sup < R_mainwings_sup
     Cf_mainwings_turb_sup = Cf_turb(R_cutoff_mainwings_sup, M);
end

if R_cutoff_HT_sup < R_HT_sup
     Cf_HT_turb_sup = Cf_turb(R_cutoff_HT_sup, M);
end

if R_cutoff_VT_sup < R_VT_sup
     Cf_VT_turb_sup = Cf_turb(R_cutoff_VT_sup, M);
end
% There's a better way of writing this lmao

% Need to get a weighted average of the flat-plate skin friction
% coefficient for each component.
% Sum the laminar and turbulent.
% Get % that's laminar.
% Compute the length of laminar flow? From characteristic length?
% Use R_cutoff since that... by deduction... is where the flow transitions
% to turbulent? Or where Laminar equations are invalid. Lol

% Component: Fuselage
Cf_fuselage_sup = ((abs(R_fuselage_sup - R_cutoff_fuselage_sup))/R_cutoff_fuselage_sup * Cf_fuselage_turb_sup + (abs(R_fuselage_sup - R_cutoff_fuselage_sup))/R_cutoff_fuselage_sup * Cf_fuselage_lam)/2;

% Component: Main wings
Cf_mainwings_sup = ((abs(R_mainwings_sup - R_cutoff_mainwings_sup))/R_cutoff_mainwings_sup * Cf_mainwings_turb_sup + (abs(R_mainwings_sup - R_cutoff_mainwings_sup))/R_cutoff_mainwings_sup * Cf_mainwings_lam)/2;

% Component: Tail (Horizontal, Vertical)
Cf_HT_sup = ((abs(R_HT_sup - R_cutoff_HT_sup))/R_cutoff_HT_sup * Cf_HT_turb_sup + (abs(R_HT_sup - R_cutoff_HT_sup))/R_cutoff_HT_sup * Cf_HT_lam)/2;
Cf_VT_sup = ((abs(R_VT_sup - R_cutoff_VT_sup))/R_cutoff_VT_sup * Cf_VT_turb_sup + (abs(R_VT_sup - R_cutoff_VT_sup))/R_cutoff_VT_sup * Cf_VT_lam)/2;

% Sum skin friction coefficient contributions
Component_Drags_sup = Cf_fuselage_sup*S_wet + Cf_mainwings_sup*SW_wings + Cf_HT_sup*SW_HT + Cf_VT_sup*SW_VT;

% Compute CDmisc
% CALCULATING DRAG AREAS
Dq_upsweep_value = Dq_upsweep(0, pi*(D_fus/2)^2);
Dq_windmillingjet_value = Dq_windmillingjet(pi*((eng_diam)/2)^2);
% Convert drag areas into parasite drag by dividing by S_ref_mainwings!

CD0_upsweep = Dq_upsweep_value/S_ref;
CD0_windmillingjet = Dq_windmillingjet_value/S_ref;

% Compute CD leakage and protuberances


% Compute WAVE DRAG
Lambda_le_deg = 40;
Dq_searshaack = @(A_max, l) (9*pi/2 * (A_max/l)^2); % eq 12.44, 6thh ed
Dq_wave = @(E_WD, M, Lambda_LE_deg, A_max, l) (E_WD*(1-0.386*(M-1.2)^(0.57)*(1 - (pi*Lambda_le_deg^0.77)/100))*(Dq_searshaack(A_max, l))); % eq 12.45, 6th ed

Dq_wave_value = Dq_wave(1.2, M, 40, pi*(D_fus/2)^2, L_fus);
CD_wave = Dq_wave_value/S_ref;

%% Mach drag divergence
% Multiple definitions used in industry.
% Using Boeing's.
% From Raymer, 6th edition, eq 12.46
% Using supercritical airfoil -> multiply actual thickness ratio by 0.6.
%
% Should use tabulated values from Figs 12.29 & 12.30 & 12.31.
%
% For accurate results, compute MDD for each mission segment.
M_DD_L0 = 0.9; % From fig 12.29, lambda_c/4 = 40
LF_DD = 0.9; % tabulated from figure 12.30 (estimated)
CL_Design = 0.9;
M_DD = M_DD_L0 * LF_DD - 0.05*CL_Design;


%% Compute CD0_supersonic
CD0_supersonic = Component_Drags_sup/S_ref + CD_misc + CD_LandP + CD_wave;











%% -----------------------------------------------
% Compute lift coefficient (CL)

CL = (Weight_Results.MTOW)/(0.5*rho_drag_polar*V^2);






%% -----------------------------------------------
% Compute drag due to lift (CDi)

% e = 0.914; % Select this from the mission segment desired I guess
e_straight = @(AR) (1.78 * ( 1 - 0.045*AR^(0.68)) - 0.64); % For straight wings (sweep < 30 deg) (eq 12.48, 6th ed)
e_swept = @(AR) (4.61*(1-0.045*AR^(0.68))*cos(Lambda_le_deg*pi/180)^(0.15) - 3.1); % For swept-wing (sweep > 30 deg) (eq 12.49, 6th ed)

if Lambda_le_deg < 30
     e = e_straight(AR);
elseif Lambda_le_deg > 30;
     e = e_swept(AR);
else
     error("Error handler, computing e. How'd you do that?")
end

% Compute K
K = 1/(pi * AR * e); % eq 12.47, 6th ed

K_supersonic = ((AR*M^2 - 1) * cos(Lambda_le_deg*pi/180))/(4*AR*sqrt(M^2 - 1) - 2); % eq 12.51, 6th ed




% FOR UNCAMBERED ONLY (ADD CAMBERED LATER)
DragResults.CD0_sub = CD0_sub;
DragResults.CD0_sup = CD0_supersonic;
DragResults.CD_sub = CD0_sub + K*CL^2;
DragResults.CD_sup = CD0_supersonic + K*CL^2;
DragResults.K_sub = K;
DragResults.K_sup = K_supersonic;
DragResults.M_DD = M_DD;






end