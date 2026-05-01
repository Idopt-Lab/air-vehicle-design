classdef (Abstract) SandCModelLevel3 < handle
     %SANDCMODELLEVEL3 Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          CG
          NP
          C_of_L
     end

     methods (Abstract)
          CG = get_CG()
          NP = get_NP()
          C_of_L = get_C_of_L()
          SM = get_static_margin()
     end
end