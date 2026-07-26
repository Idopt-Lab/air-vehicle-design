function r = f16aRoot()
%F16AROOT Absolute path to the F-16A RFLP example root folder.
%   R = F16AROOT() returns the absolute path of this example's root folder
%   (the folder that contains f16a.prj, docs/, requirements/, architecture/,
%   logical/, physical/, and verification/).
%
%   This function is the single location ANCHOR for the example. Every
%   generator, analysis, roll-up, and test derives the paths of the layer
%   folders from it -- e.g. fullfile(f16aRoot,"physical") -- instead of from
%   its own file location (fileparts(mfilename("fullpath"))). That makes each
%   script independent of WHERE it lives, so scripts can sit in their layer
%   folder without breaking sibling-folder path resolution.
%
%   f16aRoot.m itself must stay at the example root: it reports its own folder
%   as the root, so moving it would move the root with it.

r = fileparts(mfilename("fullpath"));

end
