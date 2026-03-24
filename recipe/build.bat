@echo on

@REM Enable `find_package` to detect boost on Windows
sed -i "s#if(NOT WIN32)#if(TRUE)#" python-module/CMakeLists.txt
if errorlevel 1 exit 1
sed -i "s#if(WIN32 OR NOT Boost_FOUND)#if(NOT Boost_FOUND)#" python-module/CMakeLists.txt
if errorlevel 1 exit 1
sed -i "s#find_package(Python 3.13#find_package(Python 3#" python-module/CMakeLists.txt
if errorlevel 1 exit 1

@REM Refer to https://github.com/conda-forge/dssp-feedstock/pull/14#issuecomment-2974049079 for `-DCIFPP_DATA_DIR=''`
cmake -S . -B build -G "NMake Makefiles JOM" ^
    %CMAKE_ARGS% ^
    -DCMAKE_CXX_FLAGS="%CXXFLAGS% /EHsc" ^
    -DCMAKE_CXX_STANDARD=20 ^
    -DBUILD_SHARED_LIBS=ON ^
    -DBUILD_TESTING=OFF ^
    -DINSTALL_LIBRARY=ON ^
    -DBUILD_PYTHON_MODULE=ON ^
    -DPython_ROOT_DIR="%PREFIX%" ^
    -DCIFPP_DOWNLOAD_CCD=ON ^
    -DCIFPP_INSTALL_UPDATE_SCRIPT=OFF ^
    -DCIFPP_DATA_DIR='' ^
    -DCIFPP_SHARE_DIR="%PREFIX%/share/libcifpp"
if errorlevel 1 exit 1

cmake --build build --parallel %CPU_COUNT%
if errorlevel 1 exit 1

cmake --install build
if errorlevel 1 exit 1

@REM libcifpp is not available as a standalone package on conda-forge,
@REM so we need to manually copy the shared library built as a CMake
@REM FetchContent dependency into the package prefix.
@REM On Windows, the shared library is split into two files:
@REM   cifpp.dll  - the runtime shared library, copied to Library\bin\
@REM   cifpp.lib  - the import library,         copied to Library\lib\
set CIFPP_BUILD_DIR=%SRC_DIR%\build\_deps\cifpp-build
if errorlevel 1 exit 1
if exist "%CIFPP_BUILD_DIR%\cifpp.dll" (
    copy /Y "%CIFPP_BUILD_DIR%\cifpp.dll" "%PREFIX%\Library\bin\"
    copy /Y "%CIFPP_BUILD_DIR%\cifpp.lib" "%PREFIX%\Library\lib\"
)
if errorlevel 1 exit 1

if not exist "%PREFIX%\share\libcifpp" mkdir "%PREFIX%\share\libcifpp"
if errorlevel 1 exit 1

copy /Y "%SRC_DIR%\build\_deps\cifpp-src\rsrc\*.*" "%PREFIX%\share\libcifpp\"
if errorlevel 1 exit 1

@REM Extract components.cif.gz
@REM Refer to https://github.com/conda-forge/dssp-feedstock/issues/45
IF EXIST "%PREFIX%\share\libcifpp\components.cif.gz" (
    echo Decompressing components. cif.gz -^> components.cif
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "& {" ^
      "  $ErrorActionPreference = 'Stop';" ^
      "  $InFile = '%PREFIX%\\share\\libcifpp\\components.cif.gz';" ^
      "  $OutFile = '%PREFIX%\\share\\libcifpp\\components.cif';" ^
      "  try {" ^
      "    $FileStream = [System.IO.File]::OpenRead($InFile);" ^
      "    $GzipStream = [System.IO.Compression.GzipStream]::new($FileStream, [System.IO.Compression. CompressionMode]::Decompress);" ^
      "    $OutputFileStream = [System.IO. File]::Create($OutFile);" ^
      "    $GzipStream.CopyTo($OutputFileStream);" ^
      "  } finally {" ^
      "    if ($GzipStream) { $GzipStream.Dispose() };" ^
      "    if ($OutputFileStream) { $OutputFileStream.Dispose() };" ^
      "    if ($FileStream) { $FileStream.Dispose() };" ^
      "  }" ^
      "}"
    if errorlevel 1 (
        echo ERROR: Failed to decompress "%PREFIX%\share\libcifpp\components.cif.gz"
        exit /b 1
    )
    echo Successfully decompressed components.cif.gz
) ELSE (
    echo "%PREFIX%\share\libcifpp\components.cif.gz" not found, skipping decompression.
)

@REM activaton and deactivation scripts for Windows
if not exist "%PREFIX%\etc\conda\activate.d" mkdir "%PREFIX%\etc\conda\activate.d"
if errorlevel 1 exit 1

if not exist "%PREFIX%\etc\conda\deactivate.d" mkdir "%PREFIX%\etc\conda\deactivate.d"
if errorlevel 1 exit 1

copy /Y "%RECIPE_DIR%\activate.bat" "%PREFIX%\etc\conda\activate.d\dssp_activate.bat"
if errorlevel 1 exit 1

copy /Y "%RECIPE_DIR%\deactivate.bat" "%PREFIX%\etc\conda\deactivate.d\dssp_deactivate.bat"
if errorlevel 1 exit 1
