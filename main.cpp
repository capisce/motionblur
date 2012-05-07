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

#include <QtGui>
#include <QtQuick>

#define GETTER(type, name) \
    type name() const { return m_ ## name; }
#define GETTER_INDIRECT(type, name, accessor) \
    type name() const { return accessor; }
#define SETTER(name) \
    if (value == m_ ## name) return; m_ ## name = value; emit name ## Changed();

class Controller : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool frameSkipEnabled READ frameSkipEnabled WRITE setFrameSkipEnabled NOTIFY frameSkipEnabledChanged)
    Q_PROPERTY(bool followMouse READ followMouse WRITE setFollowMouse NOTIFY followMouseChanged)
    Q_PROPERTY(bool paused READ paused WRITE setPaused NOTIFY pausedChanged)
    Q_PROPERTY(qreal velocity READ velocity WRITE setVelocity NOTIFY velocityChanged)
    Q_PROPERTY(int skippedFrames READ skippedFrames NOTIFY skippedFramesChanged)
    Q_PROPERTY(QPointF posA READ posA NOTIFY positionsChanged)
    Q_PROPERTY(QPointF posB READ posB NOTIFY positionsChanged)
    Q_PROPERTY(QPointF posC READ posC NOTIFY positionsChanged)
    Q_PROPERTY(QPointF posD READ posD NOTIFY positionsChanged)
    Q_PROPERTY(QPointF posE READ posE NOTIFY positionsChanged)
    Q_PROPERTY(QPointF posF READ posF NOTIFY positionsChanged)
    Q_PROPERTY(QRectF bounds READ bounds NOTIFY boundsChanged)

public:
    Controller(QWindow *view);

    GETTER(bool, frameSkipEnabled)
    GETTER(bool, followMouse)
    GETTER(bool, paused)
    GETTER(int, skippedFrames)
    GETTER_INDIRECT(QPointF, posA, m_pos[0])
    GETTER_INDIRECT(QPointF, posB, m_pos[1])
    GETTER_INDIRECT(QPointF, posC, m_pos[2])
    GETTER_INDIRECT(QPointF, posD, m_pos[3])
    GETTER_INDIRECT(QPointF, posE, m_pos[4])
    GETTER_INDIRECT(QPointF, posF, m_pos[5])
    GETTER(QRectF, bounds)
    GETTER(qreal, velocity)

public slots:
    void step();
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
    }

signals:
    void frameSkipEnabledChanged();
    void velocityChanged();
    void positionsChanged();
    void boundsChanged();
    void followMouseChanged();
    void pausedChanged();
    void skippedFramesChanged();

private:
    void initialize();

    QWindow *m_view;

    bool m_frameSkipEnabled;
    bool m_followMouse;
    bool m_paused;
    qreal m_velocity;
    int m_skippedFrames;

    QPointF m_pos[6];

    QList<QPointF> m_positions;
    QRectF m_bounds;

    int m_frame;

    qreal m_t;

    bool m_hologram;
    bool m_wobble;
    bool m_shadow;

    QPainterPath m_mouseTrail;
    QPointF m_mousePos;

    QTime m_time;
};

Controller::Controller(QWindow *view)
    : m_view(view)
    , m_frameSkipEnabled(false)
    , m_followMouse(false)
    , m_paused(false)
    , m_velocity(0.02)
    , m_skippedFrames(0)
    , m_frame(0)
    , m_t(0)
    , m_hologram(false)
    , m_wobble(false)
{
}

void Controller::mouseMoved(const QPoint &pos)
{
    if (m_mouseTrail.elementCount() == 0)
        m_mouseTrail.moveTo(pos);
    else
        m_mouseTrail.lineTo(pos);
}

const int tw = 256;
const int th = 256;

void Controller::step()
{
    int width = m_view->width();
    int height = m_view->height();

    if (!m_positions.isEmpty())
        m_positions = m_positions.mid(5);

    for (int i = 0; i < 5; ++i) {
        qreal x, y;

        if (m_followMouse) {
            qreal t = i * (1 / qreal(6));

            if (!m_mouseTrail.isEmpty())
                m_mousePos = m_mouseTrail.pointAtPercent(t);

            x = m_mousePos.x();
            y = m_mousePos.y();
        } else {
            m_t += (m_frameSkipEnabled ? 2 * m_velocity : m_velocity) * 120. / (5 * m_view->screen()->refreshRate());

            x = tw/2 + (width - tw) * (0.5 + 0.5 * qSin(m_t));
            y = th/2 + (height - th) * (0.5 + 0.5 * qSin(0.47 * m_t));
        }

        m_positions << QPointF(x, y);
    }

    if (m_positions.size() < 6)
        m_positions.prepend(m_positions.first());

    m_bounds = QRectF(m_positions.at(0), m_positions.at(1));
    for (int i = 2; i < m_positions.size(); i += 2)
        m_bounds = m_bounds.united(QRectF(m_positions.at(i), m_positions.at(i+1)));

    m_bounds = m_bounds.normalized();

    for (int i = 0; i < m_positions.size(); ++i)
        m_pos[i] = (m_positions.at(i) - m_bounds.center()) * (1 / 256.);

    emit positionsChanged();
    emit boundsChanged();

    m_mousePos = m_mouseTrail.currentPosition();

    m_mouseTrail = QPainterPath();
    m_mouseTrail.moveTo(m_mousePos);
}

void Controller::update()
{
    if (!m_paused && (!m_frameSkipEnabled || (m_frame & 1)))
        step();

    if (m_time.isNull()) {
        m_time.start();
    } else {
        qreal elapsed = m_time.elapsed();
        qreal refresh = 1000. / m_view->screen()->refreshRate();
        qreal hi = 1.35 * refresh;
        if (elapsed > hi) {
            ++m_skippedFrames;
            emit skippedFramesChanged();
        }

        m_time.restart();
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
    view.setGeometry(0, 0, 800, 600);
    view.showFullScreen();

    QObject::connect(&view, SIGNAL(afterRendering()), &controller, SLOT(update()));
    QObject::connect(&view, SIGNAL(mouseMoved(const QPoint &)), &controller, SLOT(mouseMoved(const QPoint &)));

    return app.exec();
}

#include "main.moc"
