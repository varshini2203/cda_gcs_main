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
set(GST_FOUND FALSE)
if(WIN32)
    # pkg-config is normally NOT installed on Windows, so the original
    # pkg_check_modules() call silently returned "not found" and the app was
    # built WITHOUT video support ("NO CAMERA").  Look for the official
    # GStreamer MSVC 64-bit installer directly instead.
    set(_GST_ROOT "$ENV{GSTREAMER_1_0_ROOT_MSVC_X86_64}")
    if(NOT _GST_ROOT)
        set(_GST_ROOT "C:/gstreamer/1.0/msvc_x86_64")
    endif()
    file(TO_CMAKE_PATH "${_GST_ROOT}" _GST_ROOT)
    if(EXISTS "${_GST_ROOT}/include/gstreamer-1.0/gst/gst.h")
        set(GST_FOUND TRUE)
        set(GST_RUNTIME_ROOT ${_GST_ROOT})
        set(GST_INCLUDE_DIRS
            ${_GST_ROOT}/include
            ${_GST_ROOT}/include/gstreamer-1.0
            ${_GST_ROOT}/include/glib-2.0
            ${_GST_ROOT}/lib/glib-2.0/include
            ${_GST_ROOT}/lib/gstreamer-1.0/include
        )
        link_directories(${_GST_ROOT}/lib)
        set(GST_LIBRARIES gstreamer-1.0 gstgl-1.0 gstvideo-1.0 gstbase-1.0 glib-2.0 intl gobject-2.0)
        message(STATUS "GStreamer: found at ${_GST_ROOT} (video streaming ENABLED)")
    else()
        message(WARNING "GStreamer NOT found at ${_GST_ROOT} - video streaming will be DISABLED. "
                        "Install the GStreamer 1.x MSVC 64-bit runtime AND development installers, "
                        "or set GSTREAMER_1_0_ROOT_MSVC_X86_64.")
    endif()
elseif(ANDROID)
    # GStreamer Android universal SDK (gstreamer-1.0-android-universal-1.18.1).
    # Extract it next to this file, or point GSTREAMER_ROOT_ANDROID (cmake -D or
    # environment variable) at its top folder (the one containing armv7/arm64/x86/x86_64).
    if(NOT GSTREAMER_ROOT_ANDROID AND DEFINED ENV{GSTREAMER_ROOT_ANDROID})
        set(GSTREAMER_ROOT_ANDROID "$ENV{GSTREAMER_ROOT_ANDROID}")
    endif()
    if(NOT GSTREAMER_ROOT_ANDROID)
        set(GSTREAMER_ROOT_ANDROID "${CMAKE_SOURCE_DIR}/gstreamer-1.0-android-universal-1.18.1")
    endif()
    file(TO_CMAKE_PATH "${GSTREAMER_ROOT_ANDROID}" GSTREAMER_ROOT_ANDROID)

    if(ANDROID_ABI STREQUAL "armeabi-v7a")
        set(_GST_ABI_DIR armv7)
    elseif(ANDROID_ABI STREQUAL "arm64-v8a")
        set(_GST_ABI_DIR arm64)
    elseif(ANDROID_ABI STREQUAL "x86_64")
        set(_GST_ABI_DIR x86_64)
    else()
        set(_GST_ABI_DIR x86)
    endif()
    set(_GST_ROOT "${GSTREAMER_ROOT_ANDROID}/${_GST_ABI_DIR}")

    if(EXISTS "${_GST_ROOT}/include/gstreamer-1.0/gst/gst.h")
        set(GST_FOUND TRUE)
        set(GST_INCLUDE_DIRS
            ${_GST_ROOT}/include/gstreamer-1.0
            ${_GST_ROOT}/lib/gstreamer-1.0/include
            ${_GST_ROOT}/include/glib-2.0
            ${_GST_ROOT}/lib/glib-2.0/include
        )
        link_directories(${_GST_ROOT}/lib/gstreamer-1.0 ${_GST_ROOT}/lib)
        # Static plugins + dependencies. Order matters for static libraries, so
        # the whole set is linked inside one --start-group/--end-group block.
        set(GST_LIBRARIES
            -Wl,--start-group
            gstcoreelements gstplayback gstudp gstrtp gstrtsp gstx264 gstlibav
            gstsdpelem gstvideoparsersbad gstrtpmanager gstisomp4 gstmatroska
            gstmpegtsdemux gstandroidmedia gstopengl gsttcp
            graphene-1.0 jpeg png16 gstfft-1.0 gstnet-1.0 gio-2.0
            gstphotography-1.0 gstgl-1.0 EGL gstaudio-1.0 gstcodecparsers-1.0
            gstbase-1.0 gstreamer-1.0 gstrtp-1.0 gstpbutils-1.0 gstrtsp-1.0
            gsttag-1.0 gstvideo-1.0 avformat avcodec avutil x264 avfilter
            swresample gstriff-1.0 gstcontroller-1.0 gstapp-1.0 gstsdp-1.0 bz2
            gobject-2.0 gstmpegts-1.0 gmodule-2.0 glib-2.0 orc-0.4 iconv ffi
            intl m
            -Wl,--end-group
            -Wl,--export-dynamic
        )
        add_compile_options(-pthread)
        message(STATUS "GStreamer (Android ${_GST_ABI_DIR}): found at ${_GST_ROOT} (video streaming ENABLED)")
    else()
        message(WARNING "GStreamer for Android NOT found at ${_GST_ROOT} - video streaming will be DISABLED. "
                        "Extract gstreamer-1.0-android-universal-1.18.1 next to CMakeLists.txt "
                        "or set GSTREAMER_ROOT_ANDROID.")
    endif()
else()
    find_package(PkgConfig)
    pkg_check_modules(GST
        gstreamer-1.0>=1.14
        gstreamer-video-1.0>=1.14
        gstreamer-gl-1.0>=1.14
        egl
    )
endif()

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
    -DQGC_ENABLE_BLUETOOTH
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

# Android: GStreamer.cc / VideoManager.cc register the statically linked GStreamer
# plugins only when __android__ is defined (qmake defines it for every file).
if(ANDROID AND GST_FOUND)
	foreach(_tgt VideoReceiver VideoManager)
		if(TARGET ${_tgt})
			target_compile_definitions(${_tgt} PRIVATE __android__)
		endif()
	endforeach()
endif()

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

# Windows: GStreamer DLLs + plugins must sit next to the exe or video will not start.
if(WIN32 AND GST_FOUND)
	add_custom_command(TARGET QGroundControl POST_BUILD
		COMMAND ${CMAKE_COMMAND} -E copy_directory "${GST_RUNTIME_ROOT}/bin" "$<TARGET_FILE_DIR:QGroundControl>"
		COMMAND ${CMAKE_COMMAND} -E copy_directory "${GST_RUNTIME_ROOT}/lib/gstreamer-1.0" "$<TARGET_FILE_DIR:QGroundControl>/gstreamer-plugins"
		COMMENT "Copying GStreamer runtime next to the executable"
	)
endif()

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