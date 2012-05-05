#include <QtGui>
#include <QtQuick>

static void frameRendered()
{
    static int frameCount = 0;
    static QTime lastTime = QTime::currentTime();

    ++frameCount;

    const QTime currentTime = QTime::currentTime();

    const int interval = 2500;

    const int delta = lastTime.msecsTo(currentTime);

    if (delta > interval) {
        qreal fps = 1000.0 * frameCount / delta;
        qDebug() << "FPS:" << fps;

        frameCount = 0;
        lastTime = currentTime;
    }
}

static const char* const glslMotionBlurVertex =
    "attribute highp   vec2      textureCoordsArray;\n"
    "varying   highp   vec2      textureCoords;\n"
    "attribute highp   vec2      vertexCoordsArray;\n"
    "void main(void)\n"
    "{\n"
    "    gl_Position = vec4(vertexCoordsArray.xy, 0.0, 1.0);\n"
    "    textureCoords = textureCoordsArray;\n"
    "}\n";

static const char* const glslMotionBlurFragment =
    "varying   highp   vec2      textureCoords;\n"
    "uniform   lowp    sampler2D imageTexture;\n"
    "uniform   lowp    vec2      velocity;\n"
    "uniform   highp   vec2      shadowOffset;\n"
    "uniform   highp   float     time;\n"
    "uniform   highp   vec4      controls;\n"
    "vec2 wobbleCoords(vec2 coords) {\n"
    "   return coords + controls.y * vec2(0.05 * sin(1.0 * cos(25.0 * (coords.y * coords.y + 0.25 * time))), 0.03 * sin(1.0 * cos(7.0 * (coords.x + 0.23 * time))));\n"
    "}\n"
#if 0
    "vec4 sample(vec2 coords) {\n"
    "   vec2 transformed = 100.0 * vec2(coords.x + 0.05 * sin(4.0 * time + 10.0 * coords.y), coords.y);\n"
    "   vec2 mod = transformed - floor(transformed);\n"
    "   vec2 dist = mod - vec2(0.5);\n"
    "   vec4 delta = mix(vec4(1.0), vec4(1.0, 0.7, 0.7, dot(dist, dist)), controls.x);\n"
    "   return delta * texture2D(imageTexture, wobbleCoords(coords));\n"
    "}\n"
#else
    "vec4 sample(vec2 coords) {\n"
    "   return texture2D(imageTexture, coords);\n"
    "}\n"
#endif
    "void main()\n"
    "{\n"
    "    vec4 color = vec4(0.0);\n"
    "    float shadow = 0.0;\n"
    "    for (int i = 0; i < 40; ++i) {\n"
    "       vec2 modulatedCoords = textureCoords + controls.z * velocity * (float(i) * (0.5 / 40.0) - 1.0);\n"
    "       color += sample(modulatedCoords);\n"
    "       shadow += sample(modulatedCoords - shadowOffset).a;\n"
    "    }\n"
    "    color = color * (1.0 / 40.0);\n"
    "    shadow = controls.w * shadow * (1.0 / 40.0);\n"
    "    gl_FragColor = color + vec4(0.0, 0.0, 0.0, 0.5) * shadow * (1.0 - color.a);\n"
    "}\n";

void interpolate(qreal target, qreal &current)
{
    const qreal interpolationSpeed = 1.0 / 30;

    if (current < target)
        current += interpolationSpeed;
    else if (current > target)
        current -= interpolationSpeed;
}

