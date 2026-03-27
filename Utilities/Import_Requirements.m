function [Requirements] = Import_Requirements(Requirements)
%IMPORT_REQUIREMENTS Summary of this function goes here
%   Detailed explanation goes here

file_name = "Requirements.xlsx";

% Mission segments should scan row F8 until it encounters a blank
req_table = readtable(file_name, 'Sheet', Requirements, 'ReadRowNames', true);
% Try cleaning up all cells

Requirements = req_table;

end