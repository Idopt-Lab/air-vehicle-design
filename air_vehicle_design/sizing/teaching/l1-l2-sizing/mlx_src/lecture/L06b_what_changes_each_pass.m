%[text] # L06b - What is actually changing?
%[text] **AOE 4065 - Aircraft Sizing, Lecture 6b of 8 (Boeing 777-200LR and F-16A)**
%[text] L06 showed that the Level-2 loop converges. It did not show **what moves while it converges**. This file opens the loop up and records about thirty quantities on every pass.
%[text] The question to answer first, because it is the one people get wrong: *the sizing problem has three outputs -* $W_{TO}$, $S_{ref}$, $T_{SL}$ *- so does the Level-2 loop iterate on three unknowns?*
%[text] **No. It iterates on two.**

%%
%[text] ## The three outputs, and what kind of thing each one is
%[text] The Live Editor does not render Markdown tables, so this one is a real MATLAB table instead.

kinds = table( ...
    ["STATE"; "STATE"; "SLAVED"], ...
    ["under-relaxed each pass from the weight closure"
     "under-relaxed each pass from (T/W)* * W_TO"
     "recomputed, never iterated: S_ref = W_TO / (W/S)*"], ...
    'VariableNames', ["Kind", "How_it_is_produced"], ...
    'RowNames', {'W_TO', 'T_SL', 'S_ref'})

%%
%[text] So all three **change** on every pass, but only two are unknowns. `SizingLoopL2` under-relaxes exactly two quantities and tests exactly two residuals. The wing area moves for two reasons at once: the weight it is carrying changes, **and** the design point it is being sized against changes. That second reason is what Level 1 does not have.
%[text] `trace_sizing_L2` is a replica of the loop body that records everything. It checks itself against `SizingLoopL2` at the end of every call and errors if the two have drifted apart, so what you see below is the real loop.

setup_sizing_path;
T16 = trace_sizing_L2(@build_f16_stack_L2, 30000, 20000);

head(T16(:, ["iter","W_TO","T_SL","S_ref","WS","TW","S_ht","S_vt"]), 6)

%%
%[text] ## Read the first three columns
%[text] $W_{TO}$ falls 30 000 $\rightarrow$ 23 279. $T_{SL}$ barely moves, 20 000 $\rightarrow$ 20 113. $S_{ref}$ falls 234 $\rightarrow$ 175.
%[text] Now look at columns 5 and 6. $(W/S)^{\ast}$ went from 129.5 to 133.0 and $(T/W)^{\ast}$ from 0.697 to **0.864**. The design point moved by 24 % in thrust-to-weight while the loop ran. **A Level-1 loop would have frozen it at the first value and sized the aeroplane against a design point that is 24 % wrong.**

%%
%[text] ## Twelve panels of the same run
%[text] Panel 4 is the one to point at: if that panel were flat, Level 1 would have been good enough. Panel 9 explains panel 10, and panel 10 explains panel 4.

plot_sizing_history(T16, "F-16A");

%%
%[text] ## The chain, in words
%[text] The wing shrinks, so the exposed and wetted areas shrink. But $S_{ref}$ shrinks **faster** than $S_{wet}$ does, because the fuselage and the inlet duct do not shrink at all. So the ratio $S_{wet}/S_{ref}$ **rises**, from 5.09 to 6.18. Parasite drag is $C_{D0} = C_{fe} S_{wet}/S_{ref}$, so $C_{D0}$ rises 21 %, $L/D_{max}$ falls from 11.0 to 9.9, every constraint curve lifts, and the design point demands more thrust.
%[text] That is a real conceptual-design effect and it is worth a minute of class time: **a smaller aeroplane is a draggier aeroplane, per unit of wing.** It is the reason fighters do not shrink indefinitely.

%%
%[text] ## The empty-weight build-up, pass by pass
%[text] The weights model is a component build-up, so we can watch each piece separately. Some move and some do not, and which is which tells you what the loop can and cannot trade against.

plot_weight_history(T16, "F-16A");

%%
%[text] **Read the bottom-right panel.** The tail loses 60 % and the wing 32 %, both because they are sized off areas the loop is changing. The landing gear and the "all else" group lose 22 %, exactly tracking $W_{TO}$, because they are fractions of gross weight. The **fuselage does not move at all** - it is a fixed input at this fidelity. The installed engine barely moves, because $T_{SL}$ barely moved.
%[text] A flat band is not a bug. It is a statement that the loop has no lever on that component, so any error in it passes straight through to $W_{OEW}$.

