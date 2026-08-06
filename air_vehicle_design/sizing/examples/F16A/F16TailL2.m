classdef F16TailL2 < TailSizingModelL2
%F16TAILL2  F-16A Level-2 ("historical sizing estimates") tail sizing.
%
%   Inherits TailSizingModelL2 (abstract enforcer). size(obj) is a single
%   delegation into the TailL2 static toolbox -- no equations are
%   duplicated here.
%
%   Same functional form as F16TailL1 (volume coefficient x wing-planform
%   term / moment-arm fraction), but with:
%     - Nicolai & Carichner's F-16-SPECIFIC measured coefficient
%       (C_HT=0.3, C_VT=0.094, Table 11.6 "General Dynamics F-16" row)
%       instead of Raymer's generic jet-fighter category row.
%     - Real L2 wing geometry (b_wing, cbar_wing, S_ref, L_fus), read LIVE
%       from an injected, read-only GeometryModelL2 collaborator, instead
%       of the caller hand-computing scalars.
%   Tail moment arm carries forward L1's 0.475*L_fus unchanged (L2 geometry
%   has no x-station data to do better) -- see TailL2.m's header and
%   TailSizing_scribe_plan.md Sec. 5.1.
%
%   AREA REUSE IS INDIRECT ONLY: size(obj) returns ONLY
%   struct('S_ht','S_vt') -- no exposed/wetted-area fields, no
%   get_S_exposed_ht-style accessor (Sec. 5.2, locked decision). The
%   injected geometry object is read ONLY for b_wing/cbar_wing/S_ref/L_fus.
%
%   CONSTRUCTOR: F16TailL2(geom) -- geom REQUIRED, no silent default (a
%   defaulted injection would silently re-freeze wing geometry, the same
%   defect class the DI pattern removes elsewhere -- see F16WeightsL2's
%   geom/prop injection for the precedent this follows). geom must be a
%   (1,1) GeometryModelL2: only b_wing, cbar_wing, S_ref, L_fus are read,
%   read-only.
%
%   C_HT/C_VT are HARDCODED in this constructor, NOT read from JSON
%   (confirmed by the io agent, TailSizing_scribe_plan.md Sec. 5.3) -- same
%   category as the superseded F16TailSizingLevel1's hardcoded 0.40/0.07
%   wiring.
%
%   SOURCES:
%     [Nicolai]  Nicolai & Carichner, Table 11.6, "General Dynamics F-16"
%                row, p.289 -- temp_AI/docs/disciplines/reference_extracts/
%                11_tail_sizing.md. EXPLICITLY NOT the conflicting
%                C_HT=0.68/C_VT=0.041 figure that appears in three other
%                temp_AI digest files (mis-transcription of the same row,
%                flagged, unresolved elsewhere -- todo.md Finding 1).
%     [Raymer]   Aircraft Design, 7th ed., aft-mounted single-engine tail-
%                arm text rule, carried forward from L1 unchanged.

    properties (SetAccess = private)
        C_HT (1,1) double   % horizontal-tail volume coefficient [Nicolai & Carichner Table 11.6, F-16 row] = 0.3
        C_VT (1,1) double   % vertical-tail volume coefficient   [Nicolai & Carichner Table 11.6, F-16 row] = 0.094
    end

    properties
        geom   % (1,1) GeometryModelL2 -- injected, read-only collaborator; supplies b_wing/cbar_wing/S_ref/L_fus by DI
    end

    methods

        function obj = F16TailL2(geom)
        %F16TAILL2  Construct with a required injected L2 geometry object.
        %   No silent default: geom must be supplied. C_HT/C_VT are
        %   hardcoded here (Nicolai & Carichner Table 11.6, F-16 row), not
        %   read from JSON.
            arguments
                geom (1,1) GeometryModelL2
            end
            obj.geom = geom;
            obj.C_HT = 0.3;    % [Nicolai & Carichner Table 11.6, "General Dynamics F-16" row, p.289]
            obj.C_VT = 0.094;  % [same source/row]
        end

        function result = size(obj)
        %SIZE  Horizontal- and vertical-tail reference areas [ft^2].
        %   [Nicolai & Carichner Table 11.6 F-16 row; Raymer 7th ed. tail-arm
        %   text rule carried forward from L1]  Reads obj.geom live on every
        %   call -- no cached copy, so a mutated geom is reflected
        %   immediately. Returns struct('S_ht', S_ht, 'S_vt', S_vt) only
        %   (Sec. 5.2 -- no exposed/wetted-area fields).
            result = TailL2.size(obj);
        end

    end

end
