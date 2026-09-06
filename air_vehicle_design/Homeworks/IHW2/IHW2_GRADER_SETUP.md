# IHW2 — Constraint Analysis · complete MATLAB Grader setup

**AOE 4065 · Test Twin Propeller Aircraft (TTPA)**

One file, everything needed to build the assignment: the assignment-level description,
the requirements-file walkthrough, the attachment plan, all twelve problems, and
the verification checklist.

IHW1 built the airplane's discipline models and closed the takeoff gross weight with a
mission analysis. IHW2 keeps every one of those files and asks the next question: what
wing loading and what power loading does the airplane have to be designed to, so that it
meets the takeoff, landing, climb and cruise requirements at the same time?

Everything in this document was produced by executing the reference set in
`air_vehicle_design/Homeworks/IHW2/`. All 42 tests of the eleven auto-graded problems
were run against it and pass. Problem 12 is submitted as a file and graded by hand. Do not
retype a number from this document into the code, and do not retype an equation from the
code into this document: the `.m` files are the single source of truth.

---

## 1 · Assignment description 

### Overview

In IHW1 you built a simple sizing framework — geometry, aerodynamics, propulsion,
weights — and used it to converge a takeoff gross weight over the design mission. In
IHW2 you extend the same framework with a **constraint analysis**, also called the
matching process. The final goal is a matching diagram: one plot that shows which
requirement is expensive, which combinations of wing loading and power loading are
feasible, and how much margin the design point has.

You keep working with the same objects. `obj.aero` is still your `TtpaAero`, `obj.prop`
is still your `TtpaProp`, and the analysis functions still take the `obj` bundle exactly
as `run_mission` did. Two things are new: your models have to answer questions IHW1
never asked, and there is a new requirements file that carries the answers.

### Recommended order

Complete the assignment in this order. Each step uses the ones before it.

1. **Requirements.** Read the new requirements file `Ttpa_requirements_IHW2.json` all
   the way through, including the underscore comments. It replaces
   `Ttpa_requirements.json` for this assignment.
2. **Aerodynamic model updates.** Extend `TtpaAero` with the CLmax and the drag polar of
   each airplane configuration.
3. **Propulsion model updates.** Extend `TtpaProp` with the power lapse, the power
   ratio, and a climb propeller efficiency.
4. **Constraint conditions.** Write `get_con`, the constraint twin of `get_miss_seg`.
5. **Individual constraints.** Takeoff ground roll, landing ground roll, the three FAR 23
   climb gradients, and cruise speed — one function each.
6. **Run every condition.** Write `run_constraints`, the constraint twin of
   `run_mission`.
7. **Matching.** Combine the limits into an envelope, find the best point, and test a
   design point.
8. **First sizing.** Turn the design point and your IHW1 takeoff weight into a wing area
   and an installed power, and check the landing requirement closes.
9. **The diagram.** Plot it.

### The airplane and its requirements

| Requirement | Value |
| --- | :---: |
| Takeoff ground roll | 1500 ft, sea level |
| Landing ground roll | 1500 ft, sea level |
| Climb gradient, all engines operating (AEO) | 8.3 %, sea level, takeoff flaps, gear up, max continuous power |
| Climb gradient, one engine inoperative (OEI) | 1.5 %, 5000 ft, clean, takeoff power on the live engine |
| Climb gradient, balked landing (BL) | 3.0 %, sea level, landing flaps, gear down, takeoff power |
| Cruise speed | 200 KTAS at 8000 ft, 80 % throttle |
| Aspect ratio | 8 |
| Number of engines | 2 |

The three climb gradients are the 14 CFR 23.2120 requirements for a Part 23 Level 2
low-speed twin. The field-length, climb and cruise methods are Roskam Part I,
Sections 3.1, 3.2, 3.3 and 3.6.

---

## 2 · The new requirements file, block by block

`Ttpa_requirements_IHW2.json` **replaces** `Ttpa_requirements.json` for IHW2. Read this
file and only this file. It carries the geometry and mission blocks of IHW1 unchanged,
so your mission analysis runs against it with no edit, and it adds three new blocks.

Read it the same way you did in IHW1:

```matlab
json_path = ttpa_requirements_path();     % finds Ttpa_requirements_IHW2.json
J         = jsondecode(fileread(json_path));
```

Keys that begin with an underscore are documentation. `jsondecode` renames them to
`x_comment`, `x_src` and so on; no code ever reads them.

### Who reads what

| Block | Read by | Pulled as |
| --- | --- | --- |
| `geometry` | `TtpaAero` constructor | `J.geometry.AR` |
| `aerodynamics` | `TtpaAero` constructor | `J.aerodynamics.CLmax_takeoff`, … |
| `propulsion` | `TtpaProp` constructor | `J.propulsion.n_engines`, … |
| `constraints.conditions` | `ConstraintSetImporter.read_conditions`, then `get_con` | `obj.cons(k)` |
| `constraints.wing_loading_range_psf`, `.wing_loading_points`, `.design_point` | the driver script | `J.constraints.design_point.wing_loading_psf` |
| `missions` | `MissionProfileReader.read_profile`, then `get_miss_seg` | unchanged from IHW1 |

### `aerodynamics` — new

In IHW1 the clean `CD0` was a literal inside `TtpaAero` and `get_CLmax` returned `NaN`.
The constraint analysis needs the airplane in **three configurations**, so every one of
those numbers now lives in the file:

| Key | Meaning |
| --- | --- |
| `CD0_clean` | clean zero-lift drag; same 0.028 you had, now read from the file |
| `CLmax_clean`, `CLmax_takeoff`, `CLmax_landing` | 1.5, 1.8, 2.2 — pull the one that matches the configuration |
| `CL_stall_margin` | 0.2, subtracted from CLmax to get the climb CL |
| `delta_CD0_flaps_takeoff`, `delta_CD0_flaps_landing`, `delta_CD0_gear_down` | Roskam Table 3.6 drag increments, added to `CD0_clean` |
| `delta_e_flaps_takeoff`, `delta_e_flaps_landing` | Roskam Table 3.6 Oswald increments, added to the clean `e` |
| `delta_CD0_propeller_stopped` | drag of the dead engine's stopped propeller, OEI only |

The configuration polar is built like this, and the file's own `_how_the_configuration_polar_is_built`
comment says the same thing:

```
CD0_config = CD0_clean + flap increment + gear increment (+ stopped-propeller increment)
e_config   = e_clean   + flap increment            (e_clean is still computed from AR)
K1_config  = 1/(pi*AR*e_config)
CL_climb   = CLmax_config - CL_stall_margin
```

The gear increment adds **on top of** the flap increment when the gear is down. Extending
the gear does not change `e`.

### `propulsion` — new, plus three values moved out of the class

| Key | Meaning |
| --- | --- |
| `n_engines` | 2. Divides the available power in the engine-out climb |
| `P_TO_over_P_max_continuous` | 1.1. Maximum continuous power is takeoff power divided by this |
| `eta_p_climb` | 0.80, the efficiency the climb constraint needs |
| `BSFC_lb_per_hp_hr`, `eta_p_cruise`, `eta_p_loiter` | the IHW1 values, moved out of the class so `TtpaProp` has one source per number |

### `constraints` — new

Six conditions, in this fixed order. `obj.cons(k)` is condition `k`:

| `k` | `name` | `type` |
| :---: | --- | --- |
| 1 | Takeoff | `takeoff` |
| 2 | Landing | `landing` |
| 3 | Climb AEO | `climb_gradient` |
| 4 | Climb OEI | `climb_gradient` |
| 5 | Climb BL | `climb_gradient` |
| 6 | Cruise Speed | `cruise_speed` |

Each condition holds **requirement data only** — where the airplane is, in what
configuration, at what weight and power, and what it must achieve. No CLmax, no CD0, no
propeller efficiency and no power lapse appears there: those come from your models.

**The conditions do not all carry the same keys.** A field-length condition has
`distance_ft`, a climb condition has `G`, the cruise condition has `ktas` and
`power_index`. Where a key is absent the importer leaves an empty value, so the optional
keys need defaults: `beta = 1.0`, `power_setting = 1.0`, `config = "clean"`, and `false`
for the three logical flags. That is what `get_con` is for.

`beta` is `W_condition/W_TO`, the weight at which the condition must be met, referred to
takeoff weight. It is a **specified requirement input, not an output of your mission
analysis**. `beta = 0.975` is the weight after startup, taxi, takeoff and the initial
climb — the same Roskam Table 2.2 fractions your `run_mission` applies
(0.984 × 0.990 = 0.974).

---

## 3 · What is given, what you write

**Given to you (do not modify):** `AerodynamicsBase.m`, `GeometryBase.m`,
`WeightsBase.m`, `PropulsionBase2.m`, `MissionProfileReader.m`,
`ConstraintSetImporter.m`, `AircraftState.m`, `json_as_struct_array.m`, `TtpaGeom.m`,
`TtpaWeights.m`, `get_miss_seg.m`, `run_mission.m`, `get_state.m`,
`ttpa_requirements_path.m`, `ttpa_disciplines.m`, `Ttpa_requirements_IHW2.json`.

**You write:** `TtpaAero.m` (extended), `TtpaProp.m` (extended), `get_con.m`,
`constraint_takeoff.m`, `constraint_landing.m`, `constraint_climb.m`,
`constraint_cruise_speed.m`, `run_constraints.m`, `matching_envelope.m`,
`design_point_check.m`, `size_from_design_point.m`, `plot_matching_diagram.m`.

### The bundle

`ttpa_disciplines` is given. It builds the same struct your mission analysis used, with
the constraint set added:

```matlab
obj = ttpa_disciplines();
%   obj.aero   TtpaAero      clean polar, CLmax, configuration polars
%   obj.geom   TtpaGeom      areas; receives S_ref from the sizing
%   obj.prop   TtpaProp      propeller efficiency, power lapse, power ratio
%   obj.wts    TtpaWeights   empty weight and payload
%   obj.miss   struct        mission profile      (IHW1)
%   obj.cons   struct array  constraint conditions (IHW2)
```

### The state, finally used

`get_state` is given. In IHW1 your segment functions passed `state = []` into
`prop_eff`, because a Breguet segment needs no atmosphere. Every constraint does need
one, so IHW2 fills that argument in:

```matlab
function [state] = get_state(alt_ft)
    atm = AircraftState(alt_ft, 0);
    sl  = AircraftState(0, 0);
    state.alt   = alt_ft;
    state.rho   = atm.rho;                 % slug/ft^3
    state.sigma = atm.rho / sl.rho;        % density ratio
end
```

`AircraftState` wraps MATLAB's `atmosisa` and converts to English units. The sea-level
density is taken from `AircraftState` as well, so `sigma` is exactly 1.0 at sea level.

### The call pattern, unchanged from IHW1

```matlab
% IHW1:  segment_cruise(W_in, obj, seg_no)   ->  miss_seg = get_miss_seg(seg_no, obj.miss)
% IHW2:  constraint_climb(WS,  obj, con_no)  ->  con      = get_con(con_no, obj.cons)
%                                                state    = get_state(con.alt)
```

Discipline queries take `(state, con)` in IHW2 where they took `(state)` or
`(state, miss_seg)` in IHW1, because the answer now depends on the configuration the
condition is flown in: `obj.aero.get_CLmax(state, con)`,
`obj.aero.get_config_polar(state, con)`, `obj.prop.prop_eff(state, con)`,
`obj.prop.power_ratio(state, con)`.

---

## 4 · Grader conventions and attachments

* Every problem is **Type = Function**, including the two class problems. IHW1 already
  grades `classdef` files this way.
* **Scoring Method = Weighted**, "Show % score to learners" on.
* Every test uses `assert`, never `assessVariableEqual` with `RelTol`.
* Formulas in descriptions go through the **CODE** button so exponents survive.
* Support files attach as **Assessment** files (invisible, on the path at run time),
  never as Solution files.

**Confirm the toolbox first.** Make a throwaway Function problem with reference
`function y = t(); y = AircraftState(5000, 0).rho; end`, attach `AircraftState.m`, and
Validate. It must return 0.0020481. Every problem depends on `atmosisa` through
`AircraftState`.

### Set A — support files (14). Attach to every problem.

`Ttpa_requirements_IHW2.json`, `ttpa_requirements_path.m`, `ttpa_disciplines.m`,
`get_state.m`, `AircraftState.m`, `ConstraintSetImporter.m`, `MissionProfileReader.m`,
`json_as_struct_array.m`, `AerodynamicsBase.m`, `GeometryBase.m`, `WeightsBase.m`,
`PropulsionBase2.m`, `TtpaGeom.m`, `TtpaWeights.m`

### Set B — the learner's earlier answers, on top of Set A

| Problem | Add |
| :---: | --- |
| 1 | `TtpaProp.m` |
| 2 | `TtpaAero.m` |
| 3 | `TtpaAero.m`, `TtpaProp.m` |
| 4, 5, 6, 7 | + `get_con.m` |
| 8 | + `constraint_takeoff.m`, `constraint_landing.m`, `constraint_climb.m`, `constraint_cruise_speed.m` |
| 9 | + `run_constraints.m` |
| 10 | + `matching_envelope.m` |
| 11 | `TtpaAero.m`, `TtpaProp.m`, `get_con.m` |
| 12 | not a Grader problem — students run their own code locally and upload the figure |

Problem 1 attaches `TtpaProp.m` and Problem 2 attaches `TtpaAero.m` because
`ttpa_disciplines` builds the whole bundle; the file being graded is the one the learner
writes.

### A note on numbers

The textbook worksheets for this airplane use rounded constants: sea-level density
0.002387, sigma at 5000 ft 0.858, power lapse 0.834. This framework computes all three
from the ISA atmosphere and gets 0.00237689, 0.861670 and 0.843411. The expected values
below are the ISA ones. A student who types a table value instead of calling the model
fails the last test of that problem, which is the intent.

---
---

# Problem 1 — Aerodynamic model updates

**Type** Function · **Weight** 12 · **Files** Set A + `TtpaProp.m`

## Description and Instructions

Extend your `TtpaAero` class. The mission analysis only ever needed the **clean**
airplane: one drag polar, no CLmax. Every constraint in this assignment is flown in a
particular flap and landing-gear position, so the class has to describe the airplane in
five configurations:

```
clean                      takeoff_flaps_gear_up      takeoff_flaps_gear_down
landing_flaps_gear_up      landing_flaps_gear_down
```

Those five names are the ones the framework uses in `AerodynamicsBase.get_config_polar`,
and they are the names the requirements file puts in each condition's `config` key.

**Step 1 — read the new data.** Add the `aerodynamics` block of the requirements file to
the constructor, next to the `J.geometry.AR` line you already have. `CD0` is no longer a
literal: it is `J.aerodynamics.CD0_clean`. Every property is declared for you in the
template; fill in the constructor only.

**The property name is not always the JSON key.** The file names the datum and carries its
qualifier; the class keeps the short name the rest of the code already uses. The tests read
the property names, so use these exactly:

