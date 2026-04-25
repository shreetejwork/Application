cmake_minimum_required(VERSION 3.16)

project(Application VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Sql Svg PrintSupport)

qt_standard_project_setup(REQUIRES 6.8)

# ✅ FIX: Add PdfExporter.cpp to executable
qt_add_executable(appApplication
    src/main.cpp
    src/PdfExporter.cpp   # 👈 IMPORTANT FIX
)

qt_add_qml_module(appApplication
    URI Application

    QML_FILES
        qml/Main.qml
        qml/screens/HomeScreen.qml
        qml/screens/DDusterScreen.qml
        qml/components/TopBar.qml
        qml/components/AnalogGauge.qml
        qml/components/CircularGauge.qml
        qml/components/CoilProgressBar.qml
        qml/components/DDButton.qml
        qml/components/NavPageIndicator.qml

        qml/components/ActionButton.qml
        qml/components/ValueControl.qml
        qml/components/CircleActionButton.qml
        qml/screens/AutoLearnScreen.qml
        qml/components/CustomPopup.qml
        qml/GlobalState.qml
        qml/screens/SysDetailsScreen.qml
        qml/screens/MenuScreen.qml
        qml/components/MenuTile.qml
        qml/screens/UserScreen.qml
        qml/screens/FactorySettingsScreen.qml
        qml/components/LoginPopup.qml
        qml/components/CreateUserPopup.qml
        qml/components/DeleteUserPopup.qml
        qml/components/EditPasswordPopup.qml
        qml/screens/SysSettingsScreen.qml
        qml/components/SettingsS1.qml
        qml/components/SettingsS2.qml
        qml/components/SettingsS3.qml
        qml/components/SettingsS4.qml
        qml/components/CommonKeyboard.qml
        qml/components/SettingsS5.qml
        qml/screens/DiagnosisScreen.qml
        qml/components/DiagCard.qml
        qml/components/SettingsS6.qml
        qml/screens/AuditTrailScreen.qml
        qml/screens/BatchReportScreen.qml
        qml/screens/ProductLibraryScreen.qml
        qml/components/PowerOffPopup.qml
        qml/components/PdfPreview.qml

    RESOURCES
        assets/images/Bell.png
        assets/images/Menu.png
        assets/images/User.png
        assets/images/PowerOff.png
        assets/images/Back.png
        assets/images/AuditTrail.png
        assets/images/FactorySettings.png
        assets/images/More.png
        assets/images/ProductLib.png
        assets/images/Settings.png
        assets/images/UserCircle.png
        assets/images/userNew.png
        assets/images/updated.png
        assets/images/usbupdate.png
        assets/images/supplier.png
        assets/images/bug.png
        assets/images/coding.png
        assets/images/social.png
        assets/images/diagnosis.png
        assets/images/calendar.png
        assets/images/filter.png

    # ✅ Keep other C++ sources here (optional but fine)
    SOURCES
        src/DatabaseManager.h
        src/DatabaseManager.cpp
        src/SystemController.h
        src/SystemController.cpp
        src/WifiScanner.h
        src/WifiScanner.cpp

        # ❌ REMOVED PdfExporter.cpp from here
        # (THIS WAS CAUSING LINKER ISSUE)
        src/PdfExporter.h
)

set_target_properties(appApplication PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
)

target_link_libraries(appApplication
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Sql
    PRIVATE Qt6::Svg
    PRIVATE Qt6::PrintSupport
)

include(GNUInstallDirs)

install(TARGETS appApplication
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

file(GLOB_RECURSE APP_ASSET_FILES CONFIGURE_DEPENDS
    assets/*
)

if(APP_ASSET_FILES)
    target_sources(appApplication PRIVATE ${APP_ASSET_FILES})
endif()
