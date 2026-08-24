# Chapter 2 — Step-By-Step Guide to Configuration Design

**Source:** Roskam, *Airplane Design, Part II: Preliminary Configuration Design and Integration of the Propulsion System* (DARcorporation), Chapter 2 "Step-By-Step Guide to Configuration Design," printed pp. 7–24.

This chapter is the master design procedure of Part II. It divides preliminary configuration
design into two sequences: p.d. sequence I (Steps 1–16, Class I methods) and p.d. sequence II
(Steps 17–36, Class II methods). Later chapters of the book refer back to these step numbers.
All 36 steps are given below in order, with the chapter or Part that each step points to.
The chapter has no numbered equations and no data tables. It has one numbered figure
(Fig. 2.1, the process flow chart) and one unnumbered courtesy drawing (DASH 8, p. 24).

---

## 2.0 Introduction (p. 7)

Figure 2.1 divides the preliminary design (p.d.) process into two parts:

1. Preliminary sizing
2. Preliminary configuration layout and integration of the propulsion system

The chapter assumes that preliminary sizing is complete. Part I (Ref. 1) gives that method.
Preliminary sizing starts from a mission specification. Part I Tables 2.17 through 2.19 give
example mission specifications.

**Data available from Part I preliminary sizing, used as the input to configuration design
(p. 7):**

| Quantity | Symbol |
|---|---|
| Take-off weight | W_TO |
| Operating weight empty | W_E |
| Payload weight | W_PL |
| Mission fuel weight | W_F |
| Wing area | S |
| Wing aspect ratio | A |
| Take-off power **or** take-off thrust | P_TO or T_TO |
| Required maximum lift coefficient, clean | C_L_max |
| Required maximum lift coefficient, take-off | C_L_max_TO |
| Required maximum lift coefficient, landing | C_L_max_L |

These are the "input" data for the configuration design process. The process covers overall
layout design and propulsion system integration.

### The two p.d. sequences (p. 9)

**Preliminary Design Sequence I.** The objective is a decision about the feasibility of a
certain configuration, *with a minimum amount of engineering work*. Its methods are
preliminary: the **Class I** methods. Chapters 3–13 of this book concentrate on Class I
methods. Section 2.1 gives the work as Steps 1–16. After these steps, the designer must be
able to tell if the proposed configuration is workable. If it is, go on to sequence II.

**Preliminary Design Sequence II.** The objective is a realistic, reasonably detailed layout
of the configuration. Sequence I already decided its feasibility. Sequence II fine-tunes the
configuration, that is, it finds out if the configuration meets all the requirements of the
mission specification. Its methods are the **Class II** methods. They need much more
engineering time, but they are more accurate. Parts III–VIII (Refs. 2–7) concentrate on Class
II methods. Section 2.2 gives the work as Steps 17–36.

The end result of sequence II is sometimes called a **point design** or **baseline design**
(p. 10). Compare the point design with competing concepts. More study can be necessary, in
particular optimization of the point design against cost criteria. Typical cost criteria are
(L/D), (nm/lbs), fuel burn per seat mile, DOC, ROI and LCC. Part VIII (Ref. 7) gives the cost
and optimization methods.

Sequence II needs much work. For that reason a team usually does it. Such a team can have
3 to 15 engineers, depending on the complexity of the airplane (p. 18).

### Reference-number to Part mapping used in this chapter

The step text cites Parts by a reference number. The mapping, as used consistently in the
step text, is:

| Ref. | Part |
|---|---|
| 1 | Part I — Preliminary Sizing |
| 2 | Part III — Layout Design of Cockpit, Fuselage, Wing and Empennage |
| 3 | Part V — Component Weight Estimation |
| 4 | Part IV — Layout Design of Landing Gear and Systems |
| 5 | Part VI — Aerodynamic, Thrust and Power Characteristics |
| 6 | Part VII — Stability, Control and Performance |
| 7 | Part VIII — Cost Estimation |
| 8 | Jane's All the World Aircraft |

### Advice to students (p. 10)