| JSON key | Property |
| --- | --- |
| `J.geometry.AR` | `AR` |
| `CD0_clean` | `CD0` — **not** `CD0_clean` |
| `CLmax_clean`, `CLmax_takeoff`, `CLmax_landing` | unchanged |
| `CL_stall_margin` | unchanged |
| `delta_CD0_flaps_takeoff` … `delta_CD0_propeller_stopped` | `dCD0_flaps_takeoff` … `dCD0_propeller_stopped` |
| `delta_e_flaps_takeoff`, `delta_e_flaps_landing` | `de_flaps_takeoff`, `de_flaps_landing` |

**Step 2 — `get_CLmax(state, con)`.** In IHW1 this returned `NaN`. Now it returns the
CLmax of `con.config`: the clean value, the takeoff value with takeoff flaps whether or
not the gear is down, or the landing value with landing flaps. The landing gear does not
change CLmax. Error on any other configuration name — a typo in a configuration must
stop the analysis, not silently return the clean value. `state` is not used at this level
of fidelity, exactly as in `prop_eff`.

**Step 3 — `get_config_polar(state, con)`.** Override the method that
`AerodynamicsBase` declares. Return a struct with

```
cfg.CD0        CD0_clean + flap increment + gear increment
cfg.e          clean e + flap increment
cfg.K1         1/(pi*AR*e) of the configuration
cfg.K2         0
cfg.CLmax      CLmax of the configuration
cfg.CL_climb   CLmax minus CL_stall_margin
```

and add `delta_CD0_propeller_stopped` when `con.propeller_stopped` is true. The stall
margin belongs **here**, not in the constraint functions: apply it once and no constraint
can forget it.

Which increment goes with which configuration — this is the whole of Step 3:

| `con.config` | add to `CD0` | add to `e` |
| --- | --- | --- |
| `clean` | nothing | nothing |
| `takeoff_flaps_gear_up` | `dCD0_flaps_takeoff` | `de_flaps_takeoff` |
| `takeoff_flaps_gear_down` | `dCD0_flaps_takeoff` + `dCD0_gear_down` | `de_flaps_takeoff` |
| `landing_flaps_gear_up` | `dCD0_flaps_landing` | `de_flaps_landing` |
| `landing_flaps_gear_down` | `dCD0_flaps_landing` + `dCD0_gear_down` | `de_flaps_landing` |
| any of them with `con.propeller_stopped` true | also `dCD0_propeller_stopped` | nothing |

Do not touch `e`, `K`, `drag_polar` or `LD_max`. They are the clean airplane, and your
mission analysis still uses them.

## Check your work

With the requirements file as given, at sea level:

| Configuration | `cfg.CD0` | `cfg.e` | `cfg.CLmax` | `cfg.CL_climb` |
| --- | :---: | :---: | :---: | :---: |
| clean | 0.028 | 0.8106 | 1.5 | 1.3 |
| takeoff flaps, gear up | 0.043 | 0.7606 | 1.8 | 1.6 |
| takeoff flaps, gear down | 0.063 | 0.7606 | 1.8 | 1.6 |
| landing flaps, gear down | 0.113 | 0.7106 | 2.2 | 2.0 |
| clean, propeller stopped | 0.033 | 0.8106 | 1.5 | 1.3 |

The clean `e` must still come out 0.8106 and `LD_max` 13.487 — the same values as IHW1.

## Reference Solution

`Homeworks/IHW2/TtpaAero.m`.

```matlab
classdef TtpaAero < AerodynamicsBase
%TTPAAERO  Test Twin Propeller Aircraft Level-1 aerodynamic model.

    properties
        AR              % Wing aspect ratio, read from requirements JSON
        CD0             % Parasitic drag coefficient, clean configuration

        CLmax_clean     % Maximum lift coefficient, clean
        CLmax_takeoff   % Maximum lift coefficient, takeoff flaps
        CLmax_landing   % Maximum lift coefficient, landing flaps

        CL_stall_margin % CL margin below CLmax used in a climb

        dCD0_flaps_takeoff      % CD0 increment, takeoff flaps
        dCD0_flaps_landing      % CD0 increment, landing flaps
        dCD0_gear_down          % CD0 increment, landing gear extended
        dCD0_propeller_stopped  % CD0 increment, stopped propeller

        de_flaps_takeoff        % e increment, takeoff flaps
        de_flaps_landing        % e increment, landing flaps
    end

    properties (Dependent)
        e               % Oswald efficiency factor
        K               % Induced drag factor
        LD_max          % Maximum lift-to-drag ratio
    end

    methods

        %% Constructor
        function obj = TtpaAero(json_path)
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            % Read requirements JSON
            J = jsondecode(fileread(json_path));

            % Read geometry-owned requirement
            obj.AR = J.geometry.AR;

            % Read aerodynamics-owned data
            A = J.aerodynamics;

            obj.CD0             = A.CD0_clean;
            obj.CLmax_clean     = A.CLmax_clean;
            obj.CLmax_takeoff   = A.CLmax_takeoff;
            obj.CLmax_landing   = A.CLmax_landing;
            obj.CL_stall_margin = A.CL_stall_margin;

            obj.dCD0_flaps_takeoff     = A.delta_CD0_flaps_takeoff;
            obj.dCD0_flaps_landing     = A.delta_CD0_flaps_landing;
            obj.dCD0_gear_down         = A.delta_CD0_gear_down;
            obj.dCD0_propeller_stopped = A.delta_CD0_propeller_stopped;

            obj.de_flaps_takeoff = A.delta_e_flaps_takeoff;
            obj.de_flaps_landing = A.delta_e_flaps_landing;
        end

        %% Oswald Efficiency
        function e = get.e(obj)
            e = 1.78 * (1 - 0.045 * obj.AR^0.68) - 0.64;
        end


        %% Induced Drag Factor
        function K = get.K(obj)

            if isnan(obj.e) || obj.e <= 0 || obj.e > 1
                error('TtpaAero:InvalidOswaldEfficiency', ...
                    'Computed Oswald efficiency e = %.4f is invalid.', obj.e);
            end

            K = 1 / (pi * obj.AR * obj.e);
        end


        %% Drag Polar
        function polar = drag_polar(obj, ~)

            polar.CD0 = obj.CD0;
            polar.K1  = obj.K;
            polar.K2  = 0;

        end


        %% Maximum Lift Coefficient
        function CLmax = get_CLmax(obj, ~, con)

            switch string(con.config)

                case "clean"
                    CLmax = obj.CLmax_clean;

                case {"takeoff_flaps_gear_up", "takeoff_flaps_gear_down"}
                    CLmax = obj.CLmax_takeoff;

                case {"landing_flaps_gear_up", "landing_flaps_gear_down"}
                    CLmax = obj.CLmax_landing;

                otherwise
                    error('TtpaAero:UndefinedConfiguration', ...
                        'CLmax is not defined for configuration "%s".', ...
                        string(con.config));

            end

        end

        %% Configuration Polar
        function cfg = get_config_polar(obj, state, con)

            dCD0 = 0;
            de   = 0;

            switch string(con.config)

                case "clean"
                    % no high-lift increment

                case "takeoff_flaps_gear_up"
                    dCD0 = obj.dCD0_flaps_takeoff;
                    de   = obj.de_flaps_takeoff;

                case "takeoff_flaps_gear_down"
                    dCD0 = obj.dCD0_flaps_takeoff + obj.dCD0_gear_down;
                    de   = obj.de_flaps_takeoff;

                case "landing_flaps_gear_up"
                    dCD0 = obj.dCD0_flaps_landing;
                    de   = obj.de_flaps_landing;

                case "landing_flaps_gear_down"
                    dCD0 = obj.dCD0_flaps_landing + obj.dCD0_gear_down;
                    de   = obj.de_flaps_landing;

                otherwise
                    error('TtpaAero:UndefinedConfiguration', ...
                        'Drag polar is not defined for configuration "%s".', ...
                        string(con.config));

            end

            % Failed engine: the stopped propeller of the dead engine drags
            if con.propeller_stopped
                dCD0 = dCD0 + obj.dCD0_propeller_stopped;
            end

            cfg.config = string(con.config);
            cfg.CD0    = obj.CD0 + dCD0;
            cfg.e      = obj.e + de;
            cfg.K1     = 1 / (pi * obj.AR * cfg.e);
            cfg.K2     = 0;
            cfg.CLmax  = obj.get_CLmax(state, con);

            cfg.CL_climb = cfg.CLmax - obj.CL_stall_margin;

        end


        %% Maximum L/D
        function LD_max = get.LD_max(obj)

            LD_max = 1 / (2 * sqrt(obj.CD0 * obj.K));

        end

    end

end
```

## Learner Template

```matlab
classdef TtpaAero < AerodynamicsBase
%TTPAAERO  Test Twin Propeller Aircraft Level-1 aerodynamic model.
%
%   IHW2: add the configuration data and the two configuration methods.
%   The clean polar is unchanged - your mission analysis still uses it.

    properties
        % Declared for you, with the JSON key each one is read from. The
        % property name is NOT always the key: the file names the datum and
        % carries its qualifier, the class keeps the short name the rest of
        % your code uses. Do not rename these.
        AR                       % <- J.geometry.AR
        CD0                      % <- J.aerodynamics.CD0_clean

        CLmax_clean              % <- J.aerodynamics.CLmax_clean
        CLmax_takeoff            % <- J.aerodynamics.CLmax_takeoff
        CLmax_landing            % <- J.aerodynamics.CLmax_landing

        CL_stall_margin          % <- J.aerodynamics.CL_stall_margin

        dCD0_flaps_takeoff       % <- J.aerodynamics.delta_CD0_flaps_takeoff
        dCD0_flaps_landing       % <- J.aerodynamics.delta_CD0_flaps_landing
        dCD0_gear_down           % <- J.aerodynamics.delta_CD0_gear_down
        dCD0_propeller_stopped   % <- J.aerodynamics.delta_CD0_propeller_stopped

        de_flaps_takeoff         % <- J.aerodynamics.delta_e_flaps_takeoff
        de_flaps_landing         % <- J.aerodynamics.delta_e_flaps_landing

    end

    properties (Dependent)
        e
        K
        LD_max
    end

    methods

        %% Constructor
        function obj = TtpaAero(json_path)
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            J = jsondecode(fileread(json_path));

            obj.AR = J.geometry.AR;

            % TODO: read the aerodynamics block, for example
            %   A = J.aerodynamics;
            %   obj.CD0 = A.CD0_clean;
            %   ...

        end


        %% Oswald Efficiency
        function e = get.e(obj)
            e = 1.78 * (1 - 0.045 * obj.AR^0.68) - 0.64;
        end


        %% Induced Drag Factor
        function K = get.K(obj)
            if isnan(obj.e) || obj.e <= 0 || obj.e > 1
                error('TtpaAero:InvalidOswaldEfficiency', ...
                    'Computed Oswald efficiency e = %.4f is invalid.', obj.e);
            end
            K = 1 / (pi * obj.AR * obj.e);
        end


        %% Drag Polar
        function polar = drag_polar(obj, ~)
            polar.CD0 = obj.CD0;
            polar.K1  = obj.K;
            polar.K2  = 0;
        end


        %% Maximum Lift Coefficient
        function CLmax = get_CLmax(obj, ~, con)
        %GET_CLMAX  CLmax of the configuration named by con.config.

            switch string(con.config)

                % TODO: one case per configuration name, and an otherwise
                %       branch that errors on an unknown name

            end

        end


        %% Configuration Polar
        function cfg = get_config_polar(obj, state, con)
        %GET_CONFIG_POLAR  Drag polar and CLmax of the configuration.

            dCD0 = 0;
            de   = 0;

            switch string(con.config)

                % TODO: set dCD0 and de for each configuration.
                %       The gear increment adds on top of the flap increment.

            end

            % TODO: add the stopped-propeller increment when the condition
            %       sets con.propeller_stopped

            cfg.config   = string(con.config);
            cfg.CD0      = ;
            cfg.e        = ;
            cfg.K1       = ;
            cfg.K2       = 0;
            cfg.CLmax    = ;
            cfg.CL_climb = ;

        end


        %% Maximum L/D
        function LD_max = get.LD_max(obj)
            LD_max = 1 / (2 * sqrt(obj.CD0 * obj.K));
        end

    end

end
```

## Code to call your function

```matlab
%% -- Leave this Blank -- %%
```

## Tests — Weighted

**Test 1 · The constructor reads the file · weight 4**
```matlab
obj = ttpa_disciplines();
assert(abs(obj.aero.AR - 8) <= 1e-9, 'AR must still be read from J.geometry.AR');
assert(abs(obj.aero.CD0 - 0.028) <= 1e-9, 'CD0 must be read from J.aerodynamics.CD0_clean');
assert(abs(obj.aero.CLmax_clean - 1.5) <= 1e-9, 'CLmax_clean is wrong');
assert(abs(obj.aero.CLmax_takeoff - 1.8) <= 1e-9, 'CLmax_takeoff is wrong');
assert(abs(obj.aero.CLmax_landing - 2.2) <= 1e-9, 'CLmax_landing is wrong');
assert(abs(obj.aero.CL_stall_margin - 0.2) <= 1e-9, 'CL_stall_margin is wrong');
assert(abs(obj.aero.e - 0.810592) <= 1e-3*0.810592, 'the clean Oswald efficiency must not change');
assert(abs(obj.aero.LD_max - 13.486901) <= 1e-3*13.486901, 'the clean LD_max must not change');
```
*Feedback:* Add one property per key of the `aerodynamics` block and set it in the
constructor from `J.aerodynamics`. Keep the property names exactly as the template gives
them. `e` and `LD_max` must still come out at their IHW1 values — if they moved, you
changed the clean polar.

**Test 2 · CLmax of each configuration · weight 3**
```matlab
obj = ttpa_disciplines();
st  = get_state(0);
assert(abs(obj.aero.get_CLmax(st, struct('config', "clean")) - 1.5) <= 1e-9, 'CLmax of the clean configuration is wrong');
assert(abs(obj.aero.get_CLmax(st, struct('config', "takeoff_flaps_gear_up")) - 1.8) <= 1e-9, 'CLmax with takeoff flaps is wrong');
assert(abs(obj.aero.get_CLmax(st, struct('config', "takeoff_flaps_gear_down")) - 1.8) <= 1e-9, 'the gear does not change CLmax');
assert(abs(obj.aero.get_CLmax(st, struct('config', "landing_flaps_gear_down")) - 2.2) <= 1e-9, 'CLmax with landing flaps is wrong');
```
*Feedback:* Switch on `con.config`. Both takeoff configurations share `CLmax_takeoff`
and both landing configurations share `CLmax_landing`: the landing gear changes drag, not
lift.

