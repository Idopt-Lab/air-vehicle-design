function r = f16aRoot()
%F16AROOT Absolute path to the F-16A RFLP example root folder.
%   R = F16AROOT() returns the absolute path of this example's root folder
%   (the folder that contains f16a.prj, docs/, requirements/, architecture/,
%   logical/, physical/, and verification/).
%
%   The single location ANCHOR for the example: every generator, roll-up and
%   test derives sibling-folder paths from it rather than from its own file
%   location, so a script works wherever it sits.
%
%   It must stay at the example root -- it reports its own folder as the root,
%   so moving it moves the root with it.

r = fileparts(mfilename("fullpath"));

end