1. First-semester design students must follow the guide of Sections 2.1 and 2.2 as closely as
   possible. Students who do not lose much calendar time.
2. Steps 1–36 need a large number of engineering calculations. Record them in a professional
   manner, so that other people can follow them. All engineering calculations must be:
   - a) neatly and logically organized by subject, with a table of contents
   - b) dated, with the name of the originator on each page
   - c) cross-referenced throughout, so that the source of each input number is obvious
   - d) written with all assumptions carefully stated and identified as such
   - e) page numbered
3. Do not carry more significant figures than the accuracy of the methods gives. In preliminary
   design, more than three significant figures is generally not justified. Round off all
   computer output accordingly.

---

## Figure 2.1 — The Preliminary Design Process as Covered in Parts I Through VIII of Airplane Design
*[Roskam Part II, Fig. 2.1, p. 8]*

Flow chart. No plotted data. Structure of the chart, box by box:

```
                      Mission Specification
                               |
                               v
PART I    +--------------------------------+      +---------------------------+
          | Preliminary Sizing             |----->| Sensitivity Studies       |
          |   W_TO   T_TO   A              |      |  * Definition of R and D  |
          |   W_E    W_F    C_L_max        |<-----|    Needs                  |
          |   W_PL   S      (clean, TO, L) |      |  * Refinement of          |
          +--------------------------------+      |    Preliminary Sizing     |
                               |                  +---------------------------+
                               v
PART II   +--------------------------------+      +---------------------------+
          | Preliminary Configuration      |      | * Initial Layout of Wing  |
          | Layout and Propulsion System   |      |   and Fuselage            |
          | Integration                    |      | * Class I: Tail Sizing,   |
          +--------------------------------+      |   Weight and Balance,     |
                               |                  |   Drag Polar              |
              P.D. SEQUENCE I, STEPS 1-16         | * Initial Landing Gear    |
                               v                  |   Disposition             |
          +--------------------------------+      | (PARTS III, IV, V and VI) |
          | Configuration Candidates       |----->+---------------------------+
          | Identified and One or More     |                    |
          | Selected for Further Study     |<---+               v
          +--------------------------------+    |  +---------------------------+
                               |                +--| Sizing Iteration and      |
                               |                   | Reconfiguration           |
                               v                   +---------------------------+
          +--------------------------------+      +---------------------------+
          | Refinement of Preliminary      |<---->| * Layout of Wing,         |
          | Configuration                  |      |   Fuselage and Empennage  |
          +--------------------------------+      | * Class II: Weight,       |
                               |                  |   Balance, Drag Polars,   |
             P.D. SEQUENCE II, STEPS 17-36        |   Flap Effects, Stability |
                               v                  |   and Control            |
          +--------------------------------+      | * Performance Verification|
          | Preliminary Configuration      |      | * Preliminary Structural  |
          | Design Finished                |      |   Layout                  |
          +--------------------------------+      | * Landing Gear Disposition|
                                                  |   and Retraction Check    |
                                                  | * Cost Calculations       |
                                                  | (PARTS II through VIII)   |
                                                  +---------------------------+
```

The chart shows two feedback loops: Sensitivity Studies feeds back into Preliminary Sizing,
and Sizing Iteration and Reconfiguration feeds back into the Configuration Candidates box.

---

## 2.1 Preliminary Design Sequence I (Steps 1–16, pp. 11–18)

### Step 1 (p. 11)
**Carefully review the mission specification and prepare a list of those items which have a
major impact on the design.**

Examples of items which can have a major impact:
- a) very short and soft field requirements
- b) hot and high field requirements
- c) water based or amphibious requirements
- d) requirements for carrying large vehicles
- e) requirements for extreme range or endurance
- f) requirements for large search radars

Make it a habit to review the mission specification at each step of both p.d. sequences. If you
do not, the design will be only partly responsive to the mission specification.

### Step 2 (p. 11)
**Perform a comparative study of airplanes with similar mission performance.**

