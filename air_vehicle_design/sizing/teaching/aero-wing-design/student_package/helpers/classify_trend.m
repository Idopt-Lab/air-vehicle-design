function [arrow, dpct] = classify_trend(y, y_base, band)
%CLASSIFY_TREND  Put an arrow on a computed trend, the way Nicolai Table 7.1 does.
%
%   [arrow, dpct] = CLASSIFY_TREND(y, y_base, band)
%     y      metric values, in order of the increasing design variable
%     y_base metric value at the baseline design
%     band   "no effect" band, as a fraction (0.03 = 3 %)
%   arrow is one of:
%     "0"   no effect: the whole curve stays inside +/- band*y_base
%     "^"   increases        "v"   decreases
%     "v^"  decreases, then increases (minimum inside the range)
%     "^v"  increases, then decreases (maximum inside the range)
%     "-"   no model (NaN values)
%   dpct is the change from the first to the last point, in % of y_base.

    arguments
        y      (1,:) double
        y_base (1,1) double
        band   (1,1) double {mustBePositive} = 0.03
    end

    if any(isnan(y)) || isnan(y_base)
        arrow = "-";  dpct = NaN;  return
    end

    rel  = (y - y_base)/abs(y_base);
    dpct = 100*(rel(end) - rel(1));

    if max(rel) - min(rel) < band
        arrow = "0";
        return
    end

    [~, imin] = min(y);
    [~, imax] = max(y);
    n   = numel(y);
    tol = band/2*abs(y_base);              % a turn smaller than half the band is not a turn
    if imin > 1 && imin < n && y(1) - y(imin) > tol && y(n) - y(imin) > tol
        arrow = "v^";
    elseif imax > 1 && imax < n && y(imax) - y(1) > tol && y(imax) - y(n) > tol
        arrow = "^v";
    elseif y(n) > y(1)
        arrow = "^";
    else
        arrow = "v";
    end
end
