classdef (Abstract) AerodynamicsBase < handle
%AERODYNAMICSBASE  Tier-1 abstract enforcer for all aerodynamics discipline classes.
%
%   Declares the two-method contract orchestrators call, plus two
%   fidelity-independent utilities every level inherits unchanged, plus the
%   per-high-lift-configuration polar accessor (get_config_polar) the FAR-25
%   field-length/climb constraints read -- a concrete class overrides it.
%
%   Inheritance: AerodynamicsBase -> AeroModelLN (abstract) -> F16AeroLN
%   The AeroLN static toolboxes are NOT in this chain.
%
%   K-convention: CD = CD0 + K1*CL^2 + K2*CL, K1 quadratic/induced and K2
%   linear/camber.  [Mattingly: Aircraft Engine Design, 2nd edition Eq. 2.9]
%
%   Companion doc: src/base/AerodynamicsBase.md

% Note (8/21/2026)(Casey): The aerodynamic base doesn't enforce any particular properties,
% but it should. These properties seem equally fitted for this class, and the "aircraft state"
% class. Which would be better? Ask Sarojini.
% properties (Abstract)
%     e_osw
%     K1_sub
%     K1_sup
%     K2_sub
%     K2_sup
%     CL
%     CD
%     CD0
% end


    methods (Abstract)

        %DRAG_POLAR  Drag polar at the given flight state.
        %   Returns struct with fields CD0, K1, K2.
        polar = drag_polar(obj, state)

        %GET_CLMAX  Maximum usable lift coefficient at the given flight state.
        CLmax = get_CLmax(obj, state)

        % Note (8/20/2026)(Casey): I think this should take a state, if it's relevant.
        %GET_CD0    zero-lift drag coefficient (should this take a state?)
        % CD0 = get_CD0(obj)

    end

    methods

        function cfg = get_config_polar(obj, config)
        %GET_CONFIG_POLAR  Drag polar + CLmax for a named high-lift configuration.
        %   Returns struct(CD0, K1, K2, CLmax) for the flaps/gear state CONFIG,
        %   one of the six FAR-25 high-lift configurations the field-length and
        %   climb-gradient constraints read:
        %     clean, takeoff_flaps_gear_up, takeoff_flaps_gear_down,
        %     landing_flaps_gear_up, landing_flaps_gear_down, approach.
        %
        %   drag_polar/get_CLmax expose only the clean polar. A concrete class a
        %   FAR-25 field-length or climb constraint needs must override this,
        %   building on its config-distinguishing methods (get_CLmax_TO/_L,
        %   get_Delta_CD0_TO/_L). The default errors rather than being abstract,
        %   so classes that never see those constraints are not forced to
        %   implement it.
            arguments
                obj
                config (1,1) string {mustBeMember(config, ...
                    ["clean", ...
                     "takeoff_flaps_gear_up", "takeoff_flaps_gear_down", ...
                     "landing_flaps_gear_up", "landing_flaps_gear_down", ...
                     "approach"])}
            end
            error('AerodynamicsBase:configPolarNotImplemented', ...
                ['aero (class %s) does not implement get_config_polar. The ', ...
                 'FAR-25 field-length and climb-gradient constraints need a ', ...
                 'per-high-lift-configuration polar (config "%s"), which the ', ...
                 'core drag_polar/get_CLmax interface (clean only) does not ', ...
                 'provide. Override get_config_polar(config) -> struct(CD0, ', ...
                 'K1, K2, CLmax) on %s, building on its clean drag_polar plus ', ...
                 'its config-distinguishing methods (get_CLmax_TO/_L, ', ...
                 'get_Delta_CD0_TO/_L).'], class(obj), config, class(obj));
        end

        function CD = compute_CD(~, CD0, K1, K2, CL)
        %COMPUTE_CD  Drag coefficient.  [Mattingly: Aircraft Engine Design, 2nd edition Eq. 2.9]
            CD = CD0 + K1*CL^2 + K2*CL;
        end

        function CL = compute_CL(~, L, q, S_ref)
        %COMPUTE_CL  Lift coefficient in steady level flight.  [Nicolai Eq. 2.1]
            arguments
                ~
                L     (1,1) double
                q     (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
            end
            CL = L / (q * S_ref);
        end

    end

end
