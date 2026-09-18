cmake_minimum_required(VERSION 3.21)
message("Using toolchain file ${CMAKE_TOOLCHAIN_FILE}.")

set(VCPKG_MANIFEST_FEATURES ON)

########################################################################################################################
## Define project
########################################################################################################################
project(
        DeviousDevices
        VERSION 3.0.0.1
        DESCRIPTION "NG Implementation of Devious Devices"
        LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)

include(GNUInstallDirs)

configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/cmake/version.rc.in
        ${CMAKE_CURRENT_BINARY_DIR}/version.rc
        @ONLY)

set(headers
        include/Papyrus.h
        include/Expression.h
        include/Hooks.h
        include/Script.hpp
        include/UI.h
        include/Utils.h
        include/Hider.h
        include/NodeHider.h
        include/InventoryFilter.h
        include/UpdateManager.h
        include/Switches.h
        include/DeviceReader.h
        include/Settings.h
        include/LibFunctions.h
        include/Config.h
        include/Serialization.h
        include/Export.h
        include/HooksVirtual.h
        include/MovementManager.h
        include/API.h
)

set(sources
        src/Main.cpp
        src/Papyrus.cpp
        src/Expression.cpp
        src/Hider.cpp
        src/Utils.cpp
        src/NodeHider.cpp
        src/InventoryFilter.cpp
        src/UpdateManager.cpp
        src/DeviceReader.cpp
        src/LibFunctions.cpp
        src/Config.cpp
        src/Serialization.cpp
        src/Export.cpp
        src/HooksVirtual.cpp
        src/MovementManager.cpp
        src/API.cpp
        ${CMAKE_CURRENT_BINARY_DIR}/version.rc)

set(tests
        test/DeviousDevices.cpp
    )

source_group(
        TREE ${CMAKE_CURRENT_SOURCE_DIR}
        FILES
        ${headers}
        ${sources}
        ${tests})

#########################################################################################################################
### Build options
#########################################################################################################################
message("Options:")
option(BUILD_TESTS "Build unit tests." OFF)
message("\tTests: ${BUILD_TESTS}")

########################################################################################################################
## Configure target DLL
########################################################################################################################
include(FetchContent)

# ---------------------------------------------------------------------------
# CommonLibSSE-NG (alandtse fork), pinned to the v8.2.0 commit
# 25440f9a42cac6cc7c4f24c259d7f9abcac4e064.
#
# Consumed with FetchContent + add_subdirectory rather than a vcpkg port:
# this is the consumption path the library itself builds and tests
# (test_consumer / test_consumer_live in its repository), and it avoids the
# installed-package export whose CommonLibSSEConfig.cmake only declares
# find_dependency(spdlog) while the imported target's link interface also
# needs Microsoft::DirectXTK. The dependency set comes from this project's
# vcpkg manifest instead.
#
# v8.2.0 supports Skyrim 1.7.104 and Address Library format 5 natively:
#   - REL::IDDB::Format::SSEv5 with a 64-byte-name format-5 header parser
#     (include/REL/IDDB.h, added by PR #299, released in v6.4.0);
#   - SKSE::RUNTIME_SSE_1_7_104 is defined (include/SKSE/Version.h);
#   - Module::load_version() classifies AE by minor version >= 6, so 1.7.x
#     is not mistaken for SE (include/REL/Module.h).
# It also emits the Address Library V5 bit itself: StructCompatibility::
# Independent is now kVersionIndependentEx_AddressLibraryV5 |
# kVersionIndependentEx_NoStructUse (0x3) in include/SKSE/Interfaces.h, so
# the CMake-generated plugin metadata no longer needs rewriting.
#
# VR is disabled on purpose: DDNG ships a flat SE/AE build, and turning VR off
# avoids the (not fetched) openvr submodule and keeps CommonLibSSE building
# from source instead of resolving a prebuilt bundle.
# ---------------------------------------------------------------------------
set(ENABLE_SKYRIM_SE ON CACHE BOOL "Build with Skyrim SE support" FORCE)
set(ENABLE_SKYRIM_AE ON CACHE BOOL "Build with Skyrim AE support" FORCE)
set(ENABLE_SKYRIM_VR OFF CACHE BOOL "Build with Skyrim VR support" FORCE)
set(SKSE_SUPPORT_XBYAK ON CACHE BOOL "Use Xbyak for trampolines" FORCE)

# BUILD_TESTS is read by CommonLibSSE as well; hide this project's value from
# it so the (large) upstream Catch2 suite is not built here.
set(DDNG_BUILD_TESTS "${BUILD_TESTS}")
set(BUILD_TESTS OFF)
FetchContent_Declare(
        commonlibsse
        GIT_REPOSITORY https://github.com/alandtse/CommonLibSSE-NG.git
        GIT_TAG 25440f9a42cac6cc7c4f24c259d7f9abcac4e064  # v8.2.0
        GIT_PROGRESS TRUE)
FetchContent_MakeAvailable(commonlibsse)
set(BUILD_TESTS "${DDNG_BUILD_TESTS}")
unset(DDNG_BUILD_TESTS)

include("${commonlibsse_SOURCE_DIR}/cmake/CommonLibSSE.cmake")

find_library(Detours_LIBRARIES NAMES detours.lib)

add_commonlibsse_plugin(
        ${PROJECT_NAME}
        AUTHOR "Devious Devices Team"
        SOURCES ${headers} ${sources})

add_library("${PROJECT_NAME}::${PROJECT_NAME}" ALIAS "${PROJECT_NAME}")

target_include_directories(${PROJECT_NAME}
        PRIVATE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/src>
        $<INSTALL_INTERFACE:src>)

target_include_directories(${PROJECT_NAME}
        PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>)

target_link_libraries(${PROJECT_NAME}
        PRIVATE
        ${Detours_LIBRARIES}
)

target_precompile_headers(${PROJECT_NAME}
        PRIVATE
        src/PCH.h)

install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include"
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")

install(TARGETS ${PROJECT_NAME}
        DESTINATION "${CMAKE_INSTALL_LIBDIR}")


########################################################################################################################
## Configure unit tests
########################################################################################################################
if(BUILD_TESTS)
    find_package(Catch2 CONFIG REQUIRED)

    include(CTest)
    include(Catch)

    add_executable(
            ${PROJECT_NAME}Tests
            ${headers}
            ${tests} "test/DeviousDevices.cpp")

    target_link_libraries(
            ${PROJECT_NAME}Tests
            PRIVATE
            ${PROJECT_NAME}
            Catch2::Catch2WithMain)

    target_precompile_headers(${PROJECT_NAME}Tests
            PRIVATE
            src/PCH.h)

    catch_discover_tests(${PROJECT_NAME}Tests)
    add_test(NAME ${PROJECT_NAME}Tests COMMAND ${PROJECT_NAME}Tests)
endif()

if(DEFINED ENV{PluginDeployTarget})
    set(DEPLOY_TARGET $ENV{PluginDeployTarget})
    message("Adding deployment target ${DEPLOY_TARGET}.")
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${PROJECT_NAME}> "${DEPLOY_TARGET}/SKSE/Plugins/")

    if(${CMAKE_BUILD_TYPE} STREQUAL Debug OR ${CMAKE_BUILD_TYPE} STREQUAL RelWithDebInfo)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_PDB_FILE:${PROJECT_NAME}> "${DEPLOY_TARGET}/SKSE/Plugins/")
    endif()
endif()