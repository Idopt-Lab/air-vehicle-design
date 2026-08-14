classdef (Abstract) SubsystemsModelL2 < SubsystemsBase
%SUBSYSTEMSMODELL2  Tier-2 abstract enforcer for Level-2 subsystems.
%
%   Inherits SubsystemsBase directly, not SubsystemsModelL1: each fidelity
%   level satisfies the Tier-1 contract independently.
%
%   L2 is geometry-derived: fuselage-internal volume via Raymer Eq. 7.14 off
%   the injected L2 geometry's envelope-ellipse A_top/A_side, wing-internal
%   volume via Roskam Eq. 6.2/6.3, and a battery-electric alternative volume
%   path -- a documented citation GAP at every level, see battery_volume.
%
%   DEPENDENCY INJECTION (mirrors F16WeightsL2's geom/prop DI, guarded at this
%   ENFORCER tier so a wrong-tier collaborator fails at construction):
%     geom              -- (1,1) GeometryModelL2. Only S_ref, b_wing,
%                           tc_r_wing/tc_t_wing, lambda_wing (Roskam wing-
%                           volume term) and L_fus/W_max_fuselage/
%                           H_max_fuselage (Raymer fuselage-volume term) are
%                           read.
%     fuel_weight_source -- (1,1) WeightsBase. Supplies BOTH the required
%                           fuel weight for fuel_volume_check (obj.W_energy)
%                           AND W_empty for the avionics-weight term
%                           (obj.OEW(obj.W_TO)) -- one injected collaborator
%                           serves both roles, matching the original
%                           "mission analysis or F16WeightsL2" design intent.
%
%   INPUT vs DERIVED. Every quantity below the injected collaborators is
%   DERIVED -- recomputed live on every read/call, never cached, matching the
%   optimization-ready pattern (CLAUDE.md; reference implementation
%   examples/F16A/models/disciplines/geom/F16GeomL2.m).
%
%   Toolbox companion: src/disciplines/subsystems/SubsystemsL2.md

    properties (Abstract)
        fuel_type                  % string, e.g. 'JP-8' -- selects SubsystemsL2.lookup_fuel_density [Nicolai & Carichner Table 8.6]
        packaging_factor_category  % string, e.g. 'Integral tank — shallow fuselage' -- selects SubsystemsL2.lookup_packaging_factor [Nicolai & Carichner p.210]
        avionics_table_row         % string, e.g. 'Fighters' -- selects SubsystemsL2.lookup_avionics_weight_fraction [Raymer 6th ed. Table 11.6]

        % ----- Injected collaborators (NOT numeric spec data) ------------- %
        geom                % (1,1) GeometryModelL2
        fuel_weight_source  % (1,1) WeightsBase
    end

    % ======================================================================= %
    % avionics_weight_fraction, avionics_density, fuel_density,
    % fuselage_raw_volume and fuel_volume are declared on SubsystemsBase, not
    % here (2026-08-03 -- see that file's header note). Every quantity below
    % takes ZERO extra arguments and reads ONLY obj's own stored inputs/
    % injected collaborators (never an externally-varying argument), so it is
    % declared as an ABSTRACT PROPERTY, not an abstract method -- matching
    % WeightsModelL2's W_wings/W_tail/W_fuselage/... split (abstract PROPERTY
    % for a self-contained derived total; abstract METHOD reserved for the
    % toolbox-style form that takes a genuine external argument, e.g.
    % battery_volume below). The concrete class implements each as a
    % `get.<name>` Dependent getter recomputing live -- CLAUDE.md
    % "Optimization-ready property design"; examples/F16A/models/disciplines/geom/F16GeomL2.m /
    % F16WeightsL2.m are the reference implementations of this exact split.
    % ======================================================================= %
    properties (Abstract)
        %AVIONICS_WEIGHT  fraction * W_empty [lbf], W_empty = obj's own
        %   fuel_weight_source.OEW(fuel_weight_source.W_TO) -- self-
        %   referencing, zero extra args: reads its own injected collaborator
        %   live.
        avionics_weight

        %AVIONICS_VOLUME  avionics_weight / avionics_density [ft^3]. MUST be
        %   summed into internal_volume() -- see SubsystemsBase header.
        avionics_volume

        %FUSELAGE_USABLE_FUEL_VOLUME  fuselage_raw_volume * packaging_factor
        %   [ft^3]. The packaging factor MUST be applied before this figure
        %   is compared against a required fuel volume -- the legacy code
        %   never applied one (a legacy bug to avoid).
        fuselage_usable_fuel_volume

        %WING_FUEL_VOLUME  Wing-internal fuel volume [ft^3].
        %   [Roskam Airplane Design Part II, Eq. 6.2/6.3] Off obj.geom's
        %   S_ref, b_wing, tc_r_wing, tc_t_wing, lambda_wing. NOT multiplied
        %   by a second packaging factor (the Nicolai factor applies only to
        %   the fuselage term, per the JSON's _cite_packaging_factor note).
        wing_fuel_volume
    end

    methods (Abstract)

        %BATTERY_VOLUME  NOT IMPLEMENTED -- documented citation GAP. Stays a
        %   METHOD (not a Dependent property): it takes a genuine external
        %   argument (E_required_kWh), AND a Dependent
        %   getter must never be allowed to throw -- MATLAB's own object
        %   display/introspection machinery (e.g. `disp(obj)`) evaluates
        %   every Dependent property's getter eagerly, so a deliberately-
        %   erroring citation-gap member would break ordinary object display
        %   if it were Dependent. Must error with a distinct, clearly-
        %   documented MATLAB error identifier rather than fabricate a
        %   coefficient.
        val = battery_volume(obj, E_required_kWh)

    end

end
