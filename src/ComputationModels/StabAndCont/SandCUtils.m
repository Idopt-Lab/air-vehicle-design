classdef SandCUtils
     %SANDCUTILS Summary of this class goes here
     %   Detailed explanation goes here

     methods (Static)
          % Load info from design sheet
          function output = get_design_weights(obj, design)

               file_name = design.Name;
               output = readtable(file_name, 'Sheet', "Stability&Control", 'ReadRowName', true);
               output = tableToNestedStruct(output, Orientation="rows");

          end
     end
end