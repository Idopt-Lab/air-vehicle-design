classdef TestHighLiftConfigBridge < matlab.unittest.TestCase
%TESTHIGHLIFTCONFIGBRIDGE  Unit tests for the HighLiftConfigBridge static
%   bridge (the minimal-blast-radius seam to per-high-lift-config polars).
%
%   HighLiftConfigBridge.polar(aero, config) forwards to
%   aero.get_config_polar(config) and validates the seam:
%     * config must be one of the six recognized strings (mustBeMember).
%     * aero must implement get_config_polar, else
%       'HighLiftConfigBridge:contractNotImplemented'.
%     * the returned value must be a struct with fields CD0/K1/K2/CLmax, else
%       'HighLiftConfigBridge:badPolarStruct'.
%
%   These are contract tests -- no hand-computed physics value. The happy path
%   confirms the clean-config struct round-trips; the three error paths confirm
%   each guard fires with the documented error id.
%
%   Stubs used:
%     * FixedConfigAeroStub -- ships the metabook Ex 4.2 per-config polars and
%       IMPLEMENTS get_config_polar (happy path + badPolarStruct via a partial
%       map whose value is missing a field).
%     * FixedAeroStub -- a minimal AerodynamicsBase that has NO get_config_polar
%       method (drag_polar/get_CLmax only), so it triggers contractNotImplemented.

    methods (Test)

        function testCleanPolarRoundTrips(tc)
            % polar(stub, "clean") returns the stub's clean struct with all four
            % fields present, matching the FixedConfigAeroStub default clean
            % polar [metabook Ex 4.2: CD0=0.01597, K1=0.03815, K2=0, CLmax=0.90].
            aero = FixedConfigAeroStub();
            cfg  = HighLiftConfigBridge.polar(aero, "clean");

            tc.verifyTrue(all(isfield(cfg, {'CD0', 'K1', 'K2', 'CLmax'})), ...
                'polar must return a struct with CD0/K1/K2/CLmax.');
            tc.verifyEqual(cfg.CD0, 0.01597, 'AbsTol', 1e-12);
            tc.verifyEqual(cfg.K1, 0.03815, 'AbsTol', 1e-12);
            tc.verifyEqual(cfg.K2, 0, 'AbsTol', 1e-12);
            tc.verifyEqual(cfg.CLmax, 0.90, 'AbsTol', 1e-12);
        end

        function testContractNotImplementedErrors(tc)
            % FixedAeroStub is an AerodynamicsBase with NO get_config_polar
            % method -> 'HighLiftConfigBridge:contractNotImplemented'.
            aero = FixedAeroStub(2.0, 0.02);   % CLmax, CD0 (K1/K2 default 0)
            tc.verifyFalse(ismethod(aero, 'get_config_polar'), ...
                'Precondition: FixedAeroStub must lack get_config_polar.');
            tc.verifyError(@() HighLiftConfigBridge.polar(aero, "clean"), ...
                'HighLiftConfigBridge:contractNotImplemented', ...
                'An aero without get_config_polar must fail loudly at the seam.');
        end

        function testBadPolarStructErrors(tc)
            % A get_config_polar returning a struct MISSING a required field
            % (here CLmax) -> 'HighLiftConfigBridge:badPolarStruct'. Use a
            % non-clean key so FixedConfigAeroStub's constructor does not try to
            % sync its clean accessors from the malformed entry.
            badMap = struct('takeoff_flaps_gear_up', ...
                struct('CD0', 0.03597, 'K1', 0.04054, 'K2', 0));   % no CLmax
            aero = FixedConfigAeroStub(badMap);
            tc.verifyError(@() HighLiftConfigBridge.polar(aero, "takeoff_flaps_gear_up"), ...
                'HighLiftConfigBridge:badPolarStruct', ...
                'A polar struct missing a field must fail loudly at the seam.');
        end

        function testInvalidConfigStringErrors(tc)
            % A config string outside the six recognized names must trip the
            % mustBeMember validation in polar's arguments block.
            aero = FixedConfigAeroStub();
            tc.verifyError(@() HighLiftConfigBridge.polar(aero, "not_a_config"), ...
                'MATLAB:validators:mustBeMember', ...
                'An unrecognized config string must trip mustBeMember.');
        end

    end

end
