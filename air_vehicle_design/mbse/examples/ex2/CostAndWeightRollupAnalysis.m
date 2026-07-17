function CostAndWeightRollupAnalysis(instance, varargin)
    if ~instance.isComponent(); return; end
    rollupAndSet(instance);   % recurse bottom-up

    function [cSum, wSum] = rollupAndSet(node)
        % Active flag (handles string/char/logical)
        isActive = false;
        if node.hasValue('DetectProfile.Physical.Active')
            v = node.getValue('DetectProfile.Physical.Active');
            if isstring(v) || ischar(v)
                isActive = strcmpi(string(v),"true");
            else
                isActive = logical(v);
            end
        end

        % this node's own contribution (only if Active)
        cSum = 0;  wSum = 0;
        if isActive
            if node.hasValue('DetectProfile.Physical.Cost')
                cSum = cSum + double(node.getValue('DetectProfile.Physical.Cost'));
            end
            if node.hasValue('DetectProfile.Physical.Weight')
                wSum = wSum + double(node.getValue('DetectProfile.Physical.Weight'));
            end
        end

        % add children recursively
        for ch = node.Components
            [cc, ww] = rollupAndSet(ch);
            cSum = cSum + cc;  wSum = wSum + ww;
        end

        % write totals so Analysis Viewer shows roll-up at every level
        if node.hasValue('DetectProfile.Physical.Cost')
            node.setValue('DetectProfile.Physical.Cost', cSum);
        end
        if node.hasValue('DetectProfile.Physical.Weight')
            node.setValue('DetectProfile.Physical.Weight', wSum);
        end
    end
end
