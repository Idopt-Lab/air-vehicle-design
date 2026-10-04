%[text] # L01 - Build the B777 discipline stack
%[text] **AOE 4065 - Aircraft Sizing, Lecture 1 of 7 (Boeing 777-200LR)**
%[text] Sizing needs four kinds of answer, and each one comes from a different discipline model: how big is the aeroplane (geometry), how much drag does it make (aerodynamics), how much thrust and fuel flow does the engine give (propulsion), and what does the structure weigh (weights). A mission model turns the flight profile into fuel. A constraint model turns the performance requirements into a design point.
%[text] The discipline models are **given** in this course. This lecture is about the loop that drives them.
%[text] Target aircraft: Boeing 777-200LR. Real values, for comparison later: MTOW 766,800 lbf, thrust 220,000 lbf, wing area 4,605 ft², wing loading 142.45 psf. Source: Martins design metabook, Table 4.3 and Chapter 7.

%%
%[text] ## Put the framework on the path
setup_sizing_path

%%
%[text] ## Build the six objects, in the right order
%[text] The order is not free. Each constructor takes the objects it depends on, so a model cannot exist before the models it reads:
%[text] - `geom` first. It needs nothing.
%[text] - `prop` next. It needs nothing.
%[text] - `aero(geom)` reads the wing and wetted areas live, so the drag polar follows the wing.
%[text] - `tail(geom)` reads the wing to size the tail.
%[text] - `wts(geom, prop)` reads the areas and the thrust, so the empty weight follows both. \

sp = b777_spec_path(1);       % the SPEC file: what the aircraft IS
rp = b777_requirements_path();% the REQUIREMENTS file: what it must DO

geom = B777GeomL2(sp);
prop = B777PropL1(sp);
aero = B777AeroL1(geom, sp);
tail = B777TailL1(geom);
wts  = B777WeightsL2(sp, geom, prop);

miss = MissionAnalysisL1.from_requirements(aero, prop, geom, rp, "long_range");
con  = ConstraintAnalysis.from_requirements(aero, prop, rp, ...
           B777ConstraintSet.constraint_map(), linspace(20, 340, 321));

stack = table( ...
    ["geom"; "prop"; "aero"; "tail"; "wts"; "miss"; "con"], ...
    [string(class(geom)); string(class(prop)); string(class(aero)); ...
     string(class(tail)); string(class(wts)); string(class(miss)); string(class(con))], ...
    ["trapezoidal planform, exposed and wetted areas"; ...
     "2x GE90, density-ratio thrust lapse, cruise TSFC"; ...
     "drag polar, CD0 = Cfe*S_wet/S_ref, tracks the wing"; ...
     "tail area from volume coefficients"; ...
     "component build-up OEW(W_TO)"; ...
     "long-range mission fuel"; ...
     "ten requirements as curves in the T/W-W/S plane"], ...
    'VariableNames', ["Object", "Class", "What it does"])

%%
%[text] ## Two files, two different jobs
%[text] The **spec** file says what the aircraft *is*: areas, sweeps, installed thrust, airfoil. The **requirements** file says what it must *do*: cruise condition, range, field lengths, climb gradients. Sizing changes the spec until it satisfies the requirements, so the two must never be mixed in one file.

files = table( ...
    [string(sp); string(rp)], ...
    ["SPEC - what the aircraft is"; "REQUIREMENTS - what it must do"], ...
    'VariableNames', ["File", "Role"])

%%
%[text] ## Two levels of fidelity are already mixed here, on purpose
%[text] Notice the class names. Geometry and weights are **Level 2**; aerodynamics and propulsion are **Level 1**. That mix is deliberate. Fidelity is chosen per discipline, for the question being asked. For a transport, the empty weight is what drives the answer, so the weights model gets the component build-up and the drag model stays simple.
%[text] Keep two different meanings of "Level 2" apart:
%[text] - **discipline fidelity** - how one model computes its answer (regression against component build-up)
%[text] - **loop fidelity** - how many unknowns the sizing loop solves for, and what it re-solves each pass \
%[text] This lecture is about the second one. Lecture L06 shows what it buys.

%%
%[text] ## These objects are handles. They change under you.
%[text] Every discipline object is a MATLAB `handle`. A sizing loop does not return a new aircraft; it **writes into the objects you gave it**. Watch what happens to the wing area when we write to it.

before = geom.S_ref;
geom.S_ref = 4000;                      % pretend the loop resized the wing
after_area = geom.S_ref;
after_span = geom.b_wing;               % a Dependent property, recomputed on read
geom.S_ref = before;                    % put it back

handles = table([before; 4000; before], [NaN; after_span; geom.b_wing], ...
    'VariableNames', ["S_ref_ft2", "b_wing_ft"], ...
    'RowNames', {'as loaded', 'after writing S_ref', 'after putting it back'})

%%
%[text] **The rule that follows:** build a fresh stack before every sizing run. A second run on a used stack starts from the first run leftovers, not from the spec file. Every script in this package calls `build_b777_stack` for exactly that reason.
%[text] Next: **L02**, turn the ten requirements into a single design point.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
