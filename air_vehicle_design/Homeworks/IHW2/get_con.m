function [con] = get_con(con_no, cons)
%GET_CON  One constraint condition out of the constraint set.
%
%   con = get_con(con_no, cons) is the constraint twin of get_miss_seg:
%   get_miss_seg pulls one SEGMENT out of the mission profile, get_con
%   pulls one CONDITION out of the constraint set that
%   ConstraintSetImporter.read_conditions returned.
%
%   The conditions do not all carry the same keys, so the optional ones are
%   read through get_field, which returns a default when the key is absent
%   or empty:
%
%       config              "clean"
%       beta                1.0      W at the condition / W_TO
%       power_setting       1.0      throttle fraction
%       oei                 false    one engine inoperative
%       propeller_stopped   false    failed engine, propeller stopped
%       max_continuous      false    maximum continuous power rating
%
%   The requirement keys are read directly and stay empty when the
%   condition does not carry them, exactly as get_miss_seg leaves ktas
%   empty for a takeoff segment.

    con.name = string(cons(con_no).name);
    con.type = string(cons(con_no).type);
    con.alt  = cons(con_no).altitude_ft;

    % Requirement of this condition, whichever one applies
    con.distance_ft = cons(con_no).distance_ft;   % ft, field length
    con.G           = cons(con_no).G;             % -,  climb gradient
    con.ktas        = cons(con_no).ktas;          % kt, cruise speed
    con.power_index = cons(con_no).power_index;   % -,  Roskam Fig. 3.28

    % Configuration, weight basis and power basis
    con.config            = string(get_field(cons(con_no), 'config', "clean"));
    con.beta              = get_field(cons(con_no), 'beta',          1.0);
    con.power_setting     = get_field(cons(con_no), 'power_setting', 1.0);
    con.oei               = logical(get_field(cons(con_no), 'oei',               false));
    con.propeller_stopped = logical(get_field(cons(con_no), 'propeller_stopped', false));
    con.max_continuous    = logical(get_field(cons(con_no), 'max_continuous',    false));

end

%% Supporting Functions
function [val] = get_field(c, name, default)
    if isfield(c, name) && ~isempty(c.(name))
        val = c.(name);
    else
        val = default;
    end
end
