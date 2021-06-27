#[=======================================================================[.rst:
FindHarfbuzz
-------

Finds the Harfbuzz library.

Imported Targets
^^^^^^^^^^^^^^^^

This module provides the following imported targets, if found:

``Harfbuzz::Harfbuzz``
  The Harfbuzz library

Result Variables
^^^^^^^^^^^^^^^^

This will define the following variables:

``Harfbuzz_FOUND``
  True if the system has the Harfbuzz library.
``Harfbuzz_VERSION``
  The version of the Harfbuzz library which was found.
``Harfbuzz_INCLUDE_DIRS``
  Include directories needed to use Harfbuzz.
``Harfbuzz_LIBRARIES``
  Libraries needed to link to Harfbuzz.

Cache Variables
^^^^^^^^^^^^^^^

The following cache variables may also be set:

``Harfbuzz_INCLUDE_DIR``
  The directory containing ``hb.h``.
``Harfbuzz_LIBRARY``
  The path to the Harfbuzz library.

#]=======================================================================]

find_package(PkgConfig)
if (PkgConfig_FOUND)
    pkg_check_modules(PC_Harfbuzz QUIET harfbuzz)
endif()

if (PC_Harfbuzz_FOUND)
find_path(Harfbuzz_INCLUDE_DIR
    NAMES hb.h
    PATHS ${PC_Harfbuzz_INCLUDE_DIRS}
    PATH_SUFFIXES harfbuzz
)
find_library(Harfbuzz_LIBRARY
    NAMES harfbuzz
    PATHS ${PC_Harfbuzz_LIBRARY_DIRS}
)
set(Harfbuzz_VERSION ${PC_Harfbuzz_VERSION})
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Harfbuzz
    FOUND_VAR Harfbuzz_FOUND
  REQUIRED_VARS
    Harfbuzz_LIBRARY
    Harfbuzz_INCLUDE_DIR
  VERSION_VAR Harfbuzz_VERSION
)
if (Harfbuzz_FOUND)
    set(Harfbuzz_LIBRARIES ${Harfbuzz_LIBRARY})
    set(Harfbuzz_INCLUDE_DIRS ${Harfbuzz_INCLUDE_DIR})
    set(Harfbuzz_DEFINITIONS ${PC_Harfbuzz_CFLAGS_OTHER})
endif()
if(Harfbuzz_FOUND AND NOT TARGET Harfbuzz::Harfbuzz)
  add_library(Harfbuzz::Harfbuzz UNKNOWN IMPORTED)
  set_target_properties(Harfbuzz::Harfbuzz PROPERTIES
    IMPORTED_LOCATION "${Harfbuzz_LIBRARY}"
    INTERFACE_COMPILE_OPTIONS "${PC_Harfbuzz_CFLAGS_OTHER}"
    INTERFACE_INCLUDE_DIRECTORIES "${Harfbuzz_INCLUDE_DIR}"
  )
endif()
else()
find_path(Harfbuzz_INCLUDE_DIR
    NAMES hb.h
    PATHS ${CMAKE_PREFIX_PATH}/include
    PATH_SUFFIXES harfbuzz
)
find_library(Harfbuzz_LIBRARY
    NAMES harfbuzz
    PATHS ${CMAKE_PREFIX_PATH}/lib
)
endif()
