function [DragResults] = Drag_Polar_II(Designgeo_wings, Designgeo_fuselage, Designgeo_propulsion, Weight_Results)


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
e = 0.914;
% S_VT = Weight_Results.S_VT;
% S_HT = Weight_Results.S_HT;

% Bingus
K = 1/(pi * e * AR);
Cf = 0.0035; % Skin friction coefficient

CD0 = Cf * S_wet/S_ref;

DragResults.CD0 = CD0;
% DragResults.CD0_sup = CD0_supersonic;
% DragResults.CD_sub = CD0_sub + K*CL^2;
% DragResults.CD_sup = CD0_supersonic + K*CL^2;
DragResults.K = K;
% DragResults.K_sup = K_supersonic;







end