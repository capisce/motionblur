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

Row {
    id: checkBox
    width: 140
    height: 32

    property bool checked: false
    property string text

    Text  {
        text: parent.text
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        id: spacing
        color: "transparent"
        height: 8
        width: 8
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter

        color: "transparent"
        border.color: "gray"
        border.width: 2

        width: parent.height
        height: parent.height

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 4
            height: parent.height - 4
            color: "darkgray"
            visible: checkBox.checked
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                checkBox.checked = !checkBox.checked
            }
        }
    }

    property var target
    property string property

    Binding {
        target: checkBox.target
        property: checkBox.property
        value: checkBox.checked
    }
}
