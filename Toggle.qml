import QtQuick 2.0
import QtUiComponents 1.0
import QtUiStyle 1.0

CheckBox {
    id: checkBox
    width: 140
    height: 24

    property var target
    property string property

    Binding {
        target: checkBox.target
        property: checkBox.property
        value: checkBox.checked
    }
}
