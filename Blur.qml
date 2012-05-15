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

ShaderEffectSource {
    id: root
    property variant source
    property bool enabled: true

    sourceItem: source
    sourceRect: Qt.rect(x, y, width, height)
    smooth: true

    property int blurSamples: 20

    property real blurFactor: enabled

    visible: blurFactor > 0.001

    Behavior on blurFactor { NumberAnimation {} }

    ShaderEffect {
        property variant source: root
        property real dx: 10 * blurFactor / width
        property real dy: 0

        anchors.fill: parent

        visible: blurFactor > 0.001 && blurSamples > 1

        fragmentShader: root.fragmentShader

        layer.enabled: parent.enabled
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
