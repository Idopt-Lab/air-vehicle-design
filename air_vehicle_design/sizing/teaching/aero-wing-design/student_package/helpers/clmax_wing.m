function CLmax = clmax_wing(method, clmax2d, varargin)
%CLMAX_WING  Clean-wing maximum lift coefficient (subsonic, M about 0.2).
%
%   CLmax = CLMAX_WING("raymer12_15", clmax2d, sweep_c4)
%       CLmax = 0.9*clmax*cos(sweep_c4)             Raymer Eq. 12.15, p. 405
%   CLmax = CLMAX_WING("raymer12_16", clmax2d, dy, sweep_LE)
%       CLmax = clmax*(CLmax/clmax)                  Raymer Eq. 12.16, p. 406
%       with (CLmax/clmax) read from Raymer Fig. 12.9 (p. 406) at the
%       leading-edge sharpness parameter dy and the LE sweep. The Mach
%       correction (Fig. 12.10) is zero at M = 0.2 and is not used.
%       dy below 1.4 uses the "<= 1.4" curve; above 2.5 the ">= 2.5" curve.
%       abs(sweep_LE) is used for forward sweep (assumption).

    arguments
        method  (1,1) string {mustBeMember(method, ["raymer12_15", "raymer12_16"])}
        clmax2d (1,1) double {mustBePositive}
    end
    arguments (Repeating)
        varargin
    end

    switch method
        case "raymer12_15"
            sweep_c4 = varargin{1};
            CLmax = 0.9*clmax2d*cosd(sweep_c4);
        case "raymer12_16"
            [dy, sweep_LE] = varargin{:};
            d  = book_data().fig12_9;
            dy = min(max(dy, d.dy(1)), d.dy(end));
            s  = min(abs(sweep_LE), d.Lambda_LE(end));
            ratio = interp2(d.dy, d.Lambda_LE, d.ratio, dy, s);
            CLmax = clmax2d*ratio;
    end
end
