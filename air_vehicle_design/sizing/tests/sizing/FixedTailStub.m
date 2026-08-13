classdef FixedTailStub < TailSizingModelL1
%FIXEDTAILSTUB  A minimal, generic (non-F-16-specific) TailSizingBase-
%   conforming stand-in, used only by TestSizingLoopL2.m.
%
%   WHY THIS EXISTS (2026-07-28): SizingLoopL2's `tail` constructor argument
%   is typed (1,1) TailSizingBase -- the Tier-1 abstract enforcer shared
%   by F16TailL1/F16TailL2/F16TailL3 -- rather than the old concrete
%   TailSizingLevel1 (see src/disciplines/tail_sizing/
%   TailSizing_scribe_plan.md Secs. 2/3). TailSizingLevel1 inherits only
%   `handle`, NOT TailSizingBase, so TestSizingLoopL2.m's previous
%   `TailSizingLevel1(0.40, 0.07)` construction fails that type check.
%   TailSizingLevel1/F16TailSizingLevel1 are themselves SUPERSEDED (see
%   their class headers) -- this stub replaces that direct construction
%   rather than reaching for a superseded class.
%
%   This file's ONLY job is to satisfy SizingLoopL2's L1 four-scalar
%   size(obj, S_ref, b, cbar, L_fus) calling convention (see
%   TailSizingBase.m's header) with arbitrary, non-F-16 coefficients, so
%   TestSizingLoopL2.m stays "generic (non-F-16-specific)" per its own class
%   header -- swapping in the real F16TailL1 would pull F-16-specific
%   coefficients into a file whose whole point is genericity.
%
%   TAIL/CONTROL-SURFACE SIZING (2026-08-03 absorption into Geometry
%   REVERTED, 2026-08-05): unchanged by that reversal -- SizingLoopL2 always
%   called tail.size(S_ref, b, cbar, L_fus), the widest TailSizingBase
%   signature, both before and after the (now-reverted) absorption
%   detour; this file's four-scalar shape was always the correct one for
%   that call convention. Production (design_study_02_L2.m,
%   design_study_03_L3.m) uses F16TailL1() -- the same shared, unmodified
%   object across both design studies -- not F16TailL2/F16TailL3, which
%   are Nicolai-alternate and stability-and-control-stub paths respectively,
%   never wired into SizingLoopL2.
%
%   size() delegates into the REAL TailL1 toolbox statics (same tail-arm
%   rule, 0.475*L_fus, as production code) -- not a duplicated formula --
%   with arbitrary coefficients c_HT=0.40, c_VT=0.07. TestSizingLoopL2.m
%   never asserts against Brandt or any F-16 number, only that the loop
%   plumbs tail.size(...) through correctly and gets positive areas
%   (testTailAndControlSurfaceAreasPositive), so the exact coefficient
%   values and tail-arm fraction are immaterial to what that suite checks.

    properties
        c_HT (1,1) double = 0.40   % arbitrary, non-F-16 coefficient
        c_VT (1,1) double = 0.07   % arbitrary, non-F-16 coefficient
    end

    methods

        function result = size(obj, S_ref, b, cbar, L_HT, L_VT)
        %SIZE  Delegates to TailL1's real statics, using this stub's
        %   arbitrary c_HT/c_VT.
        %   SIGNATURE CHANGED 2026-08-11 with TailSizingBase's: the last
        %   argument was L_fus and the arm was computed here as 0.475*L_fus.
        %   The arms are now supplied by the caller (SizingLoopL2 passes
        %   geom.L_HT/geom.L_VT), because the arm is a layout quantity --
        %   see TailSizingBase.m's header.
            S_ht = TailL1.compute_S_HT(obj.c_HT, cbar, S_ref, L_HT);
            S_vt = TailL1.compute_S_VT(obj.c_VT, b, S_ref, L_VT);
            result = struct('S_ht', S_ht, 'S_vt', S_vt);
        end

    end

end
