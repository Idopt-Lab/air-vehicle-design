function p = f16a_requirements_path()
%F16A_REQUIREMENTS_PATH  Absolute path to the F-16A requirements JSON.
%   p = f16a_requirements_path() returns examples/F16A/f16a_requirements.json.
%
%   REQUIREMENTS vs SPEC -- the distinction this file exists to enforce.
%   f16a_spec_path(N) returns per-fidelity AIRCRAFT SPEC data: what this
%   airframe and engine ARE (areas, sweeps, thrust, airfoil). The requirements
%   file holds what the aircraft must DO: mission conditions and design targets.
%   Requirements do not vary with fidelity level, so unlike f16a_spec_path this
%   takes NO level argument -- there is one requirements file, read by every
%   level. Never put spec data here, and never put a requirement in a spec file.
%
%   Introduced 2026-07-25 (Phase 4). This revives the Step-0 `requirements.json`
%   that docs/PLAN.md:178 records as planned-but-never-built: mission conditions
%   had been scattered as per-discipline inputs instead (the design max Mach
%   existed in THREE places, and the cruise condition in none the weights
%   classes could reach). Currently minimal -- cruise altitude/Mach and the
%   design Mach, which is all Phase 4 needs. Constraint analysis and mission
%   analysis will grow it into the full requirement set; it is expected to become
%   the most cross-cut input file in the repo.
%
%   Consumers: F16WeightsL2/L3 (cruise condition for the SFC dependency
%   injection; design_mach for the Raymer Eq. 10.10 engine weight) and
%   F16GeomL1 (design_mach -> GeomL1.get_AR_eq, Raymer 7th ed. Table 4.1).
    here = fileparts(mfilename('fullpath'));
    p = fullfile(here, 'f16a_requirements.json');
end
