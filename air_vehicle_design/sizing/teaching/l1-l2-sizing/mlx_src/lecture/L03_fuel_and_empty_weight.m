%[text] # L03 - The two questions the closure asks
%[text] **AOE 4065 - Aircraft Sizing, Lecture 3 of 7 (Boeing 777-200LR)**
%[text] The design point from L02 fixes the *shape*. To get the *size* we need a weight. The weight comes from one bookkeeping statement:
%[text] $W_{TO} = W_{empty} + W_{fuel} + W_{payload}$
%[text] Payload is a requirement, so it is known. The other two are not. Each one needs its own model, and both of them depend on $W_{TO}$ - which is the number we are trying to find. That circularity is the whole reason sizing is a loop.

%%
%[text] ## Build a fresh stack
setup_sizing_path;
[aero, prop, wts, geom, miss, con, tail] = build_b777_stack();
W_TO_trial = 700000;    % lbf, a guess to ask the models with

%%
%[text] ## Question 1: how much fuel does the mission need?
%[text] The mission model walks the flight profile leg by leg, threading the weight through. Cruise and loiter use Breguet; startup, taxi, takeoff, climb, descent and landing use historical fractions (Roskam Part I Table 2.1). A reserve markup goes on at the end.
%[text] Note the signature: `total_fuel` takes the takeoff weight as an argument. Fuel is not a property of the aircraft; it is a function of how heavy the aircraft is.

[W_fuel, breakdown] = miss.total_fuel(W_TO_trial);

fuel_summary = table( ...
    [breakdown.raw_burn; breakdown.reserve_fuel_fraction*100; W_fuel; W_fuel/W_TO_trial], ...
    'VariableNames', "Value", 'RowNames', ...
    {'raw mission burn [lbf]', 'reserve markup [%]', ...
     'W_fuel with reserve [lbf]', 'fuel fraction W_fuel/W_TO [-]'})

%%
%[text] ## Where the fuel goes
%[text] The profile is a **requirement**: it lives in the requirements JSON, not in any discipline model. Change the range and this picture changes, so the fuel fraction changes, so the sized aircraft changes. L07 measures how much.

plot_mission_profile(string(b777_requirements_path()), "long_range", breakdown);

%%
%[text] ## Question 2: what does the empty airframe weigh?
%[text] The 777 uses a **component build-up** (metabook Chapter 7, Algorithm 5): wing, tail, fuselage, landing gear, installed engines, and everything else, each from its own equation. Those equations read the geometry and propulsion objects live, so the empty weight follows the wing area and the engine thrust.
%[text] Like the fuel, `get_OEW` takes the takeoff weight as an argument.

W_OEW = wts.get_OEW(W_TO_trial);

% The per-component properties are Dependent and several of them scale with
% gross weight, so the object needs to be told which weight to report at.
wts.W_TO = W_TO_trial;

W_tail = wts.W_tail.HT + wts.W_tail.VT;      % this one comes back split

components = table( ...
    [wts.W_wings; W_tail; wts.W_fuselage; wts.W_landing_gear; ...
     wts.W_installed_engine; wts.W_all_else_empty; W_OEW], ...
    'VariableNames', "Weight_lbf", 'RowNames', ...
    {'wings', 'tail (HT + VT)', 'fuselage', 'landing gear', ...
     'installed engines', 'all else empty', 'TOTAL OEW'})

%%
%[text] ## Watch the empty weight follow the geometry
%[text] This is the coupling the loop has to resolve. Shrink the wing and the empty weight drops, with no re-reading of any input file. The weights object holds the geometry object and recomputes on every read.

S_before = geom.S_ref;
OEW_before = wts.get_OEW(W_TO_trial);
geom.S_ref = 0.80 * S_before;                 % a 20% smaller wing
OEW_after  = wts.get_OEW(W_TO_trial);
geom.S_ref = S_before;                        % put it back

coupling = table([S_before; 0.80*S_before], [OEW_before; OEW_after], ...
    'VariableNames', ["S_ref_ft2", "OEW_lbf"], ...
    'RowNames', {'as built', 'wing shrunk 20%'})

%%
%[text] ## Now close the weight
%[text] Put the three pieces together. Divide the bookkeeping statement through by $W_{TO}$:
%[text] $1 = \frac{W_{empty}}{W_{TO}} + \frac{W_{fuel}}{W_{TO}} + \frac{W_{payload}}{W_{TO}}$
%[text] and solve for the takeoff weight that the payload needs:
%[text] $W_{TO}^{new} = \frac{W_{payload}}{1 - W_{empty}/W_{TO} - W_{fuel}/W_{TO}}$
%[text] Reference: Raymer, *Aircraft Design*, 6th ed., Eq. 3.4; Martins metabook Algorithm 1. In code this is `SizingSteps.togw_update`.

W_payload = wts.W_payload_fixed + wts.W_payload_expendable;
[W_TO_new, denom] = SizingSteps.togw_update(W_payload, W_OEW, W_fuel, W_TO_trial);

closure = table( ...
    [W_TO_trial; W_OEW/W_TO_trial; W_fuel/W_TO_trial; W_payload; denom; W_TO_new; W_TO_new - W_TO_trial], ...
    'VariableNames', "Value", 'RowNames', ...
    {'W_TO we asked with [lbf]', 'empty fraction [-]', 'fuel fraction [-]', ...
     'W_payload [lbf]', 'denominator [-]', 'W_TO the closure returns [lbf]', ...
     'residual [lbf]'})

%%
%[text] ## Read the residual
%[text] We asked the models about a 700,000 lbf aeroplane and they answered with a different number. The two do not agree, so 700,000 lbf is not the answer. Make the residual zero and you have sized the aircraft.
%[text] Two things to notice about the denominator. It must stay positive: if empty plus fuel eats the whole takeoff weight there is nothing left for payload and no aircraft closes. And the smaller it gets, the more a small change in either fraction is amplified. That amplification is the growth factor of L07.
%[text] Next: **L04**, one full closure step with every number on screen.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
