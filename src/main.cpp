#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlEngine>
#include <QQmlContext>

#include "DatabaseManager.h"
#include "SystemController.h"

int main(int argc, char *argv[])
{
    qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));
    QGuiApplication app(argc, argv);

    DatabaseManager dbManager;
    if (!dbManager.initialize()) {
        return -1;
    }

    qmlRegisterSingletonType(
        QUrl(QStringLiteral("qrc:/qt/qml/Application/qml/GlobalState.qml")),
        "AppState", 1, 0,
        "GlobalState"
        );

    QQmlApplicationEngine engine;


    SystemController systemController;

    engine.rootContext()->setContextProperty("SystemController", &systemController);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
        );

    engine.loadFromModule("Application", "Main");

    return app.exec();
}
