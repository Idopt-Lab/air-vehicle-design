function fig = plot_mission_profile(req_path, profile_name, breakdown)
%PLOT_MISSION_PROFILE  Draw the mission the fuel fraction comes from.
%
%   fig = PLOT_MISSION_PROFILE(req_path, profile_name)
%   fig = PLOT_MISSION_PROFILE(req_path, profile_name, breakdown)
%
%   Top panel:    altitude against cumulative range, one step per segment.
%   Bottom panel: fuel burned per segment, when you supply the breakdown
%                 struct from  [W_fuel, breakdown] = miss.total_fuel(W_TO).
%
%   The mission profile is a REQUIREMENT. It lives in the requirements JSON,
%   not in any discipline model. Change the profile and the fuel fraction
%   changes, so the sized aircraft changes.
%
%   Time-based legs (loiter, combat) have no range, so they are drawn with a
%   small fixed width just to keep them visible.

    arguments
        req_path     (1,1) string
        profile_name (1,1) string
        breakdown    struct = struct([])
    end

    req  = jsondecode(fileread(req_path));
    prof = req.missions.(profile_name);
    segs = prof.segments;
    if ~iscell(segs), segs = num2cell(segs); end
    n = numel(segs);

    TIME_LEG_WIDTH_NM = 40;      % drawing width only; carries no physics

    name = strings(1, n);  alt = zeros(1, n);  dx = zeros(1, n);
    for k = 1:n
        s = segs{k};
        name(k) = string(getfielddef(s, 'name', getfielddef(s, 'type', "?")));
        alt(k)  = getfielddef(s, 'alt_ft', 0);
        if isfield(s, 'distance_nm')
            dx(k) = s.distance_nm;
        elseif isfield(s, 'time_min') && s.time_min > 0
            dx(k) = TIME_LEG_WIDTH_NM;
        else
            dx(k) = 0;
        end
    end
    x = [0, cumsum(dx)];

    haveFuel = ~isempty(fieldnames(breakdown));
    fig = new_figure([80 80 1000 640]);
    nRows = 1 + haveFuel;
    tl = tiledlayout(fig, nRows, 1, 'Padding', 'compact', 'TileSpacing', 'compact');
    title(tl, sprintf('Mission profile: %s', profile_name), ...
        'FontWeight', 'bold', 'Interpreter', 'none');

    ax = nexttile; hold(ax, 'on'); grid(ax, 'on');
    stairs(ax, x, [alt, alt(end)], '-', 'LineWidth', 2.0);
    for k = 1:n
        xm = 0.5*(x(k) + x(k+1));
        if x(k+1) == x(k), xm = x(k); end
        text(ax, xm, alt(k), "  " + name(k), 'Rotation', 55, ...
            'FontSize', 8, 'VerticalAlignment', 'bottom', 'Interpreter', 'none');
    end
    xlabel(ax, 'cumulative range [nmi]  (time-only legs drawn at fixed width)');
    ylabel(ax, 'altitude [ft]');
    ylim(ax, [0, 1.45*max(max(alt), 1)]);
    title(ax, 'Where the aircraft flies');

    if haveFuel
        ax = nexttile; grid(ax, 'on');
        fuel = breakdown.fuel_lbf(:).';
        lbl  = categorical(string(breakdown.names(:)).');
        lbl  = reordercats(lbl, string(breakdown.names(:)).');
        bar(ax, lbl, fuel);
        ylabel(ax, 'fuel burned [lbf]');
        title(ax, sprintf(['Where the fuel goes.  raw burn %.0f lbf, ', ...
            'plus %.0f%% reserve  ->  W_{fuel} = %.0f lbf'], ...
            breakdown.raw_burn, 100*breakdown.reserve_fuel_fraction, ...
            breakdown.W_fuel_with_reserve));
    end
end

function v = getfielddef(s, f, d)
    if isfield(s, f) && ~isempty(s.(f))
        v = s.(f);
    else
        v = d;
    end
end
