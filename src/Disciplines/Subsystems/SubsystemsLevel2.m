classdef SubsystemsLevel2
     %SUBSYSTEMSLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          Property1
     end

     methods (Static)

          function output = wingfuelvolume(S_ref, b, tc_root, tc_tip, lambda_w)
               % Estimates the wing fuel volume for prliminary design.
               % Source: Roskam, Airplane Design Vol 2, eq 6.2
               % Statistical estimation, so probably belongs in L2
               % Accounts for required dry bays + lightning strike problem
               % :)
               tau_w = tc_tip/tc_root;
               output = 0.54*(S_ref^2/b)*tc_root*((1+lambda_w*(tau_w)^(1/2) + lambda_w^2*tau_w)/(1+lambda_w^2));
          end
     end
end