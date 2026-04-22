classdef (Abstract) ConstraintModel < handle
     %CONSTRAINTMODEL Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          TW_table
          T_Wto_takeoff
          optimal_WS
          min_TW
          Landing
          Wto_S_landing
          T0_W0
          W0_S_ref
     end

     methods (Abstract) % Bare minimum requirements
          Constraint_Results = constraint_est(obj, design)
     end

     methods (Access = private) % Commonly shared functions
          % Importing the constraints
          
     end
end