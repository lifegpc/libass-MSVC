cmake_minimum_required(VERSION 3.11)

set(ASS_VERSION_MAJOR 0)
set(ASS_VERSION_MINOR 15)
set(ASS_VERSION_MICRO 1)
set(ASS_VERSION ${ASS_VERSION_MAJOR}.${ASS_VERSION_MINOR}.${ASS_VERSION_MICRO})
set(PACKAGE_VERSION ${ASS_VERSION})

project(libass VERSION ${ASS_VERSION})

option(CONFIG_LARGE_TILES "use large tile" ON)
option(BUILD_SHARED_LIBS "Build shared library." ON)
option(BUILD_STATIC_LIBS "Build static library." ON)
option(ENABLE_ASM "Enable ASM." ON)
option(BUILD_ASM_ON_X86_64 "Use x86_64 rather than x86 when using ASM" ON)
option(ENABLE_TEST "enable test program (requires libpng)" ON)
option(ENABLE_COMPARE "enable compare program (requires libpng)" ON)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

find_package(Iconv)
if (Iconv_FOUND)
    set(CONFIG_ICONV 1)
endif()

find_package(Freetype)
find_package(Fribidi)
find_package(Harfbuzz)
find_package(PNG)
find_package(Fontconfig)

if (Fontconfig_FOUND)
    set(CONFIG_FONTCONFIG 1)
endif()

include(CheckIncludeFiles)

CHECK_INCLUDE_FILES(windows.h HAVE_WINDOWS_H)
if (HAVE_WINDOWS_H)
    set(CONFIG_DIRECTWRITE 1)
endif()

if (NOT Freetype_FOUND AND NOT HAVE_WINDOWS_H)
    message(FATAL_ERROR "Either DirectWrite (on Windows) or Fontconfig (Linux, other) is required.")
endif()

include(CheckSymbolExists)
check_symbol_exists(strdup "string.h" HAVE_STRDUP)
check_symbol_exists(strndup "string.h" HAVE_STRNDUP)

set(LIB_OBJS libass/ass.h libass/ass.c libass/ass_types.h libass/ass_utils.h libass/ass_utils.c
libass/ass_compat.h libass/ass_string.h libass/ass_string.c libass/ass_strtod.c
libass/ass_library.h libass/ass_library.c libass/ass_cache.h libass/ass_cache.c libass/ass_cache_template.h
libass/ass_font.h libass/ass_font.c libass/ass_fontselect.h libass/ass_fontselect.c
libass/ass_render.h libass/ass_render.c libass/ass_render_api.c
libass/ass_parse.h libass/ass_parse.c libass/ass_priv.h libass/ass_shaper.h libass/ass_shaper.c
libass/ass_outline.h libass/ass_outline.c libass/ass_drawing.h libass/ass_drawing.c
libass/ass_rasterizer.h libass/ass_rasterizer.c libass/ass_rasterizer_c.c
libass/ass_bitmap.h libass/ass_bitmap.c libass/ass_blur.c libass/ass_func_template.h)

set(PUBLIC_HEADERS libass/ass.h libass/ass_types.h)

find_program(NASM nasm)
if(NASM AND ENABLE_ASM)
    set(CONFIG_ASM 1)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/libass)
    enable_language(ASM_NASM)
    set(CMAKE_ASM_NASM_COMPILE_OBJECT "<CMAKE_ASM_NASM_COMPILER> <INCLUDES> <FLAGS> -o <OBJECT> <SOURCE>")
    add_compile_options(
        "$<$<COMPILE_LANGUAGE:ASM_NASM>:-f $<IF:$<BOOL:$<TARGET_PROPERTY:NASM_OBJ_FORMAT>>, \
        $<TARGET_PROPERTY:NASM_OBJ_FORMAT>, ${CMAKE_ASM_NASM_OBJECT_FORMAT}>>"
    )
    set(NASM_SOURCES libass/x86/rasterizer.asm libass/x86/blend_bitmaps.asm libass/x86/be_blur.asm libass/x86/blur.asm libass/x86/cpuid.asm)
    set_source_files_properties(${NASM_SOURCES} PROPERTIES LANGUAGE ASM_NASM)
    if (BUILD_ASM_ON_X86_64)
        set(CMAKE_ASM_NASM_FLAGS "-DARCH_X86_64=1 -Dprivate_prefix=ass")
    else()
        set(CMAKE_ASM_NASM_FLAGS "-Dprivate_prefix=ass")
    endif()
    list(APPEND LIB_OBJS ${NASM_SOURCES} libass/x86/cpuid.h)
endif()

if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.git")
    find_program(GIT git)
    if (GIT)
        execute_process(COMMAND ${GIT} -C "${CMAKE_CURRENT_SOURCE_DIR}" describe --tags --long --always --dirty --broken --abbrev=40 OUTPUT_VARIABLE GIT_DESCRIBE)
        set(CONFIG_SOURCEVERSION "commit: ${GIT_DESCRIBE}")
        string(REPLACE "\n" "" CONFIG_SOURCEVERSION ${CONFIG_SOURCEVERSION})
    else()
        set(CONFIG_SOURCEVERSION "custom after: ${ASS_VERSION}")
    endif()
