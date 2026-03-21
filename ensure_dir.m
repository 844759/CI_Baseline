function ensure_dir(pathStr)
%ENSURE_DIR Crea una carpeta si no existe.
if ~exist(pathStr, 'dir')
    mkdir(pathStr);
end
end