Use one or more issues of Ref. 8 (Jane's All the World Aircraft). Collect data on five to ten
similar airplanes. The results must include:
1. A discussion of major differences in mission capability and configuration.
2. A tabulated comparison of significant airplane sizing parameters and planform design
   parameters.
3. A critical discussion of the configurations of these airplanes, as seen from their
   threeviews in Ref. 8.

> THE OBJECTIVE IS: FAMILIARIZE YOURSELF WITH THE COMPETITION AND WITH WORK DONE BY OTHERS!

### Step 3 (pp. 11–12)
**Select the type of configuration to be designed.**

Points to **Chapter 3**: Section 3.1 discusses existing configurations for twelve categories of
airplanes; Section 3.2 discusses 'unusual' configurations; Section 3.3 gives an outline of
configuration possibilities; Section 3.4 gives a step-by-step procedure for selecting a
configuration.

Keep the required characteristics of the propulsion system, and its disposition, in mind while
you select a configuration type. Step 5 covers the propulsion system in detail.

> For a student who is just getting started: MAKE A DECISION TO GO WITH A CERTAIN TYPE OF
> CONFIGURATION AND MOVE ON.

At this point many airframe manufacturers use the "red, white and blue team" approach:
different design teams each evolve and study a different configuration type, to find the most
suitable configuration for the mission task.

### Step 4 (p. 12)
**Prepare a preliminary (scaled) drawing of the fuselage and cockpit layout.**

Points to **Chapter 4** (step-by-step guide for fuselage and cockpit layouts).

### Step 5 (p. 12)
**Decide which type of propulsion system is to be used and how the propulsion system will be
arranged.**

This step has a major impact on the design. The engine type(s), the number of engines and the
overall engine arrangement affect the layout of the fuselage (sometimes the cockpit), the wing
and other components. The total required thrust or power level at take-off is already known
from the Part I preliminary sizing. Points to **Chapter 5**.

### Step 6 (pp. 12–13)
**Decide which wing planform design parameters are to be used. Also decide on the size and
location of wing mounted lateral controls.**

Wing area S and wing aspect ratio A are already known from Part I. The additional parameters
to select now are:

| Parameter | Symbol |
|---|---|
| Wing taper ratio | λ_w |
| Wing sweep angle | Λ_w |
| Wing thickness ratio | (t/c)_w |
| Wing airfoil(s) | — |
| Wing incidence angle | i_w |
| Wing dihedral angle | Γ_w |

If the mission needs a variable geometry wing (such as variable sweep), find the effect of this
on the planform also.

The required maximum lift coefficients (clean, take-off, landing) are also known from Part I.
The wing planform parameters must be compatible with those maximum lift coefficients. Step 7
shows that the maximum lift coefficient requirements can limit the available choice of wing
planform parameters. Points to **Chapter 6**.

### Step 7 (p. 13)
**Decide on the type, the size and the disposition of high lift devices.**

The required maximum lift coefficients, clean and flaps down, are already known from the Part I
preliminary sizing. Points to **Chapter 7**.

### Step 8 (p. 14)
**Decide on the layout of the empennage: size, planform geometry and disposition. Also select
the size and location of longitudinal and directional controls.**

"Empennage" here means tails, canards and other additional stabilizing or control surfaces.
From Step 3 the overall configuration is known: a) conventional (tail aft), b) flying wing
(no horizontal tail and no canard), c) tandem wing, d) canard, e) three surface, f) joined wing.

In each case, decide these empennage design parameters:
- Area and location
- Aspect ratio
- Taper ratio
- Sweep angle
- Thickness ratio
- Airfoil(s)
- Incidence angle
- Dihedral angle

Also select the preliminary size and disposition of the longitudinal and directional controls.
Points to **Chapter 8**.

### Step 9 (pp. 14–15)
**Decide which type of landing gear is to be used. Also: decide on the landing gear disposition
and determine the required number and size of tires.**

Answer these questions:
1. What type of landing gear is required?
2. How many and what size tires are required?
3. How are the landing gear wheels to be arranged?
4. Is the space designated for the retracted landing gear sufficient?
5. Does the landing gear retraction cause the gear to interfere with other airplane components
   or airplane structure?