**Test 3 · The configuration polar · weight 4**
```matlab
obj = ttpa_disciplines();
st  = get_state(0);
cfg = obj.aero.get_config_polar(st, struct('config', "takeoff_flaps_gear_up", 'propeller_stopped', false));
assert(abs(cfg.CD0 - 0.043) <= 1e-6, 'CD0 with takeoff flaps and gear up is wrong');
assert(abs(cfg.e - 0.760592) <= 1e-3*0.760592, 'e with takeoff flaps is wrong');
assert(abs(cfg.K1 - 0.052313) <= 1e-3*0.052313, 'K1 must be built from the e of the configuration');
assert(abs(cfg.CLmax - 1.8) <= 1e-9, 'CLmax of the configuration is wrong');
assert(abs(cfg.CL_climb - 1.6) <= 1e-9, 'CL_climb must be CLmax minus the stall margin');
cfg = obj.aero.get_config_polar(st, struct('config', "landing_flaps_gear_down", 'propeller_stopped', false));
assert(abs(cfg.CD0 - 0.113) <= 1e-6, 'CD0 with landing flaps and gear down is wrong');
assert(abs(cfg.e - 0.710592) <= 1e-3*0.710592, 'e with landing flaps is wrong');
assert(abs(cfg.CL_climb - 2.0) <= 1e-9, 'CL_climb with landing flaps is wrong');
```
*Feedback:* `CD0` adds the flap AND the gear increment; `e` takes only the flap
increment. `K1` must be rebuilt from the `e` of the configuration, not copied from the
clean `K`. `CL_climb` is `CLmax` minus `CL_stall_margin`.

**Test 4 · The stopped propeller, and the clean polar is untouched · weight 1**
```matlab
obj = ttpa_disciplines();
st  = get_state(5000);
cfg = obj.aero.get_config_polar(st, struct('config', "clean", 'propeller_stopped', true));
assert(abs(cfg.CD0 - 0.033) <= 1e-6, 'the stopped propeller must add its increment to the clean CD0');
assert(abs(cfg.e - 0.810592) <= 1e-3*0.810592, 'a stopped propeller does not change e');
polar = obj.aero.drag_polar(st);
assert(abs(polar.CD0 - 0.028) <= 1e-9, 'the clean drag polar must be unchanged');
```
*Feedback:* Add `dCD0_propeller_stopped` only when `con.propeller_stopped` is true, and
add it to `CD0`, not to `e`. `drag_polar` must keep returning the clean value.

---
---

# Problem 2 — Propulsion model updates

**Type** Function · **Weight** 12 · **Files** Set A + `TtpaAero.m`

## Description and Instructions

Extend your `TtpaProp` class. The mission analysis never asked how much power the engines
actually make: cruise and loiter used the Breguet equations, and every other segment used
a fixed weight fraction. Every constraint asks.

**Step 1 — read the new data.** Add a constructor that reads the `propulsion` block. The
three IHW1 values move out of the class body and into the file with the new ones, so
`C_bhp` returns `obj.BSFC` and `prop_eff` returns the properties. Leave `P_SL` as `NaN`:
the sizing sets it at the end of the assignment. Every property is declared for you in the
template; fill in the constructor only.

**The property name is not always the JSON key.** The file names the datum and carries its
unit; the class keeps the short name the rest of the code already uses. The tests read the
property names, so use these exactly:

| JSON key | Property |
| --- | --- |
| `n_engines` | `n_engines` |
| `BSFC_lb_per_hp_hr` | `BSFC` — **not** `BSFC_lb_per_hp_hr` |
| `eta_p_cruise`, `eta_p_loiter`, `eta_p_climb` | unchanged |
| `P_TO_over_P_max_continuous` | unchanged |

**Step 2 — `power_lapse(state, rating)`.** This is the stub `PropulsionBase2` declares
and IHW1 left empty. Implement it. Two effects multiply:

```
altitude   1.132*sigma - 0.132        normally aspirated piston engine
rating     "takeoff"        -> 1
           "max_continuous" -> 1 / P_TO_over_P_max_continuous
```

The altitude term is Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design,
Vol. I*, Eq. 14.5. Error on any other rating name. The result is a **fraction of
sea-level takeoff power**; multiplying by `P_SL` would give horsepower.

**Step 3 — `power_ratio(state, con)`.** One number that answers "how much of the
sea-level takeoff power of all engines is available at this condition?" It collects three
things:

```
power_lapse(state, rating)      rating from con.max_continuous
1 / n_engines                   when con.oei
con.power_setting               the throttle fraction
```

Every constraint calls this instead of assembling the factors itself. Work the three
numbers out before you write the line: they carry the most credit here, because a wrong
referral factor is invisible in the plot and fatal in the answer.

* Maximum continuous power is **lower** than takeoff power, so the AEO climb has kP < 1.
* In the OEI case **two** effects reduce the power, and they multiply.
* The balked landing uses full takeoff power at sea level, so its kP is 1.

**Step 4 — `prop_eff`.** Add a climb case. A constraint condition and a mission segment
both carry a `type` field, so the same method serves both; the climb-gradient conditions
have `type = "climb_gradient"`.

## Check your work

| | sea level | 5000 ft | 8000 ft |
| --- | :---: | :---: | :---: |
| `power_lapse(state, "takeoff")` | 1.0000 | 0.8434 | 0.7578 |
| `power_lapse(state, "max_continuous")` | 0.9091 | 0.7667 | 0.6889 |

`power_ratio` at the four conditions that use it:

| Condition | `kP` | why |
| --- | :---: | --- |
| Climb AEO | 0.9091 | sea level, but maximum continuous power |
| Climb OEI | 0.4217 | lapse to 5000 ft (0.8434), then one engine of two |
| Climb BL | 1.0000 | sea level, both engines, takeoff power |
| Cruise Speed | 0.6062 | lapse to 8000 ft (0.7578), then 80 % throttle |

## Reference Solution

`Homeworks/IHW2/TtpaProp.m`.

```matlab
classdef TtpaProp < PropulsionBase2
%TTPAPROP  Preliminary piston-propeller propulsion model.

    properties
        engine_type = "Piston Propeller"

        P_SL = NaN                      % rated power, all engines, sea level [hp]

        n_engines
        BSFC
        eta_p_cruise
        eta_p_loiter
        eta_p_climb
        P_TO_over_P_max_continuous
    end

    methods

        %% Constructor
        function obj = TtpaProp(json_path)
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            J = jsondecode(fileread(json_path));

            P = J.propulsion;

            obj.n_engines    = P.n_engines;
            obj.BSFC         = P.BSFC_lb_per_hp_hr;
            obj.eta_p_cruise = P.eta_p_cruise;
            obj.eta_p_loiter = P.eta_p_loiter;
            obj.eta_p_climb  = P.eta_p_climb;

            obj.P_TO_over_P_max_continuous = P.P_TO_over_P_max_continuous;
        end


        %% Power Lapse
        function alpha = power_lapse(obj, state, rating)
            % Nicolai & Carichner Eq. 14.5, times the rating factor
            alpha = (1.132 * state.sigma - 0.132) * obj.rating_factor(rating);
        end


        %% Power Ratio at a Constraint Condition
        function kP = power_ratio(obj, state, con)

            if con.max_continuous
                rating = "max_continuous";
            else
                rating = "takeoff";
            end

            kP = obj.power_lapse(state, rating);

            if con.oei
                kP = kP / obj.n_engines;
            end

            kP = kP * con.power_setting;

        end


        %% BSFC
        function C_bhp = C_bhp(obj, state)
            C_bhp = obj.BSFC;
        end


        %% Propeller Efficiency
        function eta_p = prop_eff(obj, state, miss_seg)

            switch lower(string(miss_seg.type))

                case "loiter"
                    eta_p = obj.eta_p_loiter;

                case "cruise"
                    eta_p = obj.eta_p_cruise;

                case {"climb", "climb_gradient"}
                    eta_p = obj.eta_p_climb;

                otherwise
                    error('TtpaProp:UndefinedSegment', ...
                        'Propeller efficiency is not defined for segment "%s".', ...
                        string(miss_seg.type));

            end

        end

    end

    methods (Access = private)

        %% Rating Factor
        function f = rating_factor(obj, rating)
            switch string(rating)

                case "takeoff"
                    f = 1;

                case "max_continuous"
                    f = 1 / obj.P_TO_over_P_max_continuous;

                otherwise
                    error('TtpaProp:UndefinedRating', ...
                        'Power rating "%s" is not defined.', string(rating));

            end
        end

    end

end
```

## Learner Template

```matlab
classdef TtpaProp < PropulsionBase2
%TTPAPROP  Preliminary piston-propeller propulsion model.
%
%   IHW2: read the propulsion block, implement the power lapse and the
%   power ratio, and add a climb case to prop_eff.

    properties
        engine_type = "Piston Propeller"

        P_SL = NaN      % rated power of ALL engines at sea level [hp]
                        % stays NaN until the sizing sets it

        % Declared for you, with the JSON key each one is read from. The
        % property name is NOT always the key: the file names the datum and
        % carries its unit, the class keeps the short name the rest of your
        % code uses. Do not rename these.
        n_engines                    % <- J.propulsion.n_engines
        BSFC                         % <- J.propulsion.BSFC_lb_per_hp_hr
        eta_p_cruise                 % <- J.propulsion.eta_p_cruise
        eta_p_loiter                 % <- J.propulsion.eta_p_loiter
        eta_p_climb                  % <- J.propulsion.eta_p_climb
        P_TO_over_P_max_continuous   % <- J.propulsion.P_TO_over_P_max_continuous

    end

    methods

        %% Constructor
        function obj = TtpaProp(json_path)
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            J = jsondecode(fileread(json_path));

            % TODO: read the propulsion block

        end


        %% Power Lapse
        function alpha = power_lapse(obj, state, rating)
        %POWER_LAPSE  Power at the state and rating, divided by the
        %   sea-level takeoff power of all engines [-].
        %   Nicolai & Carichner Eq. 14.5: 1.132*sigma - 0.132

            alpha = ;

        end


        %% Power Ratio at a Constraint Condition
        function kP = power_ratio(obj, state, con)
        %POWER_RATIO  Power available at the condition, divided by the
        %   sea-level takeoff power of ALL engines [-].
        %
        %   altitude and rating      power_lapse(state, rating)
        %   one engine inoperative   1 / n_engines
        %   throttle setting         con.power_setting

            % TODO: pick the rating from con.max_continuous

            kP = ;

            % TODO: the engine-out split, then the throttle setting

        end


        %% BSFC
        function C_bhp = C_bhp(obj, state)
            C_bhp = ;
        end


        %% Propeller Efficiency
        function eta_p = prop_eff(obj, state, miss_seg)

            switch lower(string(miss_seg.type))

                case "loiter"
                    eta_p = ;

                case "cruise"
                    eta_p = ;

                % TODO: a climb case. A climb-gradient CONDITION has
                %       type = "climb_gradient".

                otherwise
                    error('TtpaProp:UndefinedSegment', ...
                        'Propeller efficiency is not defined for segment "%s".', ...
                        string(miss_seg.type));

            end

        end

    end

    methods (Access = private)

        %% Rating Factor
        function f = rating_factor(obj, rating)
        %RATING_FACTOR  Power of the rating, divided by the takeoff power [-].

            % TODO: "takeoff" and "max_continuous", and an error otherwise

        end

    end

end
```

## Code to call your function

```matlab
%% -- Leave this Blank -- %%
```

## Tests — Weighted

**Test 1 · The constructor reads the file · weight 3**
```matlab
obj = ttpa_disciplines();
assert(obj.prop.n_engines == 2, 'n_engines is wrong');
assert(abs(obj.prop.BSFC - 0.4) <= 1e-9, 'BSFC must be read from the JSON');
assert(abs(obj.prop.eta_p_cruise - 0.82) <= 1e-9, 'eta_p_cruise is wrong');
assert(abs(obj.prop.eta_p_loiter - 0.72) <= 1e-9, 'eta_p_loiter is wrong');
assert(abs(obj.prop.eta_p_climb - 0.80) <= 1e-9, 'eta_p_climb is wrong');
assert(abs(obj.prop.P_TO_over_P_max_continuous - 1.1) <= 1e-9, 'P_TO_over_P_max_continuous is wrong');
assert(isnan(obj.prop.P_SL), 'P_SL must start as NaN; the sizing sets it');
```
*Feedback:* Add a constructor that takes the JSON path and reads `J.propulsion`. The
BSFC and the two mission propeller efficiencies are no longer literals in the class.
`P_SL` stays `NaN` here.

**Test 2 · The power lapse · weight 4**
```matlab
obj = ttpa_disciplines();
assert(abs(obj.prop.power_lapse(get_state(0), "takeoff") - 1.0) <= 1e-4, 'the lapse at sea level, takeoff rating, must be 1.0');
assert(abs(obj.prop.power_lapse(get_state(5000), "takeoff") - 0.843411) <= 1e-3*0.843411, 'the lapse at 5000 ft is wrong');
assert(abs(obj.prop.power_lapse(get_state(8000), "takeoff") - 0.757770) <= 1e-3*0.757770, 'the lapse at 8000 ft is wrong');
assert(abs(obj.prop.power_lapse(get_state(0), "max_continuous") - 0.909091) <= 1e-3*0.909091, 'the maximum-continuous rating is wrong');
```
*Feedback:* `1.132*sigma - 0.132` with `sigma` from the state, times the rating factor.
At sea level the takeoff rating must give exactly 1.0. Maximum continuous power is takeoff
power DIVIDED by 1.1, so its factor is less than 1.

**Test 3 · The power ratio at each condition · weight 3**
```matlab
obj = ttpa_disciplines();
% A condition is a struct. power_ratio reads three of its fields, so the four
% conditions are built here directly - get_con comes in the next problem.
con_aeo = struct('max_continuous', true,  'oei', false, 'power_setting', 1.0);
con_oei = struct('max_continuous', false, 'oei', true,  'power_setting', 1.0);
con_bl  = struct('max_continuous', false, 'oei', false, 'power_setting', 1.0);
con_cr  = struct('max_continuous', false, 'oei', false, 'power_setting', 0.8);
kP_aeo = obj.prop.power_ratio(get_state(0),    con_aeo);
kP_oei = obj.prop.power_ratio(get_state(5000), con_oei);
kP_bl  = obj.prop.power_ratio(get_state(0),    con_bl);
kP_cr  = obj.prop.power_ratio(get_state(8000), con_cr);
assert(abs(kP_aeo - 0.909091) <= 1e-3*0.909091, 'the all-engines power ratio is wrong');
assert(abs(kP_oei - 0.421705) <= 1e-3*0.421705, 'the engine-out power ratio is wrong');
assert(abs(kP_bl - 1.0) <= 1e-4, 'the balked-landing power ratio is wrong');
assert(abs(kP_cr - 0.606216) <= 1e-3*0.606216, 'the cruise power ratio is wrong');
```
*Feedback:* Three checks. The AEO climb is at sea level but at maximum continuous power,
so kP = 0.909. The OEI case has one engine of two AND a lapse to 5000 ft — both factors
multiply. The cruise condition is at 8000 ft AND at 80 % throttle. The balked landing has
both engines at takeoff power at sea level, so kP = 1.

