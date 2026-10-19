%[text] # L04 - Low speed: how much lift does the 737 need?
%[text] **AOE 4065 - Aerodynamics and Wing Design, Lecture 4 of 5 (Boeing 737 MAX 8)**
%[text] The wing is sized for cruise, but it must also land and take off. In this lecture we start from two official numbers - the approach speed and the engine thrust - and find what the high-lift system must do.
%%
%[text] ## The landing lift coefficient that the 737 needs
%[text] Boeing gives the approach speed $V\_{REF}$ = 141 kt at the maximum landing weight (Boeing, *Aerodrome Reference Code and Approach Speeds*, Rev A, p. 3). The rule for $V\_{REF}$ is
%[text] $V\_{REF} \\ge 1.23 V\_{SR0}$  (14 CFR 25.125(b)(2)(i)(A))
%[text] where $V\_{SR0}$ is the reference stall speed in the landing configuration. At $V\_{SR0}$ the wing gives its maximum lift, so
%[text] $C\_{L,max,landing} = \\frac{2 W}{\\rho S V\_{SR0}^2}$
%[text] Sea level, standard day. At sea level the calibrated and true airspeeds are equal.
setup_aero_path;
ac  = b737_baseline();
g0  = 9.80665;
atm = isa_si(0);
kt  = 1852/3600;                       % m/s per knot (exact)
V_SR0   = ac.V_app_kt*kt/1.23;
W_L     = ac.MLW*g0;
CLmax_L = 2*W_L/(atm.rho*ac.S*V_SR0^2);
landing = table([ac.V_app_kt; V_SR0/kt; ac.MLW; CLmax_L], 'VariableNames', "Value", ...
    'RowNames', {'V_REF (kt)', 'V_SR0 (kt)', 'MLW (kg)', 'C_L max, landing, needed'})
%%
%[text] ## What the clean wing gives
%[text] Level 2: $C\_{L,max} = 0.9 c\_{l,max} \\cos\\Lambda\_{c/4}$ (Raymer Eq. 12.15, p. 405).
%[text] Level 3: $C\_{L,max} = c\_{l,max} (C\_{L,max}/c\_{l,max})$, with the ratio from Raymer Fig. 12.9 (Eq. 12.16, p. 406). The ratio depends on the leading-edge sweep and on the sharpness parameter $\\Delta y = 26 t/c$ = 3.1 for a NACA 4-digit section (Table 12.1). Both use the clean wing at M about 0.2.
o2 = aero_737(ac, 2);  o3 = aero_737(ac, 3);
clean = table([o2.CLmax; o3.CLmax], 'VariableNames', "CL_max_clean", ...
    'RowNames', {'Level 2, Raymer Eq. 12.15', 'Level 3, Raymer Eq. 12.16 + Fig. 12.9'})
dCL_L = CLmax_L - o3.CLmax
%[text] The clean wing gives about 1.34. The 737 needs about 2.6. So the high-lift devices must add about 1.2: almost as much as the clean wing itself.
%%
%[text] ## What the high-lift devices must do
%[text] Raymer gives the wing increment from the section increment of each device:
%[text] $\\Delta C\_{L,max} = 0.9 \\Delta c\_{l,max} \\frac{S\_{flapped}}{S} \\cos\\Lambda\_{H.L.}$  (Raymer Eq. 12.21, p. 415)
%[text] Table 12.2 (p. 415) gives $\\Delta c\_{l,max}$ at landing settings: double-slotted flap $1.6 c'/c$, slat $0.4 c'/c$, where $c'/c$ is the chord ratio with the device extended.
%[text] **Assumptions** (no official source): the trailing-edge flaps cover 60 % of the wing area (b737.org.uk gives flap span / wing span = 0.599); the slats cover 80 %; the hinge lines have the trailing-edge and leading-edge sweeps.
%[text] Question: **how much chord extension** $c'/c$ **does each layout need to give** $\\Delta C\_{L,max}$**?**
swTE = sweep_at(1, ac.sweep_c4, 0.25, ac.AR, ac.lambda);
swLE = o3.planform.sweep_LE;
perTE   = 0.9*1.6*0.60*cosd(swTE);        % Delta CL per unit c'/c, double-slotted flap
perSlat = 0.9*0.4*0.80*cosd(swLE);        % Delta CL per unit c'/c, slat
cpc_TEonly = dCL_L/perTE;
cpc_TEslat = (dCL_L - perSlat*1.0)/perTE; % slat at c'/c = 1 (lower bound)
devices = table([cpc_TEonly; cpc_TEslat], 'VariableNames', "Flap_c_prime_over_c_needed", ...
    'RowNames', {'double-slotted flaps only', 'double-slotted flaps + slats'})
%[text] With flaps only, the flaps must make the chord about 1.5 times longer: a very large extension. With slats as well, about 1.17 is enough. This is one reason why the 737 has **both** trailing-edge flaps and leading-edge slats.
%%
%[text] ## Takeoff with one engine inoperative
%[text] For takeoff, Raymer says to use "about 60-80 %" of the landing increments (p. 415). We take 70 % (assumption).
%[text] The takeoff safety speed must be at least $V\_2 = 1.13 V\_{SR}$ (14 CFR 25.107(b)(1)(ii)). At $V\_2$, with one engine inoperative and the landing gear up, a twin must climb with a gradient of at least 2.4 % (14 CFR 25.121(b)(1)):
%[text] $\\gamma = \\frac{T - D}{W} \\ge 0.024$
%[text] Takeoff flaps: $\\Delta C\_{D0}$ = 0.010-0.020 and $e$ = 0.75-0.80 (Roskam, *Airplane Design* Part I, Table 3.6, p. 126); we take the middle values. Thrust: one LEAP-1B28B1, 130.4 kN (EASA TCDS E.115, Sec. III.6). This is the static thrust; the thrust at $V\_2$ is lower, so the gradient below is too high. The drag of the dead engine is not included.
W_TO     = ac.MTOW*g0;
CLmax_TO = o3.CLmax + 0.70*dCL_L;
V_SR     = sqrt(2*W_TO/(atm.rho*ac.S*CLmax_TO));
V2       = 1.13*V_SR;
CL2      = CLmax_TO/1.13^2;
oTO      = aero_737(ac, 3, V2/atm.a, 0);              % clean CD0 at V2, sea level
CD0_TO   = oTO.CD0 + 0.015;                           % + takeoff flaps (Roskam Table 3.6)
K_TO     = 1/(pi*o3.A_eff*0.775);                     % e for takeoff flaps (Roskam Table 3.6)
D2       = 0.5*atm.rho*V2^2*ac.S*(CD0_TO + K_TO*CL2^2);
gradient = (ac.T_eng - D2)/W_TO;
takeoff = table([CLmax_TO; V_SR/kt; V2/kt; CL2; CD0_TO; D2/1e3; ac.T_eng/1e3; 100*gradient], ...
    'VariableNames', "Value", 'RowNames', {'C_L max, takeoff', 'V_SR (kt)', 'V2 (kt)', ...
    'C_L at V2', 'C_D0 with takeoff flaps', 'drag at V2 (kN)', 'thrust, one engine (kN)', ...
    'climb gradient (%), needs >= 2.4'})
%[text] One engine gives much more than the 2.4 % gradient. The margin covers the thrust loss at $V\_2$, the drag of the dead engine, and the drag of the rudder that holds the aircraft straight.
%[text] Note the method: every number above comes either from an official document, a regulation, or a cited textbook equation. Where we had no source, the assumption is written down.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
