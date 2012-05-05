import QtQuick 2.0

ShaderEffectSource {
    id: root
    property variant source
    property bool enabled: true

    sourceItem: source
    sourceRect: Qt.rect(x, y, width, height)
    smooth: true

    property int blurSamples: 20

    property real blurFactor: enabled

    Behavior on blurFactor { NumberAnimation {} }

    ShaderEffect {
        property variant source: root
        property real dx: 10 * blurFactor / width
        property real dy: 0

        anchors.fill: parent

        visible: blurFactor > 0.001 && blurSamples > 1

        fragmentShader: root.fragmentShader

        layer.enabled: true
        layer.smooth: true
        layer.effect: ShaderEffect {
            property real dx: 0
            property real dy: 10 * blurFactor / height

            fragmentShader: root.fragmentShader
        }
    }

    property var fragmentShader: generateShader()

    function generateShader() {
        var fragmentShader =
            "uniform lowp sampler2D source;\n" +
            "uniform lowp float qt_Opacity;\n" +
            "uniform lowp float dx;\n" +
            "uniform lowp float dy;\n" +
            "varying highp vec2 qt_TexCoord0;\n" +
            "void main() {\n" +
            "    vec4 color = vec4(0.0);\n" +
            "    for (int i = 0; i < " + blurSamples + "; ++i) {\n" +
            "        vec2 modulatedCoords = qt_TexCoord0 + vec2(dx, dy) * (float(i) * (1.0 / " + (blurSamples - 1) + ".0) - 0.5);\n" +
            "        color += texture2D(source, modulatedCoords);\n" +
            "    }\n" +
            "    gl_FragColor = qt_Opacity * color / " + blurSamples + ".0;\n" +
            "}";
        return fragmentShader;
    }
}
