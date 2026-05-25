# History

## Learnings

### 2026-05-24 — OOP-first directive
- Darshan directed: all MATLAB classes must be instantiable. Static-only classes are banned.
- BrandtGeometry was the first violation — refactored to instance-based OOP.
- Pattern: constructor loads inputs, compute() stores results, display/plot methods read from obj.
- Updated bishop, ferro, dallas charters accordingly.
- ADR written: bishop-oop-first-no-static-bags.md
