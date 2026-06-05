function plotClassInheritance(classNames)
% plotClassInheritance  Plot superclass relationships for MATLAB classes.
%
% Example:
%   plotClassInheritance(["F16AeroLevel1", "F16AeroLevel2"])

    edgesFrom = strings(0,1);
    edgesTo   = strings(0,1);
    visited = containers.Map("KeyType", "char", "ValueType", "logical");

    for k = 1:numel(classNames)
        crawlClass(string(classNames(k)));
    end

    G = digraph(edgesFrom, edgesTo);

    figure
    plot(G, ...
        "Layout", "layered", ...
        "Direction", "down", ...
        "NodeLabel", G.Nodes.Name);

    title("Class Inheritance Structure")

    function crawlClass(className)
        key = char(className);

        if isKey(visited, key)
            return
        end

        visited(key) = true;

        mc = meta.class.fromName(key);

        if isempty(mc)
            warning("Class not found on MATLAB path: %s", key);
            return
        end

        for i = 1:numel(mc.SuperclassList)
            parentName = string(mc.SuperclassList(i).Name);
            childName  = string(mc.Name);

            edgesFrom(end+1,1) = parentName;
            edgesTo(end+1,1)   = childName;

            crawlClass(parentName);
        end
    end
end