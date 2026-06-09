cmake_minimum_required(VERSION 3.16)

project(Application VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Sql Svg PrintSupport)

qt_standard_project_setup(REQUIRES 6.5)


qt_add_executable(appApplication
    src/main.cpp
    src/PdfExporter.cpp
)

qt_add_qml_module(appApplication
    URI Application

    QML_FILES
        qml/Main.qml
        qml/GlobalState.qml
        qml/components/Typography.qml
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
        qml/screens/BatchMenuScreen.qml

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
        assets/images/folder.png
        assets/images/pdf.png
        assets/images/people.png
        assets/images/USB.png
        assets/images/Reports.png
        assets/images/BatchHistory.png
        assets/images/log.png
        assets/images/edit.png
        assets/images/backspace.png
        assets/images/backspaceBlue.png
        assets/images/capslock.png
        assets/images/RobotoCondensed-Bold.ttf
        assets/images/RobotoCondensed-Regular.ttf


    SOURCES
        src/DatabaseManager.h
        src/DatabaseManager.cpp
        src/SystemController.h
        src/SystemController.cpp
        src/WifiScanner.h
        src/WifiScanner.cpp
        src/PdfExporter.h
        QML_FILES qml/screens/ReportsFolderScreen.qml
        QML_FILES qml/screens/DeveloperSettingsScreen.qml
        SOURCES src/SystemDiagnosis.h
        SOURCES src/SystemDiagnosis.cpp
        QML_FILES qml/screens/ReportsScreen.qml
        QML_FILES qml/screens/ReportsLogScreen.qml
        QML_FILES qml/screens/BatchHistoryScreen.qml
        QML_FILES qml/components/AddProductPopup.qml
        QML_FILES qml/screens/CoilOutputScreen.qml
        QML_FILES qml/components/XyPlotScreen.qml
        SOURCES src/PlotItem.h
        SOURCES src/PlotItem.cpp
        QML_FILES qml/components/AnimationEffect.qml
        QML_FILES qml/components/LogoutPopup.qml
        QML_FILES qml/components/AccessDeniedPopup.qml
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
