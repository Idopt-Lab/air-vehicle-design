function [con] = get_con(con_no, cons)
% One constraint condition out of the constraint set.
% The constraint twin of get_miss_seg that was given to you in IHW1.
%
% Inputs:  con_no - condition number
%          cons   - the constraint set, obj.cons
% Output:  con    - struct with the fields listed in the problem

    % --- Milestone 1: label, type and altitude ---
    con.name = string(cons(con_no).name);
    con.type = ;
    con.alt  = ;

    % --- Milestone 2: the requirement keys, read directly ---
    con.distance_ft = ;
    con.G           = ;
    con.ktas        = ;
    con.power_index = ;

    % --- Milestone 3: the keys that need a default. Use get_field. ---
    con.config            = string(get_field(cons(con_no), 'config', "clean"));
    con.beta              = ;
    con.power_setting     = ;
    con.oei               = ;
    con.propeller_stopped = ;
    con.max_continuous    = ;

end

%% Supporting Functions -- given, do not change
function [val] = get_field(c, name, default)
    if isfield(c, name) && ~isempty(c.(name))
        val = c.(name);
    else
        val = default;
    end
end
