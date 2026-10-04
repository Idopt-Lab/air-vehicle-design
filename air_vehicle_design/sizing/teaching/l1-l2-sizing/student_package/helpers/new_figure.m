function fig = new_figure(pos)
%NEW_FIGURE  A white, light-themed figure.
%
%   Recent MATLAB releases default to a dark theme, which projects badly and
%   prints worse. Every plot in this package goes through here so the figures
%   look the same on any machine and in any release.

    arguments
        pos (1,4) double = [100 100 900 620]
    end

    fig = figure('Color', 'w', 'Position', pos);
    if isprop(fig, 'Theme')          % R2025a and newer
        try
            fig.Theme = 'light';
        catch
            % older or restricted release: the white Color above is enough
        end
    end
end
