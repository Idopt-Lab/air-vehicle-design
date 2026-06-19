%% ---------------------------------------------------


% Function: Create thrust loading table
function [TW_table, T_Wto_takeoff] = createThrustLoadingTable(constraints, aero, thrust, Wto_S_range, constraintNames, TO)
    num_constraints = length(constraintNames);
    TW_table = zeros(num_constraints, length(Wto_S_range));
    
    for i = 1:num_constraints
        name = constraintNames{i};
        TW_table(i, :) = computeWingLoading(constraints(name,:), aero(name,:), thrust(name,:), Wto_S_range);
    end
    %
    T_Wto_takeoff = takeoff_constraint(Wto_S_range, TO);
end