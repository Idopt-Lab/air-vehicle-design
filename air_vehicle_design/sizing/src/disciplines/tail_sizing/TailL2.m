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
%   TAIL MOMENT ARM -- NICOLAI'S OWN c.g.-REFERENCED DEFINITION
%   (CHANGED 2026-08-11; it used to carry forward L1's 0.475*L_fus fraction,
%   which was a Raymer rule of thumb standing in for a quantity Nicolai
%   defines differently, and which for the F-16A overstates the real arm by
%   ~46 %). GeometryModelL2 now carries x_apex_wing/x_le_ht/x_le_vt
%   [Brandt Main!B23/C23/H23 -- the SAME cells GeometryModelL3 already
%   used] and the Dependent mac quarter-chord stations built from them, so
%   the arm Eqs. (11.1)/(11.2) actually ask for IS achievable at L2:
%
%     x_cg,init = x_MAC_LE,wing + 0.30*cbar_wing
%     l_HT      = x_c/4,HT - x_cg,init
%     l_VT      = x_c/4,VT - x_cg,init
%
%   [Nicolai & Carichner Eqs. (11.1)/(11.2), pp.286/289: l_VT/l_HT is the
%   "distance from initial c.g. estimate to quarter-chord of the [tail] mac"
%   (Fig. 11.1, p.285). The initial c.g. estimate is Chapter 8's, which
%   Sec. 11.1 (p.284) cites by name: Nicolai & Carichner p.212 -- "Locate the
%   wing so the c.g. is at ~30% of the wing mean aerodynamic chord (refined
%   later)". See TailL2.compute_x_cg_initial.]
%
%   WHY NOT THE FRAMEWORK'S COMPUTED c.g. (F16SandCL2/L3's x_cg): because
%   Nicolai Sec. 11.1, p.284 states the circularity outright -- "Sizing tail
%   surfaces requires precise knowledge of c.g. location ..., but c.g.
%   location depends on knowing tail-surface weight (size) -- a circular
%   dependency. Thus tail surfaces are sized here via a shortcut: the tail
%   volume coefficient approach". Feeding a converged component-buildup c.g.
%   back into the sizer restores exactly the loop the method exists to break,
%   and the coefficients in Table 11.6 were not measured against one either.
%   The 30 %-mac station is Nicolai's own stated stand-in, and it is a LAYOUT
%   rule (the wing is positioned to put the c.g. there), not an estimate of a
%   computed number.
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
        %   [Nicolai & Carichner Eqs. (11.1)/(11.2) + Table 11.6 F-16 row;
        %   c.g.-referenced moment arm per Eq. (11.1)/(11.2)'s own definition
        %   and Nicolai Ch. 8's initial-c.g. rule]  obj must expose C_HT/C_VT
        %   and an injected geom (1,1) GeometryModelL2 -- see F16TailL2.
        %   Reads geom.S_ref, geom.b_wing, geom.cbar_wing, geom.x_mac_le_wing,
        %   geom.x_c4_ht and geom.x_c4_vt LIVE on every call, so a mutated
        %   geometry object is reflected immediately -- no cached copy.
        %   geom.L_fus is no longer read at all: the arm is now a real
        %   station-to-station distance, not a fraction of it (2026-08-11).
        %   Returns struct('S_ht', S_ht, 'S_vt', S_vt).
            S_ref = obj.geom.S_ref;
            b     = obj.geom.b_wing;
            cbar  = obj.geom.cbar_wing;

            x_cg = TailL2.compute_x_cg_initial(obj.geom.x_mac_le_wing, cbar);
            L_HT = TailL2.compute_tail_arm_cg(obj.geom.x_c4_ht, x_cg);
            L_VT = TailL2.compute_tail_arm_cg(obj.geom.x_c4_vt, x_cg);

            S_ht = TailL2.compute_S_HT(obj.C_HT, cbar, S_ref, L_HT);
            S_vt = TailL2.compute_S_VT(obj.C_VT, b, S_ref, L_VT);
            result = struct('S_ht', S_ht, 'S_vt', S_vt);
        end

        % ================================================================== %
        % LOW-LEVEL: scalars and strings only, no object access.
        % ================================================================== %

        function x_cg = compute_x_cg_initial(x_mac_le_wing, cbar_wing)
        %COMPUTE_X_CG_INITIAL  The INITIAL c.g. estimate [ft] that Nicolai's
        %   tail moment arm is measured from, placed at 30 % of the wing mean
        %   aerodynamic chord:
        %     x_cg,init = x_MAC_LE,wing + 0.30 * cbar_wing
        %
        %   [Nicolai & Carichner, Ch. 8, p.212: "Determine initial c.g.:
        %   assign a weight to every item except fuselage, wing, and
        %   wing-mounted items ..., find the c.g. of that ensemble ... Locate
        %   the wing so the c.g. is at ~30% of the wing mean aerodynamic chord
        %   (refined later)."  Sec. 11.1, p.284, is what points Eqs. (11.1)/
        %   (11.2) at this specific estimate: it names "the initial c.g.
        %   location (Chapter 8)".]
        %
        %   Read the direction of that Chapter-8 rule carefully: it is a
        %   LAYOUT decision, not a prediction. The wing is POSITIONED so the
        %   c.g. lands at 0.30*cbar; the station is therefore an input to the
        %   layout, and using it here does not re-create the tail-size/c.g.
        %   circularity Sec. 11.1 warns about. Raymer's equivalent reference
        %   is 0.25*cbar (Sec. 6.5.2, p.158 -- see
        %   TailL1.compute_tail_arm_quarter_chord); the two differ by
        %   0.05*cbar, 0.57 ft for the F-16A, ~3.9 % of the arm.
        %
        %   The 0.30 is Nicolai's printed figure and is NOT tunable here: any
        %   other value would no longer be the reference his Table 11.1-11.8
        %   coefficients are tabulated against.
            arguments
                x_mac_le_wing (1,1) double {mustBeReal}
                cbar_wing     (1,1) double {mustBePositive}
            end
            x_cg = x_mac_le_wing + 0.30 * cbar_wing;
        end

        function L = compute_tail_arm_cg(x_c4_tail, x_cg)
        %COMPUTE_TAIL_ARM_CG  Tail moment arm [ft], Nicolai's definition:
        %   initial c.g. estimate to the quarter-chord of the tail mac.
        %   [Nicolai & Carichner, Eq. (11.1) p.286 (vertical) and Eq. (11.2)
        %   p.289 (horizontal); Fig. 11.1, p.285, draws both]
        %
        %     l = x_c/4,tail - x_cg,init
        %
        %   Distinct from TailL1.compute_tail_arm_quarter_chord (Raymer's
        %   wing-c/4 reference) ONLY in where the arm starts. Both are
        %   implemented, separately named and separately cited, because each
        %   belongs to its own volume-coefficient table: a Nicolai Table 11.6
        %   coefficient must be used with a Nicolai arm and a Raymer Table 6.4
        %   coefficient with a Raymer arm, or the coefficient is being applied
        %   against a reference it was not tabulated on.
            arguments
                x_c4_tail (1,1) double {mustBeReal}
                x_cg      (1,1) double {mustBeReal}
            end
            L = x_c4_tail - x_cg;
            if L <= 0
                error('TailL2:nonPositiveTailArm', ...
                    ['Tail mac quarter-chord (%.4f ft) is not aft of the ' ...
                     'initial c.g. estimate (%.4f ft), so the aft-tail moment ' ...
                     'arm is %.4f ft. Nicolai Eqs. (11.1)/(11.2) divide by it. ' ...
                     'A forward surface is a canard and needs Eq. (11.3), not ' ...
                     'this method.'], x_c4_tail, x_cg, L);
            end
        end

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
