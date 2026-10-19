%[text] # LAB01 - Pick the aspect ratio
%[text] **AOE 4065 - Aerodynamics and Wing Design, assignment.**
%[text] You are the wing designer of the 737 MAX 8. The wing area (124.6 m²), the takeoff mass, the sweep, the taper and the airfoil are fixed. Only the **aspect ratio** $A$ is yours to choose. Which $A$ gives the most range? Does the fuel still fit in the wing? Is the wing still legal at the airport gate?
%[text] Three trends from Nicolai Table 7.1 meet here. A higher $A$:
%[text] - **lowers K**, so $L/D$ goes up and the range goes up;
%[text] - **increases the wing weight**, so less fuel is left for the same takeoff mass, and the range goes down;
%[text] - **lowers the wing volume**, so there is less room for the fuel. \
%[text] How to work: the loop below has five TODO steps. Each step has an `error("TODO n ...")` line. Write your code, then delete that `error` line. Run the script section by section. Read the step sections first: each one gives the equation you need.
%%
%[text] ## The terms
%[text] - **MTOW**, $m\_{TO}$ = 82,644 kg: the maximum takeoff mass (ACAP Sec. 2.1.2). It is fixed in this lab.
%[text] - **Zero-fuel mass**, $ZFW$: the mass of the aircraft with everything except fuel. That is the empty aircraft (structure, engines, systems, and the wing), plus the crew and the payload.
%[text] - **MZFW** = 65,952 kg: the maximum zero-fuel mass (ACAP Sec. 2.1.2). Assumption: at the 737's own aspect ratio, $A$ = 9.44, the aircraft is full, so $ZFW = MZFW$.
%[text] - **Fuel mass**: $m\_{fuel} = m\_{TO} - ZFW$. Everything that is not zero-fuel mass is fuel.
%[text] - **Cruise**: M 0.785 at 35,000 ft. $V$ is the true airspeed, $a$ the speed of sound, $\\rho$ the air density (1976 U.S. Standard Atmosphere, `isa_si`).
%[text] - **C**: the specific fuel consumption, 0.5 per hour for a high-bypass turbofan in cruise (Raymer Table 3.3, p. 36). For SI units it must be per second: divide by 3600. \
setup_aero_path;
base = b737_baseline();
g0   = 9.80665;                                            % m/s^2
inputs = table([base.S; base.AR; base.MTOW; base.MZFW; base.M_cruise; base.H_cruise/0.3048; base.tsfc_hr], ...
    'VariableNames', "Value", 'RowNames', {'wing area S (m^2)', 'aspect ratio A (737)', ...
    'MTOW (kg)', 'MZFW (kg)', 'cruise Mach', 'cruise altitude (ft)', 'C (1/hr)'})
%%
%[text] ## The mission
%[text] Raymer Table 3.2 (p. 34) gives the mass fractions of the short mission segments: warm-up and takeoff 0.970, climb 0.985, landing 0.995. So the cruise starts at
%[text] $m\_{start} = m\_{TO} \\times 0.970 \\times 0.985$
%[text] The landing burns 0.5 % of the mass, and the aircraft lands with no fuel left (no reserves: a simplification). So at the end of cruise the mass is
%[text] $m\_{end} = \\frac{ZFW}{0.995}$
%[text] The wing area and the start mass do not change, so the cruise lift coefficient does not change with $A$ (we use its value at the start of cruise):
%[text] $C\_L = \\frac{m\_{start} g\_0}{q S}, \\quad q = \\frac{1}{2} \\rho V^2, \\quad V = M a$
atm     = isa_si(base.H_cruise);
V       = base.M_cruise*atm.a;                             % m/s
C       = base.tsfc_hr/3600;                               % 1/s
m_start = base.MTOW*base.frac_to*base.frac_cl;             % kg
CL      = m_start*g0/(0.5*atm.rho*V^2*base.S);
mission = table([V; 0.5*atm.rho*V^2; C; m_start; CL], 'VariableNames', "Value", ...
    'RowNames', {'V (m/s)', 'q (Pa)', 'C (1/s)', 'm_start (kg)', 'C_L'})
