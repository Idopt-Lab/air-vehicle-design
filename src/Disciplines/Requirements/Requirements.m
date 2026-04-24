classdef Requirements < RequirementsModel
     %REQUIREMENTS Summary of this class goes here
     %   Detailed explanation goes here

     properties
          requirements
     end

     methods
          % Constructor
          function requirements_obj = Requirements(design)
               requirements_obj.requirements = design.requirements;
          end
     end
end