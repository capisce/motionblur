import QtQuick 2.0

Rectangle {
    property string text
    signal clicked

    color: "lightsteelblue"

    Text {
        anchors.centerIn: parent
        text: parent.text
    }

    MouseArea {
        anchors.fill: parent
        onClicked: parent.clicked()
    }
}
