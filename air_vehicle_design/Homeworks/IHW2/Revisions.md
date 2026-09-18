# IHW2 — Revisions from TA review (Quinn McIver)

Snippets to paste into the Grader problems. Each item names the comment, says where it
goes, and gives the exact text or code. Nothing else in the assignment changes.

**Six items are code changes** to the reference solution and the attached files, not just
wording: A4, A5, P3, P6, P7, T3. All six were applied to a scratch copy and verified:

* all 42 tests of the eleven auto-graded problems still pass with only their declared
  attachments;
* every output is **bit-identical to 15 significant figures** — `TOP23`, the six
  constraint rows, the wall, the envelope, the best point, the configuration polar and
  the power ratio all unchanged.

So these can be adopted without re-deriving a single expected value.

Two items I could not reproduce or would not do as asked — **A3** and **P3** — are marked
and explained.

---

## Assignment-level (paste into every problem, or into the assignment description)

### A7 · Troubleshoot in MATLAB, not in Grader

> **Debug in MATLAB, not in Grader.** Grader tells you a test failed; it does not show you
> the error that caused it. Download the assignment files, put them in one folder, set that
> folder as your MATLAB Current Folder, and run your function there. You will get the real
> error message, the line number, and the ability to stop on the line and inspect
> variables. Submit to Grader only once it runs locally.

### T1 · Standard header for every problem card

Quinn asked whether Problem 4 was missing its Canvas instructions. Give every card the
same three-line header so none of them looks different from the others:

> **You write** `constraint_takeoff.m`. **Already on the path, do not write these:**
> `ttpa_disciplines`, `get_state`, `get_con`, your `TtpaAero` and `TtpaProp`, and the
> framework readers. **Condition number:** the takeoff condition is number **1** in
> `Ttpa_requirements_IHW2.json`.

Change the file name, the list and the condition number per problem. *Confirm with Quinn
that this is what he meant by "no canvas instructions" — it may instead be that the Canvas
assignment page has no per-problem text, which is a Canvas edit rather than a card edit.*

### Late TA question · `ttpa_disciplines` in the test cases

> `ttpa_disciplines.m` is a **given** file, not something students write. It is attached to
> every Grader problem as an invisible Assessment file and is included in the student
> download. That is why the test cases can call it.

No change needed — this was a question, not a defect.

---

## Problem 1 — Aerodynamics

### A1 · Step 3 reads as if the base properties are ignored

Replace the opening of Step 3 with:

> **Step 3 — `get_config_polar(state, con)`.** This does not build a new polar from
> nothing. It **starts from the clean polar this class already has** — the `CD0` you just
> read and the `e` computed from `AR` — and adds the increments of the configuration on
> top. Nothing about the clean airplane changes; you are describing the same airplane with
> its flaps and gear in a different position.

### A2 · Remind them what `e` is

Wherever `e` first appears in the card, write it out:

> `e`, the **Oswald efficiency factor**, is computed from the aspect ratio by the
> `get.e` method you already have from IHW1. The flap increments shift it; extending the
> landing gear does not.

### A3 · `de_flaps_takeoff` / `de_flaps_landing` "listed twice" — could not reproduce

In the current template each appears **once** in the properties block. It also appears once
in the constructor, which is normal MATLAB: a property is *declared* in the properties
block and *assigned* in the constructor. If that is what looked like a duplicate, add this
note to the card and change nothing else:

> Each property appears twice in a class, and that is correct: once in the `properties`
> block where it is declared, and once in the constructor where it is given its value from
> the JSON.

*Ask Quinn to point at the line numbers if he meant something else — I cannot find a real
duplicate.*

### A4 · `drag_polar` and `get_config_polar` should be linked — **agreed, code change**

They should be linked, and the clean way is for the configuration polar to *call* the clean
one instead of reaching for `obj.CD0` directly. Two lines, and it makes A1 true in the code
rather than only in the prose.

```matlab
        function cfg = get_config_polar(obj, state, con)

            % Start from the CLEAN polar this class already provides, then
            % add the high-lift increments of this configuration.
            polar = obj.drag_polar(state);

            switch string(con.config)
                ...
            end

            cfg.config = string(con.config);
            cfg.CD0    = polar.CD0 + dCD0;      % <- was obj.CD0 + dCD0
            cfg.e      = obj.e + de;
            cfg.K1     = 1 / (pi * obj.AR * cfg.e);
            cfg.K2     = polar.K2;              % <- was 0
```

