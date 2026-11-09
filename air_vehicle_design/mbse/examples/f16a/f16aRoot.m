function r = f16aRoot()
%F16AROOT Return the absolute path to the root folder of the F-16A RFLP example.
%   R = F16AROOT() returns the absolute path of the root folder of this
%   example. This folder contains f16a.prj, docs/, requirements/, functions/,
%   logical/, physical/ and verification/.
%
%   This function is the single location anchor for the example. All trades,
%   roll-ups and tests get the paths of the other folders from it, not from
%   their own file location. Thus a script operates from any folder.
%
%   Keep this file in the example root. It returns its own folder as the
%   root, so if you move it, the root moves with it.

r = fileparts(mfilename("fullpath"));

end