#define GETTER(type, name) \
    type name() const { return m_ ## name; }
#define SETTER(name) \
    if (value == m_ ## name) return; m_ ## name = value; emit name ## Changed();

class Renderer : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool motionBlurEnabled READ motionBlurEnabled WRITE setMotionBlurEnabled NOTIFY motionBlurEnabledChanged)
    Q_PROPERTY(bool frameSkipEnabled READ frameSkipEnabled WRITE setFrameSkipEnabled NOTIFY frameSkipEnabledChanged)
    Q_PROPERTY(bool followMouse READ followMouse WRITE setFollowMouse NOTIFY followMouseChanged)
    Q_PROPERTY(qreal velocity READ velocity WRITE setVelocity NOTIFY velocityChanged)

public:
    Renderer(QWindow *view);

    GETTER(bool, motionBlurEnabled)
    GETTER(bool, frameSkipEnabled)
    GETTER(bool, followMouse)
    GETTER(qreal, velocity)

public slots:
    void render();
    void mouseMoved(const QPoint &pos);

    void setMotionBlurEnabled(bool value)
    {
        SETTER(motionBlurEnabled)
    }

    void setFrameSkipEnabled(bool value)
    {
        SETTER(frameSkipEnabled)
    }

    void setVelocity(qreal value)
    {
        SETTER(velocity)
    }

    void setFollowMouse(bool value)
    {
        SETTER(followMouse)

        if (!value)
            adjustAnimationPos();
    }

signals:
    void motionBlurEnabledChanged();
    void frameSkipEnabledChanged();
    void velocityChanged();
    void followMouseChanged();

private:
    void initialize();
    void adjustAnimationPos();

    QWindow *m_view;

    bool m_motionBlurEnabled;
    bool m_frameSkipEnabled;
    bool m_followMouse;
    qreal m_velocity;

    bool m_initialized;
    QPixmap m_background;
    QPixmap m_sprite;
    QPointF m_last;

    int m_frame;

    GLuint m_texture;
    QOpenGLShaderProgram *m_program;

    int m_vertexLocation;
    int m_textureCoordLocation;
    int m_textureLocation;
    int m_velocityLocation;
    int m_timeLocation;
    int m_shadowOffsetLocation;
    int m_controlsLocation;

    qreal m_pos;

    bool m_hologram;
    bool m_wobble;
    bool m_shadow;

    qreal m_hologramF;
    qreal m_wobbleF;
    qreal m_motionBlurF;
    qreal m_shadowF;

    QPointF m_currentPos;
    QPointF m_targetPos;
    QPoint m_mousePos;
};

Renderer::Renderer(QWindow *view)
    : m_view(view)
    , m_motionBlurEnabled(true)
    , m_frameSkipEnabled(false)
    , m_followMouse(false)
    , m_velocity(0.02)
    , m_initialized(false)
    , m_background(QLatin1String("background.png"))
    , m_sprite(QLatin1String("earth.png"))
    , m_frame(0)
    , m_pos(0)
    , m_hologram(false)
    , m_wobble(false)
    , m_shadow(false)
    , m_hologramF(0)
    , m_wobbleF(0)
    , m_motionBlurF(0)
    , m_shadowF(0)
{
}

void Renderer::initialize()
{
    glGenTextures(1, &m_texture);
    glBindTexture(GL_TEXTURE_2D, m_texture);

    QImage spriteImage = m_sprite.toImage().rgbSwapped().mirrored();
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, spriteImage.width(), spriteImage.height(), 0,
                 GL_RGBA, GL_UNSIGNED_BYTE, spriteImage.bits());
    QOpenGLContext::currentContext()->functions()->glGenerateMipmap(GL_TEXTURE_2D);

    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    m_program = new QOpenGLShaderProgram;
    m_program->addShaderFromSourceCode(QOpenGLShader::Vertex, glslMotionBlurVertex);
    m_program->addShaderFromSourceCode(QOpenGLShader::Fragment, glslMotionBlurFragment);
    m_program->link();

    m_vertexLocation = m_program->attributeLocation("vertexCoordsArray");
    m_textureCoordLocation = m_program->attributeLocation("textureCoordsArray");
    m_textureLocation = m_program->uniformLocation("imageTexture");
    m_velocityLocation = m_program->uniformLocation("velocity");
    m_timeLocation = m_program->uniformLocation("time");
    m_shadowOffsetLocation = m_program->uniformLocation("shadowOffset");
    m_controlsLocation = m_program->uniformLocation("controls");
}

void Renderer::mouseMoved(const QPoint &pos)
{
    m_mousePos = pos;
}

const int tw = 256;
const int th = 256;

void Renderer::adjustAnimationPos()
{
    qreal minT = 0;
    qreal minDistSqr = std::numeric_limits<qreal>::max();

    int width = m_view->width();
    int height = m_view->height();

    for (qreal t = 0; t < 20 * M_PI; t += 0.2) {
        qreal dx = (width - tw) * (0.5 + 0.5 * qSin(t)) - m_currentPos.x();
        qreal dy = (height - th) * (0.5 + 0.5 * qSin(0.47 * t)) - m_currentPos.y();

        qreal d = dx * dx + dy * dy;
        if (d < minDistSqr) {
            minDistSqr = d;
            minT = t;
        }
    }

    m_pos = minT;
}

