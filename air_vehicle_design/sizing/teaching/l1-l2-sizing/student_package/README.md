# AOE 4065 — Aircraft Sizing

Everything needed to run the two sizing classes. Self-contained: unzip it
anywhere and run. Nothing else has to be installed or downloaded.

## Start here

1. Open MATLAB.
2. Open `START_HERE.mlx` from this folder and run it.

It puts the framework on the path, checks that you have the two toolboxes the
sizing loops need, and sizes a Boeing 777 to prove the package works.

## What is in here

| Folder | What |
|---|---|
| `guide/` | `Sizing_Guide.pdf` — the written reference: the algorithm, five different diagrams of it, and the Level-1 against Level-2 comparison. `diagrams.html` opens the same diagrams in a browser with zoom and pan, offline. `Sizing_Guide.md` is the same text, browsable. |
| `lecture/` | Boeing 777-200LR walkthrough, `L01` to `L07`. Run them in order. |
| `lab/` | F-16A exercise. `LAB00` is a worked warm-up. `LAB01` is the one you write. `LAB_worksheet.pdf` is the follow-up. `solution/` holds the instructor copy. |
| `helpers/` | Short functions the Live Scripts call, so the scripts stay about sizing instead of plumbing. Read them; none is long. |
| `framework/` | The sizing framework itself. Nothing in here needs editing. |
| `output/` | Somewhere to save your figures. |

## Requirements

- MATLAB R2022b or newer to run the code. The `.mlx` Live Scripts were saved on
  **R2026a**, so open them on R2026a or a later release.
- **Aerospace Toolbox** — supplies `atmosisa`, which builds every flight
  condition.
- **Optimization Toolbox** — supplies `fmincon`, which both sizing loops use to
  find the design point.

`START_HERE.mlx` reports which of these you are missing.

## Running a Live Script in class

`Ctrl+Enter` runs one section and stays put. `Ctrl+Shift+Enter` runs a section
and moves on. The lecture files are meant to be used that way: one section at a
time, with the output on screen.

## One thing that catches everybody

Every discipline object is a MATLAB `handle`. A sizing run does not return a new
aircraft; it **writes into the objects you gave it**. So **build a fresh stack
before every run** — a second run on a used stack starts from the first run's
leftovers, not from the spec file.

Every script here does that with `build_b777_stack`, `build_f16_stack_L1` or
`build_f16_stack_L2`. Do the same in your own code.

## Where the framework came from

The sizing framework is the AOE 4065 conceptual-design codebase. Two of its
example aircraft are shipped here:

- **Boeing 777-200LR** — provenance is the Martins design metabook, Chapter 4
  (constraint analysis) and Chapter 7 (component build-up weights).
- **F-16A Block 10/15** — provenance is the Brandt F-16A workbook.

Only the parts the two classes use are included. The validation data, the
sanity-check reports and the T–S diagram material are all left out, so some
folders are thinner than in the full repository.

Every equation in the framework carries a citation in the code. If you want to
know where a number comes from, open the `.m` file, or the `.md` file sitting
next to it.

## For the instructor

The shippable folder is **built**, not hand-maintained. Sources live one level
up in `teaching/l1-l2-sizing/mlx_src/` (the Live Scripts, as plain `%%`-celled
`.m`) and `teaching/l1-l2-sizing/guide_src/` (LaTeX, TikZ and Mermaid).
Rebuild with:

```matlab
cd air_vehicle_design/sizing/teaching/l1-l2-sizing
make_student_package          % framework, .mlx, guide, smoke test, zip
```

Run it whenever the framework changes. It refuses to finish if the smoke test
fails, so a broken package cannot reach Canvas. Individual steps:

```matlab
make_student_package('steps', ["framework"])   % just recopy src/ and examples/
make_student_package('steps', ["mlx"])         % just regenerate the Live Scripts
make_student_package('steps', ["guide"])       % just rebuild the PDF and figures
```

The guide step needs `pdflatex` (TeX Live) for the XDSM, N2 and PDF, and `npx`
for the Mermaid diagrams. Both degrade to a warning if missing; the rendered
Mermaid output is committed so a machine without `npx` can still build.
