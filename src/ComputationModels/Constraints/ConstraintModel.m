classdef (Abstract) ConstraintModel < handle
     %CONSTRAINTMODEL Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          Wto_S_range
          TW_table
          T_Wto_takeoff
          optimal_WS
          min_TW
          Landing
          Wto_S_landing
          T0_W0
          W0_S_ref
          T_Wto_required
          constraints_table
          constraints_struct
     end

     methods (Abstract) % Bare minimum requirements
          constraint_table = constraint_analysis(design)
     end
end