%%
%[text] ## Step 1 - K and L/D (TODO 1)
%[text] For each $A$, the function `aero_737(ac, 3)` gives the Level-3 values of L03: the drag coefficient $C\_{D0}$ (`o.CD0`), the lift-curve slope $C\_{L\\alpha}$ (`o.CLa`, per rad), the span without winglets $b = \\sqrt{A S}$ (`o.planform.b`), and the effective aspect ratio with winglets (`o.A_eff`):
%[text] $A\_{eff} = A\\left(1 + \\frac{h}{b}\\right)^2$  (Raymer Eq. 12.11, p. 400)
%[text] The drag due to lift comes from the leading-edge suction method (L03):
%[text] $K = S\_{LE} \\frac{1}{\\pi A\_{eff}} + (1 - S\_{LE}) \\frac{1}{C\_{L\\alpha}}$  (Raymer Eqs. 12.56-12.57, p. 447)
%[text] $S\_{LE}$ is the leading-edge suction, 0.93 for an airliner wing (`ac.S_suction`). It is not the wing area. Then
%[text] $\\frac{L}{D} = \\frac{C\_L}{C\_{D0} + K C\_L^2}$
%%
%[text] ## Step 2 - wing mass and zero-fuel mass (TODO 2)
%[text] The transport wing-weight equation of Raymer (Eq. 15.25, p. 574) is
%[text] $W\_{wing} = 0.0051 (W\_{dg} N\_z)^{0.557} S\_w^{0.649} A^{0.5} (t/c)\_{root}^{-0.4} (1+\\lambda)^{0.1} (\\cos\\Lambda)^{-1} S\_{csw}^{0.1}$
%[text] - $W\_{dg}$: the design gross weight; here the MTOW (`ac.MTOW`).
%[text] - $N\_z$: the ultimate load factor, 1.5 x the limit load factor 2.5 = 3.75 (`ac.Nz`).
%[text] - $S\_w$: the trapezoidal wing area (`ac.S`). $\\Lambda$: the quarter-chord sweep. $\\lambda$: the taper ratio. $(t/c)\_{root}$: the thickness ratio.
%[text] - $S\_{csw}$: the area of the control surfaces on the wing, flaps included (`ac.Scsw_frac*ac.S`). \
%[text] The equation is in pounds and square feet. The helper `wing_weight_raymer` converts the SI inputs and returns the wing mass in kg. Read its help: `help wing_weight_raymer`.
%[text] Only the wing changes when $A$ changes. The payload, the fuselage, the engines and the systems stay the same. So the zero-fuel mass changes by exactly the change of the wing mass:
%[text] $ZFW(A) = MZFW + \\left\[ m\_{wing}(A) - m\_{wing}(9.44) \\right\]$
%[text] At $A$ = 9.44 the bracket is zero and $ZFW = MZFW$. At a higher $A$ the wing is heavier, so $ZFW$ is larger. The MTOW is fixed, so the fuel mass $m\_{TO} - ZFW$ is smaller by the same amount. The code below gives you $m\_{wing}(9.44)$ as `m_wing_base`.
%%
%[text] ## Step 3 - range (TODO 3)
%[text] $R = \\frac{V}{C} \\frac{L}{D} \\ln\\frac{m\_{start}}{m\_{end}}$  (Breguet range, Raymer Eq. 3.5, p. 34)
%[text] Use the helper `breguet_range`. Give the range in km.
%%
%[text] ## Step 4 - does the fuel fit? (TODO 4)
%[text] The fuel volume that the mission needs is $V\_{need} = m\_{fuel}/\\rho\_{fuel}$, with $\\rho\_{fuel}$ = 803 kg/m³ for Jet A-1 (Raymer Table 10.5, p. 327; `ac.rho_fuel`). The volume inside the wing is
%[text] $V\_{wing} = 0.54 \\frac{S^2}{b} (t/c)\_{root} \\frac{1 + \\lambda\\sqrt{\\tau} + \\lambda^2 \\tau}{(1+\\lambda)^2}, \\quad \\tau = \\frac{(t/c)\_{tip}}{(t/c)\_{root}}$  (Roskam Part II, Eqs. 6.2-6.3, p. 153; `o.V_wing`)
%[text] The fuel fits if $V\_{need} \\le V\_{wing}$.
%%
%[text] ## Step 5 - is the span legal? (TODO 5)
%[text] The 737-8 is an ICAO Code C aircraft (ACAP Sec. 3.3.33): its span over the winglets must be less than 36 m (ICAO Annex 14), so that it fits a Code C gate. The winglets add 1.62 m to the span (`ac.dspan_winglet`):
%[text] $b\_{tip} = b + \\Delta b\_{winglet} < 36 \\text{ m}, \\quad \\text{so} \\quad A\_{max} = \\frac{(36 - \\Delta b\_{winglet})^2}{S}$
%%
%[text] ## The loop
m_wing_base = aero_737(base, 3).m_wing;                    % wing mass at A = 9.44 (kg)
ARs = 7:0.25:14;
n   = numel(ARs);
[K, LD, m_wing, ZFW, range_km, V_need, V_wing, b_tip] = deal(zeros(1, n));
for i = 1:n
    ac = base;  ac.AR = ARs(i);
    o  = aero_737(ac, 3);
    % ---- TODO 1: K(i) and LD(i)                                        (Step 1)
    error("TODO 1: compute K(i) and LD(i)");
    % ---- TODO 2: m_wing(i) and ZFW(i)                                  (Step 2)
    error("TODO 2: compute m_wing(i) and ZFW(i)");
    % ---- TODO 3: range_km(i)                                           (Step 3)
    error("TODO 3: compute range_km(i)");
    % ---- TODO 4: V_need(i) and V_wing(i), in m^3                       (Step 4)
    error("TODO 4: compute V_need(i) and V_wing(i)");
    % ---- TODO 5: b_tip(i), the span over the winglets, in m            (Step 5)
    error("TODO 5: compute b_tip(i)");
