#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QFontDatabase>
#include <QFont>

#include "DatabaseManager.h"
#include "SystemController.h"
#include "WifiScanner.h"
#include "PdfExporter.h"
#include "SystemDiagnosis.h"
#include "PlotItem.h"
#include "SerialManager.h"

int main(int argc, char *argv[])
{

    qputenv("QT_QUICK_FLICKABLE_POINTER_HANDLING", "1");

    QGuiApplication::setAttribute(
        Qt::AA_SynthesizeTouchForUnhandledMouseEvents);

    QGuiApplication::setAttribute(
        Qt::AA_SynthesizeMouseForUnhandledTouchEvents);

    // =========================================================
    // QT SCALING FIX FOR QT 6.5
    // =========================================================

    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(
        Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);

    QGuiApplication app(argc, argv);

    SerialManager serialManager;

    int id = QFontDatabase::addApplicationFont(":/qt/qml/Application/assets/images/RobotoCondensed-Regular.ttf");

    if (id == -1) {
        qWarning("Failed to load Roboto Condensed font");
    } else {
        QString family = QFontDatabase::applicationFontFamilies(id).at(0);
        app.setFont(QFont(family));
    }

    // =========================================================
    // APP INFO
    // =========================================================

    QCoreApplication::setOrganizationName("Shreetej");
    QCoreApplication::setApplicationName("MD_Application");

    // =========================================================
    // GLOBAL STATE
    // =========================================================

    qmlRegisterSingletonType(
        QUrl(QStringLiteral(
            "qrc:/qt/qml/Application/qml/GlobalState.qml")),
        "AppState",
        1,
        0,
        "GlobalState");

    qmlRegisterSingletonInstance(
        "Backend",
        1,
        0,
        "SerialManager",
        &serialManager);

    // =========================================================
    // CUSTOM COMPONENTS
    // =========================================================

    qmlRegisterType<MagneticFieldPlotItem>(
        "CustomComponents",
        1,
        0,
        "MagneticFieldPlotItem");

    // =========================================================
    // ENGINE
    // =========================================================

    QQmlApplicationEngine engine;

    // =========================================================
    // DATABASE
    // =========================================================

    DatabaseManager dbManager;

    if (!dbManager.initialize())
        return -1;

    engine.rootContext()->setContextProperty(
        "databaseManager",
        &dbManager);

    // =========================================================
    // BACKEND OBJECTS
    // =========================================================

    SystemController systemController;
    WiFiScanner wifi;
    PdfExporter pdfExporter;
    SystemDiagnosis diag;

    engine.rootContext()->setContextProperty(
        "SystemController",
        &systemController);

    engine.rootContext()->setContextProperty(
        "WiFiScanner",
        &wifi);

    engine.rootContext()->setContextProperty(
        "PdfExporter",
        &pdfExporter);

    engine.rootContext()->setContextProperty(
        "SystemDiag",
        &diag);

    // =========================================================
    // ERROR HANDLING
    // =========================================================

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() {
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);

    // =========================================================
    // LOAD MAIN QML
    // =========================================================

    engine.loadFromModule("Application", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    // =========================================================
    // FORCE WINDOW SIZE
    // =========================================================

    QObject *root = engine.rootObjects().first();

    QQuickWindow *window =
        qobject_cast<QQuickWindow *>(root);

    if (window)
    {
        window->setWidth(1024);
        window->setHeight(600);

        window->setMinimumSize(QSize(1024, 600));
        window->setMaximumSize(QSize(1024, 600));
    }

    return app.exec();
}
