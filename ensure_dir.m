function ensure_dir(pathStr)
%ENSURE_DIR Create the directory if it does not exist.
if ~exist(pathStr, 'dir')
    mkdir(pathStr);
end
end
