if (ANDROID)
	find_package(Qt5 REQUIRED COMPONENTS Core AndroidExtras)

	add_library(qtandroidserialport
		src/qserialport.cpp
		src/qserialport_android.cpp
		src/qserialportinfo.cpp
		src/qserialportinfo_android.cpp
	)

        target_link_libraries(qtandroidserialport
		PUBLIC
		        Qt5::Core
			Qt5::AndroidExtras
	)

        target_include_directories(qtandroidserialport
		PRIVATE
		        ${Qt5Core_PRIVATE_INCLUDE_DIRS}
			${CMAKE_SOURCE_DIR}/src
		INTERFACE
		        ${CMAKE_CURRENT_SOURCE_DIR}
	)
endif()