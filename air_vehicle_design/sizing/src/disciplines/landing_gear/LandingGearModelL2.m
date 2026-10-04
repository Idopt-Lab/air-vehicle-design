classdef (Abstract) landinggearModelL2

    properties (Abstract, Constant)
        N_MAIN_WHEELS % Number of "main" wheels
        N_NOSE_WHEELS % Number of "nose" wheels
    end

    methods (Abstract)
        % Wrapper for obtaining the tipback angle.
        val = get_tipback_angle(obj)

        % Check if the tipback angle is within acceptable params.
        % x_cg_array (array): array of each components' cg's x-location.
        val = check_tipback_angle(obj, x_cg_array)
    end

end