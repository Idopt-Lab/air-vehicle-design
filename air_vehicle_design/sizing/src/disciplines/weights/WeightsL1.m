classdef WeightsL1
%WEIGHTSL1  Level-1 weight estimation static toolbox.
%
%   Call as WeightsL1.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16WeightsL1, etc.)
%   inherit from WeightsModelL1 and call these statics to implement each
%   abstract method.
%
%   TWO L1 STATISTICAL METHODS:
%
%   (1) Raymer Table 3.1 — simple sizing equation (central estimate):
%         We/Wto = Kvs × A × W_TO^C
%       A, C, Kvs are aircraft-category constants.
%       Kvs = 1.04 for variable-sweep wings, 1.00 otherwise.
%       OEW = (We/Wto) × W_TO  [lbf]
%
%   (2) Roskam Eq. 2.16 — log-log minimum bound:
%         log10(W_E) = (log10(W_TO) − A) / B
%       Gives the MINIMUM historically achievable W_E for that aircraft class.
%       Actual OEW will exceed this minimum.  Useful for checking design margin.
%
%   Compare (1) and (2): (1) is the central design-point estimate; (2) is the
%   lower efficiency frontier.  At W_TO=31,377 lbf for a jet fighter:
%     Raymer (1): OEW ≈ 19,108 lbf   (central estimate)
%     Roskam (2): W_E ≈ 15,660 lbf   (minimum achievable)
%     Brandt actual: 19,981 lbf       (Brandt F-16A.xls B12)
%
%   SOURCES:
%     AE481 Aircraft Design Metabook, Table 3.1 — Raymer empty-weight regression
%     constants.  [⚠ verify A, C against Raymer 6th ed. Table 3.1 before citing]
%     Roskam, "Airplane Design, Part I," DARcorporation, 1985,
%     Eq. 2.16 + Table 2.15.  Jet-fighter row: A=0.5091, B=0.9505.

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function oew = OEW(obj, W_TO)
        %OEW  Operating empty weight [lbf] via Raymer Table 3.1 power law.
        %   W_TO — candidate gross weight [lbf].
            oew = WeightsL1.compute_We_fraction(obj, W_TO, obj.aircraft_category) * W_TO;
        end

        function frac = compute_We_fraction(obj, W_TO, aircraft_category)
        %COMPUTE_WE_FRACTION  Empty-weight fraction We/Wto.  [Raymer Table 3.1]
        %   aircraft_category defaults to obj.aircraft_category when omitted.
            if nargin < 3
                aircraft_category = obj.aircraft_category;
            end
            c = WeightsL1.lookup_coeffs(aircraft_category);
            frac = WeightsL1.We_fraction_power_law(c.Kvs, c.A, c.C, W_TO);
        end

        function W_E = compute_We_roskam(obj, W_TO)
        %COMPUTE_WE_ROSKAM  Minimum empty weight [lbf] via Roskam Eq. 2.16.
        %   Uses obj.aircraft_category to look up Roskam Table 2.15 constants.
            c = WeightsL1.lookup_roskam_coeffs(obj.aircraft_category);
            W_E = WeightsL1.We_roskam(c.A, c.B, W_TO);
        end

        % ================================================================== %
        % LOW-LEVEL: pure math — scalars only.
        % ================================================================== %

        function frac = We_fraction_power_law(Kvs, A, C, W_TO)
        %WE_FRACTION_POWER_LAW  We/Wto = Kvs × A × W_TO^C.  [Raymer Table 3.1]
        %   Kvs — variable-sweep factor: 1.04 (VS) or 1.00 (fixed) [Raymer Table 3.1].
        %   A, C — category constants from Raymer Table 3.1.
        %   W_TO — takeoff gross weight [lbf].
            frac = Kvs .* A .* W_TO .^ C;
        end

        function W_E = We_roskam(A, B, W_TO)
        %WE_ROSKAM  Roskam log-log minimum empty weight.  [Roskam Eq. 2.16]
        %   log10(W_E) = (log10(W_TO) − A) / B
        %   W_TO — gross weight [lbf].  Returns minimum W_E [lbf].
            W_E = 10 .^ ( (log10(W_TO) - A) ./ B );
        end

        function c = lookup_coeffs(aircraft_category)
        %LOOKUP_COEFFS  Return (Kvs, A, C) constants for Raymer Table 3.1.
        %   aircraft_category — string (e.g. "jet_fighter").
        %   Source: AE481 Metabook Table 3.1 [cites Raymer Table 3.1].
        %   [⚠ verify all rows against Raymer 6th ed. Table 3.1 before citing]
            switch lower(aircraft_category)
                case 'jet_fighter'
                    c = struct('A', 2.34, 'C', -0.13, 'Kvs', 1.00); % [Raymer Table 3.1; Kvs=1.00 fixed sweep]
                case 'jet_trainer'
                    c = struct('A', 1.59, 'C', -0.10, 'Kvs', 1.00); % [Raymer Table 3.1, verify]
                case 'jet_transport'
                    c = struct('A', 1.02, 'C', -0.06, 'Kvs', 1.00); % [Raymer Table 3.1, verify]
                case 'military_cargo_bomber'
                    c = struct('A', 0.93, 'C', -0.07, 'Kvs', 1.00); % [Raymer Table 3.1, verify]
                otherwise
                    error('WeightsL1:UnknownCategory', ...
                          'Unknown aircraft_category "%s". Add row to lookup_coeffs.', ...
                          aircraft_category);
            end
        end

        function c = lookup_roskam_coeffs(aircraft_category)
        %LOOKUP_ROSKAM_COEFFS  Return (A, B) constants for Roskam Table 2.15.
        %   Source: Roskam, Airplane Design Part I, Table 2.15, book p.47.
            switch lower(aircraft_category)
                case 'jet_fighter'
                    c = struct('A', 0.5091, 'B', 0.9505);  % [Roskam Table 2.15]
                case 'fighter_piston'
                    c = struct('A', 0.5647, 'B', 0.8761);  % [Roskam Table 2.15]
                case 'single_engine_prop'
                    c = struct('A', -0.1440, 'B', 1.1162); % [Roskam Table 2.15]
                case 'military_patrol_bomber'
                    c = struct('A', -0.2009, 'B', 1.1037); % [Roskam Table 2.15]
                case 'supersonic_cruise'
                    c = struct('A', 0.0833, 'B', 1.0335);  % [Roskam Table 2.15]
                otherwise
                    error('WeightsL1:UnknownRoskamCategory', ...
                          'Unknown aircraft_category "%s". Add row to lookup_roskam_coeffs.', ...
                          aircraft_category);
            end
        end

    end

end
