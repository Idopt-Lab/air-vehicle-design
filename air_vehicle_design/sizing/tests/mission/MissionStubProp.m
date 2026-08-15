classdef MissionStubProp < PropulsionBase
%MISSIONSTUBPROP  Minimal PropulsionBase stub for mission unit tests.
%   Fixed sea-level thrust, thrust lapse, and mil/AB TSFC (all flight-state
%   independent) so segment tests have known TSFC to replay. Exposes
%   compute_TSFC_AB (so the afterburner blend path is exercised) but NOT
%   compute_TSFC_installed (so select_tsfc's dry basis is the plain get_TSFC).

    properties
        T_SL      = 20000     % lbf
        alpha_    = 0.6
        tsfc_dry_ = 0.9       % 1/hr
        tsfc_ab_  = 1.8       % 1/hr
    end

    methods
        function alpha = thrust_lapse(obj, ~, ~)
            alpha = obj.alpha_;
        end
        function c_t = get_TSFC(obj, ~)
            c_t = obj.tsfc_dry_;
        end
        function c_t = compute_TSFC_AB(obj, ~)
            c_t = obj.tsfc_ab_;
        end
    end
end