**Test 4 · Propeller efficiency · weight 2**
```matlab
obj = ttpa_disciplines();
assert(abs(obj.prop.prop_eff([], struct('type', "cruise")) - 0.82) <= 1e-9, 'the cruise efficiency must be unchanged');
assert(abs(obj.prop.prop_eff([], struct('type', "loiter")) - 0.72) <= 1e-9, 'the loiter efficiency must be unchanged');
assert(abs(obj.prop.prop_eff([], struct('type', "climb_gradient")) - 0.80) <= 1e-9, 'a climb-gradient condition must use the climb efficiency');
```
*Feedback:* Keep the two mission cases working — your mission analysis calls them — and
add a case for `"climb_gradient"`, which is the `type` a climb condition carries.

---
---

# Problem 3 — The constraint condition

**Type** Function · **Weight** 6 · **Files** Set A + `TtpaAero.m`, `TtpaProp.m`

## Description and Instructions

Write `get_con`, the constraint twin of `get_miss_seg`. `get_miss_seg` was given to you
in IHW1; this one is yours to write, because the conditions differ from one another in a
way the mission segments did not.

`ConstraintSetImporter.read_conditions` has already read the `constraints.conditions`
block into `obj.cons`, a 1×6 struct array in file order. Your job is to pull out one
condition and hand back a tidy struct.

**The catch: the conditions do not all carry the same keys.** A field-length condition
has `distance_ft`, a climb condition has `G`, the cruise condition has `ktas` and
`power_index`. Where a key is absent, the importer leaves an empty value. Two kinds of
field, treated differently:

* **Requirement keys** (`distance_ft`, `G`, `ktas`, `power_index`) — read them directly.
  Empty is fine, exactly as `get_miss_seg` leaves `ktas` empty for a takeoff segment. The
  function that needs one knows it is there.
* **Configuration, weight and power keys** (`config`, `beta`, `power_setting`, `oei`,
  `propeller_stopped`, `max_continuous`) — read them through the given `get_field`
  helper, which returns a default when the key is absent. Every constraint reads these,
  so an empty value here would break the analysis.

The defaults are `config = "clean"`, `beta = 1.0`, `power_setting = 1.0` and `false` for
the three flags. Wrap the flags in `logical(...)` so they are true or false, not 1 or 0.

## Check your work

```
get_con(4, obj.cons)   the engine-out climb
    name  "Climb OEI"      type "climb_gradient"    config "clean"
    alt   5000             G    0.015               beta   0.975
    oei   true             propeller_stopped true   max_continuous false
    distance_ft, ktas, power_index are all empty

get_con(6, obj.cons)   the cruise-speed condition
    alt   8000             ktas 200                 power_index 1.4
    power_setting 0.8
    beta  1.0     <- the default; the condition does not give one
    config "clean"<- the default; the condition does not give one
    oei/propeller_stopped/max_continuous all false  <- defaults
```

## Reference Solution

`Homeworks/IHW2/get_con.m`, header comment trimmed.

```matlab
function [con] = get_con(con_no, cons)
% One constraint condition out of the constraint set.
% The constraint twin of get_miss_seg.

    con.name = string(cons(con_no).name);
    con.type = string(cons(con_no).type);
    con.alt  = cons(con_no).altitude_ft;

    % Requirement of this condition, whichever one applies
    con.distance_ft = cons(con_no).distance_ft;   % ft, field length
    con.G           = cons(con_no).G;             % -,  climb gradient
    con.ktas        = cons(con_no).ktas;          % kt, cruise speed
    con.power_index = cons(con_no).power_index;   % -,  Roskam Fig. 3.28

    % Configuration, weight basis and power basis
    con.config            = string(get_field(cons(con_no), 'config', "clean"));
    con.beta              = get_field(cons(con_no), 'beta',          1.0);
    con.power_setting     = get_field(cons(con_no), 'power_setting', 1.0);
    con.oei               = logical(get_field(cons(con_no), 'oei',               false));
    con.propeller_stopped = logical(get_field(cons(con_no), 'propeller_stopped', false));
    con.max_continuous    = logical(get_field(cons(con_no), 'max_continuous',    false));

end

%% Supporting Functions
% Value of an optional field, or its default when the key is absent
function [val] = get_field(c, name, default)
    if isfield(c, name) && ~isempty(c.(name))
        val = c.(name);
    else
        val = default;
    end
end
```

## Learner Template

```matlab
function [con] = get_con(con_no, cons)
% One constraint condition out of the constraint set.
% The constraint twin of get_miss_seg that was given to you in IHW1.
%
% Inputs:  con_no - condition number
%          cons   - the constraint set, obj.cons
% Output:  con    - struct with the fields listed in the problem

    % --- Milestone 1: label, type and altitude ---
    con.name = string(cons(con_no).name);
    con.type = ;
    con.alt  = ;

    % --- Milestone 2: the requirement keys, read directly ---
    con.distance_ft = ;
    con.G           = ;
    con.ktas        = ;
    con.power_index = ;

    % --- Milestone 3: the keys that need a default. Use get_field. ---
    con.config            = string(get_field(cons(con_no), 'config', "clean"));
    con.beta              = ;
    con.power_setting     = ;
    con.oei               = ;
    con.propeller_stopped = ;
    con.max_continuous    = ;

end

%% Supporting Functions -- given, do not change
function [val] = get_field(c, name, default)
    if isfield(c, name) && ~isempty(c.(name))
        val = c.(name);
    else
        val = default;
    end
end
```

## Code to call your function

```matlab
obj = ttpa_disciplines();
con = get_con(4, obj.cons)      % the one-engine-inoperative climb
```

## Tests — Weighted

**Test 1 · The takeoff condition · weight 2**
```matlab
obj = ttpa_disciplines();
con = get_con(1, obj.cons);
assert(string(con.name) == "Takeoff", 'con.name is wrong');
assert(string(con.type) == "takeoff", 'con.type is wrong');
assert(string(con.config) == "takeoff_flaps_gear_down", 'con.config is wrong');
assert(con.alt == 0, 'con.alt is wrong');
assert(con.distance_ft == 1500, 'con.distance_ft is wrong');
assert(abs(con.beta - 1.0) <= 1e-9, 'con.beta is wrong');
```
*Feedback:* Read `name`, `type`, `altitude_ft` and `distance_ft` straight out of
`cons(con_no)`, and `config` and `beta` through `get_field`.

**Test 2 · The engine-out climb condition · weight 2**
```matlab
obj = ttpa_disciplines();
con = get_con(4, obj.cons);
assert(con.alt == 5000, 'con.alt is wrong');
assert(abs(con.G - 0.015) <= 1e-9, 'con.G is wrong');
assert(string(con.config) == "clean", 'con.config is wrong');
assert(abs(con.beta - 0.975) <= 1e-9, 'con.beta is wrong');
assert(islogical(con.oei) && con.oei, 'con.oei must be logical true');
assert(islogical(con.propeller_stopped) && con.propeller_stopped, 'con.propeller_stopped must be logical true');
assert(islogical(con.max_continuous) && ~con.max_continuous, 'con.max_continuous must be logical false');
```
*Feedback:* Wrap each flag in `logical(...)`. This condition sets `oei` and
`propeller_stopped` in the file and leaves `max_continuous` false.

**Test 3 · The defaults · weight 2**
```matlab
obj = ttpa_disciplines();
con = get_con(6, obj.cons);
assert(abs(con.power_index - 1.4) <= 1e-9, 'con.power_index is wrong');
assert(abs(con.power_setting - 0.8) <= 1e-9, 'con.power_setting is wrong');
assert(abs(con.beta - 1.0) <= 1e-9, 'beta must fall back to 1.0 when the condition does not give it');
assert(islogical(con.oei) && ~con.oei, 'oei must fall back to logical false');
assert(string(con.config) == "clean", 'config must fall back to clean');
con = get_con(3, obj.cons);
assert(islogical(con.max_continuous) && con.max_continuous, 'max_continuous is wrong for the AEO climb');
```
*Feedback:* The cruise condition gives no `beta`, no `config` and no flags, so the
defaults must appear. Reading `cons(con_no).beta` directly returns an empty value and
breaks this test — that is what `get_field` is for.

---
---

# Problem 4 — Takeoff ground roll

**Type** Function · **Weight** 9 · **Files** Set A + `TtpaAero.m`, `TtpaProp.m`, `get_con.m`

## Description and Instructions

The airplane must lift off within the ground roll the takeoff condition requires. Roskam
Part I, Sec. 3.1 ties the ground roll to the takeoff parameter `TOP23`:

```
s_TGR = 4.9*TOP23 + 0.009*TOP23^2
TOP23 = (W/S)*(W/P) / (sigma*CLmax_TO)
```

Both relations are **dimensional**: `s_TGR` in ft, `W/S` in lbf/ft^2, `W/P` in lbf/hp.

**Step 1.** Get the condition with `get_con` and its atmosphere with `get_state`. Take
the required ground roll from `con.distance_ft`. Do not type 1500 into the function: the
requirement lives in the file, and the analysis has to follow it if it changes.

**Step 2.** Solve the first relation for `TOP23`. It is a quadratic; keep the positive
root — the other one has no physical meaning.

**Step 3.** Rearrange the second relation for the largest power loading a given wing
loading allows, and get `CLmax_TO` from the aerodynamic model.

A larger `W/P` means fewer horsepower per pound, so a smaller engine. `WP_max` is an
upper limit: the feasible region lies **below** this curve. Takeoff is at takeoff weight
by definition, so no weight referral is needed.

**The function must accept a row vector of wing loadings** and return `WP_max` of the
same size, so divide with `./` and not with `/`.

The takeoff condition is number **1** in the requirements file.

## Check your work

```
obj = ttpa_disciplines();
[WP_max, TOP23] = constraint_takeoff([20 30 40], obj, 1)

TOP23  = 218.46
WP_max = [19.66  13.11  9.83]      lbf/hp
```

## Reference Solution

`Homeworks/IHW2/constraint_takeoff.m`, header comment trimmed.

```matlab
function [WP_max, TOP23] = constraint_takeoff(WS, obj, con_no)
% Takeoff ground-roll constraint on the power loading.
% Roskam Part I, Sec. 3.1.

    con   = get_con(con_no, obj.cons);
    state = get_state(con.alt);

    CLmax_TO = obj.aero.get_CLmax(state, con);

    % Coefficients of S_TGR = 4.9 TOP23 + 0.009 TOP23^2
    a = 0.009;
    b = 4.9;
    c = -con.distance_ft;

    % TOP23 solution; the other root is negative
    TOP23 = (-b + sqrt(b^2 - 4*a*c)) / (2*a);

    WP_max = TOP23 * state.sigma * CLmax_TO ./ WS;

end
```

## Learner Template

```matlab
function [WP_max, TOP23] = constraint_takeoff(WS, obj, con_no)
% Takeoff ground-roll constraint on the power loading.
% Roskam Part I, Sec. 3.1:
%   S_TGR = 4.9*TOP23 + 0.009*TOP23^2
%   TOP23 = (W/S)*(W/P)/(sigma*CLmax_TO)

% --- Milestone 1: the condition, its atmosphere, and CLmax ---
con      = ;
state    = ;
CLmax_TO = ;

% --- Milestone 2: solve the quadratic for TOP23, positive root ---
a = 0.009;
b = 4.9;
c = ;

TOP23 = ;

% --- Milestone 3: the largest W/P that still meets the ground roll ---
WP_max = ;

end
```

## Code to call your function

```matlab
obj = ttpa_disciplines();
[WP_max, TOP23] = constraint_takeoff([20 30 40], obj, 1)
```

## Tests — Weighted

**Test 1 · Takeoff parameter · weight 3**
```matlab
obj = ttpa_disciplines();
[~, TOP23] = constraint_takeoff(40, obj, 1);
assert(abs(TOP23 - 218.4626) <= 1e-3*218.4626, 'TOP23 is wrong');
```
*Feedback:* Solve `0.009*TOP^2 + 4.9*TOP - s_TGR = 0` and keep the positive root. Note
that `c` is negative, and that `s_TGR` is `con.distance_ft`.

**Test 2 · Power-loading limit at W/S = 40 · weight 2**
```matlab
obj = ttpa_disciplines();
WP_max = constraint_takeoff(40, obj, 1);
assert(abs(WP_max - 9.830817) <= 1e-3*9.830817, 'WP_max is wrong');
```
*Feedback:* Rearrange `TOP23 = (W/S)(W/P)/(sigma*CLmax_TO)` for `W/P`. Check whether you
multiplied where you should have divided.

**Test 3 · Row vector of wing loadings · weight 2**
```matlab
obj = ttpa_disciplines();
WP_exp = [19.661635 13.107757 9.830817 9.144946];
WP_max = constraint_takeoff([20 30 40 43], obj, 1);
assert(isequal(size(WP_max), size(WP_exp)), 'WP_max must be the same size as WS');
assert(all(abs(WP_max - WP_exp) <= 1e-3*WP_exp), 'WP_max is wrong for an array of wing loadings');
```
*Feedback:* Use `./` instead of `/` — a plain `/` is matrix right-division and silently
collapses the answer to a scalar.

**Test 4 · The requirement and the model both changed · weight 2**
```matlab
obj = ttpa_disciplines();
obj.cons(1).distance_ft = 1200;
obj.cons(1).altitude_ft = 5000;
obj.aero.CLmax_takeoff  = 1.7;
WP_exp = [10.736203 7.668716 5.964557];
[WP_max, TOP23] = constraint_takeoff([25 35 45], obj, 1);
assert(abs(TOP23 - 183.2317) <= 1e-3*183.2317, 'TOP23 must follow the ground roll of the condition');
assert(all(abs(WP_max - WP_exp) <= 1e-3*WP_exp), 'WP_max must follow the altitude of the condition and the CLmax of the model');
```
*Feedback:* Nothing in this function may be a typed-in number. The ground roll and the
altitude come from the condition, `sigma` from `get_state(con.alt)`, and `CLmax_TO` from
`obj.aero.get_CLmax(state, con)`.

---
---

# Problem 5 — Landing ground roll

**Type** Function · **Weight** 9 · **Files** Set A + `TtpaAero.m`, `TtpaProp.m`, `get_con.m`

## Description and Instructions

The airplane must stop within the ground roll the landing condition requires. Roskam
Part I, Sec. 3.2 ties it to the stall speed with landing flaps:

```
s_LGR = 0.265 * Vs_L^2                             s_LGR in ft, Vs_L in KNOTS
Vs_L  = sqrt( (W/S)_L * (2/rho) * (1/CLmax_L) )    Vs_L in FT/S
```

**The two relations use different speed units.** Convert with `1 kt = 1.68781 ft/s`. This
is the most common error in this problem; the template gives you `kts2ft_s`.

Landing distance depends on wing loading only, so this requirement does **not** limit
`W/P`. It draws a vertical wall on the matching diagram, which is why the function takes
no wing loading and returns no curve.

