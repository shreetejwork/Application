import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import AppState 1.0
import Backend 1.0


Popup {

    id: validationPopup


    Typography {
        id: popupTypography
        scale: uiScale
    }


    property real baseWidth: 1024
    property real baseHeight: 600


    property real uiScale:
        Math.min(
            Overlay.overlay.width / baseWidth,
            Overlay.overlay.height / baseHeight
        )


    width: 750 * uiScale
    height: 500 * uiScale


    x: (Overlay.overlay.width - width)/2
    y: (Overlay.overlay.height - height)/2


    modal: true
    focus: true

    closePolicy: Popup.NoAutoClose



    //==============================
    // VALIDATION VARIABLES
    //==============================


    property int totalRounds: 3

    property int currentRound: 0

    property int remainingSeconds: 180


    property bool rejectCycleStarted:false

    property bool sampleRejected:false


    property var roundStatus:[
        false,
        false,
        false
    ]



    //==============================
    // TIMER
    //==============================


    Timer {

        id: validationTimer

        interval:1000

        repeat:true

        running:false


        onTriggered: {


            if(validationPopup.remainingSeconds > 0)
            {
                validationPopup.remainingSeconds--
            }


            else
            {

                validationPopup.roundFailed()

            }

        }
    }



    function startValidation()
    {

        currentRound = 0

        remainingSeconds = 180

        roundStatus=[
                    false,
                    false,
                    false
                    ]


        validationMessage.text =
                "Please pass the sample for validation"


        validationTimer.start()

    }



    //==============================
    // SIGNAL CHECK
    //==============================


    Connections {


        target: SerialManager


        function onSignalChanged()
        {


            if(!validationPopup.visible)
                return



            // signal crossed threshold

            if(SerialManager.signal >
                    GlobalState.signalThreshold)
            {


                if(!validationPopup.rejectCycleStarted)
                {

                    validationPopup.rejectCycleStarted=true

                }

            }


            // signal returned

            else
            {


                if(validationPopup.rejectCycleStarted)
                {


                    validationPopup.rejectCycleStarted=false


                    validationPopup.roundFailed()


                }

            }

        }
    }




    function roundFailed()
    {


        validationTimer.stop()



        if(currentRound < totalRounds)
        {


            roundStatus[currentRound]=true


            currentRound++



            // all 3 failed

            if(currentRound >= totalRounds)
            {

                validationMessage.text =
                        "Validation Failed"


                return

            }


            // restart next sample

            remainingSeconds=180


            validationMessage.text =
                    "Please pass the sample for validation"



            validationTimer.start()


        }

    }



    function roundPassed()
    {

        validationTimer.stop()


        validationMessage.text =
                "Validation Passed"


        console.log("Validation Successful")


        close()

    }





    //================================
    // DESIGN
    //================================


    background: Item {


        Rectangle {


            anchors.fill: parent


            radius:25 * uiScale


            color:"#FFFFFF"


            border.color:"#D0D8EC"

            border.width:2



        }


        ColumnLayout {


            anchors.fill:parent


            anchors.margins:35*uiScale


            spacing:25*uiScale




            Text {


                Layout.alignment:
                    Qt.AlignHCenter


                text:"Validation Screen"


                font.pixelSize:
                    popupTypography.title


                color:"#1A4DB5"

            }





            Rectangle {


                Layout.fillWidth:true

                height:70*uiScale


                radius:12


                color:"#F5F7FC"


                border.color:"#1A4DB5"



                Text {


                    anchors.centerIn:parent


                    text:

                    {

                        var m=Math.floor(
                                    validationPopup.remainingSeconds/60)

                        var s=
                        validationPopup.remainingSeconds%60


                        return "Time Remaining  "
                        +
                        (m<10?"0":"")
                        +m
                        +
                        ":"
                        +
                        (s<10?"0":"")
                        +s

                    }


                    font.pixelSize:
                        popupTypography.heading


                    color:"#1A4DB5"

                }


            }





            Item {

                Layout.fillHeight:true

            }





            Text {


                id:validationMessage


                Layout.alignment:
                    Qt.AlignHCenter


                text:
                "Please pass the sample for validation"


                font.pixelSize:
                    popupTypography.heading


                color:"#1A1A2E"


            }





            //=========================
            // ROUND INDICATORS
            //=========================


            Row {


                Layout.alignment:
                    Qt.AlignHCenter


                spacing:25



                Repeater {


                    model:3



                    delegate:Rectangle {


                        width:45*uiScale

                        height:45*uiScale


                        radius:25



                        color:

                        validationPopup.roundStatus[index]

                        ?
                        "#FF3B30"

                        :
                        "#C8C8C8"



                        Text {


                            anchors.centerIn:parent


                            text:index+1


                            color:"white"


                            font.pixelSize:18*uiScale

                        }


                    }

                }

            }





            Item {

                Layout.fillHeight:true

            }



            Rectangle {


                Layout.alignment:
                    Qt.AlignHCenter


                width:180*uiScale

                height:55*uiScale


                radius:12


                color:"#1A4DB5"



                Text {


                    anchors.centerIn:parent


                    text:"Cancel"


                    color:"white"


                    font.pixelSize:
                        popupTypography.body

                }



                MouseArea {


                    anchors.fill:parent


                    onClicked:
                    {

                        validationTimer.stop()

                        validationPopup.close()

                    }

                }

            }


        }

    }



    onOpened:
    {

        startValidation()

    }


}
