import QtQuick 2.0
import QtUiComponents 1.0
import QtUiStyle 1.0

Slider {
    id: slider

    width: parent.width - 20
    height: 40

    tickInterval: maximum * 0.1
    stepSize: maximum * 0.001

    tickPosition: SliderStyle.TicksAbove

    property var target
    property string property
    property bool instantaneous: true
    property real current: value

    onPressedChanged: current = value

    Binding {
        target: slider.target
        property: slider.property
        value: slider.instantaneous ? slider.value : slider.current
    }
}