**Step 1.** Largest permitted stall speed from the ground roll, in knots.
**Step 2.** The same speed in ft/s.
**Step 3.** Largest permitted wing loading. Turning the second relation around gives the
wing loading at **landing** weight, which is then referred to takeoff weight:

```
(W/S)_L  = 0.5*rho*Vs_L^2*CLmax_L          Vs_L in ft/s, rho in slug/ft^3
(W/S)_TO = (W/S)_L / beta
```

Think before you divide in step 3. The airplane is **lighter** at landing, so the takeoff
wing loading it permits is **larger** than the value at landing weight.

The landing condition is number **2** in the requirements file.

## Check your work

```
obj = ttpa_disciplines();
[WS_max, Vs_kts, Vs_fps] = constraint_landing(obj, 2)

Vs_kts = 75.24   kt
Vs_fps = 126.98  ft/s
WS_max = 43.24   lbf/ft^2       (multiplying by beta instead of dividing gives 41.1)
```

## Reference Solution

`Homeworks/IHW2/constraint_landing.m`, header comment trimmed.

```matlab
function [WS_max, Vs_kts, Vs_fps] = constraint_landing(obj, con_no)
% Landing ground-roll constraint on the wing loading.
% Roskam Part I, Sec. 3.2.  S_LGR = 0.265*Vs_L^2  (ft, kt)

    con   = get_con(con_no, obj.cons);
    state = get_state(con.alt);

    CLmax_L = obj.aero.get_CLmax(state, con);

    % Largest stall speed that still meets the ground roll
    Vs_kts = sqrt(con.distance_ft / 0.265);   % kt
    Vs_fps = kts2ft_s(Vs_kts);                % ft/s

    % Wing loading at landing weight, then referred to takeoff weight
    WS_max_L = 0.5 * state.rho * Vs_fps^2 * CLmax_L;
    WS_max   = WS_max_L / con.beta;

end

%% Supporting Functions
function [ft_s] = kts2ft_s(kts)
    ft_s = kts*6076.115/3600;
end
```

## Learner Template

```matlab
function [WS_max, Vs_kts, Vs_fps] = constraint_landing(obj, con_no)
% Landing ground-roll constraint on the wing loading.
% Roskam Part I, Sec. 3.2.  S_LGR = 0.265*Vs_L^2  (ft, kt)

% --- Milestone 1: condition, atmosphere, CLmax and the stall speed in kt ---
con     = ;
state   = ;
CLmax_L = ;

Vs_kts = ;

% --- Milestone 2: the same speed in ft/s ---
Vs_fps = ;

% --- Milestone 3: wing loading at landing, then referred to takeoff ---
WS_max_L = ;
WS_max   = ;

end

%% Supporting Functions -- given, do not change
function [ft_s] = kts2ft_s(kts)
    ft_s = kts*6076.115/3600;
end
```

## Code to call your function

```matlab
obj = ttpa_disciplines();
[WS_max, Vs_kts, Vs_fps] = constraint_landing(obj, 2)
```

## Tests — Weighted

**Test 1 · Stall speed in knots · weight 2**
```matlab
obj = ttpa_disciplines();
[~, Vs_kts] = constraint_landing(obj, 2);
assert(abs(Vs_kts - 75.235479) <= 1e-3*75.235479, 'Vs_kts is wrong');
```
*Feedback:* Invert `s_LGR = 0.265*Vs^2`, with `s_LGR` from `con.distance_ft`. The result
is in knots.

**Test 2 · Unit conversion · weight 2**
```matlab
obj = ttpa_disciplines();
[~, ~, Vs_fps] = constraint_landing(obj, 2);
assert(abs(Vs_fps - 126.983174) <= 1e-3*126.983174, 'Vs_fps is wrong');
```
*Feedback:* Multiply knots by 1.68781 to get ft/s. Do not divide.

**Test 3 · The wall at takeoff weight · weight 3**
```matlab
obj = ttpa_disciplines();
WS_max = constraint_landing(obj, 2);
assert(abs(WS_max - 43.240424) <= 1e-3*43.240424, 'WS_max is wrong');
```
*Feedback:* Use the speed in ft/s with `state.rho` in slug/ft^3, then DIVIDE by
`con.beta`. Multiplying gives 41.1, which is wrong.

**Test 4 · The requirement and the model both changed · weight 2**
```matlab
obj = ttpa_disciplines();
obj.cons(2).distance_ft = 1300;
obj.cons(2).beta        = 0.95;
obj.aero.CLmax_landing  = 2.0;
[WS_max, Vs_kts] = constraint_landing(obj, 2);
assert(abs(Vs_kts - 70.040420) <= 1e-3*70.040420, 'Vs_kts must follow the ground roll of the condition');
assert(abs(WS_max - 34.964745) <= 1e-3*34.964745, 'WS_max must follow CLmax_L and beta');
```
*Feedback:* Every one of the ground roll, `beta` and `CLmax_L` must appear in the answer.

---
---

# Problem 6 — Climb gradient

**Type** Function · **Weight** 14 · **Files** Set A + `TtpaAero.m`, `TtpaProp.m`, `get_con.m`

## Description and Instructions

This is the core problem of the assignment. **One function serves all three FAR 23 climb
conditions** — all engines operating, one engine inoperative, and balked landing —
because every difference between them is carried by the condition and by your models.

Roskam Part I, Sec. 3.3 writes the requirement through the climb gradient parameter.
There are two expressions. The first is what the rules **demand**, the second is what the
propeller **delivers**:

```
CD   = CD0 + CL^2/(pi*AR*e)
LoD  = CL/CD
CGRP = ( CGR + 1/LoD ) / sqrt(CL)                      <- required
CGRP = 18.97*eta_p*sqrt(sigma) / ( (W/P)*sqrt(W/S) )   <- delivered
```

Set them equal and solve for `W/P`. But the `W/P` and `W/S` in the second expression are
the values **in the climb**, not at takeoff. The matching diagram uses takeoff values
only, so refer them back with two factors:

```
beta = W_condition / W_TO                     from the condition
kP   = P_available / P_takeoff at sea level   from obj.prop.power_ratio
```

Since `(W/P)_climb = (W/P)_TO * beta/kP` and `(W/S)_climb = (W/S)_TO * beta`,

```
WP_max = 18.97*eta_p*sqrt(sigma)*kP / ( CGRP * beta^1.5 * sqrt(WS) )
```

Satisfy yourself where the exponent 1.5 comes from before you code it: `beta` enters
**twice**, once through `W/P` and once inside the square root of `W/S`. The 18.97
constant is dimensional — `W/S` in lbf/ft^2 and `W/P` in lbf/hp.

**Ask the models for everything else.** `obj.aero.get_config_polar(state, con)` returns
the polar of the flap and gear position of that condition, already carrying the Roskam
Table 3.6 increments, the stopped-propeller increment when the condition asks for it, and
`cfg.CL_climb`, the CL to climb at. `obj.prop.power_ratio(state, con)` already contains
the altitude lapse, the maximum-continuous derate, the engine-out split and the throttle
setting. **Do not assemble either of them here.**

Keep the function general: no case data may appear inside it. `WS` may be a row vector,
so use `./` in the last line.

The climb conditions are numbers **3** (AEO), **4** (OEI) and **5** (BL).

## Check your work

At `WS = 40` lbf/ft^2, all three conditions through the same function:

| Condition | `cfg.CD0` | `cfg.CL_climb` | `LD` | `CGRP` | `WP_max` |
| --- | :---: | :---: | :---: | :---: | :---: |
| 3 Climb AEO | 0.043 | 1.6 | 9.044 | 0.15303 | 14.25 |
| 4 Climb OEI | 0.033 | 1.3 | 11.211 | 0.09139 | 10.68 |
| 5 Climb BL | 0.113 | 2.0 | 5.935 | 0.14035 | 17.76 |

The engine-out case is the lowest of the three, so it is the climb requirement that
drives this airplane. If your OEI number comes out near 10.54 instead of 10.68, you wrote
`beta` where the equation needs `beta^1.5`.

## Reference Solution

`Homeworks/IHW2/constraint_climb.m`, header comment trimmed.

```matlab
function [WP_max, CGRP, LD, cfg] = constraint_climb(WS, obj, con_no)
% Climb-gradient constraint on the power loading.
% Roskam Part I, Sec. 3.3; configuration increments Table 3.6.

    con   = get_con(con_no, obj.cons);
    state = get_state(con.alt);

    % Aerodynamics of the configuration
    cfg = obj.aero.get_config_polar(state, con);

    CL = cfg.CL_climb;                  % CLmax of the configuration - margin
    CD = cfg.CD0 + cfg.K1 * CL^2;       % CD0 + CL^2/(pi AR e)
    LD = CL / CD;

    CGRP = (con.G + 1/LD) / sqrt(CL);

    % Propulsion at the condition
    eta_p = obj.prop.prop_eff(state, con);      % propeller efficiency in climb
    kP    = obj.prop.power_ratio(state, con);   % P_condition / P_TO at sea level

    WP_max = 18.97 * eta_p * sqrt(state.sigma) * kP ...
        ./ (CGRP * con.beta^1.5 * sqrt(WS));

end
```

## Learner Template

```matlab
function [WP_max, CGRP, LD, cfg] = constraint_climb(WS, obj, con_no)
% Climb-gradient constraint on the power loading.
% Roskam Part I, Sec. 3.3:
%   CD   = CD0 + CL^2/(pi*AR*e)
%   CGRP = (CGR + 1/(L/D))/sqrt(CL)
%   CGRP = 18.97*eta_p*sqrt(sigma)/((W/P)*sqrt(W/S))
%
% beta = W_condition/W_TO,  kP = P_condition/P_TO at sea level

% --- Milestone 1: the condition, its atmosphere and its polar ---
con   = ;
state = ;
cfg   = ;

% --- Milestone 2: the climb CL, the drag coefficient and L/D ---
CL = ;
CD = ;
LD = ;

% --- Milestone 3: the required climb gradient parameter ---
CGRP = ;

% --- Milestone 4: propeller efficiency and power ratio, from the model ---
eta_p = ;
kP    = ;

% --- Milestone 5: the largest W/P at takeoff that meets the gradient ---
WP_max = ;

end
```

## Code to call your function

```matlab
obj = ttpa_disciplines();
% condition 3 is the all-engines-operating climb
[WP_max, CGRP, LD, cfg] = constraint_climb([20 30 40], obj, 3)
```

## Tests — Weighted

**Test 1 · The configuration polar and L/D · weight 4**
```matlab
obj = ttpa_disciplines();
[~, ~, LD, cfg] = constraint_climb(40, obj, 3);
assert(abs(cfg.CD0 - 0.043) <= 1e-6, 'the AEO configuration polar is wrong');
assert(abs(cfg.CL_climb - 1.6) <= 1e-9, 'the climb CL must come from the configuration polar');
assert(abs(LD - 9.043593) <= 1e-3*9.043593, 'L/D is wrong');
```
*Feedback:* Get the polar from `obj.aero.get_config_polar(state, con)`. Climb at
`cfg.CL_climb`, not at `cfg.CLmax`, and use `CD = cfg.CD0 + cfg.K1*CL^2`.

**Test 2 · Climb gradient parameter · weight 3**
```matlab
obj = ttpa_disciplines();
[~, CGRP] = constraint_climb(40, obj, 3);
assert(abs(CGRP - 0.153035) <= 1e-3*0.153035, 'CGRP is wrong');
```
*Feedback:* `CGRP = (CGR + 1/(L/D))/sqrt(CL)` with `CGR = con.G`. The gradient is a
fraction, not a percentage — 0.083, not 8.3.

**Test 3 · The AEO limit, array input · weight 3**
```matlab
obj = ttpa_disciplines();
WP_exp = [20.158545 14.254244];
WP_max = constraint_climb([20 40], obj, 3);
assert(isequal(size(WP_max), size(WP_exp)), 'WP_max must be the same size as WS');
assert(all(abs(WP_max - WP_exp) <= 1e-3*WP_exp), 'WP_max is wrong for the AEO case');
```
*Feedback:* `kP` in the numerator, `beta^1.5` in the denominator, and `./` so the
function works on an array. The maximum-continuous derate is already inside `kP` — do not
apply it twice.

**Test 4 · The engine-out case · weight 2**
```matlab
obj = ttpa_disciplines();
[WP_max, CGRP, ~, cfg] = constraint_climb(40, obj, 4);
assert(abs(cfg.CD0 - 0.033) <= 1e-6, 'the OEI polar must include the stopped-propeller increment');
assert(abs(CGRP - 0.091386) <= 1e-3*0.091386, 'CGRP is wrong for the OEI case');
assert(abs(WP_max - 10.676260) <= 1e-3*10.676260, 'WP_max is wrong for the OEI case');
```
*Feedback:* Each of `state.sigma`, `con.beta` and `power_ratio` must appear, and `beta`
is raised to the power 1.5, not 1. Pass the whole condition to `get_config_polar` so that
the stopped-propeller drag is included.

**Test 5 · A changed gradient and a changed CLmax · weight 2**
```matlab
obj = ttpa_disciplines();
obj.cons(5).G          = 0.05;
obj.aero.CLmax_landing = 2.1;
[WP_max, CGRP, LD] = constraint_climb(40, obj, 5);
assert(abs(LD - 6.029115) <= 1e-3*6.029115, 'L/D must follow the CLmax of the model');
assert(abs(CGRP - 0.156603) <= 1e-3*0.156603, 'CGRP must follow the gradient of the condition');
assert(abs(WP_max - 15.915539) <= 1e-3*15.915539, 'WP_max is wrong on unseen inputs');
```
*Feedback:* Read the gradient from the condition and the polar from the model on every
call — do not keep a case table inside this function.

> **Why Test 4 matters.** Tests 1 to 3 run the AEO case, where `beta = 1` and `beta^1.5`
> and `beta^1.0` are indistinguishable. Only the engine-out case, at `beta = 0.975`,
> separates them: writing `beta` instead of `beta^1.5` gives 10.542 instead of 10.676, a
> 1.3 % error that no other test catches.

---
---

# Problem 7 — Cruise speed

**Type** Function · **Weight** 7 · **Files** Set A + `TtpaAero.m`, `TtpaProp.m`, `get_con.m`

## Description and Instructions

The airplane must cruise at 200 KTAS or faster at 8000 ft. Roskam Part I, Sec. 3.6 links
cruise speed to the power index:

```
Ip = [ (W/S) / (sigma*(W/P)) ]^(1/3)
```

so the requirement becomes `sigma*Ip^3*(W/P) - (W/S) <= 0`. For 200 kt, Fig. 3.28 gives
`Ip = 1.4`, and the condition carries it as `power_index`. **This is the only place the
cruise-speed requirement enters the whole analysis.**

