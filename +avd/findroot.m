function root = findroot()
% avd.findroot  Return the repository root by locating startup.m.
%
%   Walks up the directory tree from the caller's file until it finds a
%   directory containing startup.m.  Throws an error if not found.
%
%   Usage (from any .m file):
%       root = avd.findroot();
%       addpath(genpath(fullfile(root, 'src')));

p = fileparts(mfilename('fullpath'));   % +avd/ directory
root = fileparts(p);                   % repo root (parent of +avd/)
end