6. Do the landing gear attachment points require major additional structural provisions?

> **WARNING:** Students must not underestimate the importance of preliminary landing gear
> design. The answers to questions 1–6 can decide the ultimate feasibility of the proposed
> configuration.

Questions 4 and 5 are moot for fixed landing gears. (The book prints "mute".) Points to
**Chapter 9**.

### Step 10 (p. 15)
**Prepare a scaled preliminary arrangement drawing of the proposed configuration and perform a
Class I weight and balance analysis.**

Points to **Chapter 10**, which also shows examples of the required preliminary arrangement
drawings.

### Step 11 (p. 15)
**Perform a Class I stability and control analysis of the proposed configuration.**

Points to **Chapter 11**.

### Step 12 (p. 15)
**Perform a Class I drag polar analysis.**

Points to **Chapter 12**.

### Step 13 (pp. 15–16)
**Analyze the results of Steps 10 and 11.**

By inspecting the results of Steps 10 and 11, one or more of these four conclusions is
possible:

1. The weight and balance results (Step 10) and the stability and control results (Step 11) are
   satisfactory. **Proceed to Step 14.**

2. The results of Step 10 show a 'tip-over' problem: the c.g. is incorrectly located relative
   to the landing gear. Try minor adjustments to the wing and landing gear locations. If that
   solves the problem, make the change(s) and go on to Step 14. If minor adjustments cannot
   solve it, consider a change in the configuration. That can mean going back to **Step 2**.

3. The airplane has too much travel between forward and aft c.g. The suggestions under 2 apply
   here also. This problem tends to disappear if the payload c.g., the fuel c.g. and the OWE
   c.g. are close together. Try to achieve this. Sometimes relocation of one particularly heavy
   component solves the problem.

4. The results of Step 11 show that the airplane has too much or too little longitudinal and/or
   directional stability, or that a V_mc problem exists. Make the required adjustments to tail
   or canard sizes and, when necessary, redo Steps 10 and 12. **Proceed to Step 14.**

Chapters 10 and 11 give the information needed to arrive at one or more of these four
conclusions.

### Step 14 (pp. 16–17)
**From the drag polars of Step 12, compute those L/D values which correspond to the mission
phases and to the sizing requirements considered in the preliminary sizing process of Part I
(Ref. 1).**

**14.1)** Tabulate the new and the old L/D values.

**14.2)** Determine the impact of any changes in L/D on W_TO, W_E and W_F. Use the results of
the sensitivity analyses made during the Part I preliminary sizing process. Consider these
cases:

| Case | Condition | Action |
|---|---|---|
| 1 | Weight changes are less than 5 percent | Resizing is not necessary. Proceed to Step 15. |
| 2 | Weight changes are more than 5 percent but less than 15 percent | Resize with the results of the Part I sensitivity analyses. Go back to Step 3. |
| 3 | Weight changes are more than 15 percent | Resize with the methods of Part I. Go back to Step 3. |

While working on Steps 13 and 14 you can find that the configuration choice of Step 3 was a bad
one. Do not be discouraged. That is exactly the purpose of p.d. sequence I: to weed out the bad
ideas from the good ones. The work done up to this point gives clues for any configuration
changes that are needed.

### Step 15 (p. 17)
**Prepare a dimensioned threeview which reflects all the changes which were made as a result of
the iterations involved in Steps 10 through 14.**

On the threeview, or as an addendum to it, include a tabulation of all essential dimensional
and dimensionless design parameters. **Chapter 13** shows examples of such tabulations.

### Step 16 (p. 18)
**Prepare a report which documents the results obtained during p.d. sequence I. Include
recommendations for change, for further study or for research and development work which needs
to be carried out.**

At this point the first preliminary design sequence is complete.

---

## 2.2 Preliminary Design Sequence II (Steps 17–36, pp. 18–23)

This sequence starts with the threeview of Step 15 and the report of Step 16.

### Step 17 (p. 18)
**List the major systems needed in the airplane. Also: prepare 'ghost' views indicating the
general system arrangements and their location in the airframe.**