Two power losses apply and they multiply: the engine loses power with altitude, and the
airplane cruises at 80 % throttle. Both are already inside
`obj.prop.power_ratio(state, con)` — only about 61 % of installed sea-level power is
available in cruise. Rearranged for the takeoff power loading, the constraint is a
straight line through the origin:

```
WP_max = slope * WS,     slope = kP / (sigma*Ip^3)
```

The cruise weight cancels, because it divides the wing loading and the power loading by
the same factor, which is why this condition carries no `beta`.

Note what this line does that no other constraint does: it **rises** with wing loading.
Speed can be bought two ways — more power, or a smaller wing with less drag. This is the
constraint that closes the feasible region from the left.

`WS` may be a row vector, so use `.*` in the last line. The cruise-speed condition is
number **6** in the requirements file.

## Check your work

```
obj = ttpa_disciplines();
[WP_max, slope] = constraint_cruise_speed([20 40], obj, 6)

slope  = 0.28107
WP_max = [5.62  11.24]      lbf/hp     <- rising, not falling
```

## Reference Solution

`Homeworks/IHW2/constraint_cruise_speed.m`, header comment trimmed.

```matlab
function [WP_max, slope] = constraint_cruise_speed(WS, obj, con_no)
% Cruise-speed constraint on the power loading.
% Roskam Part I, Sec. 3.6.  Ip = [ (W/S)/(sigma*(W/P)) ]^(1/3)

    con   = get_con(con_no, obj.cons);
    state = get_state(con.alt);

    kP = obj.prop.power_ratio(state, con);   % P_cruise / P_TO at sea level

    slope  = kP / (state.sigma * con.power_index^3);
    WP_max = slope .* WS;

end
```

## Learner Template

```matlab
function [WP_max, slope] = constraint_cruise_speed(WS, obj, con_no)
% Cruise-speed constraint on the power loading.
% Roskam Part I, Sec. 3.6.  Ip = [ (W/S)/(sigma*(W/P)) ]^(1/3)

% --- Milestone 1: the condition, its atmosphere and the cruise power ratio ---
con   = ;
state = ;
kP    = ;

% --- Milestone 2: the slope of the constraint line ---
slope = ;

% --- Milestone 3: the largest W/P at takeoff for each wing loading ---
WP_max = ;

end
```

## Code to call your function

```matlab
obj = ttpa_disciplines();
[WP_max, slope] = constraint_cruise_speed([20 30 40], obj, 6)
```

## Tests — Weighted

**Test 1 · The slope · weight 3**
```matlab
obj = ttpa_disciplines();
[~, slope] = constraint_cruise_speed(40, obj, 6);
assert(abs(slope - 0.281068) <= 1e-3*0.281068, 'slope is wrong');
```
*Feedback:* `slope = kP/(sigma*Ip^3)`, with `kP` from `obj.prop.power_ratio` and `Ip`
from `con.power_index`. Check that `Ip` is cubed and that `sigma` is in the denominator.

**Test 2 · The limit line · weight 2**
```matlab
obj = ttpa_disciplines();
WP_exp = [5.621368 11.242735];
WP_max = constraint_cruise_speed([20 40], obj, 6);
assert(isequal(size(WP_max), size(WP_exp)), 'WP_max must be the same size as WS');
assert(all(abs(WP_max - WP_exp) <= 1e-3*WP_exp), 'WP_max is wrong');
```
*Feedback:* `WP_max = slope*WS`. This line RISES with wing loading. If yours falls, you
inverted the relation.

**Test 3 · A changed cruise requirement · weight 2**
```matlab
obj = ttpa_disciplines();
obj.cons(6).power_index   = 1.5;
obj.cons(6).power_setting = 0.7;
obj.cons(6).altitude_ft   = 10000;
WP_exp = [5.931360 7.908480];
[WP_max, slope] = constraint_cruise_speed([30 40], obj, 6);
assert(abs(slope - 0.197712) <= 1e-3*0.197712, 'slope must follow the condition');
assert(all(abs(WP_max - WP_exp) <= 1e-3*WP_exp), 'WP_max is wrong on unseen inputs');
```
*Feedback:* The power index, the throttle setting and the altitude all come from the
condition. Do not hardcode 1.4, 0.8, or a lapse of 0.758.

---
---

# Problem 8 — Run every condition

**Type** Function · **Weight** 8
**Files** Set A + `TtpaAero.m`, `TtpaProp.m`, `get_con.m`, the four `constraint_*.m`

## Description and Instructions

Four functions, six conditions. This one walks the constraint set and sends each
condition to the function that sizes it.

It is the constraint twin of `run_mission`. Your `run_mission` walks the mission profile
segment by segment and calls `segment_takeoff`, `segment_climb`, `segment_cruise` and the
rest in a fixed order. `run_constraints` walks the constraint set and **dispatches on
`con.type` with a `switch`**, because the constraint set is read from the requirements
file. Add a condition to the file and this function picks it up with no edit.

**Two kinds of output, and they must not be mixed.** Three of the four condition types
put a ceiling on `W/P`, which is a curve over the sweep. The landing condition puts a
ceiling on `W/S`, which is a single number and no curve at all:

* `WP_limits(k,:)` is the curve of condition `k`, and stays **NaN** for the landing row.
* `WS_walls(k)` is the wall of condition `k`, and stays **NaN** for every other row.

Pre-allocate both with `NaN`, not with `zeros`. A student who forces the landing
condition into `WP_limits` produces a wrong diagram that still looks like a diagram.

End the `switch` with an `otherwise` that errors. A condition type nobody implemented must
stop the analysis, not disappear from it.

| Output | Holds | Size |
| --- | --- | :---: |
| `WP_limits` | the `W/P` ceiling of each condition at each wing loading, NaN for a wall condition | N×M |
| `WS_walls` | the `W/S` ceiling of each condition, NaN for a power condition | 1×N |
| `names` | `con.name` of each condition, in file order | 1×N string |
| `types` | `con.type` of each condition, in file order | 1×N string |

N is `numel(obj.cons)` and M is `numel(WS)`. Take N from the bundle, not from a typed-in
6, so that adding a condition to the file needs no edit here.

## Check your work

```
obj = ttpa_disciplines();
[WP_limits, WS_walls, names, types] = run_constraints(40, obj);

WP_limits' = [9.83   NaN   14.25   10.68   17.76   11.24]     lbf/hp
WS_walls   = [ NaN  43.24    NaN     NaN     NaN     NaN ]    lbf/ft^2
names      = ["Takeoff" "Landing" "Climb AEO" "Climb OEI" "Climb BL" "Cruise Speed"]
```

Every number in the first row appeared in Problems 4 to 7. If one of them moved, the
condition went to the wrong function.

## Reference Solution

`Homeworks/IHW2/run_constraints.m`, header comment trimmed.

```matlab
function [WP_limits, WS_walls, names, types] = run_constraints(WS, obj)
% Every constraint condition, over the wing-loading sweep.
% The constraint twin of run_mission: dispatch each condition by its type.

    WS = reshape(WS, 1, []);

    n_con = numel(obj.cons);

    WP_limits = NaN(n_con, numel(WS));
    WS_walls  = NaN(1, n_con);
    names     = strings(1, n_con);
    types     = strings(1, n_con);

    for k = 1:n_con

        con = get_con(k, obj.cons);

        names(k) = con.name;
        types(k) = con.type;

        switch con.type

            case "takeoff"
                WP_limits(k,:) = constraint_takeoff(WS, obj, k);

            case "landing"
                WS_walls(k)    = constraint_landing(obj, k);

            case "climb_gradient"
                WP_limits(k,:) = constraint_climb(WS, obj, k);

            case "cruise_speed"
                WP_limits(k,:) = constraint_cruise_speed(WS, obj, k);

            otherwise
                error('run_constraints:UndefinedCondition', ...
                    'Constraint condition type "%s" is not defined.', con.type);

        end

    end

end
```

## Learner Template

```matlab
function [WP_limits, WS_walls, names, types] = run_constraints(WS, obj)
% Every constraint condition, over the wing-loading sweep.
% The constraint twin of run_mission. All four constraint functions are on
% the path; call them.

WS = reshape(WS, 1, []);      % force a row vector

n_con = numel(obj.cons);

% --- Milestone 1: pre-allocate. A condition that sets no limit stays NaN. ---
WP_limits = ;
WS_walls  = ;
names     = strings(1, n_con);
types     = strings(1, n_con);

for k = 1:n_con

    % --- Milestone 2: the condition, its name and its type ---
    con = ;

    names(k) = ;
    types(k) = ;

    % --- Milestone 3: send it to the function that sizes it ---
    switch con.type

        case "takeoff"

        case "landing"

        case "climb_gradient"

        case "cruise_speed"

        otherwise
            error('run_constraints:UndefinedCondition', ...
                'Constraint condition type "%s" is not defined.', con.type);

    end

end

end
```

## Code to call your function

```matlab
obj = ttpa_disciplines();
[WP_limits, WS_walls, names, types] = run_constraints([20 30 40], obj)
```

## Tests — Weighted

**Test 1 · Shapes, names and types · weight 3**
```matlab
obj = ttpa_disciplines();
WS  = linspace(15, 50, 3501);
[WP_limits, WS_walls, names, types] = run_constraints(WS, obj);
assert(isequal(size(WP_limits), [6 3501]), 'WP_limits must be 6-by-N');
assert(isequal(size(WS_walls), [1 6]), 'WS_walls must be 1-by-6');
assert(string(names(1)) == "Takeoff" && string(names(6)) == "Cruise Speed", 'names are wrong or out of order');
assert(string(types(3)) == "climb_gradient", 'types are wrong or out of order');
```
*Feedback:* One row per condition and one column per wing loading, in file order. Take
the number of conditions from `numel(obj.cons)`, not from a typed-in 6.

**Test 2 · The landing condition is a wall, not a curve · weight 2**
```matlab
obj = ttpa_disciplines();
WS  = linspace(15, 50, 3501);
[WP_limits, WS_walls] = run_constraints(WS, obj);
assert(all(isnan(WP_limits(2,:))), 'the landing row of WP_limits must stay NaN');
assert(all(isnan(WS_walls([1 3 4 5 6]))), 'only the landing condition sets a wall');
assert(abs(WS_walls(2) - 43.240424) <= 1e-3*43.240424, 'the landing wall is wrong');
```
*Feedback:* Landing limits the wing loading and nothing else. Pre-allocate both outputs
with `NaN`, not with `zeros`.

**Test 3 · The five power ceilings at W/S = 40 · weight 2**
```matlab
obj = ttpa_disciplines();
WS  = linspace(15, 50, 3501);
WP_limits = run_constraints(WS, obj);
i40 = find(abs(WS-40) < 1e-6, 1);
col_exp = [9.830817; 14.254244; 10.676260; 17.758333; 11.242735];
col_got = WP_limits([1 3 4 5 6], i40);
assert(all(abs(col_got - col_exp) <= 1e-3*col_exp), 'the limits at W/S = 40 are wrong');
```
*Feedback:* A condition went to the wrong function, or a condition number was passed that
does not match the loop index. Pass `k` itself into each constraint function, so that the
three climb cases each get their own configuration, altitude, weight and power.

**Test 4 · Any grid · weight 1**
```matlab
obj = ttpa_disciplines();
[WP_limits, WS_walls] = run_constraints(linspace(15, 50, 100), obj);
assert(isequal(size(WP_limits), [6 100]), 'WP_limits must be 6-by-100 on a 100-point grid');
assert(abs(WS_walls(2) - 43.240424) <= 1e-3*43.240424, 'the wall must not depend on the grid');
```
*Feedback:* The landing wall comes from the landing requirement alone and cannot depend
on the wing loadings you were given.

---
---

# Problem 9 — The matching envelope

**Type** Function · **Weight** 11 · **Files** Set A + everything through `run_constraints.m`

## Description and Instructions

Combine everything. `run_constraints` is on the path; call it once and work with what it
returns.

**The envelope is the lowest ceiling.** At each wing loading the airplane must satisfy
every power condition, so the binding limit is the smallest of them. Rows that are all
NaN are wall conditions and take no part in it.

**The wall is separate.** Take the tightest of the wall conditions. If the set has none,
the answer is `Inf`, not an error.

**Then find the best point.** Among the wing loadings the wall still allows, find the one
where the envelope is highest. That point needs the fewest horsepower per pound, so it
buys the smallest, lightest, cheapest engine that still meets every requirement.

*Hint.* Copy `WP_env`, set the entries where `WS > WS_max` to `-Inf`, then take `max`.

*Hint on the empty case.* If no wing loading of the sweep is left of the wall, return
`NaN` for the best point instead of erroring. Problem 10 depends on this: it tests points
that lie beyond the wall on purpose.

The feasible region of a propeller airplane is **below** the envelope and **left** of the
wall — the mirror image of a jet's thrust-to-weight diagram, where feasible is above the
curve, because a large `W/P` means a small engine.

| Output | Holds | Size |
| --- | --- | :---: |
| `WP_env` | the smallest power ceiling at each wing loading | 1×M |
| `WS_max` | the tightest wall, `Inf` if the set has none | scalar |
| `driving` | the NAME of the condition that gives `WP_env` there | 1×M string |
| `WS_best`, `WP_best` | the best feasible point, NaN each if none | scalar |

`driving` comes from the second output of `min`, used to index the names — but index the
names of the **power conditions only**, or the labels shift by one once the landing row
is dropped.

## Check your work

```
obj = ttpa_disciplines();
WS  = linspace(15, 50, 3501);
[WP_env, WS_max, driving, WS_best, WP_best] = matching_envelope(WS, obj);

WS_max  = 43.24                        lbf/ft^2
WP_env  at W/S = 20, 30, 40, 43   ->   5.62,  8.43,  9.83,  9.14   lbf/hp
driving at W/S = 20               ->   "Cruise Speed"
driving at W/S = 40               ->   "Takeoff"
WS_best = 37.40  WP_best = 10.51
```

The best point sits where the rising cruise line crosses the falling takeoff line.

## Reference Solution

`Homeworks/IHW2/matching_envelope.m`, header comment trimmed.

```matlab
function [WP_env, WS_max, driving, WS_best, WP_best] = matching_envelope(WS, obj)
% Combine every constraint into the matching diagram.
% Feasible is BELOW the power-loading envelope and LEFT of the wall.

    WS = reshape(WS, 1, []);

    [WP_limits, WS_walls, names] = run_constraints(WS, obj);

    % Conditions that limit the power loading
    is_power = ~all(isnan(WP_limits), 2);

    if ~any(is_power)
        error('matching_envelope:NoPowerConstraint', ...
            'The constraint set has no condition that limits the power loading.');
    end

    [WP_env, idx] = min(WP_limits(is_power,:), [], 1);

    power_names = names(is_power);
    driving     = power_names(idx);

    % Conditions that limit the wing loading
    if all(isnan(WS_walls))
        WS_max = Inf;
    else
        WS_max = min(WS_walls(~isnan(WS_walls)));
    end

    % Best feasible point: largest power loading left of the wall
    usable = WP_env;
    usable(WS > WS_max) = -Inf;

    if all(isinf(usable))
        WS_best = NaN;
        WP_best = NaN;
    else
        [WP_best, j_best] = max(usable);
        WS_best           = WS(j_best);
    end

end
```

