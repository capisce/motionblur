import QtQuick 2.0

Rectangle {
    id: pane

    property bool hovered: false
    property bool enabled: true

    layer.enabled: true

    radius: 6
    color: "white"
    opacity: enabled ? (hovered ? 0.6 : 0.2) : 0

    Behavior on x { NumberAnimation {} }
    Behavior on y { NumberAnimation {} }
    Behavior on opacity { NumberAnimation {} }

    MouseArea {
        onEntered: pane.hovered = true
        hoverEnabled: pane.enabled
        anchors.fill: parent
    }
}
