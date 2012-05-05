import QtQuick 2.0

Rectangle {
    property bool hovered: false

    layer.enabled: true

    id: pane
    radius: 6
    color: "white"
    opacity: hovered ? 0.6 : 0.2

    Behavior on x { NumberAnimation {} }
    Behavior on y { NumberAnimation {} }
    Behavior on opacity { NumberAnimation {} }

    MouseArea {
        onEntered: pane.hovered = true
        hoverEnabled: true
        anchors.fill: parent
    }
}
