import QtQuick 2.0

Rectangle {
    id: pane

    property bool hovered: false
    property bool enabled: true

    layer.enabled: true

    radius: 6
    color: "white"
    opacity: hovered ? 0.5 : 0.1

    Behavior on x { NumberAnimation {} }
    Behavior on y { NumberAnimation {} }
    Behavior on opacity { NumberAnimation {} }

    MouseArea {
        onEntered: pane.hovered = true
        hoverEnabled: pane.enabled
        anchors.fill: parent
    }
}