void Renderer::render()
{
    if (!m_initialized) {
        initialize();
        m_initialized = true;
    }

    glClear(GL_COLOR_BUFFER_BIT);

    int width = m_view->width();
    int height = m_view->height();

    QOpenGLPaintDevice device(width, height);

    QPainter p(&device);
    p.scale(0.5, 0.5);
    p.drawTiledPixmap(0, 0, 2 * width, 2 * height, m_background);
    p.end();

    if (!m_frameSkipEnabled || (m_frame & 1)) {
        qreal x, y;

        if (m_followMouse) {
            x = m_mousePos.x() - tw / 2;
            y = height - m_mousePos.y() - th / 2;
        } else {
            m_pos += m_frameSkipEnabled ? 2 * m_velocity : m_velocity;

            x = (width - tw) * (0.5 + 0.5 * qSin(m_pos));
            y = (height - th) * (0.5 + 0.5 * qSin(0.47 * m_pos));
        }

        m_targetPos = QPointF(x, y);

        m_currentPos += 0.5 * (m_targetPos - m_currentPos);
    }

    qreal x = m_currentPos.x();
    qreal y = m_currentPos.y();

    glBindTexture(GL_TEXTURE_2D, m_texture);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

    QVector<GLfloat> vertices;
    QVector<GLfloat> texCoords;

    QPointF shadowOffset(40, -30);

    QPointF delta(qAbs(shadowOffset.x()) + qAbs(m_last.x() - x), qAbs(shadowOffset.y()) + qAbs(m_last.y() - y));

    qreal vx0 = -1.0 + (2.0 * (x - delta.x())) / width;
    qreal vx1 = -1.0 + (2.0 * (x + tw + delta.x())) / width;

    qreal vy0 = -1.0 + (2.0 * (y - delta.y())) / height;
    qreal vy1 = -1.0 + (2.0 * (y + th + delta.y())) / height;

    vertices << vx0 << vy0 << vx1 << vy0 << vx1 << vy1
             << vx0 << vy0 << vx1 << vy1 << vx0 << vy1;

    qreal tx0 = -delta.x() / tw;
    qreal tx1 = 1 + delta.x() / tw;
    qreal ty0 = -delta.y() / th;
    qreal ty1 = 1 + delta.y() / th;

    texCoords << tx0 << ty0 << tx1 << ty0 << tx1 << ty1
              << tx0 << ty0 << tx1 << ty1 << tx0 << ty1;

    m_program->bind();
    m_program->enableAttributeArray(m_vertexLocation);
    m_program->enableAttributeArray(m_textureCoordLocation);
    m_program->setAttributeArray(m_vertexLocation, vertices.data(), 2);
    m_program->setAttributeArray(m_textureCoordLocation, texCoords.data(), 2);
    m_program->setUniformValue(m_textureLocation, 0);
    m_program->setUniformValue(m_timeLocation, GLfloat(m_frame / 120.0));
    m_program->setUniformValue(m_shadowOffsetLocation, QPointF(shadowOffset.x() / tw, shadowOffset.y() / th));
    m_program->setUniformValue(m_controlsLocation, GLfloat(m_hologramF), GLfloat(m_wobbleF), GLfloat(m_motionBlurF), GLfloat(m_shadowF));

    m_program->setUniformValue(m_velocityLocation, (m_last.x() - x) / tw, (m_last.y() - y) / th);

    glDrawArrays(GL_TRIANGLES, 0, 6);

    m_program->disableAttributeArray(m_vertexLocation);
    m_program->disableAttributeArray(m_textureCoordLocation);
    m_program->release();

    glDisable(GL_BLEND);
    glBindTexture(GL_TEXTURE_2D, 0);

    interpolate(m_hologram, m_hologramF);
    interpolate(m_wobble, m_wobbleF);
    interpolate(m_motionBlurEnabled, m_motionBlurF);
    interpolate(m_shadow, m_shadowF);

    m_frame++;
    frameRendered();

    if (!m_frameSkipEnabled || (m_frame & 1))
        m_last = QPointF(x, y);
}

class View : public QQuickView
{
    Q_OBJECT

protected:
    virtual void mouseMoveEvent(QMouseEvent *event)
    {
        emit mouseMoved(event->pos());
        QQuickView::mouseMoveEvent(event);
    }

signals:
    void mouseMoved(const QPoint &pos);
};

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);

    View view;

    Renderer renderer(&view);

    view.setClearBeforeRendering(false);
    view.rootContext()->setContextProperty("renderer", &renderer);
    view.rootContext()->setContextProperty("screen", view.screen());
    view.setSource(QUrl("main.qml"));
    view.setResizeMode(QQuickView::SizeRootObjectToView);
    view.setGeometry(0, 0, 1024, 768);
    view.showFullScreen();

    QObject::connect(&view, SIGNAL(beforeRendering()), &renderer, SLOT(render()), Qt::DirectConnection);
    QObject::connect(&view, SIGNAL(mouseMoved(const QPoint &)), &renderer, SLOT(mouseMoved(const QPoint &)));

    return app.exec();
}

#include "main.moc"
