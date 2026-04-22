#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "DatabaseManager.h"
#include "SystemController.h"
#include "WifiScanner.h"

int main(int argc, char *argv[])
{
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
    WiFiScanner wifi;


    engine.rootContext()->setContextProperty("SystemController", &systemController);
    engine.rootContext()->setContextProperty("WiFiScanner", &wifi);

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