## Learner Template

```matlab
function [WP_env, WS_max, driving, WS_best, WP_best] = matching_envelope(WS, obj)
% Combine every constraint into the matching diagram.
% run_constraints is on the path; call it once.

WS = reshape(WS, 1, []);

% --- Milestone 1: every condition, in one call ---
[WP_limits, WS_walls, names] = ;

% --- Milestone 2: the envelope and the condition that sets it.
%     Rows that are all NaN are wall conditions; leave them out. ---
is_power = ;

[WP_env, idx] = ;

power_names = names(is_power);
driving     = ;

% --- Milestone 3: the tightest wall, Inf if the set has none ---
if all(isnan(WS_walls))
    WS_max = ;
else
    WS_max = ;
end

% --- Milestone 4: the best point inside the feasible set ---
usable = WP_env;
usable(WS > WS_max) = ;

if all(isinf(usable))
    WS_best = NaN;      % nothing feasible on this sweep
    WP_best = NaN;
else
    [WP_best, j_best] = ;
    WS_best           = ;
end

end
```

## Code to call your function

```matlab
obj = ttpa_disciplines();
[WP_env, WS_max, driving, WS_best, WP_best] = matching_envelope(linspace(15, 50, 3501), obj)
```

## Tests — Weighted

**Test 1 · The wall · weight 2**
```matlab
obj = ttpa_disciplines();
[~, WS_max] = matching_envelope(linspace(15, 50, 3501), obj);
assert(abs(WS_max - 43.240424) <= 1e-3*43.240424, 'WS_max is wrong');
```
*Feedback:* Take the smallest of the entries of `WS_walls` that are not NaN — `min` over
a vector that still holds NaN entries needs them removed first.

**Test 2 · The envelope · weight 3**
```matlab
obj = ttpa_disciplines();
WS  = linspace(15, 50, 3501);
env_exp = [5.621368 8.432052 9.830817 9.144946];
WP_env  = matching_envelope(WS, obj);
idx = [find(abs(WS-20)<1e-6,1) find(abs(WS-30)<1e-6,1) ...
       find(abs(WS-40)<1e-6,1) find(abs(WS-43)<1e-6,1)];
assert(isequal(size(WP_env), size(WS)), 'WP_env must be 1-by-N');
assert(all(abs(WP_env(idx) - env_exp) <= 1e-3*env_exp), 'WP_env is wrong');
```
*Feedback:* The envelope is the SMALLEST of the power ceilings at each wing loading —
`min(..., [], 1)` down the rows, not across the columns.

**Test 3 · Which condition is active · weight 2**
```matlab
obj = ttpa_disciplines();
WS  = linspace(15, 50, 3501);
[~, ~, driving] = matching_envelope(WS, obj);
dr  = string(driving);
assert(numel(dr) == numel(WS), 'driving must have one entry per wing loading');
assert(dr(find(abs(WS-20)<1e-6,1)) == "Cruise Speed", 'the active condition at W/S = 20 is wrong');
assert(dr(find(abs(WS-40)<1e-6,1)) == "Takeoff", 'the active condition at W/S = 40 is wrong');
```
*Feedback:* At a low wing loading the rising cruise line is the lowest ceiling; at W/S =
40 the falling takeoff line is. Index the names of the POWER conditions only, or the
labels shift by one once the landing row is dropped.

**Test 4 · The best feasible point · weight 2**
```matlab
obj = ttpa_disciplines();
[~, ~, ~, WS_best, WP_best] = matching_envelope(linspace(15, 50, 3501), obj);
assert(abs(WS_best - 37.40) <= 0.02, 'WS_best is wrong');
assert(abs(WP_best - 10.511958) <= 2e-3*10.511958, 'WP_best is wrong');
```
*Feedback:* Take the HIGHEST envelope value, not the lowest — the smallest engine, not
the largest. It sits where the rising cruise line crosses the falling takeoff line.

**Test 5 · Any grid, and the wall really binds · weight 2**
```matlab
obj = ttpa_disciplines();
WSc = 15:0.5:50;
[WP_env, WS_max] = matching_envelope(WSc, obj);
assert(abs(WS_max - 43.240424) <= 1e-3*43.240424, 'WS_max must not depend on the grid');
assert(numel(WP_env) == numel(WSc), 'WP_env must have one entry per input wing loading');

obj = ttpa_disciplines();
obj.aero.CLmax_landing = 1.6;
[~, WS_max2, ~, WS_best2, WP_best2] = matching_envelope(linspace(15, 50, 3501), obj);
assert(abs(WS_max2 - 31.447581) <= 1e-3*31.447581, 'the wall must follow CLmax_L');
assert(abs(WS_best2 - 31.44) <= 0.02, 'the best point must stay left of the wall');
assert(abs(WP_best2 - 8.836790) <= 2e-3*8.836790, 'the best point must stay left of the wall');
```
*Feedback:* Either the wall depends on the grid, which it must not, or the search for the
best point ignores the wall. Set the entries where `WS > WS_max` to `-Inf` before taking
`max`.

> **Why the second half of Test 5 exists.** With the real `CLmax_L = 2.2` the wall sits at
> 43.2 and the best point at 37.4, so a student who never applies the wall gets the right
> answer anyway and Tests 1 to 4 all pass. Lowering `CLmax_L` to 1.6 moves the wall to
> 31.4, in front of the crossing: the correct answer becomes (31.44, 8.84) while the
> unfiltered search still returns (37.40, 10.51). This is the only test that separates
> them.

---
---

# Problem 10 — Test a design point

**Type** Function · **Weight** 6 · **Files** Set A + everything through `matching_envelope.m`

## Description and Instructions

The requirements file selects `(W/S)_TO = 40` lbf/ft^2 and `(W/P)_TO = 9.25` lbf/hp,
which is **not** the best point of Problem 9. Test it. `matching_envelope` accepts a
scalar, so one call gives the ceiling, the wall and the active condition at that point.

Report the margin against each limit as a fraction of the limit:

```
WP_margin = (WP_limit - WP_point) / WP_limit
WS_margin = (WS_max   - WS_point) / WS_max
```

A positive margin means the point satisfies that constraint. A negative margin means it
violates it, and says by how much. **Return the margins for any point, feasible or not** —
do not take an absolute value and do not clip at zero. A negative margin is information,
and this function has to stay useful during a trade study. If the set has no wall,
`WS_max` is `Inf`; report the wing-loading margin as `Inf` rather than letting
`(Inf - WS)/Inf` produce a `NaN`.

When you have the answer, write one sentence in a comment: why would a designer pick
`(40, 9.25)` instead of the best point of Problem 9? Compare the two margins.

## Check your work

```
obj = ttpa_disciplines();
design_point_check(40,   9.25, obj)  ->  feasible true,  "Takeoff",      +0.0591, +0.0749
design_point_check(30,  12,    obj)  ->  feasible false, "Cruise Speed", -0.4231, +0.3062
design_point_check(45,   8,    obj)  ->  feasible false, "Takeoff",      +0.0845, -0.0407
```

The last point is the one to think about: it has plenty of power but too much wing
loading, so only the `W/S` margin goes negative. Both limits have to enter `feasible`.

## Reference Solution

`Homeworks/IHW2/design_point_check.m`, header comment trimmed.

```matlab
function [feasible, driving, WP_margin, WS_margin] = design_point_check(WS_pt, WP_pt, obj)
% Test one design point against every constraint.

    [WP_limit, WS_max, driving] = matching_envelope(WS_pt, obj);

    WP_margin = (WP_limit - WP_pt) / WP_limit;

    if isinf(WS_max)
        WS_margin = Inf;   % no wall in the constraint set
    else
        WS_margin = (WS_max - WS_pt) / WS_max;
    end

    feasible = (WP_pt <= WP_limit) && (WS_pt <= WS_max);

end
```

## Learner Template

```matlab
function [feasible, driving, WP_margin, WS_margin] = design_point_check(WS_pt, WP_pt, obj)
% Test one design point against every constraint.
% matching_envelope is on the path and accepts a scalar wing loading.

% --- Milestone 1: the limits at this wing loading ---
[WP_limit, WS_max, driving] = ;

% --- Milestone 2: the margins, signed, each divided by its own limit ---
WP_margin = ;

if isinf(WS_max)
    WS_margin = Inf;      % no wall in the constraint set
else
    WS_margin = ;
end

% --- Milestone 3: the verdict. BOTH limits must be satisfied. ---
feasible = ;

% Answer in one sentence: why choose (40, 9.25) over the best point?
%

end
```

## Code to call your function

```matlab
obj = ttpa_disciplines();
[feasible, driving, WP_margin, WS_margin] = design_point_check(40, 9.25, obj)
```

## Tests — Weighted

**Test 1 · The selected design point · weight 2**
```matlab
obj = ttpa_disciplines();
[feasible, driving, WP_margin, WS_margin] = design_point_check(40, 9.25, obj);
assert(logical(feasible), 'the point (40, 9.25) meets every constraint, but your function says it does not');
assert(string(driving) == "Takeoff", 'the active condition at W/S = 40 is wrong');
assert(abs(WP_margin - 0.059081) <= 5e-3*0.059081, 'WP_margin is wrong');
assert(abs(WS_margin - 0.074940) <= 5e-3*0.074940, 'WS_margin is wrong');
```
*Feedback:* Divide each margin by the LIMIT, not by the point value. At W/S = 40 the
takeoff ground roll gives the lowest `W/P` ceiling.

**Test 2 · A point above the ceiling · weight 2**
```matlab
obj = ttpa_disciplines();
[feasible, driving, WP_margin] = design_point_check(30, 12, obj);
assert(~logical(feasible), 'the point (30, 12) sits above the cruise line, so it is not feasible');
assert(string(driving) == "Cruise Speed", 'the active condition at W/S = 30 is wrong');
assert(abs(WP_margin - (-0.423141)) <= 5e-3*0.423141, 'a violated constraint must give a negative margin');
```
*Feedback:* A violated constraint must give a NEGATIVE margin. Do not take an absolute
value and do not clip at zero.

**Test 3 · A point past the wall · weight 2**
```matlab
obj = ttpa_disciplines();
[feasible, ~, WP_margin, WS_margin] = design_point_check(45, 8, obj);
assert(~logical(feasible), 'W/S = 45 is past the landing wall, so the point is not feasible');
assert(abs(WP_margin - 0.084512) <= 5e-3*0.084512, 'WP_margin is wrong');
assert(abs(WS_margin - (-0.040693)) <= 5e-3*0.040693, 'WS_margin is wrong');
```
*Feedback:* This point has a comfortable `W/P` but too much wing loading. Report the
positive power margin as it is and the negative wing-loading margin as it is, and use
`&&` so that BOTH limits enter the verdict.

> **Why Test 3 exists.** A student who checks only `WP_pt <= WP_limit` passes Tests 1 and
> 2. Only a point that clears the ceiling but not the wall separates the two conditions.

---
---

# Problem 11 — First sizing from the design point

**Type** Function · **Weight** 6 · **Files** Set A + `TtpaAero.m`, `TtpaProp.m`, `get_con.m`

## Description and Instructions

The design point is a pair of ratios. Turn it into an airplane.

The takeoff gross weight comes from your IHW1 mission analysis, `W_TO = 5354` lbf. It is
an argument here, so this problem does not depend on that homework being right.

```
S_ref = W_TO / (W/S)
b     = sqrt(AR * S_ref)
c_bar = S_ref / b
P_TO  = W_TO / (W/P)
```

Take the aspect ratio from `obj.aero.AR` — the aerodynamic model is the one that reads
`J.geometry.AR`. Use `GeometryBase.compute_span(AR, S_ref)` for the span; it is the same
static the framework uses.

`P_TO` is the **total installed power**. This airplane has two engines, so each delivers
`P_TO/obj.prop.n_engines`. Keep that in mind when you open an engine catalogue.

**Write the two sized values back into the models.** `obj.geom.S_ref` and `obj.prop.P_SL`
are `NaN` until this point; set them. The discipline objects are handle objects, so the
caller sees the change without the function returning them.

Then close the loop on the landing requirement. Compute the stall speed with landing flaps
**at landing weight** and put it back into the Roskam relation of Problem 5:

```
V_fps       = sqrt( 2*(W/S)*beta / (rho*CLmax_L) )     ft/s
Vs_L_kts    = V_fps * 3600/6076.115                    kt
s_LGR_check = 0.265 * Vs_L_kts^2                       ft
```

`s_LGR_check` must come out at or below the required 1500 ft. **This is the check that
closes the analysis**: it re-derives the landing distance from the airplane you just
sized, running the same relation forward instead of backward.

Take `beta`, `rho` and `CLmax_L` from the landing condition and the aerodynamic model —
that is why the landing condition number is an argument. It is number **2**.

## Check your work

```
obj = ttpa_disciplines();
[S_ref, b, c_bar, P_TO, P_engine, Vs_L_kts, s_LGR_check] = ...
    size_from_design_point(5354, 40, 9.25, obj, 2)

S_ref       = 133.85   ft^2        P_TO        = 578.81   hp
b           =  32.72   ft          P_engine    = 289.41   hp
c_bar       =   4.09   ft          Vs_L_kts    =  72.36   kt
s_LGR_check = 1387.6   ft   <= 1500 ft, so the design closes

obj.geom.S_ref and obj.prop.P_SL must now hold 133.85 and 578.81 instead of NaN.
```

## Reference Solution

`Homeworks/IHW2/size_from_design_point.m`, header comment trimmed.

```matlab
function [S_ref, b, c_bar, P_TO, P_engine, Vs_L_kts, s_LGR_check] = size_from_design_point(W_TO, WS_pt, WP_pt, obj, con_no_landing)
% First wing and engine size from the design point.

    % Wing
    S_ref = W_TO / WS_pt;
    b     = GeometryBase.compute_span(obj.aero.AR, S_ref);
    c_bar = S_ref / b;

    % Engine
    P_TO     = W_TO / WP_pt;
    P_engine = P_TO / obj.prop.n_engines;

    % Write the sized values back into the discipline models
    obj.geom.S_ref = S_ref;
    obj.prop.P_SL  = P_TO;

    % Landing check
    con     = get_con(con_no_landing, obj.cons);
    state   = get_state(con.alt);
    CLmax_L = obj.aero.get_CLmax(state, con);

    V_fps    = sqrt(2 * WS_pt * con.beta / (state.rho * CLmax_L));   % ft/s
    Vs_L_kts = ft_s2kts(V_fps);                                      % kt

    s_LGR_check = 0.265 * Vs_L_kts^2;                                % ft

end

%% Supporting Functions
function [kts] = ft_s2kts(ft_s)
    kts = ft_s*3600/6076.115;
end
```

## Learner Template

