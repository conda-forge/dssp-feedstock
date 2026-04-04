if 'LIBCIFPP_DATA_DIR' in @.env:
    @.env['_CONDA_SET_LIBCIFPP_DATA_DIR'] = @.env['LIBCIFPP_DATA_DIR']

$LIBCIFPP_DATA_DIR = f"{CONDA_PREFIX}/share/libcifpp"
