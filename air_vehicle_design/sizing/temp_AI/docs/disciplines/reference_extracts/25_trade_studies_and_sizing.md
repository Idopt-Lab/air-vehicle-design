# Chapter 25 — Trade Studies and Sizing

Scraped from Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Volume I*, printed
pp. 651–668 (PDF pp. 660–677). Page offset: PDF page = printed page + 9 (consistent with Ch. 20-24).

Text-layer inventory: Figs 25.1-25.10 (with sub-parts 25.3a-d — regex initially only caught 25.3a-c; 25.3d
confirmed present during transcription — and 25.4a-b); Table 25.1; Eqs 25.1-25.3 — confirmed complete via
post-transcription Grep verification.

## Chapter Opener (p. 651)

Two black-and-white photos: left, a man in a suit standing beside a swept vertical tail of a
supersonic-looking aircraft (nose visible in background) with hand resting on the tail's leading edge;
right, a formal portrait of an older man in a suit seated, with military plaques/shields on the wall behind
him and what appears to be a model rocket or missile resting across his lap.

Caption *(paraphrased)*: identifies the man as Kelly Johnson, described as perhaps the greatest airplane
designer of the 20th century, whose legendary designs included the P-38, XF-90, F-94, F-104, F-117A,
C-130, U-2, SR-71, and D-21 drone. His famous 14 rules of management were the forerunners of "concurrent
engineering" and are summarized at the end of this chapter.

Section-list sidebar: Trade Studies; Carpet Plots; Knothole Plots; Risk Assessment; Risk Mitigation;
Kelly's 14 Rules.

Epigraph: "Be quick, be quiet, and be on time!" — Clarence "Kelly" Johnson.

Copyright notice: Copyright © 2010 American Institute of Aeronautics and Astronautics.

## §25.1 Introduction (p. 652)

Are we done yet? The answer is No. We have essentially completed one iteration for a baseline
configuration as shown in Fig. 25.1. The design may meet the mission requirements, or exceed some and fall
short on others. In any event the designer, being very close to the design, has definite feelings on what
should be changed to make the design better. The designer is now ready to start another iteration, hoping
to make the estimates of aerodynamics, weight, propulsion data, and performance more refined.

There are three major trade studies shown in Fig. 25.1 that the designer needs to conduct:

1. **Design.** Helps the designer select the best combination of design features to meet the measures of
   merit (MoM)
2. **Mission.** Indicates the sensitivity of the baseline design to changes in the mission requirements
3. **Technology.** Indicates the sensitivity of the baseline design to the selected technologies and forms
   the basis for the risk assessment