else()
    set(CONFIG_SOURCEVERSION "tarball: ${ASS_VERSION}")
endif()

configure_file(cmake_config.h config.h)

if (MSVC)
    configure_file(libass.rc.in libass.rc)
    set(RC_FILE ${CMAKE_CURRENT_BINARY_DIR}/libass.rc)
endif()

if (CONFIG_DIRECTWRITE)
    list(APPEND LIB_OBJS libass/ass_directwrite.c libass/ass_directwrite.h libass/dwrite_c.h)
endif()

if (Fontconfig_FOUND)
    list(APPEND LIB_OBJS libass/ass_fontconfig.c libass/ass_fontconfig.h)
endif()

if (BUILD_SHARED_LIBS)
    add_library(libass SHARED ${LIB_OBJS} ${RC_FILE})
    set_target_properties(libass PROPERTIES OUTPUT_NAME ass)
    if(MSVC)
        target_link_options(libass PRIVATE "/DEF:${CMAKE_CURRENT_SOURCE_DIR}/libass/libass.def")
    endif()
    list(APPEND TARGETS libass)
endif()
if (BUILD_STATIC_LIBS)
    add_library(libass-static STATIC ${LIB_OBJS})
    if (NOT MSVC OR (MSVC AND NOT BUILD_SHARED_LIBS))
        set_target_properties(libass-static PROPERTIES OUTPUT_NAME ass)
    else()
        set_target_properties(libass-static PROPERTIES OUTPUT_NAME ass-static)
    endif()
    list(APPEND TARGETS libass-static)
endif()

include_directories(${CMAKE_BINARY_DIR})

if (Iconv_FOUND)
    include_directories(${Iconv_INCLUDE_DIRS})
endif()
if(FREETYPE_FOUND)
    include_directories(${FREETYPE_INCLUDE_DIRS})
endif()
if (Fribidi_FOUND)
    include_directories(${Fribidi_INCLUDE_DIRS})
endif()
if (HARFBUZZ_FOUND)
    include_directories(${HARFBUZZ_INCLUDE_DIRS})
endif()
if (PNG_FOUND)
    include_directories(${PNG_INCLUDE_DIRS})
endif()
if (Fontconfig_FOUND)
    include_directories(${Fontconfig_INCLUDE_DIRS})
endif()

foreach(TAR ${TARGETS})
    if (Iconv_FOUND)
        target_link_libraries(${TAR} Iconv::Iconv)
    endif()
    if (FREETYPE_FOUND)
        target_link_libraries(${TAR} Freetype::Freetype)
    endif()
    if (Fribidi_FOUND)
        target_link_libraries(${TAR} Fribidi::Fribidi)
    endif()
    if (HARFBUZZ_FOUND)
        target_link_libraries(${TAR} Harfbuzz::Harfbuzz)
    endif()
    if (Fontconfig_FOUND)
        target_link_libraries(${TAR} Fontconfig::Fontconfig)
    endif()
endforeach(TAR TARGETS)

set(prefix ${CMAKE_PREFIX_PATH})
set(exec_prefix ${CMAKE_SOURCE_DIR})
if (NOT CMAKE_INSTALL_LIBDIR)
    set(CMAKE_INSTALL_LIBDIR lib)
    set(libdir "${CMAKE_INSTALL_PREFIX}/lib")
else()
    set(libdir ${CMAKE_INSTALL_LIBDIR})
endif()
if (NOT CMAKE_INSTALL_INCLUDEDIR)
    set(CMAKE_INSTALL_INCLUDEDIR include/ass)
    set(includedir "${CMAKE_INSTALL_PREFIX}/include/ass")
else()
    set(includedir ${CMAKE_INSTALL_INCLUDEDIR})
endif()
if (NOT CMAKE_INSTALL_BINDIR)
    set(CMAKE_INSTALL_BINDIR bin)
endif()

configure_file(libass.pc.in libass.pc)

install(TARGETS ${TARGETS}
LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

if (BUILD_SHARED_LIBS AND MSVC)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/ass.lib TYPE LIB)
endif()

install(FILES ${PUBLIC_HEADERS} TYPE INCLUDE)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libass.pc DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig)

if (ENABLE_TEST OR ENABLE_COMPARE)
    if (BUILD_SHARED_LIBS)
        set(LINK_TARGET libass)
    else()
        set(LINK_TARGET libass-static)
    endif()
endif()

if (ENABLE_TEST AND PNG_FOUND)
    add_executable(test test/test.c)
    target_link_libraries(test ${LINK_TARGET})
    target_link_libraries(test PNG::PNG)
endif()

if (ENABLE_COMPARE AND PNG_FOUND)
    add_executable(compare compare/image.h compare/image.c compare/compare.c)
    target_link_libraries(compare ${LINK_TARGET})
    target_link_libraries(compare PNG::PNG)
endif()
