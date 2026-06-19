%% ---------------------------------------------------
% Function: Solve for optimal W/S and T/W
function [optimal_WS, min_TW] = solveOptimalPoint(TW_table, T_Wto_takeoff, Wto_S_range)
    T_Wto_required = max([TW_table; T_Wto_takeoff], [], 1);
    [min_TW, min_idx] = min(T_Wto_required);
    optimal_WS = Wto_S_range(min_idx);
end