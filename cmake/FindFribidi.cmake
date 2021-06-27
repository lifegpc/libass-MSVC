#[=======================================================================[.rst:
FindFribidi
-------

Finds the Fribidi library.

Imported Targets
^^^^^^^^^^^^^^^^

This module provides the following imported targets, if found:

``Fribidi::Fribidi``
  The Fribidi library

Result Variables
^^^^^^^^^^^^^^^^

This will define the following variables:

``Fribidi_FOUND``
  True if the system has the Fribidi library.
``Fribidi_VERSION``
  The version of the Fribidi library which was found.
``Fribidi_INCLUDE_DIRS``
  Include directories needed to use Fribidi.
``Fribidi_LIBRARIES``
  Libraries needed to link to Fribidi.

Cache Variables
^^^^^^^^^^^^^^^

The following cache variables may also be set:

``Fribidi_INCLUDE_DIR``
  The directory containing ``Fribidi.h``.
``Fribidi_LIBRARY``
  The path to the Fribidi library.

#]=======================================================================]

find_package(PkgConfig)
if (PkgConfig_FOUND)
    pkg_check_modules(PC_Fribidi QUIET fribidi)
endif()

if (PC_Fribidi_FOUND)
find_path(Fribidi_INCLUDE_DIR
    NAMES fribidi.h
    PATHS ${PC_Fribidi_INCLUDE_DIRS}
    PATH_SUFFIXES fribidi
)
find_library(Fribidi_LIBRARY
    NAMES fribidi
    PATHS ${PC_Fribidi_LIBRARY_DIRS}
)
set(Fribidi_VERSION ${PC_Fribidi_VERSION})
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Fribidi
    FOUND_VAR Fribidi_FOUND
  REQUIRED_VARS
    Fribidi_LIBRARY
    Fribidi_INCLUDE_DIR
  VERSION_VAR Fribidi_VERSION
)
if (Fribidi_FOUND)
    set(Fribidi_LIBRARIES ${Fribidi_LIBRARY})
    set(Fribidi_INCLUDE_DIRS ${Fribidi_INCLUDE_DIR})
    set(Fribidi_DEFINITIONS ${PC_Fribidi_CFLAGS_OTHER})
endif()
if(Fribidi_FOUND AND NOT TARGET Fribidi::Fribidi)
  add_library(Fribidi::Fribidi UNKNOWN IMPORTED)
  set_target_properties(Fribidi::Fribidi PROPERTIES
    IMPORTED_LOCATION "${Fribidi_LIBRARY}"
    INTERFACE_COMPILE_OPTIONS "${PC_Fribidi_CFLAGS_OTHER}"
    INTERFACE_INCLUDE_DIRECTORIES "${Fribidi_INCLUDE_DIR}"
  )
endif()
else()
find_path(Fribidi_INCLUDE_DIR
    NAMES fribidi.h
    PATHS ${CMAKE_PREFIX_PATH}/include
    PATH_SUFFIXES fribidi
)
find_library(Fribidi_LIBRARY
    NAMES fribidi
    PATHS ${CMAKE_PREFIX_PATH}/lib
)
endif()
