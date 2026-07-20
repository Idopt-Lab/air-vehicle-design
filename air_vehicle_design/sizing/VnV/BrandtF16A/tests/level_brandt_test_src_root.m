function level_brandt_root = level_brandt_test_src_root()
% level_brandt_test_src_root  Return the level_brandt source folder for tests.

level_brandt_root = fileparts(fileparts(mfilename('fullpath')));
