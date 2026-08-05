# Roskam — *Airplane Design, Part I: Preliminary Sizing of Airplanes* — Extracted Data

**Source:** Jan Roskam, *Airplane Design, Part I: Preliminary Sizing of Airplanes*, Roskam Aviation and Engineering Corp. (DARcorporation), 1st printing 1985.
**Purpose:** Reference for the MATLAB MDA package (F-16A, L1 sizing). Method + equations captured and paraphrased; large historical data tables (Tables 2.3–2.14) are NOT reproduced — page pointers given instead.

> Citation format used below: *Roskam, Airplane Design Part I, <eq/table/section>*. Page numbers are the printed book pages (PDF page in parentheses where OCR'd).

---

## Chapter 2 — Estimating Takeoff Gross Weight W_TO, Empty Weight W_E, and Mission Fuel Weight W_F

### 2.1 Weight breakdown & iterative method
Basic breakdown (§2.1):
```
W_TO = W_OE + W_F + W_PL          (operating-empty + fuel + payload)
W_OE = W_E + W_tfo + W_crew       (empty + trapped fuel/oil + crew)
```

Iterative sizing procedure (§2.1, eqs 2.4–2.5, 2.16):
```
Step 1.  Determine mission payload weight W_PL (and crew W_crew).      (§2.2)
Step 2.  Guess a likely takeoff weight  W_TO_guess.                    (§2.3)
Step 3.  Determine mission fuel weight  W_F.                           (§2.4)
Step 4.  W_F_used_tent = W_TO_guess − W_PL − W_F(reserve...)           (2.4)
Step 5.  W_E_tent      = W_TO_tent − W_tfo − W_crew                    (2.5)
         (W_tfo ≈ up to ~0.5% of W_TO, often neglected at this stage)
Step 6.  Find allowable W_E from the regression (eq 2.16 / Fig 2.3–2.14).
Step 7.  Compare W_E_tent vs allowable W_E; adjust W_TO_guess and repeat
         Steps 3–6 until they agree to within ~0.5% tolerance.
```

### 2.2 Payload & crew weight (§2.2)
- Passengers: **175 lb/person + 30 lb baggage** (short/medium haul); **40 lb baggage** long haul.
- Crew (commercial): **175 lb + 30 lb baggage** each.
- **Military crew: 200 lb each** (extra gear).
- Military payload = ammunition, bombs, missiles, external stores/pods (note: external stores affect drag).

### 2.4 Mission fuel weight — fuel-fraction method
- Mission is broken into phases; each phase has a fuel-fraction `Wi/Wi-1`.
- Mission fuel fraction `Mff = Π (Wi / Wi-1)` over all phases.
- Used fuel: `W_F_used = (1 − Mff) · W_TO`; total `W_F = W_F_used + W_reserve` (reserves often a % of fuel used; e.g. fighter example uses **25% of fuel used** as reserve).
- **Table 2.1** gives recommended *fixed* phase fuel-fractions for warmup/taxi/takeoff/climb/descent/landing (book p.12 region). For cruise/loiter, fuel fraction comes from the Breguet equations using **Table 2.2** guideline values of L/D, SFC (cj), η_p.
  - *(The specific Raymer/Roskam fixed phase fractions — 0.970 TO, 0.985 climb, 0.990 descent, 0.995 land — are already captured in `metabook_data.md`; Roskam Table 2.1 is consistent with these. Cruise/loiter use Breguet, see `metabook_data.md` eqs 2.6–2.8.)*

### 2.5 Empty-weight regression — **Eq (2.16)** (the key L1 relation)
```
W_E = inv.log10{ ( log10(W_TO) − A ) / B }                            (2.16)
```
- Linear log–log trend between `log10(W_TO)` and `log10(W_E)` across 12 airplane categories.
- A, B are category-specific constants from **Table 2.15** (book p.47, PDF p.59).
- The trend line is the *minimum allowable* W_E at current state-of-the-art.

**Table 2.15 regression constants — project-relevant rows** (transcribed from the scanned table; jet-fighter row is the F-16 case):

| Category (Roskam #9 = Fighters)        | A       | B      |
|----------------------------------------|---------|--------|
| **Fighters — jets**                    | **0.5091** | **0.9505** |
| Fighters — piston/props                | 0.5647  | 0.8761 |
| Single-engine prop driven              | −0.1440 | 1.1162 |
| Mil. patrol/bomb/transport — jets      | −0.2009 | 1.1037 |
| Supersonic cruise — jets (cruise val.) | 0.0833  | 1.0335 |

> ⚠️ The full 12-category table is image-only; the rows above were OCR-recovered. The **jet-fighter A=0.5091, B=0.9505** is the value to use for the F-16A L1 empty-weight estimate. Verify against the book before locking into code.

**Composite-construction correction (Table 2.16, book p.48, PDF p.60):** multiply the metallic-airplane allowable W_E by `Wcomp/Wmetal`. Component factors include **Fuselage 0.85**, Wing/Vertical Tail (≈0.85 region — verify remaining rows in book).

### 2.6.3 Worked Example 3 — Fighter
- Roskam works a fighter sizing example (mission spec → W_PL, fuel fractions per Table 2.1, cruise/loiter via Breguet, then iterate eq 2.16). Reserve = 25% of fuel used. *(Use this as a cross-check structure for the F-16A L1 sizing unit test; target TOGW ≈ 31,000 lbf per project spec.)*

### 2.7 Sensitivity / growth factors (§2.7)
- Analytical method for takeoff-weight sensitivity to payload, empty weight, range, endurance, speed, SFC, η_p, and L/D — useful for the project's "growth factor" discussion (book p.74+).

---

## Chapter 3 — Estimating Wing Area S, Takeoff Thrust T_TO (or Power), and CL_max (clean / TO / landing)

This chapter is the **L1 constraint-analysis source** (sizing to point-performance requirements). Each requirement maps to wing loading (W/S), thrust loading (T/W), or both:

- **3.1 Sizing to stall-speed** → drives required CL_max and W/S (V_stall).
- **3.2 Sizing to takeoff distance** → FAR 23, FAR 25, **Military (book p.101–106)**, and carrier-based variants.
- **3.3 Sizing to landing distance** → FAR 23/25, **Military (p.115)**, carrier-based.
- **3.4 Climb requirements** → FAR 23/25 climb, **Military climb summary (p.149)**.
- Ends with a **matching plot** (constraint diagram) — "Matching Example 3: Fighter" (book p.185) is the fighter worked example to mirror in the project's L1 constraint diagram.

> CL_max clean / takeoff / landing are treated here categorically for the L1 method (consistent with the project's L1 plan: tabulate ΔCL_max_TO, ΔCL_max_L). Specific CL_max ranges per flap type are in image tables/figures of Ch.3 — look up book pp. ~90–120 if exact values are needed.

---

## Notes for the project
- **L1 empty-weight estimate:** use Eq 2.16 with jet-fighter A=0.5091, B=0.9505. This is Roskam's categorical/historical approach the project's L1 spec calls for.
- **L1 fuel weight:** fuel-fraction method (Table 2.1 fixed fractions + Breguet for cruise/loiter via Table 2.2 L/D & SFC guides).
- **L1 constraint analysis:** Ch.3 military sizing equations (takeoff, landing, climb, stall) — these are the point-performance requirements feeding the constraint diagram.
- Raw historical data tables (2.3–2.14, hundreds of specific aircraft) intentionally NOT copied; consult the book directly if a specific airplane datapoint is needed.