```matlab
function [S_ref, b, c_bar, P_TO, P_engine, Vs_L_kts, s_LGR_check] = size_from_design_point(W_TO, WS_pt, WP_pt, obj, con_no_landing)
% First wing and engine size from the design point.

% --- Milestone 1: wing geometry. AR comes from the aerodynamic model. ---
S_ref = ;
b     = GeometryBase.compute_span( , );
c_bar = ;

% --- Milestone 2: installed power, all engines, then per engine ---
P_TO     = ;
P_engine = ;

% --- Milestone 3: write the sized values back into the models ---
obj.geom.S_ref = ;
obj.prop.P_SL  = ;

% --- Milestone 4: close the loop on the landing requirement ---
con     = ;
state   = ;
CLmax_L = ;

V_fps       = ;
Vs_L_kts    = ;
s_LGR_check = ;

end

%% Supporting Functions -- given, do not change
function [kts] = ft_s2kts(ft_s)
    kts = ft_s*3600/6076.115;
end
```

## Code to call your function

```matlab
obj = ttpa_disciplines();
[S_ref, b, c_bar, P_TO, P_engine, Vs_L_kts, s_LGR_check] = ...
    size_from_design_point(5354, 40, 9.25, obj, 2)
```

## Tests — Weighted

**Test 1 · Wing geometry and power · weight 2**
```matlab
obj = ttpa_disciplines();
[S_ref, b, c_bar, P_TO, P_engine] = size_from_design_point(5354, 40, 9.25, obj, 2);
assert(abs(S_ref - 133.8500) <= 1e-3*133.8500, 'S_ref is wrong');
assert(abs(b - 32.723081) <= 1e-3*32.723081, 'b is wrong');
assert(abs(c_bar - 4.090385) <= 1e-3*4.090385, 'c_bar is wrong');
assert(abs(P_TO - 578.810811) <= 1e-3*578.810811, 'P_TO is wrong');
assert(abs(P_engine - 289.405405) <= 1e-3*289.405405, 'P_engine is wrong');
```
*Feedback:* `S_ref = W_TO/(W/S)` and `P_TO = W_TO/(W/P)` — divide, do not multiply. The
span follows from `AR = b^2/S`, and the power per engine from `obj.prop.n_engines`.

**Test 2 · The landing check and the write-back · weight 2**
```matlab
obj = ttpa_disciplines();
[S_ref, ~, ~, P_TO, ~, Vs_L_kts, s_LGR_check] = size_from_design_point(5354, 40, 9.25, obj, 2);
assert(abs(Vs_L_kts - 72.361526) <= 1e-3*72.361526, 'Vs_L_kts is wrong');
assert(abs(s_LGR_check - 1387.590453) <= 1e-3*1387.590453, 's_LGR_check is wrong');
assert(s_LGR_check <= 1500, 'the sized airplane must still meet the 1500 ft landing requirement');
assert(abs(obj.geom.S_ref - S_ref) <= 1e-9, 'S_ref must be written into the geometry model');
assert(abs(obj.prop.P_SL - P_TO) <= 1e-9, 'P_TO must be written into the propulsion model');
```
*Feedback:* The stall speed must include `con.beta`, be worked in ft/s with `state.rho`,
then converted to knots by DIVIDING by 1.68781. Then assign the two sized values into
`obj.geom` and `obj.prop`.

**Test 3 · A different airplane · weight 2**
```matlab
obj = ttpa_disciplines();
obj.aero.AR            = 7;
obj.aero.CLmax_landing = 2.0;
obj.cons(2).beta       = 0.96;
[S_ref, b, ~, P_TO, P_engine, ~, s_LGR_check] = size_from_design_point(4800, 35, 11, obj, 2);
assert(abs(S_ref - 137.142857) <= 1e-3*137.142857, 'S_ref is wrong for a different weight and wing loading');
assert(abs(b - 30.983867) <= 1e-3*30.983867, 'b must follow the aspect ratio of the model');
assert(abs(P_TO - 436.363636) <= 1e-3*436.363636, 'P_TO is wrong');
assert(abs(P_engine - 218.181818) <= 1e-3*218.181818, 'P_engine is wrong');
assert(abs(s_LGR_check - 1315.008798) <= 1e-3*1315.008798, 's_LGR_check is wrong on unseen inputs');
```
*Feedback:* Every argument and every model value must appear in the answer — do not
hardcode the aspect ratio, the engine count, `CLmax_L` or the landing weight ratio.

---
---

# Problem 12 — The matching diagram (submitted deliverable)

**Type** File upload, graded by the instructor · **Not a MATLAB Grader problem**
**Submit** one PDF (or one image plus a text box) containing your matching diagram and a
short written answer.

This is the only part of IHW2 that is not auto-graded. Everything you need you have
already written: this problem asks you to put it together, produce the one figure the
whole assignment has been building toward, and say in your own words why the airplane is
designed to the point it is designed to.

## Part 1 — The matching diagram

Run your `plot_matching_diagram` over the wing-loading sweep the requirements file gives
(`constraints.wing_loading_range_psf`, 15 to 50 lbf/ft^2). The driver script
`run_ttpa_constraint_analysis.m` already does every step in order; if your twelve
functions are correct, it produces the figure with no editing.

**Your figure must show all seven of these.** This is the grading checklist.

| # | Item | What it looks like |
| :---: | --- | --- |
| 1 | Takeoff ground roll | curve, falls with W/S |
| 2 | Climb AEO | curve, falls with W/S |
| 3 | Climb OEI | curve, falls with W/S |
| 4 | Climb BL | curve, falls with W/S |
| 5 | Cruise speed | straight line through the origin, **rises** with W/S |
| 6 | Landing ground roll | **vertical** dashed line, not a curve |
| 7 | Feasible region | shaded: below all five curves AND left of the vertical line |

**Plus two marked points**, clearly distinguishable from each other:

* the **best point** — the corner of the feasible region, the smallest engine the
  requirements permit, which your `matching_envelope` returns as `(WS_best, WP_best)`;
* the **design point** — `(40, 9.25)` lbf/ft^2 and lbf/hp, which the requirements file
  gives in `constraints.design_point`.

**And the presentation:** both axes labelled with the quantity **and its unit**, a legend
that names every condition, and a title. A design-review audience has to be able to read
the figure with no help from you. That is the entire purpose of a matching diagram: it
puts on one page which requirement is expensive and how much room the design has left.

### Check your figure before you submit

If your numbers are right, the figure shows:

```
landing wall (the vertical line)      43.24 lbf/ft^2
best point                            W/S = 37.4 lbf/ft^2 , W/P = 10.51 lbf/hp
design point                          W/S = 40.0 lbf/ft^2 , W/P =  9.25 lbf/hp

the five ceilings at W/S = 40 :  Takeoff 9.83 | Climb AEO 14.25 | Climb OEI 10.68
                                 Climb BL 17.76 | Cruise Speed 11.24   lbf/hp
```

Two shapes worth checking by eye. The upper boundary of the shaded region **bends over**
at W/S = 37.4: to the left of it the rising cruise line is the binding limit, to the right
the falling takeoff curve is. And the design point sits **inside** the shaded region,
below the takeoff curve and left of the landing wall — not on the boundary.

Export at a readable resolution, for example

```matlab
exportgraphics(fig, 'ttpa_matching_diagram.png', 'Resolution', 200)
```

## Part 2 — Short answer

**In 150 to 250 words:** the analysis found a best point at (37.4, 10.51), yet the
airplane is designed to (40, 9.25). Why would a designer deliberately choose a point that
is not the optimum?

Use your own numbers from Problems 10 and 11 to support the argument. A complete answer
addresses all three of these:

1. **What is different about the two points.** What are the margins at each one, and what
   does a margin of zero mean physically? Which constraints is the best point sitting on?
2. **What the margin protects against.** Name at least one specific thing that could
   change between now and a finished airplane, and say what it would do to a design that
   had no margin.
3. **What the margin costs.** Compare the wing area and the installed power at the two
   points, and state the trade in numbers, not adjectives.

Do not just assert that margin is good practice. Show it with the numbers your own code
produced.

## Instructor notes — reference answer and rubric

**Reference figure:** `IHW2_reference_matching_diagram.png` in this folder.

**Reference numbers for Part 2**, from the reference solution at `W_TO = 5354` lbf:

| | Best point | Design point |
| --- | :---: | :---: |
| W/S, lbf/ft^2 | 37.37 | 40.00 |
| W/P, lbf/hp | 10.51 | 9.25 |
| power margin | **0.0000** | +0.0591 |
| wing-loading margin | +0.1357 | +0.0749 |
| binding condition | Takeoff and Cruise Speed, simultaneously | Takeoff |
| wing area, ft^2 | 143.3 | 133.8 |
| installed power, hp | 509.7 | 578.8 |
| power per engine, hp | 254.8 | 289.4 |

So the design point buys its margin for **13.6 % more engine**, and gets a **6.6 % smaller
wing** in return. Points a strong answer may raise:

* The best point is the intersection of two constraint curves, so it satisfies takeoff and
  cruise speed with **exactly zero** to spare. Any adverse change makes it infeasible, not
  marginal — it is on the boundary in two directions at once.
* Preliminary weight estimates grow. `W_TO` rising in detailed design moves the required
  wing area and power up; with no margin the airplane no longer meets its field length.
* `CD0`, `CLmax` and propeller efficiency are all preliminary estimates here, several of
  them mid-range values taken from a table. A 5 % error in `CLmax_TO` moves the takeoff
  curve directly.
* Engines come in discrete sizes. 509.7 hp total is 254.8 hp per engine, which is not a
  catalogue engine; a designer picks a real one and lives with the rounding.
* Moving right to a higher W/S gives a smaller, lighter, cheaper wing — but moves toward
  the landing wall at 43.24, so the wing-loading margin falls from 13.6 % to 7.5 %. The
  design point trades some of one margin for the other, which is a choice, not an oversight.
* A student who observes that the three climb curves never touch the envelope, so climb is
  not driving this airplane at all, has read the diagram properly. Give credit.

**Suggested rubric — 100 points, scale as you wish**

| | Points |
| --- | :---: |
| Five power curves present and correctly shaped (cruise rises, the other four fall) | 20 |
| Landing drawn as a vertical wall, at 43.2 lbf/ft^2 | 10 |
| Feasible region shaded, bounded by the envelope AND stopping at the wall | 15 |
| Both points marked and distinguishable, at (37.4, 10.51) and (40, 9.25) | 15 |
| Axis labels with units, legend naming each condition, title | 10 |
| Short answer: contrasts the two points and explains a zero margin | 10 |
| Short answer: names a specific risk the margin protects against | 10 |
| Short answer: quantifies the cost of the margin | 10 |

Common failures to look for: the landing constraint drawn as a sloping curve rather than a
vertical line; shading that continues past the wall; only one point marked; the design
point plotted on the envelope rather than inside the feasible region; a legend that says
"Condition 1 … Condition 6" instead of the condition names.

---
---
# The capstone script

Problems 1 to 12 are the parts. `TtpaConstraintAnalysis.m` is the whole, and it is worth
walking the class through it after the deadline. It is the constraint twin of
`TtpaSizing.m` and runs in this order:

1. `ttpa_disciplines` builds the bundle
2. `missionAnalysis` — the IHW1 code, unchanged — gives the takeoff gross weight
3. the wing-loading sweep comes from the requirements file
4. `run_constraints`, then `matching_envelope`
5. `design_point_check` on the best point AND on the selected design point
6. `size_from_design_point` at the selected point, writing `S_ref` and `P_SL` back into
   the models
7. `plot_matching_diagram` with both points marked

For the TTPA it prints `W_TO = 5353.9` lbf, a landing wall at 43.24 lbf/ft^2, a best point
at (37.40, 10.51), the selected design point (40, 9.25) with margins of 5.9 % on power and
7.5 % on wing loading, and a first size of 133.8 ft^2 of wing, 32.7 ft of span and 578.8 hp
total, 289.4 hp per engine.

Ask the class why the selected point is not the best point. The best point sits exactly on
two constraints at once and has no margin at all; the selected point pays 14 % more engine
for room to grow.

---
---

# Verification checklist

For each problem: Validate the reference solution, preview it as a learner, then **break
it on purpose** and confirm the *right* test fails. Step 3 is the one people skip and the
one that matters.

| Problem | Validate | Deliberate error | Expected |
| :---: | :---: | --- | --- |
| 1 | 4/4 | `cfg.CL_climb = cfg.CLmax` (drop the margin) | T1, T2, T4 pass, T3 fails |
| 2 | 4/4 | drop the `/ n_engines` in `power_ratio` | T1, T2, T4 pass, T3 fails |
| 3 | 3/3 | `con.beta = cons(con_no).beta;` (no default) | T1, T2 pass, T3 fails |
| 4 | 4/4 | `.* WS` instead of `./ WS` | T1 passes, T2–T4 fail |
| 5 | 4/4 | multiply by `con.beta` instead of dividing | T1, T2 pass, T3, T4 fail |
| 6 | 5/5 | `con.beta` instead of `con.beta^1.5` | T1–T3 pass, T4, T5 fail |
| 7 | 3/3 | `WP_max = slope ./ WS` | T1 passes, T2, T3 fail |
| 8 | 4/4 | pre-allocate with `zeros` instead of `NaN` | T1 passes, T2 fails |
| 9 | 5/5 | skip the wall when searching for the best point | T1–T4 pass, T5 fails |
| 10 | 3/3 | `feasible = WP_pt <= WP_limit` only | T1, T2 pass, T3 fails |
| 11 | 3/3 | multiply by 1.68781 instead of dividing | T1 passes, T2 fails |
| 12 | — | not auto-graded; check a submission against the reference figure and rubric on the card |

Rows 6, 9 and 10 are the important ones: each is the only test in its problem that
separates a right answer from a plausible wrong one.

# Weight summary

| Problem | Topic | Tests | Weights | Total |
| :---: | --- | :---: | --- | :---: |
| 1 | Aerodynamic model updates | 4 | 4, 3, 4, 1 | 12 |
| 2 | Propulsion model updates | 4 | 3, 4, 3, 2 | 12 |
| 3 | The constraint condition | 3 | 2, 2, 2 | 6 |
| 4 | Takeoff ground roll | 4 | 3, 2, 2, 2 | 9 |
| 5 | Landing ground roll | 4 | 2, 2, 3, 2 | 9 |
| 6 | Climb gradient | 5 | 4, 3, 3, 2, 2 | 14 |
| 7 | Cruise speed | 3 | 3, 2, 2 | 7 |
| 8 | Run every condition | 4 | 3, 2, 2, 1 | 8 |
| 9 | Matching envelope | 5 | 2, 3, 2, 2, 2 | 11 |
| 10 | Design point check | 3 | 2, 2, 2 | 6 |
| 11 | First sizing | 3 | 2, 2, 2 | 6 |
| 12 | Matching diagram (uploaded) | — | graded by rubric | separate |
| | **Total, Problems 1-11** | **42** | | **100** |
