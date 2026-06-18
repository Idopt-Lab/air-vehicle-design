classdef TailSizingLevel1 < TailSizingBase
    % Level I tail sizing: Raymer Eq 6.28–6.29 volume coefficient method.
    %
    % Tail moment arms are estimated as 0.5 * L_fus (HT) and 0.5 * L_fus (VT).
    %
    % Typical fighter volume coefficients (Raymer Table 6.4):
    %   c_HT = 0.40, c_VT = 0.07
    %
    % Sizing loop usage:
    %   tail   = TailSizingLevel1(0.40, 0.07);
    %   result = tail.size(S_ref, b, cbar, L_fus);
    %   S_HT   = result.S_HT;   % horizontal tail area (ft²)
    %   S_VT   = result.S_VT;   % vertical tail area (ft²)

    properties
        c_HT    % horizontal tail volume coefficient
        c_VT    % vertical tail volume coefficient
        L_fus_fraction_HT = 0.5  % HT arm as fraction of L_fus
        L_fus_fraction_VT = 0.5  % VT arm as fraction of L_fus
    end

    methods
        function obj = TailSizingLevel1(c_HT, c_VT)
            obj.c_HT = c_HT;
            obj.c_VT = c_VT;
        end

        function result = size(obj, S_ref, b, cbar, L_fus)
            L_HT = obj.L_fus_fraction_HT * L_fus;
            L_VT = obj.L_fus_fraction_VT * L_fus;
            result.S_HT = obj.c_HT * cbar * S_ref / L_HT;
            result.S_VT = obj.c_VT * b    * S_ref / L_VT;
        end
    end

end
