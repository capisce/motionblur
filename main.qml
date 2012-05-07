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

            property real x0: controller.posA.x
            property real y0: controller.posA.y
            property real x1: controller.posB.x
            property real y1: controller.posB.y
            property real x2: controller.posC.x
            property real y2: controller.posC.y
            property real x3: controller.posD.x
            property real y3: controller.posD.y
            property real x4: controller.posE.x
            property real y4: controller.posE.y
            property real x5: controller.posF.x
            property real y5: controller.posF.y

            property variant source: sourceeffect
            property real motionBlurFactor

            property real avx: controller.bounds.width
            property real avy: controller.bounds.height

            property real dtx: 0.5 * avx / 256
            property real dty: 0.5 * avy / 256
            property int blurSamples

            property bool motionBlurEnabled: motionBlurFactor > 0.001

            x: controller.bounds.x + (controller.bounds.width - avx) * 0.5 - 128
            y: controller.bounds.y + (controller.bounds.height - avy) * 0.5 - 128

            width: 256 + avx
            height: 256 + avy

            Component.onCompleted: generateShader()
            onBlurSamplesChanged: generateShader()
            onMotionBlurEnabledChanged: generateShader()

            Behavior on motionBlurFactor { NumberAnimation {} }

            vertexShader: "
                uniform highp mat4 qt_Matrix;
                attribute highp vec4 qt_Vertex;
                attribute highp vec2 qt_MultiTexCoord0;
                varying highp vec2 qt_TexCoord0;
                uniform highp float dtx;
                uniform highp float dty;
                void main() {
                    highp vec2 t = qt_MultiTexCoord0;
                    if (t.x < 0.5) {
                        t.x -= dtx;
                    } else {
                        t.x += dtx;
                    }
                    if (t.y < 0.5) {
                        t.y -= dty;
                    } else {
                        t.y += dty;
                    }
                    qt_TexCoord0 = t;
                    highp vec4 pos = qt_Vertex;
                    gl_Position = qt_Matrix * qt_Vertex;
                }" 

            function generateShader() {
                var fragmentShaderText =
                    "uniform lowp sampler2D source;\n" +
                    "uniform lowp float qt_Opacity;\n" +
                    "varying highp vec2 qt_TexCoord0;\n" +
                    "uniform lowp float motionBlurFactor;\n";

                if (motionBlurEnabled && blurSamples >= 6) {
                    var samplesPerInterval = Math.floor(((motionBlurEnabled ? blurSamples : 1) - 1) / 5)

                    fragmentShaderText +=
                        "uniform mediump float x0;\n" +
                        "uniform mediump float y0;\n" +
                        "uniform mediump float x1;\n" +
                        "uniform mediump float y1;\n" +
                        "uniform mediump float x2;\n" +
                        "uniform mediump float y2;\n" +
                        "uniform mediump float x3;\n" +
                        "uniform mediump float y3;\n" +
                        "uniform mediump float x4;\n" +
                        "uniform mediump float y4;\n" +
                        "uniform mediump float x5;\n" +
                        "uniform mediump float y5;\n" +
                        "void main()\n" +
                        "{\n" +
                        "    vec4 color = vec4(0.0);\n";

                    for (var i = 0; i < 5; ++i) {
                        fragmentShaderText +=
                            "    for (int i = 0; i < " + samplesPerInterval + "; ++i) {\n" +
                            "       vec2 modulatedCoords = qt_TexCoord0 - motionBlurFactor *\n" +
                            "                              mix(vec2(x" + i + ", y" + i + "), vec2(x" + (i+1) + ", y" + (i+1) + "), float(i) / " + samplesPerInterval + ".0);\n" +
                            "       color += texture2D(source, modulatedCoords);\n" +
                            "    }\n";
                    }

                    fragmentShaderText +=
                        "    color += texture2D(source, qt_TexCoord0 - motionBlurFactor * vec2(x5, y5));\n" +
                        "    color = color * (1.0 / " + (samplesPerInterval * 5 + 1) + ".0);\n" +
                        "    gl_FragColor = qt_Opacity * color;\n" +
                        "}\n";
                } else {
                    fragmentShaderText +=
                        "void main()\n" +
                        "{\n" +
                        "    gl_FragColor = qt_Opacity * texture2D(source, qt_TexCoord0);\n" +
                        "}\n";
                }

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
                enabled: controller.paused
                text: "Step"
                onClicked: {
                    controller.step()
                }
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
                maximum: 0.9
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
                maximum: 200
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
