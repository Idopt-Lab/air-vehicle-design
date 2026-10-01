function [WS_sweep, WS_wall] = wing_loading_sweep(obj)
%WING_LOADING_SWEEP  The wing-loading sweep the sizing loop solves on.
%
%   [WS_sweep, WS_wall] = wing_loading_sweep(obj)
%
%   GIVEN - you do not write this. The driver and the tests both call it,
%   so both solve the constraint analysis on exactly the same points.
%
%   The range comes from constraints.wing_loading_range_psf, sampled at
%   no fewer than 400 points. The landing wall is then APPENDED at its exact
%   location. The wall does not move as the airplane is resized - it
%   depends only on CLmax_landing and the landing distance - and on this
%   airplane the least-engine corner sits against it. Without the appended
%   point the corner, and with it S_ref = W_0/(W/S), would be quantised to
%   the grid spacing.
%
%   obj must already hold a wing area and a power (obj.geom.S_ref and
%   obj.prop.P_SL), because run_constraints evaluates every condition.

    J  = jsondecode(fileread(ttpa_requirements_path()));
    Cn = J.constraints;

    WS_sweep = linspace(Cn.wing_loading_range_psf(1), Cn.wing_loading_range_psf(2), ...
                        max(Cn.wing_loading_points, 400));

    [~, walls] = run_constraints(mean(WS_sweep), obj);
    WS_wall = min(walls(~isnan(walls)));

    if isempty(WS_wall) || ~isfinite(WS_wall)
        WS_wall = Inf;
    else
        WS_sweep = unique([WS_sweep, WS_wall*(1 - 1e-9)]);
    end
end
