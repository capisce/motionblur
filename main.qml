import QtQuick 2.0
import QtUiComponents 1.0
import QtUiStyle 1.0

Rectangle {
    color: "transparent"
    property real t

    NumberAnimation on t {
        from: 0
        to: 100
        loops: Animation.Infinite
        running: true
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: {
            velocitypane.hovered = false
            controlspane.hovered = false
        }
    }

    Pane {
        id: controlspane
        x: hovered ? -10 : 20 - width

        anchors.verticalCenter: parent.verticalCenter

        width: 200
        height: parent.height * 0.8

        Column {
            anchors.fill: parent
            anchors.margins: 10
            anchors.leftMargin: 20
            spacing: 10

            Toggle {
                text: "Motion blur"
                target: renderer
                property: "motionBlurEnabled"
            }

            Toggle {
                text: (screen.refreshRate * 0.5) + " Hz"
                target: renderer
                property: "frameSkipEnabled"
            }

            Toggle {
                text: "Follow mouse"
                target: renderer
                property: "followMouse"
            }
        }
    }

    Pane {
        id: velocitypane
        y: hovered ? -10 : 20 - height

        anchors.horizontalCenter: parent.horizontalCenter

        width: parent.width * 0.8
        height: 120

        Column {
            anchors.fill: parent
            anchors.margins: 10
            anchors.topMargin: 20
            spacing: 10

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                height: 40
                text: "Velocity"
            }
            
            Slider {
                id: velocitySlider
                value: 0.02
                maximum: 0.2
                width: parent.width - 20
                height: 40
                tickInterval: maximum * 0.1
                tickPosition: SliderStyle.TicksAbove
                stepSize: 0.0002

                Binding {
                    target: renderer
                    property: "velocity"
                    value: velocitySlider.value
                }
            }
        }
    }

    onTChanged: update() // force continuous animation
}
