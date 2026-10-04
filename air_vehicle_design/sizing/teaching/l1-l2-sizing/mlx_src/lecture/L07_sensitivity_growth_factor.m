%[text] # L07 - Growth factor: what a requirement really costs
%[text] **AOE 4065 - Aircraft Sizing, Lecture 7 of 7 (Boeing 777-200LR)**
%[text] Add one pound of payload to a sized aircraft and the takeoff weight does **not** go up by one pound. It goes up by several. More payload needs more weight, which needs a bigger wing and a bigger engine, which weigh more, which need more fuel, which weighs more. The loop settles at a new, heavier fixed point.
%[text] The amplification is the **growth factor**, and it is the single most useful number conceptual design produces. It tells you which requirements are expensive and which are free.

%%
%[text] ## Read it straight off the closure
%[text] Start from the closure equation,
%[text] $W_{TO} = \frac{W_{payload}}{1 - W_{empty}/W_{TO} - W_{fuel}/W_{TO}}$
%[text] If the two fractions held still, the growth factor would be exactly $1/\mathrm{denom}$. They do not hold still, so treat that as a first look and not an answer.

setup_sizing_path;
[aero, prop, wts, geom, miss, con, tail] = build_b777_stack();
r0 = SizingLoopL2(aero, prop, wts, geom, miss, con, tail).run(700000, 200000);
denom = 1 - r0.W_OEW/r0.W_TO - r0.W_fuel/r0.W_TO;

first_look = table([r0.W_OEW/r0.W_TO; r0.W_fuel/r0.W_TO; denom; 1/denom], ...
    'VariableNames', "Value", 'RowNames', ...
    {'empty fraction', 'fuel fraction', 'denominator', ...
     'growth factor IF the fractions were frozen, 1/denom'})

%%
%[text] ## Measure it properly: re-size with more payload
%[text] The honest way is to change the payload and run the whole loop again.

dW = 5000;                          % lbf of extra payload
s  = build_b777_stack_s();
s.wts.W_payload_fixed = s.wts.W_payload_fixed + dW;
r1 = SizingLoopL2(s.aero, s.prop, s.wts, s.geom, s.miss, s.con, s.tail).run(700000, 200000);

growth = table([r0.W_TO; r1.W_TO; r1.W_TO - r0.W_TO; (r1.W_TO - r0.W_TO)/dW; 1/denom], ...
    'VariableNames', "Value", 'RowNames', ...
    {'W_TO baseline [lbf]', 'W_TO with extra payload [lbf]', ...
     'change in W_TO [lbf]', 'GROWTH FACTOR, lbf of W_TO per lbf of payload', ...
     'compare: the frozen-fraction estimate 1/denom'})

%%
%[text] ## The frozen-fraction estimate is not the answer
%[text] The measured growth factor comes out well **below** $1/\mathrm{denom}$. That is not a mistake in either number; it is the loop doing something the frozen estimate cannot see.
%[text] Go back to the table in L04 and follow the `denom` column against `W_TO_in`: 0.074 at 630,000 lbf, 0.107 at 740,000 lbf, 0.164 at 1,070,000 lbf. For this aircraft the denominator **grows** as the aeroplane grows, because the empty and fuel fractions both fall slightly with size. Each pound of growth therefore buys a little less growth than the pound before it, and the runaway damps itself.
%[text] Keep $1/\mathrm{denom}$ anyway, as a warning light. A design with a small denominator is a design where the empty weight and the fuel between them have eaten nearly the whole aircraft, and it will be violently sensitive to everything.

%%
%[text] ## Which requirements are expensive?
%[text] Now nudge four different inputs by the same 10 % and re-size each time. Each knob is a small function that mutates a fresh stack, so you can see exactly what is being changed.
%[text] - **payload** - a requirement
%[text] - **cruise range** - a requirement
%[text] - **cruise TSFC** - an engine technology level
%[text] - **skin-friction coefficient** $C_{fe}$ - an aerodynamic cleanliness level \
%[text] This takes a couple of minutes: eight full sizing solves.

knobs = { ...
    "payload",              @(s, f) setfield_payload(s, f)      ; ...
    "cruise range",         @(s, f) setfield_range(s, f)        ; ...
    "cruise TSFC",          @(s, f) setfield_tsfc(s, f)         ; ...
    "skin friction C_fe",   @(s, f) setfield_cfe(s, f)          };

runFcn = @(s) SizingLoopL2(s.aero, s.prop, s.wts, s.geom, s.miss, s.con, s.tail) ...
                 .run(700000, 200000);

[sens, ~] = sizing_sensitivity(@build_b777_stack_s, runFcn, knobs, 10);
sens

%%
%[text] ## Put it in elasticities
%[text] Divide each result by the 10 % input change and you get an **elasticity**: percent change in takeoff weight per percent change in the input. Now the four knobs are directly comparable.

elasticity = table(sens.Input, sens.pct_change_high/10, sens.pct_change_low/(-10), ...
    'VariableNames', ["Input", "elasticity_up", "elasticity_down"])

%%
%[text] ## Read the tornado
%[text] For this aircraft, **cruise range and cruise TSFC both come out near 1.0**. A one percent longer mission, or a one percent thirstier engine, buys a one percent heavier aeroplane. Those are the two expensive knobs, and they are the ones worth an argument with the customer or with the engine supplier.
%[text] **Payload comes out near 0.35**, well under one. That is not a contradiction of the growth factor above: each *pound* of payload still costs 3.3 lbf of aircraft, but payload is only about 11 % of the takeoff weight to begin with, so ten percent of it is not many pounds. Growth factor and elasticity answer different questions - one per pound, one per percent - and you need both.
%[text] Two more things to take away:
%[text] - The chart is not symmetric. Read the up and down bars separately; the loop is nonlinear, and the closure denominator moves as the aircraft resizes.
%[text] - Technology knobs ($TSFC$, $C_{fe}$) and requirement knobs (payload, range) land on the same axis in the same units. That is how conceptual design decides whether to buy a better engine or to renegotiate the mission. \

%%
%[text] ## End of the walkthrough
%[text] What we did: built a discipline stack (L01), turned requirements into a design point (L02), got a fuel fraction and an empty weight (L03), closed the weight once by hand (L04), let the Level-1 loop run it to convergence (L05), freed the frozen assumption with the Level-2 loop (L06), and measured what the requirements cost (L07).
%[text] Next class you write the Level-2 loop yourself, for the F-16A. Start with `lab/LAB00_warmup_L1_loop.mlx`.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---

function setfield_payload(s, f)
    s.wts.W_payload_fixed = s.wts.W_payload_fixed * (1 + f);
end

function setfield_range(s, f)
    for k = 1:numel(s.miss.segments)
        seg = s.miss.segments{k};
        if isprop(seg, 'distance_nm') && seg.distance_nm > 0
            seg.distance_nm = seg.distance_nm * (1 + f);
        end
    end
end

function setfield_tsfc(s, f)
    s.prop.tsfc_cruise = s.prop.tsfc_cruise * (1 + f);
end

function setfield_cfe(s, f)
    s.aero.Cfe = s.aero.Cfe * (1 + f);
end
