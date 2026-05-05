pragma Singleton
import QtQuick 2.15
import Qt.labs.settings 1.1

QtObject {
    id: root

    property Settings settings: Settings {
        category: "GlobalState"

        property bool showDDuster: true
        property bool showNetworkScreen: true
    }

    // ===== PERSISTED PROPERTIES =====
    property bool showDDuster: settings.showDDuster
    property bool showNetworkScreen: settings.showNetworkScreen

    // Sync changes back to storage
    onShowDDusterChanged: settings.showDDuster = showDDuster
    onShowNetworkScreenChanged: settings.showNetworkScreen = showNetworkScreen

    // ===== OTHER PROPERTIES =====
    property real productPhase: 40
    property real machinePhase: 60

    property real signalThreshold: 500
    property real amplitudeThreshold: 400

    property bool loginKeyboardRequest: false
    property var activeInputField: null

    property var globalDateTime: new Date()
}
