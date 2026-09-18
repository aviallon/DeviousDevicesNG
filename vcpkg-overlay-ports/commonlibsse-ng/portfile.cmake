# Local overlay of the Color-Glass "commonlibsse-ng" port (registry baseline
# 6309841a1ce770409708a67a9ba5c26c537d2937, CommonLibSSE-NG v3.7.0).
#
# The pinned upstream release predates Skyrim 1.7.99 and therefore cannot load
# the new Address Library encoding (format 5, versionlib-1-7-104-0.bin).
# format5-address-library.patch teaches REL::IDDatabase to parse format 5 and
# to classify the 1.7.x runtime as AE (upstream only handled minor version 6).
#
# This keeps the plugin source compatible with the v3.7.0 API while making it
# usable on the current AE runtime. Remove the overlay once a CommonLibSSE-NG
# release with upstream format-5 support is used.
vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO CharmedBaryon/CommonLibSSE
        REF c4ab853d095e81e3390b282d7ba01ab2f24ebf25
        SHA512  fd615c16f8f2c637cad5ed9d139c776d21314664f4084a62231645114d03ee74e720c1ecf09b4e5daa5d56d418374ad6d587806788d95af8ac08ce3de930015b
        HEAD_REF main
        PATCHES
            format5-address-library.patch
)

vcpkg_configure_cmake(
        SOURCE_PATH "${SOURCE_PATH}"
        PREFER_NINJA
        OPTIONS -DBUILD_TESTS=off -DSKSE_SUPPORT_XBYAK=on
)

vcpkg_install_cmake()
vcpkg_cmake_config_fixup(PACKAGE_NAME CommonLibSSE CONFIG_PATH lib/cmake)
vcpkg_copy_pdbs()

file(GLOB CMAKE_CONFIGS "${CURRENT_PACKAGES_DIR}/share/CommonLibSSE/CommonLibSSE/*.cmake")
file(INSTALL ${CMAKE_CONFIGS} DESTINATION "${CURRENT_PACKAGES_DIR}/share/CommonLibSSE")
file(INSTALL "${SOURCE_PATH}/cmake/CommonLibSSE.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/CommonLibSSE")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/share/CommonLibSSE/CommonLibSSE")

file(
        INSTALL "${SOURCE_PATH}/LICENSE"
        DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
        RENAME copyright)