What deliberately stays separate: `drag_polar` remains the clean polar because it is the
`AerodynamicsBase` method the **mission analysis** calls through `LD_max`, and the mission
is always flown clean. `get_config_polar` is the constraint-analysis method. One is the
clean airplane, the other is the airplane in a named configuration; linking them by having
the second call the first is the right amount of coupling.

Add to the card:

> `cfg.CD0` starts from `obj.drag_polar(state).CD0`, so the clean polar is the single
> source of the clean value. If you later change `CD0`, every configuration follows.

### A5 · `dCD0 = 0` and `de = 0` belong under `clean` — **agreed, code change**

Also removes the empty `case "clean"` body, which currently looks like an oversight.

```matlab
            switch string(con.config)

                case "clean"
                    dCD0 = 0;          % <- moved here from above the switch
                    de   = 0;

                case "takeoff_flaps_gear_up"
                    dCD0 = obj.dCD0_flaps_takeoff;
                    de   = obj.de_flaps_takeoff;
                ...
```

Delete the two initialisations that sat above the `switch`. Every branch now assigns both,
and the `otherwise` branch errors, so no path leaves them undefined. Update the template
the same way, replacing `dCD0 = 0; de = 0;` above the switch with a `case "clean"` the
student fills in.

### A6 · `CD0` follows a different naming convention

Already addressed by the key-to-property table now on the card (`CD0_clean` → `CD0`,
`delta_CD0_*` → `dCD0_*`, `BSFC_lb_per_hp_hr` → `BSFC`). **Two reviewers have now
independently flagged this**, which is evidence the mapping itself is the problem, not the
documentation of it. If you want it gone rather than documented:

| Rename in `Ttpa_requirements_IHW2.json` | To | Touches |
| --- | --- | --- |
| `CD0_clean` | `CD0` | JSON, `TtpaAero` constructor, card table, template comment |
| `BSFC_lb_per_hp_hr` | `BSFC` | JSON, `TtpaProp` constructor, card table, template comment |

Then key and property are identical everywhere and the table can be deleted. Cost: the JSON
loses the `_clean` qualifier that distinguishes it from the five configuration `CD0`s, and
loses the unit on BSFC. **My recommendation: do the rename.** Two reviewers tripping on it
outweighs the descriptive key names, and no test reads the JSON keys.

---

## Problem 2 — Propulsion

### P1 · Define AEO, OEI and BL

Add to the top of the card, and to the assignment description:

> **Three climb cases, three abbreviations used throughout this assignment:**
> **AEO** — all engines operating. Both engines running, gear up, takeoff flaps, maximum
> continuous power.
> **OEI** — one engine inoperative. One engine has failed and its propeller has stopped;
> the live engine is at takeoff power, at 5,000 ft.
> **BL** — balked landing. A landing that is abandoned and turned into a climb: gear down,
> landing flaps, both engines at takeoff power.

### P2 · What is sigma, and where does it come from

Add before Step 2:

> **`sigma` is the density ratio**, the air density at the condition divided by the density
> at sea level: `sigma = rho / rho_sealevel`. It is 1.0 at sea level and falls with
> altitude, which is why an engine loses power as it climbs.
>
> You do not compute it. `get_state(alt_ft)` is **given** to you and returns
>
> ```
> state.alt     altitude [ft]
> state.rho     density [slug/ft^3]
> state.sigma   density ratio [-]
> ```
>
> so `state.sigma` is what you use here. Its values for this airplane are 1.0000 at sea
> level, 0.8617 at 5,000 ft and 0.7860 at 8,000 ft. `get_state` is the `state` argument
> your IHW1 `prop_eff` already accepted but never used — IHW2 finally fills it in.

### P3 · Introduce `rating_factor` before it is used — **partly agreed**

His instinct is right: the student meets `obj.rating_factor(rating)` inside `power_lapse`
before seeing what it is. But moving it "first in the code" cannot be done by relocating it
inside the public `methods` block — a `methods (Access = private)` block nested inside
`methods` is a **parse error**. I tried it; every test in every problem failed with a
syntax error.

Two legal options:

**Option 1, recommended — fix the reading order in the card, not the file.** Renumber the
steps so `rating_factor` is introduced first:

> **Step 2 — `rating_factor(rating)`.** A small private helper. It answers "how much of
> the takeoff power does this rating give me?" and it is the only place the
> `P_TO_over_P_max_continuous` number is used:
>
> ```
> "takeoff"         -> 1
> "max_continuous"  -> 1 / P_TO_over_P_max_continuous
> anything else     -> error
> ```
>
> **Step 3 — `power_lapse(state, rating)`.** Now use it.