end
%%
%[text] ## Results
%[text] This code is given. It needs all five TODOs.
[Rmax, iBest] = max(range_km);
AR_span = (36 - base.dspan_winglet)^2/base.S;
iVol    = find(V_wing < V_need, 1);
if isempty(iVol), AR_vol = NaN; else, AR_vol = ARs(iVol); end
answer = table([ARs(iBest); Rmax; interp1(ARs, range_km, base.AR); AR_span; AR_vol], ...
    'VariableNames', "Value", 'RowNames', ...
    {'AR for the most range', 'most range (km)', 'range at the 737 AR 9.44 (km)', ...
     'largest AR inside the 36 m gate (Code C)', 'first AR where the fuel does not fit (NaN: none)'})
at737 = table(interp1(ARs, LD, base.AR), m_wing_base, interp1(ARs, range_km, base.AR), ...
    'VariableNames', ["LD", "Wing_mass_kg", "Range_km"], 'RowNames', {'the 737, A = 9.44'})
fig = new_figure([100 100 1050 450]);
tl  = tiledlayout(fig, 1, 2, 'Padding', 'compact');
ax  = nexttile(tl); hold(ax, 'on'); grid(ax, 'on');
plot(ax, ARs, range_km, '-o', 'LineWidth', 1.6, 'MarkerSize', 4);
xline(ax, AR_span, 'r--', 'span limit, 36 m', 'LabelVerticalAlignment', 'bottom');
xline(ax, base.AR, 'k:', '737', 'LabelVerticalAlignment', 'bottom');
plot(ax, ARs(iBest), Rmax, 'p', 'MarkerSize', 14, 'MarkerFaceColor', 'y');
xlabel(ax, 'aspect ratio'); ylabel(ax, 'cruise range (km)'); title(ax, 'Range at fixed MTOW and wing area');
ax = nexttile(tl); hold(ax, 'on'); grid(ax, 'on');
yyaxis(ax, 'left');  plot(ax, ARs, LD, '-', 'LineWidth', 1.6); ylabel(ax, 'cruise L/D');
yyaxis(ax, 'right'); plot(ax, ARs, m_wing, '--', 'LineWidth', 1.6); ylabel(ax, 'wing mass (kg)');
xlabel(ax, 'aspect ratio'); title(ax, 'The trade: L/D against wing mass');
%%
%[text] ## The same trade with 5,000 kg less payload
%[text] Less payload means a lower zero-fuel mass and more fuel at the same MTOW. This code is given; use it for Q3.
dP = 5000;
range_lp = zeros(1, n);  V_need_lp = zeros(1, n);
for i = 1:n
    ZFW_lp       = ZFW(i) - dP;
    range_lp(i)  = breguet_range(V, C, LD(i), m_start, ZFW_lp/base.frac_ld)/1e3;
    V_need_lp(i) = (base.MTOW - ZFW_lp)/base.rho_fuel;
end
[Rmax_lp, iBest_lp] = max(range_lp);
lessPayload = table([ARs(iBest_lp); Rmax_lp; V_need_lp(iBest_lp); V_wing(iBest_lp); base.fuel_cap], ...
    'VariableNames', "Value", 'RowNames', {'AR for the most range', 'most range (km)', ...
    'fuel volume needed (m^3)', 'wing volume, Roskam Eq. 6.2 (m^3)', '737 usable fuel, ACAP (m^3)'})

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
