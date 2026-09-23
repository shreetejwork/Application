#include <QGuiApplication>
#include <QEvent>
#include <QMouseEvent>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QDebug>
#include <QQuickWindow>
#include <QTouchEvent>
#include <QFontDatabase>
#include <QFont>

#include "DatabaseManager.h"
#include "SystemController.h"
#include "WifiScanner.h"
#include "PdfExporter.h"
#include "SystemDiagnosis.h"
#include "PlotItem.h"
#include "SerialManager.h"
#include "LanManager.h"
#include "UsbSoftwareUpdateManager.h"

class InputTraceFilter final : public QObject
{
public:
    explicit InputTraceFilter(QObject *parent = nullptr)
        : QObject(parent)
    {
    }

protected:
    bool eventFilter(QObject *watched, QEvent *event) override
    {
        Q_UNUSED(watched)

        switch (event->type()) {
        case QEvent::TouchBegin:
        case QEvent::TouchUpdate:
        case QEvent::TouchEnd:
        case QEvent::TouchCancel: {
            const auto *touchEvent = static_cast<const QTouchEvent *>(event);
            qInfo() << "INPUT_TRACE touch" << event->type()
                    << "points=" << touchEvent->points().size();
            break;
        }
        case QEvent::MouseButtonPress:
        case QEvent::MouseButtonRelease:
        case QEvent::MouseButtonDblClick: {
            const auto *mouseEvent = static_cast<const QMouseEvent *>(event);
            qInfo() << "INPUT_TRACE mouse" << event->type()
                    << "button=" << mouseEvent->button()
                    << "position=" << mouseEvent->position();
            break;
        }
        default:
            break;
        }

        return false;
    }
};


int main(int argc, char *argv[])
{

    qputenv("QT_QUICK_FLICKABLE_POINTER_HANDLING", "1");
    qputenv("QSG_RHI_BACKEND", "opengl");

    // =========================================================
    // QT SCALING FIX FOR QT 6.5
    // =========================================================

    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(
        Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);

    QGuiApplication app(argc, argv);

        qInfo() << "INPUT_TRACE platform=" << QGuiApplication::platformName()
            << "QT_QPA_PLATFORM=" << qgetenv("QT_QPA_PLATFORM")
            << "XDG_SESSION_TYPE=" << qgetenv("XDG_SESSION_TYPE")
            << "WAYLAND_DISPLAY=" << qgetenv("WAYLAND_DISPLAY")
            << "DISPLAY=" << qgetenv("DISPLAY");

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

    serialManager.setDatabaseManager(&dbManager);

    engine.rootContext()->setContextProperty(
        "databaseManager",
        &dbManager);

    // =========================================================
    // BACKEND OBJECTS
    // =========================================================

    SystemController systemController;
    UsbSoftwareUpdateManager usbUpdateManager;
    WiFiScanner wifi;
    PdfExporter pdfExporter;
    SystemDiagnosis diag;
    NetworkManager networkManager;

    engine.rootContext()->setContextProperty(
        "SystemController",
        &systemController);

    engine.rootContext()->setContextProperty(
        "UsbSoftwareUpdateManager",
        &usbUpdateManager);

    engine.rootContext()->setContextProperty(
        "WiFiScanner",
        &wifi);

    engine.rootContext()->setContextProperty(
        "PdfExporter",
        &pdfExporter);

    engine.rootContext()->setContextProperty(
        "SystemDiag",
        &diag);

    engine.rootContext()->setContextProperty(
        "NetworkManager",
        &networkManager);

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
        auto *inputTraceFilter = new InputTraceFilter(window);
        window->installEventFilter(inputTraceFilter);

        window->setWidth(1024);
        window->setHeight(600);

        window->setMinimumSize(QSize(1024, 600));
        window->setMaximumSize(QSize(1024, 600));
    }

    return app.exec();
}
