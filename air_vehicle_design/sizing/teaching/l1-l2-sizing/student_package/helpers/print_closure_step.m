function print_closure_step(s, label)
%PRINT_CLOSURE_STEP  Print one closure step as a readable block.
%
%   PRINT_CLOSURE_STEP(s) where s comes from ONE_CLOSURE_STEP.

    arguments
        s     (1,1) struct
        label (1,1) string = "closure step"
    end

    fprintf('\n=== %s ===\n', label);
    fprintf('  GUESS      W_TO        = %12.1f lbf\n', s.W0);
    fprintf('  design pt  (W/S)*      = %12.3f psf\n', s.WS);
    fprintf('             (T/W)*      = %12.4f\n',     s.TW);
    fprintf('  1. wing    S_ref       = W_TO/(W/S)  = %10.1f ft^2\n', s.S_ref);
    fprintf('  2. engine  T_SL        = (T/W)*W_TO  = %10.1f lbf\n',  s.T_SL);
    fprintf('  3. mission W_fuel      = %12.1f lbf   (%.4f of W_TO)\n', s.W_fuel, s.fuel_fraction);
    fprintf('  4. weights W_OEW       = %12.1f lbf   (%.4f of W_TO)\n', s.W_OEW,  s.empty_fraction);
    fprintf('             W_payload   = %12.1f lbf\n', s.W_payload);
    fprintf('  5. closure denom       = 1 - %.4f - %.4f = %.4f\n', ...
        s.empty_fraction, s.fuel_fraction, s.denom);
    fprintf('             W_TO_new    = W_payload/denom = %10.1f lbf\n', s.W0_new);
    fprintf('             residual    = %+12.1f lbf\n', s.residual);
end
