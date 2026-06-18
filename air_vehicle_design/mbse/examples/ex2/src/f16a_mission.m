clear; clc; close all;

in2ft = 0.0833333;
in2m = 0.0254;
lbf2N = 4.44822;
mps2ftphr = 11811;
kgpm32slugpft3 = 0.00194;
kgpm32lbmpft3 = 0.0624;
ft2m = 0.3048;
lbmphr2lbmps = 0.000277778;
lbf2lbm = 32.174;

lbmphr2kgps = 0.000125998;
kgphr2kgps = 0.000277778;

% Mission segments
MissionSegment = ["Acceleration", "Climb", "Cruise", "Dash", "Combat", "Egress", "Climb", "Cruise", "Loiter"];
beta = [0.950914744, 0.938892236, 0.924578603, 0.892603709, 0.877176645, 0.718970787, 0.709264431, 0.684104494, 0.668533248];
altitude_ft = [10000, 20000, 40000, 40000, 25000, 30000, 35000, 40000, 10000];
Mach        = [0.87 , 0.87 , 0.87 , 1.6  , 1.2  , 0.87 , 0.87 , 0.87 , 0.87];
time_min = [2.256075454, 1.046635351, 26.57369484, 3.27154543, 2, 5.854499819, 0.772238304, 29.30891371, 20];


CD0= [0.026995734, 0.026995734, 0.026995734, 0.049316997, 0.052390397, 0.016995734, 0.016995734	0.016995734, 0.016995734];
k1 = [0.116031446, 0.116031446, 0.116031446, 0.276030901, 0.169663712, 0.116031446, 0.116031446	0.116031446	0.116031446];
k2 = [-0.006301925, -0.006301925, -0.006301925, 0, 0, -0.006301925, -0.006301925, -0.006301925	-0.006301925];

drag_lbf = [3576.093055, 4629.898566, 2944.971605, 11313.51539, 12741.45841, 2053.606518, 1826.721158, 1655.217207, 1904.966191];


mission = table(MissionSegment', beta', altitude_ft', Mach', time_min', drag_lbf', ...
    'VariableNames', {'MissionSegment', 'beta', 'Altitude (ft)', 'Mach', 'Time (min)', 'Drag (lbf)'});


%% Check that thrust available (dry or AB) is greater than thrust required (drag)

[T_dry_lbf, T_AB_lbf, TSFC_dry, TSFC_AB] = f100_engine_model(altitude_ft, Mach);

check1 = T_dry_lbf > drag_lbf;
check2 = T_AB_lbf  > drag_lbf;
thrust_drag_check = min(check1 | check2)

%% Engine

% https://www.prattwhitney.com/en/products/military-engines/f100
% Find the area of the engine using the maximum diameter
d_eng_m = 46.5*in2m;
A_eng_m2 = pi*d_eng_m^2/4;

%%

fuel_flow_rate_kgps = zeros(1, length(drag_lbf));
area_ifty_m2 = zeros(1, length(drag_lbf));

for i = 1 : length(drag_lbf)

    [T_dry_lbf, T_AB_lbf, TSFC_dry_phr, TSFC_AB_phr] = f100_engine_model(altitude_ft(i), Mach(i));
    if T_dry_lbf>drag_lbf(i)
        fuel_flow_rate_kgps(i) = drag_lbf(i) * TSFC_dry_phr * lbmphr2kgps;
    else
        fuel_flow_rate_kgps(i) = drag_lbf(i) * TSFC_AB_phr * lbmphr2kgps;
    end

    [T_K,a_mps,P_Pa,rho_kgpm3,nu_m2p3,mu_kgps] = atmosisa(altitude_ft(i)*ft2m);
    area_ifty_m2(i) = ( fuel_flow_rate_kgps(i) + 0.05*fuel_flow_rate_kgps(i) )*lbf2lbm / ((rho_kgpm3*(Mach(i)*a_mps)));

end

Ac = max(area_ifty_m2) + 0.04*max(area_ifty_m2);
Ac < A_eng_m2

fuel_burn_kg = sum(fuel_flow_rate_kgps .* (time_min*60))

%% F100 Simulator data at h=0 and M=0
% throttles = [0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];
% T_dry = [0, 1963, 3896, 6279, 9259, 12494, 17464, 22918].*0.6545;
% p = polyfit(throttles,T_dry,2);
% y1 = polyval(p,throttles);
% plot(throttles, T_dry)
% hold on
% plot(throttles, y1)

f100_throttle_setting = [59  , 68  , 70  , 81   , 73.8 , 55.5, 55  , 57  , 49.4];  % To get to around the same drag
f100_fuel_flow_lbphr  = [2824, 3612, 2199, 18912, 22215, 1506, 1296, 1164, 1493];
f100_fuel_flow_kgps = f100_fuel_flow_lbphr * 0.000125998;

fuel_flow_rate_kgps
f100_fuel_flow_kgps
