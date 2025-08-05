@echo on

@REM Refer to https://github.com/conda-forge/dssp-feedstock/pull/14#issuecomment-2974049079 for `-DCIFPP_DATA_DIR=''`
cmake -S . -B build ^
    %CMAKE_ARGS% ^
    -DCMAKE_PREFIX_PATH="%PREFIX%" ^
    -DCMAKE_CXX_FLAGS="%CXXFLAGS% /EHsc" ^
    -DCMAKE_CXX_STANDARD=20 ^
    -DBUILD_TESTING=OFF ^
    -DINSTALL_LIBRARY=ON ^
    -DBUILD_PYTHON_MODULE=ON ^
    -DPython_ROOT_DIR="%PREFIX%" ^
    -DCIFPP_DOWNLOAD_CCD=ON ^
    -DCIFPP_INSTALL_UPDATE_SCRIPT=OFF ^
    -DCIFPP_DATA_DIR='' ^
    -DCIFPP_SHARE_DIR="%PREFIX%/share/libcifpp" ^
    -DBOOST_ALL_NO_LIB=OFF ^
    -DBOOST_AUTO_LINK_TAGGED=ON ^
    -DCMAKE_EXE_LINKER_FLAGS="/FORCE:MULTIPLE" ^
    -DCMAKE_SHARED_LINKER_FLAGS="/FORCE:MULTIPLE"
if errorlevel 1 exit 1

cmake --build build --config Release --parallel %CPU_COUNT%
if errorlevel 1 exit 1

cmake --install build
if errorlevel 1 exit 1

if not exist "%PREFIX%\share\libcifpp" mkdir "%PREFIX%\share\libcifpp"
if errorlevel 1 exit 1

copy /Y "%SRC_DIR%\build\_deps\cifpp-src\rsrc\*.*" "%PREFIX%\share\libcifpp\"
if errorlevel 1 exit 1

@REM activaton and deactivation scripts for Windows
mkdir "%PREFIX%\etc\conda\activate.d" 2>nul
mkdir "%PREFIX%\etc\conda\deactivate.d" 2>nul
copy /Y "%RECIPE_DIR%\activate.bat" "%PREFIX%\etc\conda\activate.d\dssp_activate.bat"
copy /Y "%RECIPE_DIR%\deactivate.bat" "%PREFIX%\etc\conda\deactivate.d\dssp_deactivate.bat"
if errorlevel 1 exit 1
