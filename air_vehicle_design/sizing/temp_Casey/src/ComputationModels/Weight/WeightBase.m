classdef (Abstract) WeightBase < handle
     %WEIGHTBASE Discipline-wide contract for weight-estimation classes.
     %   Abstract surface common to every fidelity level (L1-L3). Level-
     %   specific properties/methods live in the WeightModelLevelN classes.

     properties (Abstract)
          MTOW      % Maximum take-off weight (lbf)
          OEW       % Operating empty weight (lbf)
          W_fixed   % Fixed / payload weight (lbf)
     end
end
