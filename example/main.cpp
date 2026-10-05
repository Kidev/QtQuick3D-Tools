#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQuick3D/qquick3d.h>

int main(int argc, char *argv[])
{
    QGuiApplication app {argc, argv};

    QSurfaceFormat::setDefaultFormat(QQuick3D::idealSurfaceFormat());
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/MainScene.qml")));
    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}