%%
%[text] ## One chart that answers the question
%[text] Every traced quantity, as a percentage change from the first pass to the last. Colour says what kind of thing it is.

[~, S16] = plot_what_changed(T16, "F-16A, SizingLoopL2");
S16

%%
%[text] ## Now the same for the 777, and a difference worth catching
%[text] The transport behaves differently, and one row of the table is a genuine finding about the model rather than about the aeroplane.

T77 = trace_sizing_L2(@build_b777_stack, 700000, 200000, 'state', AircraftState(40000, 0.85));
[~, S77] = plot_what_changed(T77, "B777-200LR, SizingLoopL2");
S77

%%
%[text] ## The 777 tail is written, and never read
%[text] Look for `S_ht` and `S_vt` in that table: both move about +8.8 %. Now look for `S_exp_ht`, `S_exp_vt` and `W_tail`: all three say **did not move**.
%[text] So on the 777 the tail-sizing step writes `geom.S_ht` and `geom.S_vt` every pass, and **nothing downstream reads them**. `B777GeomL2` derives its exposed tail areas from the fixed Chapter-7 trapezoids, not from the loop-written reference areas. Its own header says so: *the HT/VT trapezoids are held at their Table 7.2 baseline; S\_ht/S\_vt remain the tail-sizing write-back slots.*
%[text] On the F-16 the same step is fully coupled: `S_ht` $\rightarrow$ chords and span $\rightarrow$ exposed area $\rightarrow$ wetted area and tail weight $\rightarrow$ $C_{D0}$ and $W_{OEW}$.

tail_test = compare_tail_coupling();
tail_test

%%
%[text] **Why this matters for the lecture.** In L06 the honest claim is: *Level 2 sizes the tail and Level 1 cannot.* That is true for both aircraft. The stronger claim - *and the empty weight sees the new tail* - is true for the **F-16 only**. On the 777 the tail areas are reported, not consumed.
%[text] It is also a good illustration of why you trace a loop instead of trusting it. Both aircraft converge, both look healthy, and only one of them has the coupling you assumed.

%%
%[text] ## Summary
%[text] - Two states, $W_{TO}$ and $T_{SL}$. $S_{ref}$ is slaved to them and to the design point.
%[text] - The design point is the third moving part, and it is what separates Level 2 from Level 1. On the F-16 it moved 24 % in $(T/W)^{\ast}$.
%[text] - Shrinking the wing raises $S_{wet}/S_{ref}$, so it raises $C_{D0}$. Smaller is draggier.
%[text] - In the weight build-up, wing and tail track the areas, gear and "all else" track gross weight, and the fuselage does not move.
%[text] - On the 777, the tail resize is write-only. Trace before you trust. \

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

function T = compare_tail_coupling()
%COMPARE_TAIL_COUPLING  Double geom.S_ht on each aircraft; see what follows.
    [~, ~, w7, g7, ~, ~, t7] = build_b777_stack();
    r = t7.size(); g7.S_ht = r.S_ht; g7.S_vt = r.S_vt; w7.W_TO = 740000;
    a0 = [g7.S_exposed_ht; g7.S_wet; w7.W_tail.HT; w7.get_OEW(740000)];
    g7.S_ht = 2*r.S_ht;
    a1 = [g7.S_exposed_ht; g7.S_wet; w7.W_tail.HT; w7.get_OEW(740000)];

    [~, ~, w6, g6, ~, ~, t6] = build_f16_stack_L2();
    r6 = t6.size(); g6.S_ht = r6.S_ht; g6.S_vt = r6.S_vt; w6.W_TO = 23000;
    b0 = [g6.S_exposed_ht; g6.S_wet; w6.W_tail.HT; w6.get_OEW(23000)];
    g6.S_ht = 2*r6.S_ht;
    b1 = [g6.S_exposed_ht; g6.S_wet; w6.W_tail.HT; w6.get_OEW(23000)];

    T = table(100*(a1-a0)./a0, 100*(b1-b0)./b0, ...
        'VariableNames', ["B777_pct", "F16A_pct"], 'RowNames', ...
        {'geom.S_exposed_ht', 'geom.S_wet', 'wts.W_tail.HT', 'wts.get_OEW'});
    T.Properties.Description = 'percent change when geom.S_ht is doubled';
end
