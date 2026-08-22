
# Workaround for SC_BUILD_SHARED_LIBS flag.
# Would prefer to set to OFF.  However, it won't build on Mac with
# flag set to OFF -- and it won't build on MSVC with it set to ON.
IF( WIN32 )
    SET( SC_SHARED OFF )
ELSE()
    SET( SC_SHARED ON )
ENDIF()


SET(SC_CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
SET(SC_CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")

IF(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64" OR CMAKE_SYSTEM_PROCESSOR MATCHES "amd64")
	SET(SC_CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
	SET(SC_CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
ENDIF()

# SC_BUILD_TYPE drives STEPCODE's internal CMAKE_BUILD_TYPE, and therefore the
# MSVC runtime it links (/MDd vs /MD).  Forcing Debug here is a workaround for
# STEPCODE ignoring CMAKE_INSTALL_PREFIX (see note at the end of this file), but
# that only matters on Unix, where a non-Debug build installs to /usr/local/lib.
# On Windows the install path is taken from INSTALL_DIR regardless, and forcing
# Debug produces /MDd libraries that cannot link against a Release OpenVSP
# (LNK2038: _ITERATOR_DEBUG_LEVEL / RuntimeLibrary mismatch).
IF( WIN32 )
	SET( SC_BUILD_TYPE_VALUE ${CMAKE_BUILD_TYPE} )
ELSE()
	SET( SC_BUILD_TYPE_VALUE Debug )
ENDIF()

ExternalProject_Add( STEPCODE
	URL ${CMAKE_CURRENT_SOURCE_DIR}/stepcode-28350d91294b.zip
	DOWNLOAD_EXTRACT_TIMESTAMP TRUE
	CMAKE_ARGS -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
		-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
		-DCMAKE_CXX_FLAGS=${SC_CMAKE_CXX_FLAGS}
		-DCMAKE_C_FLAGS=${SC_CMAKE_C_FLAGS}
		-DSC_BUILD_TYPE=${SC_BUILD_TYPE_VALUE}
		-DSC_BUILD_SCHEMAS=ap203/ap203.exp
		-DSC_BUILD_STATIC_LIBS=ON
		-DSC_BUILD_SHARED_LIBS=${SC_SHARED}
		-DSC_PYTHON_GENERATOR=OFF
		-DSC_INSTALL_PREFIX:PATH=<INSTALL_DIR>
)
ExternalProject_Get_Property( STEPCODE SOURCE_DIR )
ExternalProject_Get_Property( STEPCODE BINARY_DIR )
ExternalProject_Get_Property( STEPCODE INSTALL_DIR )

IF( NOT WIN32 )
	SET( STEPCODE_INSTALL_DIR ${SOURCE_DIR}/../sc-install )
ELSE()
	SET( STEPCODE_INSTALL_DIR ${INSTALL_DIR} )
ENDIF()

SET( STEPCODE_BINARY_DIR ${BINARY_DIR} )

# SC CMake does not honor -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
# Consequently, force Debug so it installs in ../sc-install directory
# instead of /usr/local/lib.
#
# SC's own programs fail to build with -DSC_BUILD_SHARED_LIBS=OFF