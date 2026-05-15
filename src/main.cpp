#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>


#include "DatabaseManager.h"
#include "SystemController.h"
#include "WifiScanner.h"
#include "PdfExporter.h"
#include "SystemDiagnosis.h"
#include "PlotItem.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QCoreApplication::setOrganizationName("Shreetej");
    QCoreApplication::setApplicationName("MD_Application");

    DatabaseManager dbManager;
    if (!dbManager.initialize()) {
        return -1;
    }

    qmlRegisterSingletonType(
        QUrl(QStringLiteral("qrc:/qt/qml/Application/qml/GlobalState.qml")),
        "AppState", 1, 0,
        "GlobalState"
        );

    qmlRegisterType<MagneticFieldPlotItem>(
        "CustomComponents",
        1,
        0,
        "MagneticFieldPlotItem"
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

    PdfExporter pdfExporter;
    engine.rootContext()->setContextProperty("PdfExporter", &pdfExporter);

    SystemDiagnosis diag;
    engine.rootContext()->setContextProperty("SystemDiag", &diag);

    engine.loadFromModule("Application", "Main");

    return app.exec();
}
