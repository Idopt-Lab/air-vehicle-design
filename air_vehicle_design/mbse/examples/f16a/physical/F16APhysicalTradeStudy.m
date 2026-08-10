function results = F16APhysicalTradeStudy()
%F16APHYSICALTRADESTUDY Run the three F-16A physical trade studies.
%   RESULTS = F16APHYSICALTRADESTUDY() runs each trade in turn and collects the
%   ranked tables. Each of the three does its own work -- opens the models,
%   scores its candidates, and writes its decision into P, L and R -- so this
%   file has nothing to add beyond the order and the collection.
%
%   RESULTS is a dictionary from role to ranked table. A table cannot live in a
%   dictionary's value array, so read it WITH BRACES: results{"Airframe"}.
%
%   The trades are INDEPENDENT: three separate variation points, three separate
%   requirements, and no candidate is scored against a candidate of another role
%   (D-056). Searching the 2x2x3 morphological box instead is deferred, C3.
%
%   Read F16AEngineTradeStudy, F16AAirframeTradeStudy or
%   F16AFlightControlsTradeStudy to see how a trade actually works.
%   generate_f16a_physical.m calls this as its section 7b.

airframe = F16AAirframeTradeStudy();
fcs      = F16AFlightControlsTradeStudy();
engine   = F16AEngineTradeStudy();

% Keys in sorted role order, which is the order docs/05_physical.md reports and
% the order the generator's closing banner prints. A dictionary keeps INSERTION
% order, so this list is the order -- not an alphabetical sort applied later.
results = dictionary( ...
    ["Airframe", "FlightControlSystem", "PropulsionSystem"], ...
    {airframe,    fcs,                   engine});

fprintf("\n########## ALL THREE DECISIONS RECORDED ##########\n");
roles = reshape(keys(results), 1, []);
for i = 1:numel(roles)
    T = results{roles(i)};
    fprintf("  %-20s -> %s (%s), score %.5f\n", roles(i), ...
        T.Candidate(T.Rank == 1), T.Kind(T.Rank == 1), T.Score(T.Rank == 1));
end
fprintf("\n");

end
