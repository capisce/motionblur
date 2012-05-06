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
import QtUiComponents 1.0
import QtUiStyle 1.0

Rectangle {
    id: root
    color: "black"
    property real time
    property bool panesEnabled: false
    property bool calibrating: true

    Item {
        id: contents
        anchors.fill: parent

        property bool blurredPanes: false

        Image {
            source: "background.jpg"
            smooth: true
            anchors.fill: parent
        }

        Rectangle {
            id: shadersource

            width: 512
            height: 512

            color: "transparent"

            Image {
                source: "earth.png"
            }

            visible: false

            layer.enabled: true
            layer.smooth: true
            layer.mipmap: true
        }


        ShaderEffect {
            id: sourceeffect

            width: 512
            height: 512

            property variant source: shadersource
            property real time: root.time
            property real wobbleFactor
            property real hologramFactor

            visible: false

            layer.enabled: true
            layer.smooth: true
            layer.mipmap: true
            layer.wrapMode: ShaderEffectSource.ClampToEdge
            layer.sourceRect: Qt.rect(-256, -256, 1024, 1024)
            layer.textureSize: Qt.size(1024, 1024)

            Component.onCompleted: generateShader()
            onWobbleEnabledChanged: generateShader()
            onHologramEnabledChanged: generateShader()

            property bool wobbleEnabled: wobbleFactor > 0.001
            property bool hologramEnabled: hologramFactor > 0.001

            Behavior on wobbleFactor { NumberAnimation {} }
            Behavior on hologramFactor { NumberAnimation {} }

            function generateShader() {
                var fragmentShaderText =
                    "uniform lowp sampler2D source;\n" +
                    "uniform lowp float qt_Opacity;\n" +
                    "uniform highp float time;\n" +
                    "varying highp vec2 qt_TexCoord0;\n" +
                    "uniform lowp float hologramFactor;\n" +
                    "uniform lowp float wobbleFactor;\n";

                if (wobbleEnabled) {
                    fragmentShaderText +=
                        "vec2 wobbleCoords(vec2 coords) {\n" +
                        "   return coords + wobbleFactor * vec2(0.05 * sin(1.0 * cos(25.0 * (coords.y * coords.y + 0.25 * time))), 0.03 * sin(1.0 * cos(7.0 * (coords.x + 0.23 * time))));\n" +
                        "}\n";
                }

                if (wobbleEnabled || hologramEnabled) {
                    fragmentShaderText += "vec4 sample(vec2 coords) {\n";

                    if (hologramEnabled) {
                        fragmentShaderText +=
                            "   vec2 transformed = 100.0 * vec2(coords.x + 0.05 * sin(4.0 * time + 10.0 * coords.y), coords.y);\n" +
                            "   vec2 mod = transformed - floor(transformed);\n" +
                            "   vec2 dist = mod - vec2(0.5);\n" +
                            "   vec4 delta = mix(vec4(1.0), vec4(1.0, 0.7, 0.7, dot(dist, dist)), hologramFactor);\n";
                    } else {
                        fragmentShaderText +=
                            "   vec4 delta = vec4(1.0);\n";
                    }

                    if (wobbleEnabled) {
                        fragmentShaderText +=
                            "   return delta * texture2D(source, wobbleCoords(coords));\n";
                    } else {
                        fragmentShaderText +=
                            "   return delta * texture2D(source, coords);\n";
                    }

                    fragmentShaderText += "}\n";
                } else {
                    fragmentShaderText +=
                        "vec4 sample(vec2 coords) {\n" +
                        "   return texture2D(source, coords);\n" +
                        "}\n";
                }

                fragmentShaderText +=
                    "void main()\n" +
                    "{\n" +
                    "    gl_FragColor = sample(qt_TexCoord0);\n" +
                    "}\n";

                fragmentShader = fragmentShaderText
            }
        }

        ShaderEffect {
            id: effect

            property variant source: sourceeffect
            property real motionBlurFactor
            property real velocityX: controller.currentVelocity.x * 0.5
            property real velocityY: controller.currentVelocity.y * 0.5
            property int blurSamples

            property bool motionBlurEnabled: motionBlurFactor > 0.001

            x: controller.currentPos.x - 128
            y: controller.currentPos.y - 128

            width: 512
            height: 512

            Component.onCompleted: generateShader()
            onBlurSamplesChanged: generateShader()
            onMotionBlurEnabledChanged: generateShader()

            Behavior on motionBlurFactor { NumberAnimation {} }

            function generateShader() {
                var fragmentShaderText =
                    "uniform lowp sampler2D source;\n" +
                    "uniform lowp float qt_Opacity;\n" +
                    "varying highp vec2 qt_TexCoord0;\n" +
                    "uniform lowp float motionBlurFactor;\n" +
                    "uniform mediump float velocityX;\n" +
                    "uniform mediump float velocityY;\n";

                var samples = motionBlurEnabled ? blurSamples : 1

                fragmentShaderText +=
                    "void main()\n" +
                    "{\n" +
                    "    vec4 color = vec4(0.0);\n" +
                    "    for (int i = 0; i < " + samples + "; ++i) {\n" +
                    "       vec2 modulatedCoords = qt_TexCoord0 + vec2(motionBlurFactor) *\n" +
                    "                              vec2(velocityX, velocityY) * (float(i) * (1.0 / " + Math.max(samples - 1, 1) + ".0) - 0.5);\n" +
                    "       color += texture2D(source, modulatedCoords);\n" +
                    "    }\n" +
                    "    color = color * (1.0 / " + samples + ".0);\n" +
                    "    gl_FragColor = qt_Opacity * color;\n" +
                    "}\n";

                fragmentShader = fragmentShaderText
            }
        }
    }

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

    Blur {
        anchors.fill: controlspane
        source: contents
        enabled: contents.blurredPanes
        blurSamples: effect.blurSamples
    }

    Blur {
        anchors.fill: velocitypane
        source: contents
        enabled: contents.blurredPanes
        blurSamples: effect.blurSamples
    }

    Blur {
        anchors.fill: calibrationPane
        source: contents
        enabled: contents.blurredPanes
        blurSamples: root.calibrating ? effect.blurSamples : 1
    }

    Pane {
        id: controlspane
        enabled: root.panesEnabled
        x: hovered ? -10 : 20 - width

        anchors.verticalCenter: parent.verticalCenter

        width: 220
        height: column.height + 32

        Column {
            id: column

            x: 20

            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Toggle {
                id: motionBlurToggle
                text: "Motion blur"
                target: effect
                checked: true
                property: "motionBlurFactor"
            }

            Toggle {
                id: wobbleToggle
                text: "Wobble"
                target: sourceeffect
                checked: true
                property: "wobbleFactor"
            }

            Toggle {
                id: hologramToggle
                text: "Hologram"
                target: sourceeffect
                checked: true
                property: "hologramFactor"
            }

            Toggle {
                text: (screen.refreshRate * 0.5) + " Hz"
                target: controller
                property: "frameSkipEnabled"
            }

            Toggle {
                text: "Follow mouse"
                target: controller
                property: "followMouse"
            }

            Toggle {
                text: "Paused"
                target: controller
                property: "paused"
            }

            Toggle {
                id: blurredPanesToggle
                text: "Blurred panes"
                target: contents
                checked: true
                property: "blurredPanes"
            }

            Button {
                width: 140
                height: 24
                text: "Recalibrate"
                onClicked: {
                    root.calibrating = true
                    root.initialized = false
                    root.panesEnabled = false
                    controlspane.hovered = false
                    blurSlider.value = 50
                    motionBlurToggle.checked = true
                    wobbleToggle.checked = true
                    hologramToggle.checked = true
                    blurredPanesToggle.checked = true
                    initTimer.start()
                }
            }

            Text {
                text: "Frame rate: " + fpsTimer.fps + " Hz"
            }

            Text {
                text: "Screen refresh: " + screen.refreshRate + " Hz"
            }

            Text {
                text: "Missed frames: " + controller.skippedFrames
            }
        }
    }

    Pane {
        id: velocitypane
        enabled: root.panesEnabled
        y: hovered ? -10 : 20 - height

        anchors.horizontalCenter: parent.horizontalCenter

        width: parent.width * 0.6
        height: 180

        Column {
            anchors.fill: parent
            anchors.margins: 10
            anchors.topMargin: 20
            spacing: 10

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                height: font.pixelSize + 4
                text: "Velocity"
            }
            
            PaneSlider {
                value: 0.01
                maximum: 0.18
                target: controller
                property: "velocity"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                height: font.pixelSize + 4
                text: "Blur quality (number of samples per pixel)"
            }
            
            PaneSlider {
                id: blurSlider
                value: 50
                minimum: 1
                maximum: 80
                tickInterval: 1 
                stepSize: 1
                target: effect
                property: "blurSamples"
                instantaneous: false
            }
        }
    }

    property int frame: 0

    Timer {
        id: fpsTimer
        property real fps: 0
        repeat: true
        running: true
        interval: 1000
        onTriggered: {
            fps = frame
            frame = 0
        }
    }

    property bool initialized: false

    Timer {
        id: initTimer
        running: true
        interval: 2000
        onTriggered: {
            initialized = true
            hideCalibrationPaneTimer.start()
        }
    }

    Timer {
        id: hideCalibrationPaneTimer
        interval: 2000
        onTriggered: {
            root.calibrating = false
            root.panesEnabled = true
            blurSlider.value = calibrationPane.targetSamples
            console.log("Blur samples initialized to " + effect.blurSamples);
        }
    }

    Pane {
        id: calibrationPane
        anchors.centerIn: parent
        opacity: root.calibrating ? 0.5 : 0

        width: calibrationColumn.width * 1.2
        height: calibrationColumn.height * 1.2

        property int targetSamples

        Connections {
            target: effect
            onBlurSamplesChanged: {
                if (root.calibrating)
                    calibrationPane.targetSamples = Math.max(1, Math.floor(effect.blurSamples * 0.8))
            }
        }

        Behavior on targetSamples { NumberAnimation { duration: 400 } }

        Column {
            anchors.centerIn: parent
            id: calibrationColumn
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Calibrating effects for best frame rate"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Blur samples: " + calibrationPane.targetSamples
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Blurred panes enabled: " + blurredPanesToggle.checked
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Hologram enabled: " + hologramToggle.checked
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Wobble enabled: " + wobbleToggle.checked
            }
        }
    }

    Connections {
        id: connections
        target: controller
        property bool ignore: false
        onSkippedFramesChanged: {
            if (initialized)
                return;
            connections.ignore = !connections.ignore;
            // changing blurSamples _will_ result in skipped frames
            // so ignore every other change
            if (connections.ignore)
                return;
            if (calibrationPane.targetSamples <= 32 && blurredPanesToggle.checked) {
                blurredPanesToggle.checked = false
            } else if (calibrationPane.targetSamples <= 16 && hologramToggle.checked) {
                hologramToggle.checked = false
            } else if (calibrationPane.targetSamples <= 16 && wobbleToggle.checked) {
                wobbleToggle.checked = false
            } else {
                blurSlider.value = Math.max(1, Math.floor(effect.blurSamples * 0.8));
            }
            initTimer.restart();
        }
    }

    onTChanged: {
        update() // force continuous animation
        if (!controller.paused)
            time += 1.0 / screen.refreshRate
        ++frame
    }
}
