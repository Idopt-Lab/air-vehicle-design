function [K, e] = k_le_suction(A, CLa, S, delta)
%K_LE_SUCTION  Drag-due-to-lift factor by the leading-edge-suction method.
%
%   [K, e] = K_LE_SUCTION(A, CLa, S) with aspect ratio A (effective, with
%   winglets), wing lift slope CLa (per rad) and leading-edge suction S (0-1):
%     K0   = 1/CLa                    0 % suction        Raymer Eq. 12.56, p. 447
%     K100 = 1/(pi*A)                 100 % suction      Raymer p. 447
%     K    = S*K100 + (1 - S)*K0                         Raymer Eq. 12.57, p. 447
%     e    = 1/(pi*A*K)  (the same as Raymer Eq. 12.58, p. 451)
%   S is about 0.93 for a large-LE-radius airliner wing (Raymer p. 450).
%
%   [K, e] = K_LE_SUCTION(A, CLa, S, delta) also applies Nicolai's
%   non-elliptic correction to the 100 %-suction (inviscid) term:
%     K100 = (1 + delta)/(pi*A)                          Nicolai Eq. 2.10, p. 43
%   This combination of the two books is an assumption of this lesson.

    arguments
        A     (1,1) double {mustBePositive}
        CLa   (1,1) double {mustBePositive}
        S     (1,1) double {mustBeInRange(S, 0, 1)}
        delta (1,1) double {mustBeNonnegative} = 0
    end

    K0   = 1/CLa;
    K100 = (1 + delta)/(pi*A);
    K    = S*K100 + (1 - S)*K0;
    e    = 1/(pi*A*K);
end
