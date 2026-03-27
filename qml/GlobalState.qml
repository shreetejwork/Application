pragma Singleton
import QtQuick 2.15

QtObject {
    property real productPhase: 40
    property real machinePhase: 60

    property real signalThreshold: 500
    property real amplitudeThreshold: 400

    property bool loginKeyboardRequest: false
}
