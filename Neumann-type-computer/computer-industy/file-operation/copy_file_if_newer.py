def copy_file_if_newer(src: pathlib.Path, dst: pathlib.Path):
    src_string = str(src); dst_string = str(dst)
    already_exist_q = os.path.isfile(dst_string)
    if (not already_exist_q) | (already_exist_q and src.stat().st_mtime - dst.stat().st_mtime > 1):
        shutil.copy2(src_string, dst_string)
