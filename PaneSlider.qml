/*
 * Copyright (c) 2012 Samuel Rødal
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

import QtQuick 2.0

Item {
    id: slider

    Rectangle {
        id: groove
        x: 2
        width: parent.width - 4

        anchors.verticalCenter: parent.verticalCenter
        height: 3
        color: "lightGray"
    }

    Rectangle {
        x: 2 + (parent.width - 4) * (parent.value - parent.minimum) / (parent.maximum - parent.minimum)
        id: handle
        anchors.verticalCenter: parent.verticalCenter
        color: "lightsteelblue"

        radius: 2

        height: 28
        width: 22
    }

    MouseArea {
        anchors.verticalCenter: parent.verticalCenter
        x: 2
        width: parent.width - 4
        height: 32
        onPressed: slider.pressed = true
        onReleased: slider.pressed = false
        onPositionChanged: {
            var x = (mouse.x - handle.width / 2) / width
            slider.value = Math.min(Math.max(x * (slider.maximum - slider.minimum), slider.minimum), slider.maximum)
        }
    }

    width: parent.width - 20
    height: 40

    property var stepSize: maximum * 0.001
    property bool pressed: false

    property var target
    property real value: 0
    property real minimum: 0
    property real maximum: 100

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