**Option 2, if you want the file order changed too.** Move the whole
`methods (Access = private)` block to class level, between the `properties` block and the
public `methods` block. This is legal and verified — all 42 tests pass. The reading order
becomes properties → `rating_factor` → constructor → `power_lapse`, which puts a private
helper ahead of the constructor; that is the trade.

### P4 · No information on `eta_p` for the climb gradient

Add to Step 4 (`prop_eff`):

> The climb value is **`eta_p_climb` = 0.80**, read from
> `J.propulsion.eta_p_climb`. The mission analysis never needed it, because IHW1 modelled
> climb with a fixed weight fraction; the climb-gradient constraint does need it. A
> constraint condition and a mission segment both carry a `type` field, so the same method
> serves both: a climb condition arrives with `type = "climb_gradient"` and must return the
> climb value.

### P5 · What is `rating`

Add to Step 2 (or Step 3 under Option 1 above):

> **`rating` is a string argument** naming the engine power setting, and it takes exactly
> two values in this assignment:
>
> * `"takeoff"` — full rated power, what the engine gives for the few minutes of a takeoff
>   or a go-around;
> * `"max_continuous"` — the highest power the engine may hold indefinitely, which is
>   **lower** than takeoff power by the factor `P_TO_over_P_max_continuous` = 1.1.
>
> Your `power_ratio` chooses between them from `con.max_continuous`; `power_lapse` receives
> whichever one was chosen. Error on any other string.

### P6 · `kP` defined three times — **agreed, code change**

Rewrite as one assignment of `kP` built from named factors, which also matches the way the
card already describes it ("three factors multiply"):

```matlab
            if con.max_continuous
                rating = "max_continuous";
            else
                rating = "takeoff";
            end

            % one engine of n_engines when the engine-out flag is set
            f_oei = 1;
            if con.oei
                f_oei = 1 / obj.n_engines;
            end

            kP = obj.power_lapse(state, rating) * f_oei * con.power_setting;
```

Update the template to match: leave `f_oei` and the final `kP` line as the blanks.

### P7 · Break `alpha` into its components — **agreed, code change**

```matlab
        function alpha = power_lapse(obj, state, rating)

            % altitude term: normally aspirated piston engine
            % [Nicolai & Carichner, Fundamentals of Aircraft and Airship
            %  Design, Vol. I, Eq. 14.5]
            alpha_altitude = 1.132 * state.sigma - 0.132;

            % rating term: full takeoff power, or the max-continuous derate
            f_rating = obj.rating_factor(rating);

            alpha = alpha_altitude * f_rating;

        end
```

Add to the card:

> Two separate effects, multiplied. The **altitude** term is physics: thinner air, less
> mass flow, less power. The **rating** term is a limit the manufacturer sets: the same
> engine at the same altitude is allowed more power for a takeoff than it is allowed to
> hold continuously. Compute them on separate lines so you can check each one.

---

## Problem 3 — `get_con`

### G1 · Reiterate that this pulls from the requirements JSON

Add as the opening line of the card:

> Everything this function returns comes out of the `constraints.conditions` block of
> `Ttpa_requirements_IHW2.json`. `ConstraintSetImporter.read_conditions` has already read
> that block into `obj.cons`, a 1×6 struct array in file order; `cons(con_no)` is the raw
> JSON object for one condition, and your job is to turn it into a tidy struct with every
> field the constraint functions need. **No number is invented here and none is computed —
> this function only reads, renames and supplies defaults.**

### G2 · Say which variables use `get_field`

Replace the two-category prose with an explicit table:

> | Field of `con` | How to read it | If the JSON does not give it |
> | --- | --- | --- |
> | `name`, `type`, `alt` | direct, every condition has them | — |
> | `distance_ft` | direct | stays empty, `[]` |
> | `G` | direct | stays empty, `[]` |
> | `ktas` | direct | stays empty, `[]` |
> | `power_index` | direct | stays empty, `[]` |
> | `config` | **`get_field`** | `"clean"` |
> | `beta` | **`get_field`** | `1.0` |
> | `power_setting` | **`get_field`** | `1.0` |
> | `oei` | **`get_field`**, wrap in `logical()` | `false` |
> | `propeller_stopped` | **`get_field`**, wrap in `logical()` | `false` |
> | `max_continuous` | **`get_field`**, wrap in `logical()` | `false` |
>
> Six fields use `get_field` and four do not. The rule: a field that **every** constraint
> reads must always have a value, so it needs a default. A field that only one constraint
> reads may stay empty, because the function that needs it knows it is there — exactly as
> `get_miss_seg` leaves `ktas` empty for a takeoff segment.

