Wto_S_range = 20:7:160;
% Constraint data (Max Mach row from table)
B = 0.899666;
CD0 = 0.039317;
K1 = 0.213727;
alpha_dry = 0.298293;
alpha_AB = 0.57698;

% Engine thrust
T_min = 15000; % lb (dry thrust)
T_max = 23770; % lb (max AB thrust)
AB_percent = 1.0; % 100% afterburner for max Mach

% Flight condition
Mach = 1.6; % max Mach requirement
h = 36000; % altitude [ft]

% Standard atmosphere at 36,000 ft
a = 968.1; % speed of sound [ft/s] at 36k ft (approx ISA)
rho = 0.000889; % density [slugs/ft^3] at 36k ft
V = Mach * a; % ft/s
q = 0.5 * rho * V^2; % psf

% Compute throttle lapse (alpha) using formula
alpha = (alpha_dry * T_min + (AB_percent * ((alpha_AB * T_max) - (alpha_dry * T_min)))) / T_max;

% Compute T/W for each W/S
MaxMach = (((q * CD0)/alpha) ./ Wto_S_range) + (((q/alpha) * K1 * (B/q)^2) .* Wto_S_range);

% Plot results
figure;
hold on;
grid on;
plot(Wto_S_range, MaxMach, 'r-', 'LineWidth', 2);
xlabel('Wing Loading W/S [lb/ft^2]');
ylabel('Thrust-to-Weight T/W');
title('Max Mach Constraint (M = 1.6 @ 36,000 ft)');
