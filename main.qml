import QtQuick 2.0
import QtUiComponents 1.0
import QtUiStyle 1.0

Rectangle {
    id: root
    property real time

    Item {
        id: contents
        anchors.fill: parent

        property bool blurredPanes: false

        Image {
            source: "background.png"
            smooth: true
            width: parent.width * 2
            height: parent.height * 2
            scale: 0.5
            transformOrigin: Item.TopLeft
            fillMode: Image.Tile
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
            layer.wrapMode: ShaderEffectSource.ClampToEdge
            layer.sourceRect: Qt.rect(-256, -256, 1024, 1024)
            layer.textureSize: Qt.size(1024, 1024)
        }

        ShaderEffect {
            id: effect

            property variant source: shadersource
            property real motionBlurFactor
            property real wobbleFactor
            property real hologramFactor
            property real time: root.time
            property real velocityX: controller.currentVelocity.x * 0.5
            property real velocityY: controller.currentVelocity.y * 0.5
            property int blurSamples

            property bool motionBlurEnabled: motionBlurFactor > 0.001
            property bool wobbleEnabled: wobbleFactor > 0.001
            property bool hologramEnabled: hologramFactor > 0.001

            x: controller.currentPos.x - 128
            y: controller.currentPos.y - 128

            width: 512
            height: 512

            Component.onCompleted: generateShader()
            onBlurSamplesChanged: generateShader()
            onMotionBlurEnabledChanged: generateShader()
            onWobbleEnabledChanged: generateShader()
            onHologramEnabledChanged: generateShader()

            Behavior on wobbleFactor { NumberAnimation {} }
            Behavior on motionBlurFactor { NumberAnimation {} }
            Behavior on hologramFactor { NumberAnimation {} }

            function generateShader() {
                var fragmentShaderText =
                    "uniform lowp sampler2D source;\n" +
                    "uniform lowp float qt_Opacity;\n" +
                    "uniform highp float time;\n" +
                    "varying highp vec2 qt_TexCoord0;\n" +
                    "uniform lowp float motionBlurFactor;\n" +
                    "uniform lowp float hologramFactor;\n" +
                    "uniform lowp float wobbleFactor;\n" +
                    "uniform mediump float velocityX;\n" +
                    "uniform mediump float velocityY;\n";

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

                var samples = motionBlurEnabled ? blurSamples : 1

                fragmentShaderText +=
                    "void main()\n" +
                    "{\n" +
                    "    vec4 color = vec4(0.0);\n" +
                    "    for (int i = 0; i < " + samples + "; ++i) {\n" +
                    "       vec2 modulatedCoords = qt_TexCoord0 + vec2(motionBlurFactor) *\n" +
                    "                              vec2(velocityX, velocityY) * (float(i) * (1.0 / " + Math.max(samples - 1, 1) + ".0) - 0.5);\n" +
                    "       color += sample(modulatedCoords);\n" +
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

    Pane {
        id: controlspane
        x: hovered ? -10 : 20 - width

        anchors.verticalCenter: parent.verticalCenter

        width: 200
        height: column.height + 20

        Column {
            id: column

            x: 20

            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Toggle {
                text: "Motion blur"
                target: effect
                checked: true
                property: "motionBlurFactor"
            }

            Toggle {
                text: "Wobble"
                target: effect
                property: "wobbleFactor"
            }

            Toggle {
                text: "Hologram"
                target: effect
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
                text: "Blurred panes"
                target: contents
                property: "blurredPanes"
            }

            Text {
                text: "Frame rate: " + fpsTimer.fps + " Hz"
            }

            Text {
                text: "Screen refresh: " + screen.refreshRate + " Hz"
            }
        }
    }

    Pane {
        id: velocitypane
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
                value: 20
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

    onTChanged: {
        update() // force continuous animation
        if (!controller.paused)
            time += 1.0 / screen.refreshRate
        ++frame
    }
}
