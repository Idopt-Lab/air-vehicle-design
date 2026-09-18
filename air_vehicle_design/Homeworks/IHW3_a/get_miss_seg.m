function [miss_seg] = get_miss_seg(seg_no, miss)
    miss_seg.type = miss.segments(seg_no).type;
    miss_seg.alt = miss.segments(seg_no).alt_ft;
    miss_seg.ktas = miss.segments(seg_no).ktas;
    miss_seg.time_min = miss.segments(seg_no).time_min;
    miss_seg.dist = miss.segments(seg_no).distance_nm;
end