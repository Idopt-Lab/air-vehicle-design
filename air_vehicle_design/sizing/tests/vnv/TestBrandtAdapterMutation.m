classdef TestBrandtAdapterMutation < matlab.unittest.TestCase
%TESTBRANDTADAPTERMUTATION  Unit tests for the mutation-capable Brandt
%   adapter layer (2026-08-13 sizing pass):
%     VnV/BrandtF16A/BrandtMissionGeomAdapter.m  (settable S_ref/S_ht/S_vt,
%         dependents re-analysis, derived b_wing/cbar_wing/L_fus)
%     VnV/BrandtF16A/BrandtPropAdapter.m         (settable T_SL, rubber scale)
%     VnV/BrandtF16A/BrandtWeightAdapter.m       (WeightsBase OEW wrapper)
%
%   Each test builds a FRESH Brandt stack (handle objects; no shared state
%   between tests).
%
%   HAND-COMPUTED EXPECTED VALUES
%   -----------------------------
%   (1) OEW ground truth [Brandt Wt!B12]:
%         OEW(31,377) = 19,980.70 lbf.
%       RelTol 1e-3: BrandtWeight's only documented deviation is the nacelle
%       area using pi instead of Excel's 3.1516 (BrandtWeight.m header,
%       "DISCREPANCIES"). W_nacelles(GT) = 186.82 lbf; the deviation
%       propagates through W_inlet = 3.9x and W_other = 0.3x, i.e. x5.2,
%       giving |dOEW| ~ 186.82*(1 - pi/3.1516)*5.2 ~ 3 lbf ~ 0.016 % -- well
%       inside 1e-3.
%   (2) Payload split [Brandt Main!O16/O17]: 700 lbf fixed, 4,400 lbf
%       expendable, EXACT (read straight from the input JSON).
%   (3) Thrust mutation, T_SL: 23,770 -> 47,540 lbf (x2):
%       - All thrust lapses INVARIANT: the Engn(s)-tab alphas are pure
%         ratios T/T_sl, and set.T_SL scales T_sl_dry and T_sl_AB by the
%         same factor (dry/AB ratio preserved), so
%         alpha_AB_ref = T_total/T_sl_AB is unchanged at every state.
%       - T_sl_dry: 15,000 -> 30,000 lbf (same x2 scale).
%       - dOEW = 0.199 * (47,540 - 23,770) = 0.199 * 23,770 = 4,730.23 lbf
%         EXACTLY [Brandt Wt!B11: W_engine = 0.199*T_AB_SLS]. The inlet-duct
%         chain (W_nacelles = 4.5*Geom!B4 [Wt!G9], W_inlet = 3.9*W_nacelles
%         [Wt!B24], W_other = 0.3*W_structure [Wt!B29]) does NOT move: the
%         nacelle is sized from BrandtGeometry.inp.engine.T_AB_SLS_lb, a
%         field BrandtPropAdapter deliberately does not touch (thrust
%         ownership, BrandtPropAdapter header). The inlet-duct delta is
%         therefore ZERO BY WIRING at this adapter layer -- a documented
%         limitation, not a bug in this test.
%   (4) Tail mutation, S_ht: 108 -> 120 ft^2:
%         dOEW = k_pitch * dS * (1 + 0.30) = 6.0 * 12 * 1.3 = 93.6 lbf EXACT.
%       [Wt!E9: W_pitch = 6.0*S_ht; Wt!B29: W_other = 0.30*W_structure,
%       which contains W_pitch. No other weight term reads S_ht: the pitch
%       S_wet feeds aerodynamics, not the Wt tab.]
%   (5) Geometry round-trip, S_ref: 300 -> 330 -> 300 ft^2:
%       - S_wet INCREASES at 330 (wing exposed planform grows with S_ref;
%         S_wet_wing = S_exposed*(1.977 + 0.52*t/c), Geom!B14 basis).
%       - OEW INCREASES at 330: W_wing is linear in S_ref [Wt!C9],
%         dW_wing ~ 1,785.95*(30/300) = +178.6 lbf, which dominates the
%         controls LE-flap term 6.75*200*21.314*(1/330 - 1/300) = -8.7 lbf
%         [Wt!B25].
%       - aero CD0 CHANGES (coherence: reanalyze_ re-syncs aero's private
%         inp copy, so CD0 = Cfe*S_wet/S_ref uses BOTH new values).
%       - Restoring 300 returns every recorded value to its original within
%         RelTol 1e-10 (analyze() is a deterministic pure recompute).
%   (6) Derived geometry getters at stock inputs (JSON: S_ref = 300, AR = 3,
%       taper lambda = 0.2275, L_fus = 46.5, S_ht = 108, S_vt = 60):
%         b_wing    = sqrt(300*3) = 30 ft (definitional, AR = b^2/S)
%         cbar_wing = (4S/(3b)) * (1+lambda+lambda^2)/(1+lambda)^2
%                   = 13.3333333 * (1.27925625/1.50675625)
%                   = 13.3333333 * 0.8490134022 = 11.3201787 ft
%                   [Raymer 7th ed. Eq. 7.8 via GeometryBase.compute_mac]
%         L_fus     = 46.5 ft (input passthrough, Main!B32)

    properties (Constant)
        W_TO_GT       = 31377        % lbf  Brandt sizing-point gross weight
        OEW_GT        = 19980.70     % lbf  Brandt Wt!B12
        T_AB_STOCK    = 23770        % lbf  Brandt Engn!T_AB_SLS
        T_DRY_STOCK   = 15000        % lbf  Brandt Engn!T_mil_SLS
        DOEW_THRUST   = 0.199*23770  % lbf  = 4,730.23 (hand calc (3))
        DOEW_TAIL     = 93.6         % lbf  hand calc (4)
        CBAR_WING_GT  = 11.3201787   % ft   hand calc (6)
    end

    methods (Access = private)

        function [gA, pA, wA, aA] = buildStack_(~)
        %BUILDSTACK_  Fresh Brandt stack + adapters, dependents registered.
            bg = BrandtGeometry();        bg.analyze();
            be = BrandtEngine();          be.analyze();
            ba = BrandtAerodynamics(bg);  ba.analyze();
            bw = BrandtWeight(bg);        bw.analyze();

            gA = BrandtMissionGeomAdapter(bg);
            gA.dependents = {ba, bw};     % re-analyze order: aero, then weight
            pA = BrandtPropAdapter(be);
            wA = BrandtWeightAdapter(bw, be);
            aA = BrandtAeroAdapter(ba);
        end

    end

    methods (Test)

        function testOEWGroundTruth(tc)
        % Hand calc (1): OEW(31,377) = 19,980.70 lbf [Brandt Wt!B12].
            [~, ~, wA, ~] = tc.buildStack_();
            oew = wA.OEW(tc.W_TO_GT);
            tc.verifyEqual(oew, tc.OEW_GT, 'RelTol', 1e-3, ...
                'OEW(31377) must reproduce Brandt Wt!B12 (pi-vs-3.1516 nacelle deviation ~0.016 %).');
        end

        function testPayloadProperties(tc)
        % Hand calc (2): payload split 700 / 4,400 lbf, exact JSON reads.
            [~, ~, wA, ~] = tc.buildStack_();
            tc.verifyEqual(wA.W_payload_fixed, 700, ...
                'W_payload_fixed must equal Brandt Main!O16 exactly.');
            tc.verifyEqual(wA.W_payload_expendable, 4400, ...
                'W_payload_expendable must equal Brandt Main!O17 exactly.');
        end

        function testGeometryMutationRoundTrip(tc)
        % Hand calc (5): S_ref 300 -> 330 -> 300 round trip.
            [gA, ~, wA, aA] = tc.buildStack_();
            state = AircraftState(30000, 0.9);

            S_wet0 = gA.get_S_wet();
            oew0   = wA.OEW(tc.W_TO_GT);
            polar0 = aA.drag_polar(state);

            gA.S_ref = 330;
            S_wet1 = gA.get_S_wet();
            oew1   = wA.OEW(tc.W_TO_GT);
            polar1 = aA.drag_polar(state);

            tc.verifyEqual(gA.S_ref, 330, 'S_ref must read back the mutated value.');
            tc.verifyGreaterThan(S_wet1, S_wet0, ...
                'S_wet must increase with S_ref (wing exposed planform grows).');
            tc.verifyGreaterThan(oew1, oew0, ...
                'OEW must increase with S_ref (W_wing linear in S_ref, Wt!C9).');
            tc.verifyGreaterThan(abs(polar1.CD0 - polar0.CD0), 1e-5, ...
                'Aero CD0 must move with the geometry mutation (dependents re-sync).');

            gA.S_ref = 300;
            tc.verifyEqual(gA.get_S_wet(), S_wet0, 'RelTol', 1e-10, ...
                'S_wet must return to the original after restoring S_ref (pure recompute).');
            tc.verifyEqual(wA.OEW(tc.W_TO_GT), oew0, 'RelTol', 1e-10, ...
                'OEW must return to the original after restoring S_ref (pure recompute).');
            polar2 = aA.drag_polar(state);
            tc.verifyEqual(polar2.CD0, polar0.CD0, 'RelTol', 1e-10, ...
                'Aero CD0 must return to the original after restoring S_ref.');
        end

        function testThrustMutation(tc)
        % Hand calc (3): T_SL x2 -> lapses invariant, dOEW = 4,730.23 lbf.
            [~, pA, wA, ~] = tc.buildStack_();
            states = {AircraftState(30000, 0.9), AircraftState(0, 0.4)};

            oew1 = wA.OEW(tc.W_TO_GT);
            alpha_AB0  = cellfun(@(s) pA.thrust_lapse(s), states);
            alpha_mil0 = cellfun(@(s) pA.thrust_lapse_mil_on_AB_scale(s), states);

            pA.T_SL = 2 * tc.T_AB_STOCK;

            tc.verifyEqual(pA.T_SL, 2*tc.T_AB_STOCK, ...
                'T_SL must read back the mutated AB SLS thrust.');
            tc.verifyEqual(pA.brandtEng.T_sl_dry, 2*tc.T_DRY_STOCK, ...
                'RelTol', 1e-12, ...
                'T_sl_dry must scale by the same factor (dry/AB ratio preserved).');

            alpha_AB1  = cellfun(@(s) pA.thrust_lapse(s), states);
            alpha_mil1 = cellfun(@(s) pA.thrust_lapse_mil_on_AB_scale(s), states);
            tc.verifyEqual(alpha_AB1, alpha_AB0, 'RelTol', 1e-12, ...
                'AB thrust lapse must be invariant under the ratio-preserving rubber scale.');
            tc.verifyEqual(alpha_mil1, alpha_mil0, 'RelTol', 1e-12, ...
                'Mil-on-AB thrust lapse must be invariant under the ratio-preserving rubber scale.');

            oew2 = wA.OEW(tc.W_TO_GT);
            tc.verifyEqual(oew2 - oew1, tc.DOEW_THRUST, 'RelTol', 1e-9, ...
                'dOEW must equal 0.199*dT exactly (Wt!B11; inlet-duct chain fixed by wiring, see header (3)).');
        end

        function testTailMutation(tc)
        % Hand calc (4): S_ht 108 -> 120, dOEW = 6.0*12*1.3 = 93.6 lbf.
            [gA, ~, wA, ~] = tc.buildStack_();

            oew0 = wA.OEW(tc.W_TO_GT);
            gA.S_ht = 120;
            oew1 = wA.OEW(tc.W_TO_GT);

            tc.verifyEqual(gA.S_ht, 120, 'S_ht must read back the mutated value.');
            tc.verifyGreaterThan(oew1, oew0, ...
                'OEW must increase with S_ht (W_pitch = 6.0*S_ht, Wt!E9).');
            tc.verifyEqual(oew1 - oew0, tc.DOEW_TAIL, 'RelTol', 1e-9, ...
                'dOEW must equal k_pitch*dS*(1+0.30) = 93.6 lbf (Wt!E9 + Wt!B29).');

            gA.S_ht = 108;
            tc.verifyEqual(wA.OEW(tc.W_TO_GT), oew0, 'RelTol', 1e-10, ...
                'OEW must return to the original after restoring S_ht (pure recompute).');
        end

        function testDerivedGeometryGetters(tc)
        % Hand calc (6): derived reads at stock inputs.
            [gA, ~, ~, ~] = tc.buildStack_();
            tc.verifyEqual(gA.b_wing, 30, 'RelTol', 1e-12, ...
                'b_wing = sqrt(S_ref*AR) = sqrt(900) = 30 ft.');
            tc.verifyEqual(gA.cbar_wing, tc.CBAR_WING_GT, 'RelTol', 1e-6, ...
                'cbar_wing must match the Raymer Eq. 7.8 hand computation (header (6)).');
            tc.verifyEqual(gA.L_fus, 46.5, ...
                'L_fus is an input passthrough (Main!B32 = 46.5 ft).');
            tc.verifyEqual(gA.S_ht, 108, 'S_ht stock read (Main!C18).');
            tc.verifyEqual(gA.S_vt, 60,  'S_vt stock read (Main!H18).');
        end

        function testSetterValidation(tc)
        % Mutation setters must reject non-physical values.
            [gA, pA, ~, ~] = tc.buildStack_();
            tc.verifyError(@() setS_(gA, -5), ...
                'BrandtMissionGeomAdapter:invalidInput', ...
                'Negative S_ref must be rejected.');
            tc.verifyError(@() setT_(pA, 0), ...
                'BrandtPropAdapter:invalidThrust', ...
                'Zero T_SL must be rejected.');
            function setS_(g, v), g.S_ref = v; end
            function setT_(p, v), p.T_SL = v; end
        end

    end

end
