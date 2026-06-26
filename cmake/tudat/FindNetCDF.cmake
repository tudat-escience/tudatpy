#[=======================================================================[.rst:
FindNetCDF
----------

Find the NetCDF C and Fortran libraries and create imported targets.

Imported Targets
^^^^^^^^^^^^^^^

``NetCDF::NetCDF_C``
  The NetCDF C library, if found.
``NetCDF::NetCDF_Fortran``
  The NetCDF Fortran library, if found.

Result Variables
^^^^^^^^^^^^^^^^

``NetCDF_FOUND``
  True if both C and Fortran components were found.
``NetCDF_INCLUDE_DIRS``
  NetCDF include directories.
``NetCDF_C_LIBRARIES``
  NetCDF C library paths.
``NetCDF_Fortran_LIBRARIES``
  NetCDF Fortran library paths.
#]=======================================================================]

# Prioritize conda environment if available
if(DEFINED ENV{CONDA_PREFIX})
    set(CONDA_PREFIX $ENV{CONDA_PREFIX})
    list(INSERT CMAKE_PREFIX_PATH 0 ${CONDA_PREFIX})
    message(STATUS "Using conda environment: ${CONDA_PREFIX}")
endif()

set(_NetCDF_SEARCH_PATHS
    ${CMAKE_PREFIX_PATH}
    ${CMAKE_INSTALL_PREFIX}
    $ENV{CONDA_PREFIX}
    $ENV{NetCDF_ROOT}
    $ENV{NETCDF_ROOT}
    $ENV{NetCDF_DIR}
    /usr
    /usr/local
)

set(_NetCDF_LIB_SUFFIXES lib lib64 lib/x86_64-linux-gnu)

if(WIN32)
    set(_NetCDF_LIB_SUFFIXES ${_NetCDF_LIB_SUFFIXES} Library/lib)
    set(_NetCDF_INCLUDE_SUFFIXES include Library/include)
else()
    set(_NetCDF_INCLUDE_SUFFIXES include)
endif()

# Find NetCDF C library
find_library(NetCDF_C_LIBRARY
    NAMES netcdf
    HINTS ${_NetCDF_SEARCH_PATHS}
    PATH_SUFFIXES ${_NetCDF_LIB_SUFFIXES}
    DOC "NetCDF C library"
)

# Find NetCDF Fortran library
find_library(NetCDF_Fortran_LIBRARY
    NAMES netcdff
    HINTS ${_NetCDF_SEARCH_PATHS}
    PATH_SUFFIXES ${_NetCDF_LIB_SUFFIXES}
    DOC "NetCDF Fortran library"
)

# Find NetCDF C include directory
find_path(NetCDF_INCLUDE_DIR
    NAMES netcdf.h
    HINTS ${_NetCDF_SEARCH_PATHS}
    PATH_SUFFIXES ${_NetCDF_INCLUDE_SUFFIXES}
    DOC "NetCDF C include directory"
)

# Find NetCDF Fortran module directory
find_path(NetCDF_Fortran_INCLUDE_DIR
    NAMES netcdf.mod
    HINTS ${_NetCDF_SEARCH_PATHS}
    PATH_SUFFIXES ${_NetCDF_INCLUDE_SUFFIXES}
    DOC "NetCDF Fortran module directory"
)

# In conda environments, Fortran modules are often in the same directory as C headers
if(NOT NetCDF_Fortran_INCLUDE_DIR AND NetCDF_INCLUDE_DIR)
    if(EXISTS "${NetCDF_INCLUDE_DIR}/netcdf.mod")
        set(NetCDF_Fortran_INCLUDE_DIR ${NetCDF_INCLUDE_DIR})
        message(STATUS "Found NetCDF Fortran modules in C include directory")
    endif()
endif()

# Set result variables
if(NetCDF_C_LIBRARY AND NetCDF_Fortran_LIBRARY AND NetCDF_INCLUDE_DIR)
    set(NetCDF_FOUND TRUE)
    set(NetCDF_C_LIBRARIES ${NetCDF_C_LIBRARY})
    set(NetCDF_Fortran_LIBRARIES ${NetCDF_Fortran_LIBRARY})

    set(NetCDF_INCLUDE_DIRS ${NetCDF_INCLUDE_DIR})
    if(NetCDF_Fortran_INCLUDE_DIR AND NOT "${NetCDF_Fortran_INCLUDE_DIR}" STREQUAL "${NetCDF_INCLUDE_DIR}")
        list(APPEND NetCDF_INCLUDE_DIRS ${NetCDF_Fortran_INCLUDE_DIR})
    endif()
    list(REMOVE_DUPLICATES NetCDF_INCLUDE_DIRS)

    # Create imported target for NetCDF C
    if(NOT TARGET NetCDF::NetCDF_C)
        add_library(NetCDF::NetCDF_C UNKNOWN IMPORTED)
        set_target_properties(NetCDF::NetCDF_C PROPERTIES
            IMPORTED_LOCATION "${NetCDF_C_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${NetCDF_INCLUDE_DIR}"
        )
    endif()

    # Create imported target for NetCDF Fortran
    if(NOT TARGET NetCDF::NetCDF_Fortran)
        add_library(NetCDF::NetCDF_Fortran UNKNOWN IMPORTED)
        set_target_properties(NetCDF::NetCDF_Fortran PROPERTIES
            IMPORTED_LOCATION "${NetCDF_Fortran_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${NetCDF_INCLUDE_DIRS}"
            INTERFACE_LINK_LIBRARIES "NetCDF::NetCDF_C"
        )
    endif()

    message(STATUS "NetCDF found:")
    message(STATUS "  NetCDF C library: ${NetCDF_C_LIBRARY}")
    message(STATUS "  NetCDF Fortran library: ${NetCDF_Fortran_LIBRARY}")
    message(STATUS "  NetCDF include dirs: ${NetCDF_INCLUDE_DIRS}")
else()
    set(NetCDF_FOUND FALSE)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(NetCDF
    REQUIRED_VARS NetCDF_C_LIBRARY NetCDF_Fortran_LIBRARY NetCDF_INCLUDE_DIR
    FAIL_MESSAGE "Could not find NetCDF. Please ensure netcdf-fortran is installed: conda install -c conda-forge netcdf-fortran"
)

mark_as_advanced(
    NetCDF_C_LIBRARY
    NetCDF_Fortran_LIBRARY
    NetCDF_INCLUDE_DIR
    NetCDF_Fortran_INCLUDE_DIR
)