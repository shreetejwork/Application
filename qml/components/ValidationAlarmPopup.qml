import QtQuick
import QtQuick.Controls
import QtQuick.Layouts


Popup {

    id: popupRoot


    width: 420
    height: 240


    modal: true
    focus: true


    anchors.centerIn: parent


    background: Rectangle {

        radius: 18

        color:"#FFFFFF"

        border.color:"#E5E7EB"
    }



    Column {

        anchors.fill: parent

        anchors.margins: 30

        spacing:25



        Text {

            width: parent.width

            text:"This is remainder for Validation"

            wrapMode: Text.WordWrap

            horizontalAlignment: Text.AlignHCenter


            font.pixelSize:24


            color:"#1A4DB5"
        }



        Row {

            spacing:30

            anchors.horizontalCenter: parent.horizontalCenter



            Rectangle {

                width:120

                height:45

                radius:10

                color:"#9CA3AF"



                Text {

                    anchors.centerIn:parent

                    text:"Skip"

                    color:"white"

                    font.pixelSize:18
                }



                MouseArea {

                    anchors.fill:parent


                    onClicked:
                    {
                        popupRoot.close()
                    }
                }
            }




            Rectangle {

                width:120

                height:45

                radius:10

                color:"#1A4DB5"



                Text {

                    anchors.centerIn:parent

                    text:"Continue"

                    color:"white"

                    font.pixelSize:18
                }



                MouseArea {

                    anchors.fill:parent


                    onClicked:
                    {
                        popupRoot.close()

                        console.log("Validation Started")
                    }
                }
            }
        }
    }
}
