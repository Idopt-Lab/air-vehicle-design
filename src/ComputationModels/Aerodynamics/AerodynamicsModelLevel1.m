classdef AerodynamicsModelLevel1 < handle
     %AERODYNAMICSMODELLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          e_osw
          LD_max
          AR_wet
          CL_minD
          K_LD
          K1
          K2
     end

     methods (Abstract)
          LD_max = get_LD_max(aircraft_type)
          AR_wet = get_AR_wet(b, S_wet)

     end
end