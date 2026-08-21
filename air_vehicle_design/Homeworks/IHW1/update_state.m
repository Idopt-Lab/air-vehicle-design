function [state] = update_state(seg_no, miss)
    state.seg_type = miss.segments(seg_no).type;
    state.alt = miss.segments(seg_no).alt_ft;
    state.ktas = miss.segments(seg_no).ktas;
    state.time_min = miss.segments(seg_no).time_min;
    state.dist = miss.segments(seg_no).distance_nm;
end