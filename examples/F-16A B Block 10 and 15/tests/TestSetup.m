function TestSetup()
% TestSetup  Configure MATLAB paths for F-16 V&V tests.
%
%   Call from TestClassSetup in every test class:
%
%       methods (TestClassSetup)
%           function setup(tc)  %#ok<MANU>
%               TestSetup();
%           end
%       end
%
%   Locates the repo root by finding startup.m, then delegates to it.
%   Robust to any working directory; does not rely on hard-coded depth.

% Walk up from this file until startup.m is found
p = fileparts(mfilename('fullpath'));
while true
    if isfile(fullfile(p, 'startup.m'))
        break
    end
    parent = fileparts(p);
    if isequal(parent, p)
        error('TestSetup:notFound', ...
            'Could not locate startup.m above %s', ...
            fileparts(mfilename('fullpath')));
    end
    p = parent;
end

run(fullfile(p, 'startup.m'));
end
