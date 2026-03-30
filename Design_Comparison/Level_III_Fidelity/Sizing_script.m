%% Sizing script
% Written byeah Casey Chamberlain
% 2/12/2026

% Sizes... something

function [S_ref, T0] = Sizing_script(T0_W0, W0_Sref, W_TO)


S_ref = W_TO/W0_Sref;
T0 = T0_W0*W_TO;

end