Points to **Part IV (Ref. 4)**. Two reasons to identify the required airplane systems now:
1. Airplane systems have a significant impact on empty weight. Step 21 needs a detailed weight
   estimate.
2. To find any obvious conflicts where two or more systems occupy the same space. The 'ghost'
   views help find such conflicts early.

### Step 18 (pp. 18–19)
**Size the landing gear tires and struts using Class II methods. Also: verify the validity of
the proposed landing gear disposition and of the proposed retraction scheme.**

Points to **Part IV**, which has the Class II landing gear sizing methods and detailed examples
of landing gear design practice.

Prepare drawings showing that the landing gear can be retracted into the designated volume.
Include a 'stick-diagram' of the retraction kinematics. Determine the force-stroke diagram for
the retraction actuator and verify its feasibility.

### Step 19 (p. 19)
**Prepare an initial structural arrangement drawing.**

Points to **Part III (Ref. 2)** for a step-by-step method. Two reasons to prepare the
structural arrangement now:
1. The structural arrangement has a major impact on the Class II weight predictions of Step 21.
2. The structural arrangement influences the manufacturing breakdown of Step 34 and, in turn,
   the cost estimates of Step 36.

> **Important Note:** Frequently a synergistic effect is possible: cleverly combine major
> structural components to take advantage of mutually supporting functions. Structural
> synergism reduces the empty weight of the proposed airplane.

### Step 20 (p. 19)
**Construct a V-n diagram.**

Points to **Part V (Ref. 3)**.

### Step 21 (p. 19)
**Perform a Class II weight and balance analysis. This includes the calculation of moments and
product(s) of inertia.**

Points to **Part V (Ref. 3)**.

### Step 22 (p. 19)
**Analyze the results of Step 21. This step is similar to Step 13, points 1–3.**

### Step 23 (p. 19)
**Redraw the threeview obtained at the end of p.d. sequence I, as required.**

### Step 24 (p. 20)
**Perform a Class II stability and control analysis using the threeview of Step 23.**

The Class II stability and control analysis must consider these items:
1. Trim diagram (power-on and power-off)
2. Take-off rotation
3. Minimum control speed with engine out, including the effect of bank angle
4. Roll performance
5. Crosswind control during final approach and on the runway
6. Open loop dynamic handling
7. Gain sizing of any required SAS-loops
8. For airplanes with reversible flight control systems, the slopes ∂F/∂V (stick-force versus
   speed) and ∂F/∂n (stick-force versus load factor) must be determined and checked against the
   certification base
9. Actuator size and rate requirements

The methods are in **Part VII (Ref. 6)**.

The important outcome is that the 'final' sizes of stabilizing and control surfaces are
established. Adjust the threeview of Step 23 if necessary, and perform any other required
iterations. Example of a required iteration: the tail sizes change by more than 10 percent in
area and/or in weight in going from Class I to Class II results. Then both drag (thrust and
fuel) and weight can change a lot, and another design iteration is necessary.

For airplanes which lack inherent static and/or dynamic stability, the Class II analysis must
also give a preliminary definition of the required stability augmentation system and its gains.
This includes the initial determination of actuator size and rate requirements. Part VII gives
a methodology for the preliminary definition of the SAS and of the required actuator
performance.

### Step 25 (pp. 20–21)
**Recompute the drag polars using Class II methods.**

Use the tail and surface sizes of Step 23. Class II drag polar methods, also called component
build-up methods, are in **Part VI (Ref. 5)**.

### Step 26 (p. 21)
**Compute the installed power and/or thrust characteristics of the propulsion system.**

> *Nota bene:* Account for all essential installation losses, and for losses caused by the
> operation of all 'flight essential' airplane systems.

Methods are in **Part VI (Ref. 5)**.

### Step 27 (p. 21)
**List all performance requirements which the airplane must meet. This includes FAR as well as
mission requirements. Identify those requirements found to be critical in the preliminary
sizing of the airplane.**

### Step 28 (p. 21)
**Compute the critical performance capabilities of the airplane and compare them with the
requirements of Step 27.**

