function startup()
% avd.startup  Configure paths for the Air Vehicle Design framework.
%
%   This is a thin wrapper.  The canonical path-setup logic lives in
%   startup.m at the repository root.
%
%   Usage (from any working directory):
%       avd.startup()
%
%   Or, if the repo root is already on the path:
%       startup()

pkg_root = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(pkg_root, 'startup.m'));
end
