function Swet = wetted_area(kind, varargin)
%WETTED_AREA  Wetted area of a component (SI units).
%
%   Swet = WETTED_AREA("surface", S_exp, tc)
%       wing or tail from its exposed planform area.
%       tc <= 0.05: 2.003*S_exp; tc > 0.05: S_exp*(1.977 + 0.52*tc)
%                                          Raymer Eqs. 7.11, 7.12, p. 204
%   Swet = WETTED_AREA("fuselage", l, D)
%       fuselage with a cylindrical mid-section, l = length, D = diameter.
%       Swet = pi*D*l*(1 - 2/f)^(2/3)*(1 + 1/f^2), f = l/D
%                                          Roskam, Airplane Design Part II, Eq. 12.3, p. 284
%   Swet = WETTED_AREA("cylinder", l, D)
%       lateral area pi*D*l (geometry; used for the nacelles).

    arguments
        kind (1,1) string {mustBeMember(kind, ["surface", "fuselage", "cylinder"])}
    end
    arguments (Repeating)
        varargin
    end

    switch kind
        case "surface"
            [S_exp, tc] = varargin{:};
            if tc <= 0.05
                Swet = 2.003*S_exp;
            else
                Swet = S_exp.*(1.977 + 0.52*tc);
            end
        case "fuselage"
            [l, D] = varargin{:};
            f = l/D;
            Swet = pi*D*l*(1 - 2/f)^(2/3)*(1 + 1/f^2);
        case "cylinder"
            [l, D] = varargin{:};
            Swet = pi*D*l;
    end
end