Make all calculations of critical performance capability with the Class II drag polars of
Step 25 and with the Class II installed engine characteristics of Step 26. Use the Class II
performance methods of **Part VII (Ref. 6)**. Further design iterations can be needed,
depending on the results.

### Step 29 (p. 21)
**Iterate through Steps 17–28 as needed and adjust the configuration.**

> The reader will now appreciate why configuration design was referred to as a non-unique,
> iterative process in the introduction (Chapter 1).

### Step 30 (p. 21)
**Finalize the threeview and tabulate the essential airplane geometry.**

Examples of threeviews and of geometric tabulations are in **Part III (Ref. 2)**.

### Step 31 (p. 21)
**Finalize the inboard profile(s).**

Examples are in **Part III (Ref. 2)**.

### Step 32 (p. 22)
**Prepare a preliminary layout drawing for all essential airplane systems, in particular the
primary and secondary flight control systems.**

**Part IV** contains examples of layout drawings for various airplane systems. Check for any
conflicts and go through the 'WHAT IF' safety and maintenance checklist given in Part IV.
(The printed text cites "Part IV (Ref.3)"; Ref. 3 is Part V elsewhere in this chapter — see the
misprint note at the end.) It is of particular importance to make sure that no undue fire
hazards and no obstacles to crash survivability have been 'built in'.

### Step 33 (p. 22)
**Finalize the structural arrangement.**

Step 19 asked for an initial structural arrangement. The work done in Steps 20–32 can impose
modifications on it.

### Step 34 (p. 22)
**Prepare a preliminary manufacturing breakdown.**

Points to **Part III** for how to decide on manufacturing breakdowns. (The printed text cites
"Part III (Ref.3)"; Ref. 2 is Part III elsewhere in this chapter — see the misprint note.)

### Step 35 (p. 22)
**Make a study of maintenance and accessibility requirements.**

The study needs these schematics:
1. A schematic showing all essential access requirements for inspection and for maintenance.
   Make sure it is compatible with the structural arrangement.
2. For transports and for military airplanes, a schematic demonstrating the accessibility of
   standard service, loading and unloading vehicles.
3. A schematic showing that the engine(s) and the APU can be easily inspected and removed.

**Part IV** gives useful hints about the maintenance requirements of various airplane systems.

### Step 36 (p. 23)
**Perform a preliminary cost analysis for the airplane.**

This generally includes an estimate of these cost items:
1. Design and development cost
2. Manufacturing cost
3. Operating cost

**Part VIII (Ref. 7)** gives the methods. From these estimates, judge if the proposed airplane
will let the manufacturer and the operator make a profit.

For a military airplane, the cost analysis must include a comparison of the military utility, or
'bang-per-buck', of the proposed new airplane against alternate solutions. It must also include
a rationale for the selected design in view of expected enemy threats.

At this point it often makes sense to study the possible benefits of design optimization against
cost criteria. Typical cost criteria are DOC, ROI and LCC. Part VIII (Ref. 7) addresses this
problem also.

Prepare a final report documenting the results obtained during p.d. sequence II. This completes
all p.d. sequence II work.

### IMPORTANT COMMENT (p. 23)

Experience has shown that the decisions made during preliminary configuration design 'lock in'
90 percent of the life-cycle-cost (LCC) of the airplane.

This is of staggering importance, because the total investment made in the airplane at the end
of the preliminary design phase is negligible even when compared with the total full scale
development cost. Clearly, it is penny-wise and dollar-foolish not to invest heavily in
supportive research work during the early design work on a new airplane.

---

## Unnumbered figure — DASH 8 General Arrangement
*[Roskam Part II, p. 24; caption "DASH 8 General Arrangement", marked "Courtesy of: De Havilland Canada"]*

Three-view general arrangement drawing of the de Havilland Canada DASH 8. It closes Chapter 2
and carries no plotted data. The drawing carries a note: "★ NOTE: DIMENSIONS ARE APPROXIMATE
AND MAY VARY DEPENDING ON AIRCRAFT CONFIGURATION AND LOADING CONDITIONS." Dimensions marked ★
on the drawing carry that note.

