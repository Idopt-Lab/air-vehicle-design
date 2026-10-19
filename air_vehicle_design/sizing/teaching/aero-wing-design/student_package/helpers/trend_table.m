function [grid, R] = trend_table(n, band)
%TREND_TABLE  Reproduce the subsonic columns of Nicolai Table 7.1 for the 737.
%
%   grid = TREND_TABLE() returns a 6 x 6 table, one string per cell:
%       "Nicolai arrow | Level-3 arrow"
%   Rows: AR, sweep, taper, t/c, LE radius, camber.
%   Columns: CD0 (subsonic), K, CL_alpha, CL_max, wing weight, wing volume.
%   The 737 at cruise; see trend_737 for the models.
%   [grid, R] = TREND_TABLE(n, band) also returns the trend data R (one
%   trend_737 result per row), with n points per curve (default 41) and the
%   "no effect" band (default 0.03 = 3 % of the baseline value).
%
%   Arrows: "↑" increases, "↓" decreases, "↓↑" minimum inside the range,
%   "↑↓" maximum inside, "no effect" stays inside the band, "—" no model.
%   Nicolai's arrows: Nicolai & Carichner (2010), Table 7.1, p. 193.

    arguments
        n    (1,1) double {mustBeInteger, mustBePositive} = 41
        band (1,1) double {mustBePositive} = 0.03
    end

    nic   = book_data().table7_1;
    rows  = nic.rows;                       % AR, Sweep, Taper, t/c, LE radius, Camber
    vars  = ["AR", "Sweep", "Taper", "t/c", "LE radius", "Camber"];
    cols  = ["CD0_sub", "K", "CL_alpha", "CL_max", "Wing_wt", "Wing_vol"];

    cells = strings(numel(rows), numel(cols));
    for r = 1:numel(rows)
        T = trend_737(vars(r), n);
        R.(matlab.lang.makeValidName(vars(r))) = T;
        for c = 1:numel(cols)
            k    = find(T.names == cols(c));
            got  = classify_trend(T.L3{:,k}', T.base3(k), band);
            want = nic.arrow(r, nic.cols == cols(c));
            cells(r, c) = pretty(want) + " | " + pretty(got);
        end
    end
    grid = array2table(cells, 'VariableNames', cols, 'RowNames', cellstr(rows));
end

function s = pretty(a)
    switch a
        case "^",  s = "↑";
        case "v",  s = "↓";
        case "v^", s = "↓↑";
        case "^v", s = "↑↓";
        case "0",  s = "no effect";
        otherwise, s = "—";
    end
end
