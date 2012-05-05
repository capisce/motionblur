import QtQuick 2.0
import QtUiComponents 1.0
import QtUiStyle 1.0

Rectangle {
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
        property variant source: shadersource
        property real motionBlurFactor: controller.motionBlurEnabled
        property real velocityX: controller.currentVelocity.x * 0.5
        property real velocityY: controller.currentVelocity.y * 0.5
        property int blurSamples: controller.blurSamples

        x: controller.currentPos.x - 128
        y: controller.currentPos.y - 128

        width: 512
        height: 512

        Component.onCompleted: generateShader()
        onBlurSamplesChanged: generateShader()

        function generateShader() {
            var fragmentShaderText =
                "uniform lowp sampler2D source;" +
                "uniform lowp float qt_Opacity;" +
                "varying highp vec2 qt_TexCoord0;" +
                "uniform lowp float motionBlurFactor;" +
                "uniform mediump float velocityX;" +
                "uniform mediump float velocityY;";

            fragmentShaderText +=
                "vec4 sample(vec2 coords) {\n" +
                "   return texture2D(source, coords);\n" +
                "}\n";

            fragmentShaderText +=
                "void main()\n" +
                "{\n" +
                "    vec4 color = vec4(0.0);\n" +
                "    for (int i = 0; i < " + blurSamples + "; ++i) {\n" +
                "       vec2 modulatedCoords = qt_TexCoord0 + motionBlurFactor *\n" +
                "                              vec2(velocityX, velocityY) * (float(i) * (1.0 / " + blurSamples + ") - 0.5);\n" +
                "       color += sample(modulatedCoords);\n" +
                "    }\n" +
                "    color = color * (1.0 / " + blurSamples + ");\n" +
                "    gl_FragColor = qt_Opacity * color;\n" +
                "}\n";

            fragmentShader = fragmentShaderText
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

    Pane {
        id: controlspane
        x: hovered ? -10 : 20 - width

        anchors.verticalCenter: parent.verticalCenter

        width: 200
        height: parent.height * 0.8

        Column {
            anchors.fill: parent
            anchors.margins: 10
            anchors.leftMargin: 20
            spacing: 10

            Toggle {
                text: "Motion blur"
                target: controller
                checked: true
                property: "motionBlurEnabled"
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
        }
    }

    Pane {
        id: velocitypane
        y: hovered ? -10 : 20 - height

        anchors.horizontalCenter: parent.horizontalCenter

        width: parent.width * 0.8
        height: 200

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
                value: 0.02
                maximum: 0.16
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
                target: controller
                property: "blurSamples"
            }
        }
    }

    onTChanged: update() // force continuous animation
}
