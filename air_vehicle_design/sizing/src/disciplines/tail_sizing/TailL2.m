classdef TailL2
%TAILL2  Level-2 tail-sizing static toolbox: historical sizing estimates
%   from an F-16-specific measured volume coefficient and real L2 wing
%   geometry.
%
%   Call as TailL2.method(...); never instantiated. F16TailL2 inherits
%   TailSizingModelL2 and delegates to these statics.
%
%   METHOD -- same governing identity as TailL1's Raymer 7th ed. Table 6.4
%   form, algebraically identical to Nicolai & Carichner Eq. (11.1)/(11.2)
%   [11_tail_sizing.md Secs. 11.2-11.3, pp. 286, 289]:
%     C_VT = (l_VT*S_VT)/(b*S_ref)      ==>  S_VT = C_VT*b*S_ref/l_VT
%     C_HT = (l_HT*S_HT)/(cbar*S_ref)   ==>  S_HT = C_HT*cbar*S_ref/l_HT
%
%   COEFFICIENTS: Nicolai & Carichner Table 11.6, "General Dynamics F-16"
%   row, p.289 -- an F-16-specific measured coefficient, not a generic
%   category row: C_HT = 0.3, C_VT = 0.094. NOT the conflicting C_HT=0.68,
%   C_VT=0.041 that other digest files mis-transcribe from the same row
%   (VnV/BrandtF16A/todo.md Finding 1).
%
%   Tail moment arm carries L1's rule forward unchanged:
%     L_HT = L_VT = TailL1.compute_tail_arm(L_fus) = 0.475*L_fus
%   [Raymer 7th ed. text rule; GeometryModelL2 has no x-stations, so a
%   geometry-derived arm is not achievable at L2. Cross-toolbox reuse, not
%   a copy -- same idiom as AeroL1.oswald_eff.]
%
%   Area reuse is indirect: size(obj) returns struct('S_ht','S_vt') only.
%   The caller writes these back into the geometry object, whose Dependent
%   S_exposed_ht/S_wet_ht/... recompute automatically.
%
%   History and rationale: docs/decision_log.md;
%   TailSizing_scribe_plan.md Secs. 5.1/5.2. Companion doc: TailL2.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the concrete object, return the result.
        % ================================================================== %

        function result = size(obj)
        %SIZE  HT and VT reference areas [ft^2].  [Nicolai & Carichner
        %   Table 11.6 F-16 row; Raymer 7th ed. tail-arm text rule]  obj
        %   must expose C_HT/C_VT and an injected geom (see F16TailL2). Reads
        %   geom.b_wing, geom.cbar_wing, geom.S_ref, geom.L_fus live on every
        %   call (no cache). Returns struct('S_ht', S_ht, 'S_vt', S_vt).
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
            val = TailSizingBase.tail_volume_area(C_HT, cbar, S_ref, L_HT);
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
            val = TailSizingBase.tail_volume_area(C_VT, b, S_ref, L_VT);
        end

    end
end
