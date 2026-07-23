function v = BrandtVariant()
%BRANDTVARIANT  Single manual switch selecting which F16Baseline() Brandt
%   reference table the constraint tests' diagnostic Brandt-comparison
%   tables compare against -- TestThrustConstraint's six *RequiredTWTable
%   tests and TestLandingConstraint's testF16LandingWSMaxByFidelityLevel.
%
%   Edit the string below to "original" or "corrected" and re-run the
%   tests -- no other file needs to change.
%
%     "original"  -- Brandt F-16A.xls, as-is [F16Baseline.m sections 1-2].
%     "corrected" -- Casey's revised-OEW/component-weight recalculation
%                    [F16Baseline.m section 11b, source workbook "Brandt
%                    F-16A - corrections.xls"].

    v = "original";   % <-- EDIT THIS LINE to switch: "original" | "corrected"

end
