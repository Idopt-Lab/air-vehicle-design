function R = breguet_range(V, C, LD, W_start, W_end)
%BREGUET_RANGE  Jet cruise range (m), Raymer Eq. 3.5.
%
%   R = BREGUET_RANGE(V, C, LD, W_start, W_end)
%     R = (V/C)*(L/D)*ln(W_start/W_end)            Raymer Eq. 3.5, p. 34
%     V       velocity (m/s)
%     C       specific fuel consumption (1/s). Raymer Table 3.3 gives C in
%             1/hr: divide by 3600. (Raymer p. 35: use consistent units.)
%     LD      lift-to-drag ratio
%     W_start, W_end  weight (or mass) at the start and end of cruise

    arguments
        V       double {mustBePositive}
        C       double {mustBePositive}
        LD      double {mustBePositive}
        W_start double {mustBePositive}
        W_end   double {mustBePositive}
    end

    R = (V./C).*LD.*log(W_start./W_end);
end
