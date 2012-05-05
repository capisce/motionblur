#include <QtGui>
#include <QtQuick>

#define GETTER(type, name) \
    type name() const { return m_ ## name; }
#define SETTER(name) \
    if (value == m_ ## name) return; m_ ## name = value; emit name ## Changed();

class Controller : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool frameSkipEnabled READ frameSkipEnabled WRITE setFrameSkipEnabled NOTIFY frameSkipEnabledChanged)
    Q_PROPERTY(bool followMouse READ followMouse WRITE setFollowMouse NOTIFY followMouseChanged)
    Q_PROPERTY(bool paused READ paused WRITE setPaused NOTIFY pausedChanged)
    Q_PROPERTY(qreal velocity READ velocity WRITE setVelocity NOTIFY velocityChanged)
    Q_PROPERTY(QPointF currentPos READ currentPos NOTIFY currentPosChanged)
    Q_PROPERTY(QPointF currentVelocity READ currentVelocity NOTIFY currentVelocityChanged)

public:
    Controller(QWindow *view);

    GETTER(bool, frameSkipEnabled)
    GETTER(bool, followMouse)
    GETTER(bool, paused)
    GETTER(QPointF, currentPos)
    GETTER(QPointF, currentVelocity)
    GETTER(qreal, velocity)

public slots:
    void update();
    void mouseMoved(const QPoint &pos);

    void setFrameSkipEnabled(bool value)
    {
        SETTER(frameSkipEnabled)
    }

    void setVelocity(qreal value)
    {
        SETTER(velocity)
    }

    void setPaused(bool value)
    {
        SETTER(paused)
    }

    void setFollowMouse(bool value)
    {
        SETTER(followMouse)

        if (!value)
            adjustAnimationPos();
    }

signals:
    void frameSkipEnabledChanged();
    void velocityChanged();
    void currentVelocityChanged();
    void currentPosChanged();
    void followMouseChanged();
    void pausedChanged();

private:
    void initialize();
    void adjustAnimationPos();

    QWindow *m_view;

    bool m_frameSkipEnabled;
    bool m_followMouse;
    bool m_paused;
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

    QPointF m_currentVelocity;
    QPointF m_currentPos;
    QPointF m_targetPos;
    QPoint m_mousePos;
};

Controller::Controller(QWindow *view)
    : m_view(view)
    , m_frameSkipEnabled(false)
    , m_followMouse(false)
    , m_paused(false)
    , m_velocity(0.02)
    , m_frame(0)
    , m_pos(0)
    , m_hologram(false)
    , m_wobble(false)
{
}

void Controller::mouseMoved(const QPoint &pos)
{
    m_mousePos = pos;
}

const int tw = 256;
const int th = 256;

void Controller::adjustAnimationPos()
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

void Controller::update()
{
    int width = m_view->width();
    int height = m_view->height();

    if (!m_paused && (!m_frameSkipEnabled || (m_frame & 1))) {
        qreal x, y;

        if (m_followMouse) {
            x = m_mousePos.x() - tw / 2;
            y = m_mousePos.y() - th / 2;
        } else {
            m_pos += m_frameSkipEnabled ? 2 * m_velocity : m_velocity;

            x = (width - tw) * (0.5 + 0.5 * qSin(m_pos));
            y = (height - th) * (0.5 + 0.5 * qSin(0.47 * m_pos));
        }

        m_targetPos = QPointF(x, y);

        m_currentPos += 0.5 * (m_targetPos - m_currentPos);

        if (m_frameSkipEnabled) {
            m_currentPos += 0.5 * (m_targetPos - m_currentPos);
        }

        m_currentVelocity = QPointF((m_last.x() - m_currentPos.x()) / tw, (m_last.y() - m_currentPos.y()) / th);

        m_last = m_currentPos;

        emit currentPosChanged();
        emit currentVelocityChanged();
    }

    m_frame++;
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

    Controller controller(&view);

    view.rootContext()->setContextProperty("controller", &controller);
    view.rootContext()->setContextProperty("screen", view.screen());
    view.setSource(QUrl("main.qml"));
    view.setResizeMode(QQuickView::SizeRootObjectToView);
    view.setGeometry(0, 0, 1024, 768);
    view.showFullScreen();

    QObject::connect(&view, SIGNAL(afterRendering()), &controller, SLOT(update()));
    QObject::connect(&view, SIGNAL(mouseMoved(const QPoint &)), &controller, SLOT(mouseMoved(const QPoint &)));

    return app.exec();
}

#include "main.moc"