Dimensions printed on the drawing:

| Dimension | Value (ft-in) | Value (mm) |
|---|---|---|
| Span | 84 ft 0 in | 25 603 |
| Length | 73 ft 0 in | 22 253 |
| Height ★ | 25 ft 0 in | 7 620 |
| Wing height above ground ★ | 13 ft 5 in | 4 077 |
| Propeller diameter | 13 ft 0 in | 3 962 |
| Propeller tip to fuselage centerline | 12 ft 11 in | 3 942 |
| Propeller tip to fuselage clearance | 30 in | 762 |
| Propeller ground clearance ★ | 37 in | 937 |
| Main gear track | 25 ft 10 in | 7 884 |
| Horizontal tail span | 26 ft 0 in | 7 925 |
| Wheelbase (nose gear to main gear, side view) | 25 ft 11 in | 7 899 |
| Plan view, longitudinal: forward reference line to the propeller plane | 27 ft 2 in | 8 293 |
| Plan view, longitudinal: propeller plane to the wing line | 6 ft 5 in | [verify p. 24] |
| Sill height ★ (rear door) | 43 in | 1 092 |
| Forward fuselage top above ground ★ | 10 ft 5 in | 3 175 |
| Wing dihedral | 2.5 degrees | — |

The two plan-view longitudinal dimensions (27 ft 2 in and 6 ft 5 in) are dimension brackets
without text labels. The endpoints given above are read from the drawing geometry, not from a
printed label.

Also labelled on the plan view: "Lateral Control Spoilers" and "Ground Spoilers" on the wing
upper surface.

**`[verify p. 24]`** — the millimetre value in the callout "6 FT 5 IN (1 ??4 mm)" is not
legible. What I tried: rendered the page at 200, 500, 900 and 1400 dpi and clipped tightly on
that callout. At 1400 dpi the middle two digits of the four-digit number blot into one another
in the raw scan, so the number reads as either "1 964" or "1 984". The scan itself, not the
render, is the limit. 6 ft 5 in = 1956 mm, which does not decide between the two. I did not
guess a value.

**Note on the conversions.** Some ft-in / mm pairs on this drawing do not convert exactly:
84 ft 0 in = 25 603 mm, 13 ft 0 in = 3 962 mm and 30 in = 762 mm are exact, but 12 ft 11 in is
3 937 mm (printed 3 942), 37 in is 940 mm (printed 937), 13 ft 5 in is 4 089 mm (printed
4 077), 25 ft 10 in is 7 874 mm (printed 7 884) and 27 ft 2 in is 8 280 mm (printed 8 293).
The differences are all under 0.5 percent. The drawing is a manufacturer's approximate general
arrangement, and the ★ note allows this. Recorded as printed.

---

## Suspected misprints in Chapter 2

1. **Step 32, p. 22** — "the 'WHAT IF' safety and maintenance checklist given in Part IV
   (Ref.3)". Everywhere else in this chapter Part IV is Ref. 4 (Step 17, p. 18) and Ref. 3 is
   Part V (Steps 20 and 21, p. 19). The reference number appears to be wrong; the Part name
   (Part IV) agrees with the surrounding text.
2. **Step 34, p. 22** — "Part III (Ref.3) addresses the problem of deciding on manufacturing
   breakdowns". Part III is Ref. 2 elsewhere (Step 19, p. 19). Same kind of error.
3. **Step count of sequence II** — Chapter 1, p. 4 says p.d. sequence II "involves 30 design
   steps". Chapter 2 (p. 9, p. 18) and Fig. 2.1 (p. 8) both give sequence II as Steps 17–36,
   which is 20 steps. The two statements do not agree. The step list itself is what the rest of
   the book cites, so Steps 17–36 is the working number.
4. Typographical errors (recorded, no effect on content): "prelimininary" (p. 16, Step 14),
   "af all" for "of all" (p. 17, Step 15), "mute" for "moot" (p. 15, Step 9).
