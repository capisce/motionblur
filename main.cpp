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
    Q_PROPERTY(QPointF currentPos READ currentPos NOTIFY currentPosChanged)
    Q_PROPERTY(QPointF lastPos READ lastPos NOTIFY lastPosChanged)

public:
    Controller(QWindow *view);

    GETTER(bool, frameSkipEnabled)
    GETTER(bool, followMouse)
    GETTER(bool, paused)
    GETTER(int, skippedFrames)
    GETTER(QPointF, lastPos)
    GETTER(QPointF, currentPos)
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
    void currentPosChanged();
    void lastPosChanged();
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

    QPointF m_lastPos;

    int m_frame;

    qreal m_pos;

    bool m_hologram;
    bool m_wobble;
    bool m_shadow;

    QPointF m_currentPos;
    QPointF m_targetPos;
    QPoint m_mousePos;

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

void Controller::step()
{
    int width = m_view->width();
    int height = m_view->height();

    qreal x, y;

    if (m_followMouse) {
        x = m_mousePos.x();
        y = m_mousePos.y();
    } else {
        m_pos += (m_frameSkipEnabled ? 2 * m_velocity : m_velocity) * 120. / m_view->screen()->refreshRate();

        x = tw/2 + (width - tw) * (0.5 + 0.5 * qSin(m_pos));
        y = th/2 + (height - th) * (0.5 + 0.5 * qSin(0.47 * m_pos));
    }

    m_targetPos = QPointF(x, y);

    if (m_currentPos.isNull()) {
        m_currentPos = m_targetPos;
    }

    m_lastPos = m_currentPos;

    emit lastPosChanged();

    m_currentPos += 0.8 * (m_targetPos - m_currentPos);

    if (m_frameSkipEnabled) {
        m_currentPos += 0.8 * (m_targetPos - m_currentPos);
    }

    emit currentPosChanged();
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
    view.setGeometry(0, 0, 1024, 768);
    view.showFullScreen();

    QObject::connect(&view, SIGNAL(afterRendering()), &controller, SLOT(update()));
    QObject::connect(&view, SIGNAL(mouseMoved(const QPoint &)), &controller, SLOT(mouseMoved(const QPoint &)));

    return app.exec();
}

#include "main.moc"
