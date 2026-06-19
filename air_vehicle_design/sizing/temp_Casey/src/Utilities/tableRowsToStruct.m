% Written by ChatGPT
function S = tableRowsToStruct(T)
% Converts a table with:
%   - columns = entities (Startup, Climb, Main, HorizontalTail, ...)
%   - row names = attributes (Altitude (ft), Aspect ratio, ...)
% into:
%   S.Startup.altitude
%   S.Climb.mach
%   S.Main.aspectRatio
%
% Assumes table values are scalar-compatible.

rowNames = string(T.Properties.RowNames);
colNames = string(T.Properties.VariableNames);

S = struct();

for c = 1:numel(colNames)
     colField = matlab.lang.makeValidName(colNames(c));

     for r = 1:numel(rowNames)
          rowField = normalizeRowName(rowNames(r));
          S.(colField).(rowField) = T{r, c};
     end
end
end


function name = normalizeRowName(rawName)
rawName = string(rawName);

% Custom aliases for the names you care about most
switch rawName
     case "Altitude (ft)"
          name = "altitude";
     case "Mach number"
          name = "mach";
     case "Payload, fixed (lbf)"
          name = "payloadFixed";
     case "Payload, drop (lbf)"
          name = "payloadDrop";
     case "Time (min)"
          name = "timeMin";
     case "Range (ft)"
          name = "rangeFt";
     case "Range (nm)"
          name = "rangeNm";
     case "q (lbf/ft^2)"
          name = "q";
     case "a (ft/s)"
          name = "a";
     case "Temp (R)"
          name = "temp";
     case "P (psi)"
          name = "pressure";
     case "rho (slug/ft^3)"
          name = "rho";
     case "nu (ft^2/s)"
          name = "nu";
     case "V (ft/s)"
          name = "velocity";
     case "Aspect ratio"
          name = "aspectRatio";
     case "Mean geometric chord"
          name = "meanGeometricChord";
     case "Root chord length (ft)"
          name = "rootChord";
     case "Span (ft)"
          name = "span";
     case "Length (ft)"
          name = "length";
     otherwise
          % Generic fallback
          name = matlab.lang.makeValidName(rawName);

          % Optional cleanup
          name = regexprep(name, '_ft_|_ft2_|_ft3_|_lbf_|_psi_|_R_', '');
          name = regexprep(name, '_+', '_');
          name = regexprep(name, '^_+|_+$', '');

          % Lower camel-ish first letter
          if strlength(name) > 0
               name = char(name);
               name(1) = lower(name(1));
          end
end
end