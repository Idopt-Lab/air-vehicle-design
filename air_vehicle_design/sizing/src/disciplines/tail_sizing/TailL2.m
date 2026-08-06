classdef TailL2
%TAILL2  Level-2 tail-sizing static toolbox: "historical sizing estimates"
%   using an F-16-specific measured volume coefficient and real L2 wing
%   geometry.
%
%   Call as TailL2.method(...); never instantiated, not in the inheritance
%   chain. F16TailL2 inherits TailSizingModelL2 and delegates to these
%   statics.
%
%   METHOD -- same governing identity as TailL1's Raymer 7th ed. Table 6.4
%   form, confirmed algebraically identical to Nicolai & Carichner's own
%   Eq. (11.1)/(11.2) [temp_AI/docs/disciplines/reference_extracts/
%   11_tail_sizing.md Secs. 11.2-11.3, pp. 286, 289]:
%
%     C_VT = (l_VT*S_VT)/(b*S_ref)      ==>  S_VT = C_VT*b*S_ref/l_VT
%     C_HT = (l_HT*S_HT)/(cbar*S_ref)   ==>  S_HT = C_HT*cbar*S_ref/l_HT
%
%   COEFFICIENT SOURCE: Nicolai & Carichner Table 11.6, "General Dynamics
%   F-16" row, p.289 [temp_AI/docs/disciplines/reference_extracts/
%   11_tail_sizing.md] -- an F-16-SPECIFIC measured coefficient, not a
%   generic category row:
%     C_HT = 0.3
%     C_VT = 0.094
%   EXPLICITLY NOT the conflicting C_HT=0.68, C_VT=0.041 figure that appears
%   in nicolai_data.md / roskam_vol2_data.md / usaf_f16_data.md -- those
%   three temp_AI digest files mis-transcribe the same Table 11.6 row
%   (flagged, left OPEN/unresolved elsewhere; see VnV/BrandtF16A/todo.md
%   Finding 1 and TailSizing_scribe_plan.md Secs. 5.1/7.1). Fixing those
%   three digest files is out of scope for this deep-dive.
%
%   TAIL MOMENT ARM CARRIES FORWARD L1's RULE, UNCHANGED: GeometryModelL2
%   has no x-station properties at all (no x_apex_wing/x_le_ht/x_le_vt --
%   those first appear on GeometryModelL3), so a genuinely geometry-derived
%   moment arm is not achievable at L2 with today's inputs:
%
%     L_HT = L_VT = TailL1.compute_tail_arm(L_fus) = 0.475*L_fus
%
%   [Raymer 7th ed. text rule, reused verbatim via a cross-toolbox static
%   call -- deliberately NOT a duplicated copy, matching the precedent of
%   AeroL1.oswald_eff being called by L2/L3 drag-polar paths. See
%   TailSizing_scribe_plan.md Sec. 5.1.]
%
%   AREA REUSE IS INDIRECT ONLY (Sec. 5.2): size(obj) returns
%   struct('S_ht','S_vt') and nothing else. No geometry object is injected
%   for the purpose of computing exposed/wetted area inside tail sizing,
%   and no get_S_exposed_ht-style accessor exists here. The caller (e.g.
%   SizingLoopL2) writes S_ht/S_vt back into the geometry object; that
%   object's own Dependent properties (S_exposed_ht, S_wet_ht, ...) do the
%   rest automatically.
%
%   Companion doc: src/disciplines/tail_sizing/TailL2.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the concrete object, return the result.
        % ================================================================== %

        function result = size(obj)
        %SIZE  Horizontal- and vertical-tail reference areas [ft^2].
        %   [Nicolai & Carichner Table 11.6 F-16 row; Raymer 7th ed. tail-arm
        %   text rule, carried forward from L1]  obj must expose C_HT/C_VT
        %   and an injected geom (1,1) GeometryModelL2 -- see F16TailL2.
        %   Reads geom.b_wing, geom.cbar_wing, geom.S_ref, geom.L_fus LIVE on
        %   every call, so a mutated geometry object is reflected
        %   immediately -- no cached copy.
        %   Returns struct('S_ht', S_ht, 'S_vt', S_vt).
            S_ref = obj.geom.S_ref;
            b     = obj.geom.b_wing;
            cbar  = obj.geom.cbar_wing;
            L_fus = obj.geom.L_fus;

            L_HT = TailL1.compute_tail_arm(L_fus);   % carried forward from L1, unchanged [Sec. 5.1]
            L_VT = L_HT;

            S_ht = TailL2.compute_S_HT(obj.C_HT, cbar, S_ref, L_HT);
            S_vt = TailL2.compute_S_VT(obj.C_VT, b, S_ref, L_VT);
            result = struct('S_ht', S_ht, 'S_vt', S_vt);
        end

        % ================================================================== %
        % LOW-LEVEL: scalars and strings only, no object access.
        % ================================================================== %

        function val = compute_S_HT(C_HT, cbar, S_ref, L_HT)
        %COMPUTE_S_HT  Horizontal-tail area [ft^2].
        %   [Nicolai & Carichner Eq. 11.2, solved for S_HT:
        %   C_HT = (l_HT*S_HT)/(cbar*S_ref)  =>  S_HT = C_HT*cbar*S_ref/l_HT]
            arguments
                C_HT  (1,1) double {mustBeNonnegative}
                cbar  (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
                L_HT  (1,1) double {mustBePositive}
            end
            val = C_HT * cbar * S_ref / L_HT;
        end

        function val = compute_S_VT(C_VT, b, S_ref, L_VT)
        %COMPUTE_S_VT  Vertical-tail area [ft^2].
        %   [Nicolai & Carichner Eq. 11.1, solved for S_VT:
        %   C_VT = (l_VT*S_VT)/(b*S_ref)  =>  S_VT = C_VT*b*S_ref/l_VT]
            arguments
                C_VT  (1,1) double {mustBeNonnegative}
                b     (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
                L_VT  (1,1) double {mustBePositive}
            end
            val = C_VT * b * S_ref / L_VT;
        end

    end
end
