cmake_minimum_required(VERSION 3.10)

project(ChennaiDroneAcademy LANGUAGES C CXX)

set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug;Release;RelWithDebInfo;MinSizeRel;Coverage")

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

include(FeatureSummary)

if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
	add_compile_options(-Wall -Wextra)
endif()

# CMake build type
# Debug Release RelWithDebInfo MinSizeRel Coverage
if (NOT CMAKE_BUILD_TYPE)
	# default to release with debug symbols
	set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Build type" FORCE)
endif()

# Add folder where are supportive functions
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Configure Qt5 to get necessary variables
include(Qt5QGCConfiguration)
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Qt version: ${QT_VERSION}")
message(STATUS "Qt spec: ${QT_MKSPEC}")

set(COMPANY "Chennai Drone Academy")
set(COPYRIGHT "Copyright (c) 2026 Chennai Drone Academy. All rights reserved.")
set(IDENTIFIER "org.chennaidroneacademy.cdagcs")

add_definitions(
	-DQGC_APPLICATION_NAME="Chennai Drone Academy"
	-DQGC_ORG_NAME="Chennai Drone Academy"
	-DQGC_ORG_DOMAIN="org.chennaidroneacademy"
        )

include(Git)
message(STATUS "QGroundControl version: ${GIT_VERSION}")

#=============================================================================
# ccache
#
option(CCACHE "Use ccache if available" ON)
find_program(CCACHE_PROGRAM ccache)
if (CCACHE AND CCACHE_PROGRAM AND NOT DEFINED ENV{CCACHE_DISABLE})
	set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
endif()

#=============================================================================
# Compile QML
#
option(COMPILE_QML "Pre-compile QML files using the Qt Quick compiler." FALSE)
add_feature_info(COMPILE_QML COMPILE_QML "Pre-compile QML files using the Qt Quick compiler.")
if(COMPILE_QML)
    find_package(Qt5QuickCompiler)

    set_package_properties(Qt5QuickCompiler PROPERTIES
	DESCRIPTION "Pre-compile QML files using the Qt Quick compiler."
	TYPE OPTIONAL
    )
endif()

#=============================================================================
# Debug QML
#
option(DEBUG_QML "Build QGroundControl with QML debugging/profiling support." FALSE)
add_feature_info(DEBUG_QML DEBUG_QML "Build QGroundControl with QML debugging/profiling support.")
if(DEBUG_QML)
    message(STATUS "To enable the QML debugger/profiler, run with: '-qmljsdebugger=port:1234'")
    add_definitions(-DQMLJSDEBUGGER)
    add_definitions(-DQT_DECLARATIVE_DEBUG)
    add_definitions(-DQT_QML_DEBUG)
endif()

#=============================================================================
# GStreamer
#
find_package(PkgConfig)
pkg_check_modules(GST
    gstreamer-1.0>=1.14
    gstreamer-video-1.0>=1.14
    gstreamer-gl-1.0>=1.14
    egl
)

if (GST_FOUND)
    include_directories(
	${GST_INCLUDE_DIRS}
	src/Taisync
	src/Microhard
    )
    add_definitions(
	-DQGC_GST_STREAMING
	-DQGC_GST_TAISYNC_ENABLED
	-DQGC_GST_MICROHARD_ENABLED
    )
endif()

add_definitions(
    -DQGC_ENABLE_MAVLINK_INSPECTOR
)

#=============================================================================
# Qt5
#
find_package(Qt5 ${QT_VERSION}
	COMPONENTS
	        Bluetooth
		Charts
		Concurrent
		Core
		Location
		Multimedia
		Network
		Positioning
		Quick
		QuickControls2
		QuickWidgets
		OpenGL
		Sql
		Svg
		Test
		TextToSpeech
		Widgets
		Xml
	REQUIRED
	HINTS
	        ${QT_LIBRARY_HINTS}
)

if(ANDROID)
	find_package(Qt5 ${QT_VERSION}
		COMPONENTS
		        AndroidExtras
		REQUIRED
		HINTS
		        ${QT_LIBRARY_HINTS}
	)
        add_definitions(-D__mobile__)
endif()

if(NOT QT_MKSPEC MATCHES "winrt")
	find_package(Qt5 ${QT_VERSION}
		COMPONENTS
		        SerialPort
		REQUIRED
		HINTS
		        ${QT_LIBRARY_HINTS}
	)
endif()

# Sets the default flags for compilation and linking.
include(CompileOptions)

include_directories(
	libs/eigen

	libs/mavlink/include/mavlink/v2.0
	libs/mavlink/include/mavlink/v2.0/ardupilotmega
	libs/mavlink/include/mavlink/v2.0/common

	libs/shapelib
)

add_subdirectory(libs)
add_subdirectory(src)

set(QGC_RESOURCES
	qgcresources.qrc
	qgroundcontrol.qrc
	qgcimages.qrc
	src/FirmwarePlugin/APM/APMResources.qrc
	src/FirmwarePlugin/PX4/PX4Resources.qrc
	src/Airmap/airmap.qrc
	src/Airmap/dummy/airmap_dummy.qrc
	src/ui/Auth/Auth.qrc
	src/ui/SettingsTheme/SettingsTheme.qrc
        )

if(BUILD_TESTING)
	list(APPEND QGC_RESOURCES
		UnitTest.qrc
	)
endif()

if(ANDROID)
	add_library(QGroundControl SHARED ${QGC_RESOURCES})
elseif(WIN32)
	add_executable(QGroundControl ${QGC_RESOURCES} qgcwinicon.rc)
else()
	add_executable(QGroundControl ${QGC_RESOURCES})
endif()

# Windows only: name the output exe ChennaiDroneAcademy.exe.
# (Not applied on Android - the APK needs libQGroundControl.so.)
if(WIN32)
	set_target_properties(QGroundControl PROPERTIES OUTPUT_NAME "ChennaiDroneAcademy")
endif()

target_link_libraries(QGroundControl PRIVATE qgc)

if(ANDROID)
	target_link_options(QGroundControl PRIVATE "-Wl,-u,main")
endif()

if(BUILD_TESTING)
	target_link_libraries(QGroundControl PRIVATE Qt5::Test)
endif()

if(NOT QT_MKSPEC MATCHES "winrt")
	target_link_libraries(QGroundControl
		PUBLIC
		        Qt5::SerialPort
		)
endif()

# QGCDeploy.cmake refers to the build target through the project name,
# and the target is still called QGroundControl.
set(PROJECT_NAME QGroundControl)
set(CMAKE_PROJECT_NAME QGroundControl)

include(QGCDeploy)