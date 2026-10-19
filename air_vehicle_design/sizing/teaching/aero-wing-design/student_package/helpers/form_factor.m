function FF = form_factor(kind, varargin)
%FORM_FACTOR  Subsonic component form factor (Raymer 6th ed., Sec. 12.5.4).
%
%   FF = FORM_FACTOR("surface", tc, xc_m, sweep_m, M)
%        wing, tail, strut or pylon. tc = thickness ratio, xc_m = chordwise
%        position of max thickness, sweep_m = sweep of the max-thickness
%        line (deg), M = Mach number.                    Raymer Eq. 12.30, p. 422
%   FF = FORM_FACTOR("body", f)
%        fuselage or smooth canopy, f = length/diameter. Raymer Eq. 12.31, p. 422
%        (6th-edition form; prior editions printed 1 + 60/f^3 + f/400)
%   FF = FORM_FACTOR("nacelle", f)
%        nacelle or smooth external store.               Raymer Eq. 12.32, p. 423
%
%   Raymer p. 422 says these are valid up to the drag-divergence Mach number.

    arguments
        kind (1,1) string {mustBeMember(kind, ["surface", "body", "nacelle"])}
    end
    arguments (Repeating)
        varargin
    end

    switch kind
        case "surface"
            [tc, xc_m, sweep_m, M] = varargin{:};
            FF = (1 + 0.6./xc_m.*tc + 100*tc.^4) .* (1.34*M.^0.18 .* cosd(sweep_m).^0.28);
        case "body"
            f  = varargin{1};
            FF = 0.9 + 5./f.^1.5 + f/400;
        case "nacelle"
            f  = varargin{1};
            FF = 1 + 0.35./f;
    end
end