**Fig. 25.1** — *What happens after the first design iteration?* *[Nicolai & Carichner, Fig. 25.1,
p. 652]*. A large process-flow diagram spanning the full design cycle, in two main tracks connected by a
circular "A" waypoint marker. Left/lower track (labeled "YOU ARE HERE" at a circular badge near its end,
indicating the reader's current position in the overall design process): Customer -> Mission Reqs ->
Concept of Ops (feeding into, alongside System Approach [Tactics, Support Aircraft, ECM, Subsystems, etc.]
and Measures of Merit [Life Cycle Cost (LCC), Takeoff Weight, Targets Killed/LCC, etc.]) -> Design
Guidelines (Radius, Payload, Altitude, Signature, etc., also fed by Technology [Materials, Stealth,
Propulsion, etc.]) -> Configuration Sketches -> "Concept No. 1" (stack of planform sketches) -> Initial
Sizing -> Select Configuration -> Functional Inputs (Aero, Propulsion, Weights, Mat'l Structure, Signature)
-> Design Trades (a small carpet-plot-style chart with axes W/S, T/W, AR, Sweep, etc., MoM y-axis) ->
Select Preferred Configuration -> Baseline Design. A side loop shows Evaluate Req/Con Ops -> Negotiate with
Customer -> a "GO" starburst decision -> feeding back into Design Guidelines, with Selection Criteria as an
input. The circular "A" waypoint connects this baseline design into the right/upper track: Mission Trades
(inputs: Radius, Payload, Speed, Box Size, Hover Time, etc.; small MoM-vs-percent-change chart) -> Point
Design (inputs: OML, Gen Arrangement, Performance, Subsystems, Risk Analysis, Req Analysis, Sys Engr
Results, Management Plan, RM&S, LCC Analysis, System Specs, Test Planning, TRL = 3-4) -> a "Req Change??"
decision diamond: "Yes" branches to "Back to GO" (returning to the GO starburst on the left), "No" branches
to "Share Trade Results with Customer" -> a "Happy??" decision diamond: "Yes" proceeds down to "Preliminary
Design" (large circular badge at bottom right), "No" branches to "Iterate Design (back to A)" and
"Technology Trades" (small MoM-vs-percent-change chart with TSFC, Engine T/W, Empty Weight, $C_D$,
$L/D$, $C_{L_{max}}$, etc. as the varied parameters) and "Risk Assessment," which feed back around into
"Iterate Design (back to A)" and then loop back toward Point Design. A footnote defines "MoM = Measure of
Merit."

The results of the trade studies are extremely important as they indicate the sensitivity of some measure
of merit to changes in the design parameters, mission requirements, and technologies. These measures of
merit are usually one or more of the following:

- **Takeoff weight.** Indicates the general vehicle size and hence cost and energy requirements
- **Cost.** The total life cycle cost (LCC) over a fixed period such as 10 years; tradeoff between RDT&E,
  acquisition, and O&M costs
- **Energy.** Total fuel required for mission
- **System effectiveness.** Some parameter that combines performance, cost, and/or energy, such as the
  following:
  - Return on investment (ROI)
  - Bombs on target per hour per dollar
  - Kill ratio per aircraft dollar
  - Survivability
  - Transport direct operating cost (DOC)
  - Energy effectiveness parameter

## §25.2 Carpet Plots and Knotholes (p. 653)

The number of variables that might be considered in a tradeoff study may be less than 10 or more than 50.
The designer has the difficult task of sorting through all combinations in a systematic fashion to find the
best combination. These data should also be used to visually explain why certain design decisions were
made so internal and external managers understand why the final design looks the way it does. Sometimes
the designer might want to display several parameters on the trade study charts.

Figure 25.2 shows an example of examining the three design variables $T/W$, $W/S$, and aspect ratio (AR).
The mission requirement calls for a deep strike interdiction fighter with a payload of 4500 lb and a
mission radius of 400 n mile. The fighter also has the acceleration requirement of $P_S=700$ fps at
$M=1.6/35{,}000$ ft and a maximum sustained maneuver load factor of 4.5 $g$ at $M=0.9/20{,}000$ ft. The
takeoff gross weight (TOGW) is the measure of merit for this example. The AR is held constant and the
$T/W$ and $W/S$ are iterated to give the minimum TOGW vehicle that just meets the mission.

The design cycle is then repeated for other values of AR. The minimum TOGW for each AR is then plotted
versus AR to find the best AR for the interdiction fighter. Admittedly, the computer must be used to
perform the design iterations; however, the designer is in the loop to assess the results and make the
final design selection. The computer cannot be asked to select the final design as some measures of merit
are qualitative and will often change with time. The designer must be aware of this and

**Fig. 25.2** — *Parametric tradeoff showing a three-variable example of wing loading, thrust-to-weight
ratio, and aspect ratio* *[Nicolai & Carichner, Fig. 25.2, p. 654]*. A stack of several $T/W$-vs-$W/S$
carpet-style charts (one per aspect ratio value, the stack itself labeled "Aspect Ratio" along its depth
axis), the frontmost chart titled "Interdiction Mission, Radius = 400 n mile," with $T/W$ (0.80-0.94) on
the y-axis and $W/S$ (86-98) on the x-axis. Overlaid families of curves: constant TOGW contours (68,000 lb,
72,000 lb, 76,000 lb); constant $P_S$ lines (650, 700, 750 f/s); constant $n_z$ lines (4.4g, 4.5g, 4.6g,
approximately). A "Min TOGW" point is circled near $W/S\approx94$, $T/W\approx0.865$. An arrow leads from
the stack of charts to a smaller inset chart at right, TOGW (y-axis) vs Aspect Ratio (x-axis), showing a
curve that dips to a labeled "Optimum" point before rising again — illustrating how the minimum-TOGW point
from each aspect-ratio slice is collected into a single optimization curve.

project into the future as best as he can. Alan Mullaly (Project Manager for the Boeing 777 and later
Boeing CEO) said it best: "Planes are made by people not computers [1]."

Sometimes during a parametric trade study, the data on the charts become dense and tend to overlap. This
makes interpolation difficult. One way of spreading the data of more than two variables apart for better
visibility and still providing direct interpolation is to present the data on *design carpet plots*. A
design carpet plot buildup is demonstrated in Fig. 25.3 using a Navy multimission fighter-attack aircraft.

Figure 25.3a shows the relative interdiction mission gross weight required to fly the desired radius with
a constant $W/S$ of 100 psf, with $T/W$ varying from 0.35 to 0.45. The relative gross weights required to
fly this constant radius interdiction mission at other wing loadings can be presented by shifting the
abscissa and plotting a second wing loading on the new shifted scale as shown in Fig. 25.3b. Additional
wing loadings can be added in the same manner and points of constant $T/W$ are connected to form a final
design carpet plot as shown in Fig. 25.3c, where the abscissa scales have been eliminated.

By interpolation between the curves the relative interdiction mission gross weight can be determined for
any combination of $W/S$ and $T/W$. Other information could be presented in Fig. 25.3c by superimposing
lines of constant design characteristics. For example, Fig. 25.3d shows lines of constant relative
acquisition cost. Other design constraint lines can be added such as approach speed, takeoff field length,
and airport noise.

**Fig. 25.3** — *Example of design carpet plot buildup for a Navy multimission fighter* *[Nicolai &
Carichner, Fig. 25.3, p. 655]*. Four-panel carpet-plot buildup, all sharing the title "Constant
Interdiction Mission Radius," y-axis Relative Interdiction Mission Gross Weight (0.7-1.4):

**a. Basic two variable plot** — a single curve of Relative Gross Weight vs Thrust/Weight (0.35-0.45) at
constant Wing Loading $W/S=100$ psf, rising monotonically from ~1.02 at $T/W=0.35$ to ~1.37 at $T/W=0.45$.

**b. Carpet plot buildup showing three variables with abscissa scale shift** — two such curves, one
labeled $W/S=100$ (same as panel a) and a second labeled $W/S=110$ plotted on a shifted abscissa
(sub-labeled "0.35, 0.40, 0.45 (W/S=110)" beneath the original "0.35, 0.40, 0.45 (W/S=100)" scale), with
dashed lines connecting points of equal $T/W$ between the two curves.

**c. Completed design carpet plot for three variables (abscissa scales deleted)** — the full carpet-plot
fan of five wing-loading curves (100, 110, 120, 130 psf, plus the implied continuation) crossed by
constant-$T/W$ diagonal lines (0.35, 0.40, 0.45), abscissa numeric scales removed, leaving only the
crossing-curve grid for graphical interpolation.

**d. Design carpet plot with Relative Acquisition Cost added** — the same panel-c carpet grid with three
additional dashed nearly-horizontal lines overlaid, labeled Relative Cost = 1.1, 1.0, and 0.9 (top to
bottom), showing how acquisition-cost contours can be superimposed on the $T/W$-$W/S$ design space.

The trade space data just discussed can also be presented in a format that is capable of illustrating an
entire trade study on a single plot. This plot is called a *knothole* based on its usual form. Figures
25.4 and 25.5 summarize the entire process used to create a complete "knothole" for a commercial
transport. The benefits of putting the data in this format are that it clearly communicates where the
optimum design point is and what constraints are preventing the optimum from being selected. The extra
work

**Fig. 25.4a** — *Performance trade results used to construct "knotholes"* *[Nicolai & Carichner, Fig.
25.4a, p. 656]*. Eight small linked charts (a "build-up" sequence for a commercial transport knothole),
arranged in two columns:

Left column, top to bottom: (1) Empty Weight vs $S_{wing}$, two lines "High TOGW" (upper, steeper) and
"Low TOGW" (lower, shallower); (2) $T_{actual}/T_{SLS}$ vs $T_{SLS}$, two roughly flat lines labeled
"Takeoff" (upper) and "Cruise" (lower); (3) TOGW vs Range, a single rising line annotated "Mach = constant,
All TOFL"; (4) $C_L$ vs $C_D$, a single curve annotated "Adjust for various wing sizes" and "AR = constant,
Taper ratio = constant."

Right column, top to bottom: (1) Propulsion System Weight vs $T_{SLS}$, a single rising line annotated
"Constant Engine Cycle"; (2)-(4) three charts (Range vs $S_{wing}$; TOGW vs $S_{wing}$; $T_{SLS}$ vs
$S_{wing}$), each shown as a family of three curves labeled "TOFL" (takeoff field length) at varying
values, all rising with $S_{wing}$ — this right-column trio is highlighted in a shaded box distinguishing
it as the TOFL-parameterized sub-sequence feeding into the final knothole construction.

**Fig. 25.4b** — *Performance results needed to draw constraint lines on "knotholes"* *[Nicolai &
Carichner, Fig. 25.4b, p. 657]*. Six small linked charts, two columns:

Left column: (1) $g$s vs $S_{wing}$, labeled "BUFFET," a distorted grid of curves crossing "Low Altitude"
vs "High Altitude" and "Low TOGW" vs "High TOGW"; (2) $W_{land}$ vs (unlabeled, implicitly $S_{wing}$),
labeled "$V_{approach}$," a skewed grid with axes/arrows for $V_{app}$ and $T_{SLS}$; (3) TOFL vs TOGW,
labeled "TOFL," two curves "Small Swing" (upper) and "Large Swing" (lower), both decreasing/concave.

Right column: (1) TOGW vs $S_{wing}$, labeled "Cruise Altitude," two rising lines "Low Altitude" (upper)
and "High Altitude" (lower); (2) $V_{approach}$ vs TOGW, labeled "$V_{approach}$," two rising lines "Small
Swing" (upper) and "Large Swing" (lower); (3) TOFL vs $S_{wing}$, labeled "TOFL," two curves "Small Engine"
(upper) and "Large Engine" (lower), both decreasing/concave.

involved to generate this plot is repaid many times over because it distills numerous technical issues
into a form that is easily understandable by customers, management, and nontechnical program personnel.

The included example is for defining an optimum large-scale commercial transport that has a size
somewhere between an L-1011 and a B-747. Figures 25.4a and 25.4b summarize all of the data that must be
accumulated. This data is a mix of experimental, analytical, and sometimes "best guess" information. The
data plots are unique to a commercial transport and differ significantly from that of a military fighter
or bomber. Here the constraints were noise, buffet, approach speed, and takeoff and landing field lengths.

The final knotholes are shown in Fig. 25.5 and present that data in two different ways. One plot holds
range constant and shows rings of constant TOGW. The other is for a constant TOGW and shows rings of
constant range. This entire study assumed a constant wing aspect ratio of 8.0.

**Fig. 25.5** — *Parametric trade study results presented as "knotholes" (commercial transport)* *[Nicolai
& Carichner, Fig. 25.5, p. 658]*. Two large "knothole" charts, both with axes Thrust/Engine (1000 lb,
40-90) vs Wing Area (ft², 1000-9000), each showing a set of nested oval "TOGW"/"Range" contour rings
crossed by several near-vertical constraint-line families:

**Top panel** — conditions "Range = 4500 n mile, Payload = 60,000 lb, Mach = 0.85." Nested ovals labeled
(innermost to outermost) 525, 550, 575, 600 (Takeoff Gross Weight, 1000 lb). Crossing constraint lines:
$V_{approach}$ (KEAS) at 140, 130, 120; Takeoff Field Length (1000 ft) at 29/31, 12/11/10, 33, 35, 37, 39;
Initial Cruise Altitude (1000 ft) at 1.25 $g$s, 1.35 $g$s (labeled "Buffet Onset"), 1.5 $g$s.

**Bottom panel** — conditions "Takeoff Gross Weight = 700,000 lb, Payload = 60,000 lb, Mach = 0.85."
Nested ovals labeled (innermost to outermost) 6600, 6400, 6200, 6000, 5800 (Range, n mile). Crossing
constraint lines: $V_{approach}$ (KEAS) at 140, 130, 120; Takeoff Field Length (1000 ft) at 14, 29, 12, 31,
10, 33, 35, 37, 39; Initial Cruise Altitude (1000 ft) at 1.25 $g$s, 1.35 $g$s (Buffet Onset), 1.5 $g$s.

These knotholes used $T/W$ and $W/S$ for the axes, but for studies where the engine is known and the wing
planform is also known the axes will become $T$ (thrust) and $S$ (wing area). The process is identical.

Some words of caution when generating knotholes are appropriate at this point. First, knotholes take
extra time to generate so they must be

useful for communicating outside the technical study group. If the results are only going to be used by
technical groups, then the carpet plots in Fig. 25.2 will likely suffice. Second, drawing the entire ring
can be difficult particularly on the low wing loading and low thrust/weight edges. Solutions will blow up
for very slight changes, making a little "artistic license" necessary for the final shapes. In the end
knotholes offer a means to concisely summarize large amounts of carpet-plotted data in an easily understood
form.

To illustrate that knotholes can look vastly different depending on the type of air vehicle that is being
studied, Figure 25.6 is presented without discussion but represents a small autonomous UAV that has a
portable ground control station. It is similar yet very different from the commercial transport knothole
in Fig. 25.5.

**Fig. 25.6** — *Parametric sizing study for Class III UAV* *[Nicolai & Carichner, Fig. 25.6, p. 659]*.
Chart titled "Parametric Sizing Knothole," $T/W$ (y-axis, 0.040-0.096) vs $W/S$ (x-axis, 10-60). A family
of near-vertical curves labeled "TOGW (lb)" at 370, 360, 355, 350, 345, 340 sweeping down-and-right, and a
nested set of closed contour loops (350, 345, 340, 335, 333, 332, 331 lb, innermost smallest) forming the
characteristic "knothole" shape — the outer 350 and 345 loops are large open crescents spanning
$W/S\approx15$-$60$, while the inner loops (340 down to 331) tighten progressively toward a small region
around $W/S\approx30$-$35$, $T/W\approx0.06$-$0.065$. Design condition annotations: Time on Station = 8 h;
Payload = 75 lb; Wing Taper Ratio = 1.0.

## §25.3 Design Trades (p. 660)

The tradeoff information is used to select the proper combination of design features to achieve the most
efficient vehicle relative to the measure of merit criteria. Some of the design parameters that are often
varied during a parametric study are the following:

- Body shape (fineness ratio, nose shape, cross-sectional area distribution)
- Wing size and wing loading
- Wing shape (sweep, aspect ratio, taper ratio, thickness ratio, variable versus fixed geometry)
- High-lift devices (mechanical vs powered)
- Tail configuration (aft tail, canard, or tailless)
- Stability level (degree of static margin)
- Engine [$T/W$, number of engines, bypass ratio, fan pressure ratio, overall pressure ratio, turbine
  temperature, propulsion concept (turboprop, turbofan, turbojet, etc.)]
- Inlet or nozzle (location, type of inlet, type of nozzle)
- Materials (metals vs composites)

Figures 25.3-25.6 show examples of design trades.

## §25.4 Mission Trades (p. 660)

Mission requirements are usually fixed by the customer; however, they should be considered negotiable and
forcefully challenged when they distort the design. The designer has the responsibility of pointing out the
sensitivity of the aircraft design to the mission requirements. If one mission requirement, such as range,
is driving the aircraft design to large takeoff weights (and hence high cost) the designer should advise
the customer of this situation. The customer might choose to back off on the performance requirement to
bring the cost down to an affordable level. The designer should provide mission requirement tradeoff
information to the decision makers to permit the best compromise between performance and cost. Thus, the
mission requirements of range, payload, turning performance, field length, and so on are typical
candidates for the mission requirements trade study.

This trade is briefly discussed in Chapter 5, where the composite Lightweight Fighter (LWF) was sized.

## §25.5 Technology Trades (p. 661)

The results of a technology trade are used in two different ways by different groups:

1. The results are used by the program community to form the basis for a risk analysis as it answers two
   very important questions: What is the consequence (on the MoM) of the technology failing to perform as
   expected and what is the probability of the technology not performing as expected?
2. The results are used by the technology planners to form the basis for technology investment decisions
   as they show the payoff for spending research dollars on maturing the technology.

**Sidebar: Nontechnical Issues Can Drive Technical Decisions (p. 660)** — Sometimes technical decisions
are made based on nontechnical events. In 1987 the YF-22 design team (Lockheed, Boeing, and General
Dynamics) was conducting design trades to select the best wing (planform, sweep, aspect ratio, and span)
for their advanced tactical fighter (ATF) prototype. The clipped diamond planform won out over the swept
trapezoidal planform (even though the "trap" wing had more aspect ratio) because it offered more wing area
at a lighter structural weight (more root chord). The 48 deg LE wing sweep was a compromise between
supersonic drag and subsonic aero performance. The 43-ft wing span was selected (even though it had a low
aspect ratio of 2.2) because the width of the door on the TAB-V aircraft shelters was 45 ft. The wing span
on the production F-22A was increased to 44.5 ft and sweep decreased to 42 deg to increase the aspect
ratio to 2.4.

An example of a technology trade is shown in Fig. 25.7. The example is an intelligence, surveillance, and
reconnaissance (ISR) aircraft (called SensorCraft) with the mission requirements shown on the chart.
SensorCraft uses the off-the-shelf (OTS) engines AE 3007H and the aircraft TOGW is 130,000 lb using
state-of-the-art technologies. The technologies are allowed to improve or degrade and the sensitivity of
TOGW is determined. The change in the TOGW is the consequence of failure (or success) of the technology.
The technology community would be asked to assess the probability of technology failure (or success).

The technology trade study shows that aircraft $L/D$ and engine thrust specific fuel consumption (TSFC)
have the most impact on the aircraft TOGW: both have a $\Delta\text{TOGW}/\Delta\%$ change $=-1000$.
Getting a +5% improvement in TSFC is probably expensive, otherwise Allison (Rolls Royce) would have done
it long ago. Similarly the TSFC is not likely to degrade because the AE 3007H is a mature engine in the
Global Hawk. Thus, it is probably unwise to invest dollars in the AE 3007H. Likewise, there is little
concern about the TSFC degrading (low probability of failure). On the other hand

**Fig. 25.7** — *ISR aircraft technology trade results* *[Nicolai & Carichner, Fig. 25.7, p. 662]*. Chart
titled "Sensorcraft Technology Sensitivity," TOGW (1000 lb, y-axis 110-150) vs % Change in Technology
(x-axis -15 to 15), with mission-condition annotations: 40 hour Mission Endurance; 3000 n mile Mission
Radius; 55,000 ft Loiter Altitude at Mach=0.6; AE3007H Allison Engines. All lines cross at the baseline
point (0% change, TOGW=130,000 lb). Six sensitivity lines, by steepness: "L/D (base=37)" — steepest,
falling from ~142,000 lb at -10% to ~122,000 lb at +10% (i.e., TOGW decreases as L/D improves); "SFC
(base=0.63)" — steep, rising from ~120,000 lb at -10% to ~140,000 lb at +10% (TOGW increases as SFC
worsens); "Landing Gear Wt" — shallow, nearly flat; "Wing Weight" — shallow, slight positive slope;
"Fuselage & Sys Wt" — shallow, slight positive slope; "Payload Weight (base=6900 lb)" — shallow dotted
line, slight positive slope. The four shallow lines (Payload Weight, Fuselage & Sys Wt, Wing Weight,
Landing Gear Wt) cluster tightly together near TOGW=127,000-135,000 lb across the full x-range, visually
confirming the text's point that structural/system weight technologies have far less TOGW sensitivity than
L/D or SFC.

dollars might be invested in improving the $L/D$ (more laminar flow, winglet, and airfoil research) and be
concerned about degraded $L/D$ (high probability of failure) due to losing laminar extent on the wing. The
trade study shows that reducing aircraft structural and system weight has less impact on TOGW and the
technology community would probably agree that it is harder to achieve.

## §25.6 Risk Analysis (p. 662)

Risk is an increasingly popular topic in the aerospace industry because there is risk in every decision
that is made [2]. Choosing between configurations that have similar performance could prove to be easy if
their respective risks were quite different. Folding in risk to conceptual and preliminary design efforts
adds another element to consider when making engineering choices. Understanding potential risks early in
the program is important but there needs to be an objective means of assigning risk to unfavorable program
events. Assigning risk allows customers and management to better understand how the engineering group
plans on maturing technologies that are part of a selected design and the priorities of each risk.

Quantifying risk uses relationships from probability and set theory as its mathematical basis (see [3]).
Risk is simply defined mathematically as the union of failures and impacts or the probability of
occurrence of unfa-

vorable events. A *failure* is an unfavorable event and an *impact* is an unfavorable event that follows a
failure; an impact may also be a failure. Risk has two major components. The first is the probability that
the item will fail (Pf) (or likelihood that the failure will occur, Lo) and the second is the consequence
(impact) of that failure, Cf (or the consequence of occurrence, Co). The terms Pf and Cf are considered to
be too negative and so, popular usage has replaced them with their equivalents Lo and Co. These two
parameters are mathematically combined (based on set theory) in Eq. (25.3) to yield a single number,
generally referred to as the *risk index*, that represents the total risk of that item.

Generally, Co is broken into its three parts representing (technical, schedule, and cost). Scoring the
three components of Co can be combined using the same set theory mathematics to yield a single value for
Co [see Eq. (25.2)]. Once Co is calculated then Eq. (25.3) can be used to obtain the *Risk Index*. Both
equations depend on Eq. (25.1) realistically representing the risk of any system. Table 25.1 shows a
sample calculation of the total system risk based on the individual risks of each of its components.
Notice how high the total risk index is. Managers and engineers often underestimate the aggregate risk of
numerous items when assigning a total system risk:

$$\text{Risk(Overall)} = A\cup B - A\cap B = \text{Lo}\cup\text{Co} - \text{Lo}\cap\text{Co} \tag{25.1}$$
*[Nicolai & Carichner, Eq. (25.1), p. 663]*

$$\text{Risk(Consequences, Co)} = P(C_T)\cup P(C_S)\cup P(C_C) \tag{25.2}$$
*[Nicolai & Carichner, Eq. (25.2), p. 663]*

where $P(C_T)$ = probability of the consequence from technical failure; $P(C_S)$ = probability of the
consequence from schedule failure; $P(C_C)$ = probability of the consequence from cost failure.

$$\text{Risk Index (RI)} = \text{Lo} + \text{Co} - \text{Lo}\cdot\text{Co} \tag{25.3}$$
*[Nicolai & Carichner, Eq. (25.3), p. 663]*

**Table 25.1** — *Sample Risk Calculation* *[Nicolai & Carichner, Table 25.1, p. 663]*. Component No. / Lo
/ Co / Risk Index: 1 (0.3, 0.2, 0.44); 2 (0.2, 0.2, 0.36); 3 (0.4, 0.3, 0.58); 4 (0.6, 0.1, 0.64); 5 (0.1,
0.4, 0.45); **TOTAL = (0.879, 0.758, 0.971)**.

Although the mathematics is appealing and objective, many system engineers assess risk in other ways.
However, any other mathematical technique is clearly inferior to the set theory approach. Many engineers
use a nonmathematical technique that ultimately ends up with risk simply having a value of low, moderate,
or high. This approach will be discussed next.

In the non-mathematical approach a risk matrix is used to determine the overall Risk Index value.
Although this matrix can vary from user to user, Fig. 25.8 is a good representative of this matrix. The 5
ratings of Lo and Co must have agreed-upon definitions (see Fig. 25.9) so that they are consistent across
the program and independent of the person(s) giving the rating.

Once Lo and Co (remember Lo and Co are probabilities with values from 0 to 1) ratings have been assigned
they are located on the matrix and will end up in the low, moderate, or high category. General rules state
that any item that is high risk must have a mitigation plan and a backup plan in case the original plan
fails. Any item that has moderate risk must have a mitigation plan. Items that are low risk are just
watched to make sure their risk does not change over the course of the program. Some managers will also
use the results of risk assessment to allocate resources. Obviously, there is a relationship between the
amount of risk (i.e., difficulty) and the cost of mitigating or maturing that risk.

The final result of these risk identification and assessment processes becomes a risk mitigation chart
(waterfall chart) that shows the amount of risk reduction (mitigation) as a function of time. Figure 25.10
illustrates the relationship between risk assessment and risk mitigation.

It is a good time to reflect on how individuals assign risk to systems containing numerous components.
Which system has more risk, (1) a

**Fig. 25.8** — *Risk assessment matrix* *[Nicolai & Carichner, Fig. 25.8, p. 664]*. A 5x5 grid matrix,
y-axis "Likelihood" (Low, Minimum, Moderate, Significant, High, bottom to top) vs x-axis "Consequence"
(Low, Min, Mod, Sig, High, left to right). Cells are shaded/labeled into three risk-level regions: **Low**
(the bottom-left corner cells, darkest shading) — Likelihood x Consequence combinations of
Low/Low, Low/Min, Minimum/Low; **Moderate** (a diagonal band of medium-shaded cells) — includes
Low/Mod, Minimum/Min, Moderate/Low, Moderate/Min, Significant/Low, and similar mid-diagonal cells;
**High** (upper-right cells, lightest/most prominent shading) — includes High/Sig, High/High,
Significant/Sig, Significant/High, Moderate/High, and similar upper-right cells. Arrows along the axes
reinforce that Likelihood increases upward and Consequence increases rightward.

**Fig. 25.9** — *Example of risk assessment template (performance)* *[Nicolai & Carichner, Fig. 25.9,
p. 665]*. A composite template titled "Risk Assessment Template—Performance," with a top block "Likelihood
of Occurrence—Lo" (5-column table, Low/Minor/Moderate/Significant/High) whose row entries define each
rating: Low = "Off the shelf"; Minor = "Flight Test"; Moderate = "Element test complete"; Significant =
"Partial test mixed with mostly analysis"; High = "Analysis only." Below it, three further 5-column tables
under the heading "Consequence of Occurrence—Co," one per consequence category:

**Cost** — Low: "Negligible cost impact"; Minor: "Minor cost impact on functional area, No cost impact on
overall program"; Moderate: "Minor cost impact on the program"; Significant: "Significant cost impact on
the program"; High: "Major cost impact on the program."

**Schedule** — Low: "Negligible impact on program success"; Minor: "Could impact noncritical path
milestones, No impact on program critical path"; Moderate: "Minor impact on program critical path
milestones, Workaround will likely maintain schedule"; Significant: "Moderate impact on program critical
path milestones"; High: "Major impact on program schedule (>4 month slip)."

**Technical** — Low: "Negligible impact on mission performance, No impact on program success, Can accept
degradation"; Minor: "Minor impact on mission performance, No impact on program success, Can accept
degradation"; Moderate: "Minor impact on mission performance, Minor impact on program success, Acceptable
workaround available"; Significant: "Degrades mission performance, Impacts program success, Expedited
resolution required"; High: "Significantly impacts mission performance, Endangers program success, Must be
fixed prior to aircraft delivery."

system that has one high-risk item and one low-risk item or (2) a system that has one moderate-risk item
and two low-risk items? There is no single right answer and answers will vary with individuals. Although
the mathematical technique (Eq. 25.1) can consistently calculate relative risks regardless of the number
of components, managers will often substitute subjective values for the mathematical values.

## §25.7 Now We Are Done (p. 665)

There is no set rule on how many iterations and parametric tradeoffs are necessary for a design—it depends
upon the skill and thoroughness of the designer and the design team and upon the time and budget available
for the conceptual phase. The conceptual phase usually continues until the decision is made to move the
most promising design into the preliminary design phase or to terminate the design effort.

## §25.8 Kelly Johnson's 14 Rules of Management (p. 665)

1. The Skunk Works manager must be delegated practically complete control of his program in all aspects.
   He should report to a division president or higher.
2. Strong but small project offices must be provided by both the military and industry.

**Fig. 25.10** — *Assessing and mitigating risk* *[Nicolai & Carichner, Fig. 25.10, p. 666]*. Three-part
process diagram. Left: the same Fig. 25.9 "Risk Assessment Template—Performance" composite table
(Likelihood of Occurrence—Lo; Consequence of Occurrence—Co broken into Cost/Schedule/Technical), feeding
via an arrow into: Center, a "Risk Matrix" (the same Low/Min/Mod/Sig/High x Low/Minimum/Moderate/
Significant/High grid as Fig. 25.8), showing a star marker at High-Likelihood/Moderate-Consequence
connected by a dashed "Risk Mitigation Efforts" arrow diagonally down to a pentagon marker at
Low-Likelihood/Moderate-Consequence — illustrating a risk item's movement from high risk toward low risk
over time as mitigation proceeds. This matrix then feeds down via an arrow into: Bottom, a "Risk Mitigation
(waterfall)" chart spanning Year 1 through Year 5, y-axis Low/Moderate/High, plotting a descending
staircase of risk level over time from a star (Year 1, High) down to a pentagon (end of Year 5, Low),
annotated with program milestones (SRR "Systems Requirements Review," PDR "Preliminary Design Review," CDR
"Critical Design Review," FFRR "First Flight Readiness Review," FF "First Flight") and labeled risk-
reduction activities at each step-down: Define Test Reqs, ID Test Facilities, Static Test, Inlet Test,
Powered Test, Control Law Simulation, Nozzle Test, Flight Clearance Runs, Development Test.

3. The number of people having any connection with the project must be restricted in an almost vicious
   manner. Use a small number of good people (10% to 25% compared with the so-called normal systems).
4. A very simple drawing and drawing release system with great flexibility for making changes must be
   provided.
5. There must be a minimum number of reports required, but important work must be recorded thoroughly.
6. There must be a monthly cost review covering not only what has been spent and committed but also
   projected costs to the conclusion of the program. Don't have the books 90 days late, and don't surprise
   the customer with sudden overruns.
7. The contractor must be delegated and must assume more than normal responsibility to get good vendor
   bids for subcontract on the project. Commercial bid procedures are very often better than military ones.
8. The inspection system as currently used by the Skunk Works, which has been approved by both the Air
   Force and Navy, meets the intent of existing military requirements and should be used on new projects.
   Push more basic inspection responsibility back to subcontractors and vendors. Don't duplicate so much
   inspection.
9. The contractor must be delegated the authority to test his final product in flight. He can and must
   test it in the initial stages. If he doesn't, he rapidly loses his competency to design other vehicles.
10. The specifications applying to the hardware must be agreed to well in advance of contracting. The
    Skunk Works practice of having a specification section stating clearly which important military
    specification items will not knowingly be complied with and reasons therefore is highly recommended.
11. Funding a program must be timely so that the contractor doesn't have to keep running to the bank to
    support government projects.
12. There must be mutual trust between the military project organization and the contractor with very
    close cooperation and liaison on a day-to-day basis. This cuts down misunderstanding and correspondence
    to an absolute minimum.
13. Access by outsiders to the project and its personnel must be strictly controlled by appropriate
    security measures.
14. Because only a few people will be used in engineering and most other areas, ways must be provided to
    reward good performance by pay not based on the number of personnel supervised.

**Sidebar: Kelly Johnson and Lulu Belle (p. 668)** — Axis Germany's Messerschmitt Me 262 was the first
operational jet fighter, becoming operational during the summer of 1944. It instantly raised the bar for
fighter aircraft, having a 100-mph advantage over every WWII Allied fighter.

The US Army Air Force had commissioned Bell aircraft in September 1941 to build a jet fighter—the P-59
Airacomet using a British jet engine with the Whittle design. The YP-59 had its first flight in October
1942, but from the beginning its performance was disappointing. On June 21, 1943 the US Army gave Lockheed
a contract to build one prototype of a jet fighter using the British Goblin jet engine. The contract was
for \$642,000 with a delivery date of November 1943 (180 days).

The project lead was given to a young engineer named Clarence "Kelly" Johnson. The Lockheed Advanced
Development Projects (ADP, better known as the Skunk Works) was born. Kelly set up a super-secret
operation with about 20 engineers and 80 shop men working 10 hour days, 6 days a week (Sunday was a day of
rest ... no matter what). Kelly shaped his 14 rules of management during this mission-critical project.

Four days early on November 17, 1943, the XP-80, dubbed "Lulu Belle" (see the first page of Appendix K)
rolled out with the Goblin engine installed and ready for systems check-out. Problems with engine/inlet
integration delayed first flight until January 8, 1944. Lulu Belle made two flights that day and reached
490 mph on the second flight—50 mph more than the maximum speed of the fastest Allied aircraft, the P-38.
The XP-80 led to the P-80 Shooting Star, which eventually reached 600 mph. Kelly Johnson and his team's
implementation of his 14 rules of management led to the Skunk Works' success: Lockheed built 1,715
aircraft for the USAF and Navy.

## References (p. 668)

[1] Sabbagh, Karl, "21st Century Jet-The Making of the Boeing 777," MacMillan General Books, London, UK,
1995.
[2] Bernstein, P. L., *Against the Gods, The Remarkable Story of Risk*, Wiley, New York, 1998.
[3] Blanchard, B. S., *System Engineering Management*, 3rd ed., Wiley, New York, 2004.

Chapter 25 extraction complete.