---

## Problem 4 — Takeoff ground roll

### T2 · Reword the row-vector sentence

Replace:

> ~~The function must accept a row vector of wing loadings and return `WP_max` of the same
> size, so divide with `./` and not with `/`.~~

with:

> `WS` may arrive as a single wing loading or as a whole row of them, and `WP_max` must come
> back the same size — one power-loading limit for each wing loading you were given. In
> MATLAB that means the final division has to be **element-by-element**: write `./` rather
> than `/`. A plain `/` is matrix right-division and will quietly collapse your row of
> answers into one number.

### T3 · Use `roots`, and drop `a`, `b`, `c` — **agreed, code change**

Both parts of his comment are right: `a`, `b`, `c` collide with the way Roskam and Raymer
use those letters for other things, and `roots` is clearer than a hand-written quadratic
formula.

```matlab
    % S_TGR = 4.9 TOP23 + 0.009 TOP23^2, written as a polynomial in TOP23:
    %   0.009 TOP23^2 + 4.9 TOP23 - S_TGR = 0
    poly_TOP = [0.009, 4.9, -con.distance_ft];

    % Two roots; the physical one is positive, so take the larger
    TOP23 = max(roots(poly_TOP));
```

Verified: `TOP23 = 218.462610372256`, identical to the quadratic formula to every digit.
Card wording:

> **Step 2 — solve for `TOP23`.** The ground-roll relation is a quadratic in `TOP23`.
> Write it as a polynomial with the highest power first, `0.009 TOP23^2 + 4.9 TOP23 -
> S_TGR = 0`, hand the coefficient vector to MATLAB's `roots`, and keep the positive root —
> the negative one has no physical meaning. Do not name your coefficients `a`, `b` and `c`:
> those letters already mean other things in Roskam and Raymer.

Update the template blank from the three `a`/`b`/`c` lines to:

```matlab
% --- Milestone 2: solve the quadratic for TOP23, keep the positive root ---
poly_TOP = ;

TOP23 = ;
```

---

## Problem 6 — Climb gradient

### C1 · Connect `CGR` to `G` in the JSON

Add immediately after the two CGRP equations:

> **`CGR` is the required climb gradient, and in the code it is `con.G`.** The requirements
> file names it `G`, `get_con` passes it through unchanged, and the equations above call it
> `CGR` because that is what Roskam calls it. Same number, three names:
>
> ```
> Ttpa_requirements_IHW2.json    "G": 0.083
> get_con                        con.G
> Roskam Part I, Sec. 3.3        CGR
> ```
>
> It is a **fraction, not a percentage**: 0.083 means 8.3 %.

---

## Adoption checklist

| Item | Kind | Files to change |
| :---: | --- | --- |
| A1, A2 | wording | Problem 1 description |
| A3 | wording, optional | Problem 1 description |
| **A4** | **code** | `TtpaAero.m` (reference + attachment + starter), Problem 1 card |
| **A5** | **code** | `TtpaAero.m` (reference + attachment + starter + template) |
| A6 | decision | optional JSON rename, then `TtpaAero.m`, `TtpaProp.m`, both cards |
| A7 | wording | assignment description, every card |
| P1, P2, P4, P5 | wording | Problem 2 description |
| **P3** | wording, or code | Problem 2 card (Option 1) or `TtpaProp.m` (Option 2) |
| **P6, P7** | **code** | `TtpaProp.m` (reference + attachment + starter + template) |
| G1, G2 | wording | Problem 3 description |
| T1 | wording | every card |
| T2 | wording | Problem 4 description |
| **T3** | **code** | `constraint_takeoff.m` (reference + attachment + starter + template) |
| C1 | wording | Problem 6 description |

**No test case changes anywhere.** Every expected value on every card stays as it is.

A patched copy of the three affected `.m` files, already verified, is at
`C:\Users\krish\AppData\Local\Temp\claude\rev\` — `TtpaAero.m`, `TtpaProp.m` and
`constraint_takeoff.m`. Say the word and I will apply them to the IHW2 folder and the
starter pack, and fold the wording into the cards.
