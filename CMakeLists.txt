cmake_minimum_required(VERSION 3.16)

project(Application VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appApplication
    src/main.cpp
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
        RESOURCES
            assets/images/Bell.png
            assets/images/Menu.png
            assets/images/User.png
            assets/images/PowerOff.png
            assets/images/Back.png
            assets/images/AuditTrail.png
            assets//images/FactorySettings.png
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
            QML_FILES qml/components/ActionButton.qml
            QML_FILES qml/components/ValueControl.qml
            QML_FILES qml/components/CircleActionButton.qml
            QML_FILES qml/screens/AutoLearnScreen.qml
            QML_FILES qml/components/CustomPopup.qml
            QML_FILES qml/GlobalState.qml
            QML_FILES qml/screens/SysDetailsScreen.qml
            QML_FILES qml/screens/MenuScreen.qml
            QML_FILES qml/components/MenuTile.qml
            QML_FILES qml/screens/UserScreen.qml
            QML_FILES qml/screens/FactorySettingsScreen.qml
            QML_FILES qml/components/LoginPopup.qml
            QML_FILES qml/components/CreateUserPopup.qml
            QML_FILES qml/components/DeleteUserPopup.qml
            QML_FILES qml/components/EditPasswordPopup.qml
            QML_FILES qml/screens/SysSettingsScreen.qml


)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appApplication PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appHomePage
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appApplication
    PRIVATE Qt6::Quick
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
