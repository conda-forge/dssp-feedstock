#!/bin/bash

set -exo pipefail

if [[ "$build_platform" != "$target_platform" ]]; then
    EXTRA_CMAKE_ARGS="-D_CXX_ATOMIC_BUILTIN_EXITCODE=0"
fi

if [[ "$target_platform" == "osx-"* ]]; then
    export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

sed -i.bak 's|find_package(Python 3.13|find_package(Python 3|' python-module/CMakeLists.txt

# Refer to https://github.com/conda-forge/dssp-feedstock/pull/14#issuecomment-2974049079 for `-DCIFPP_DATA_DIR=''`
cmake -S . -B build \
    ${CMAKE_ARGS} \
    -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
    -DCMAKE_CXX_STANDARD=20 \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTING=OFF \
    -DINSTALL_LIBRARY=ON \
    -DBUILD_PYTHON_MODULE=ON \
    -DPython_ROOT_DIR="${PREFIX}" \
    -DCIFPP_DOWNLOAD_CCD=ON \
    -DCIFPP_INSTALL_UPDATE_SCRIPT=OFF \
    -DCIFPP_DATA_DIR='' \
    -DCIFPP_SHARE_DIR="${PREFIX}/share/libcifpp" \
    ${EXTRA_CMAKE_ARGS}
cmake --build build --config Release --parallel "${CPU_COUNT}"
cmake --install build

# libcifpp is not available as a standalone package on conda-forge,
# so we need to manually copy the shared library built as a CMake
# FetchContent dependency into the package prefix.
# On macOS, dylib versioning uses the pattern libcifpp*.dylib (e.g. libcifpp.10.0.dylib),
# so we cannot use libcifpp${SHLIB_EXT}* which would expand to libcifpp.dylib*
# and miss the versioned files.
# On Linux, libcifpp.so* correctly matches libcifpp.so, libcifpp.so.10, etc.
CIFPP_BUILD_DIR="${SRC_DIR}/build/_deps/cifpp-build"
if [[ "${target_platform}" == "linux-"* ]]; then
    find "${CIFPP_BUILD_DIR}" -maxdepth 2 -name "libcifpp.so*" \
        -exec cp -vP {} "${PREFIX}/lib/" \;
elif [[ "${target_platform}" == "osx-"* ]]; then
    find "${CIFPP_BUILD_DIR}" -maxdepth 2 -name "libcifpp*.dylib" \
        -exec cp -vP {} "${PREFIX}/lib/" \;
fi

# Extract components.cif.gz
# Refer to https://github.com/conda-forge/dssp-feedstock/issues/45
cp -f "${SRC_DIR}/build/_deps/cifpp-src/rsrc/"* "${PREFIX}/share/libcifpp/"
if [[ -f "${PREFIX}/share/libcifpp/components.cif.gz" ]]; then
    gunzip -fk "${PREFIX}/share/libcifpp/components.cif.gz"
fi

# activaton and deactivation scripts
mkdir -p "${PREFIX}/etc/conda/activate.d"
mkdir -p "${PREFIX}/etc/conda/deactivate.d"
install -m 644 "${RECIPE_DIR}/activate.sh" "${PREFIX}/etc/conda/activate.d/dssp_activate.sh"
install -m 644 "${RECIPE_DIR}/deactivate.sh" "${PREFIX}/etc/conda/deactivate.d/dssp_deactivate.sh"
install -m 644 "${RECIPE_DIR}/activate.fish" "${PREFIX}/etc/conda/activate.d/dssp_activate.fish"
install -m 644 "${RECIPE_DIR}/deactivate.fish" "${PREFIX}/etc/conda/deactivate.d/dssp_deactivate.fish"
