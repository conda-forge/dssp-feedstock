# Store existing env var so it can be restored after deactivation.
if ( $?LIBCIFPP_DATA_DIR ) then
    setenv _CONDA_SET_LIBCIFPP_DATA_DIR "$LIBCIFPP_DATA_DIR"
endif

setenv LIBCIFPP_DATA_DIR "${CONDA_PREFIX}/share/libcifpp"
