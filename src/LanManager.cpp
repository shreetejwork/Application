#include "LanManager.h"

#include <QProcess>
#include <QDebug>

NetworkManager::NetworkManager(QObject *parent)
    : QObject(parent)
{
}

// ============================================================
// RUN NMCli COMMAND
// ============================================================

bool NetworkManager::runNmcliCommand(
    const QStringList &arguments,
    QString *output,
    QString *error,
    int timeout)
{
    QProcess process;

    process.start("nmcli", arguments);

    if (!process.waitForStarted(5000)) {

        qDebug() << "Failed to start nmcli:"
                 << arguments;

        if (error)
            *error = "Failed to start nmcli";

        return false;
    }

    if (!process.waitForFinished(timeout)) {

        qDebug() << "nmcli timed out:"
                 << arguments;

        process.kill();
        process.waitForFinished(1000);

        if (error)
            *error = "Network operation timed out";

        return false;
    }

    QString stdoutText =
        QString::fromLocal8Bit(
            process.readAllStandardOutput()
            ).trimmed();

    QString stderrText =
        QString::fromLocal8Bit(
            process.readAllStandardError()
            ).trimmed();

    if (output)
        *output = stdoutText;

    if (error)
        *error = stderrText;

    if (process.exitCode() != 0) {

        qDebug() << "nmcli failed:"
                 << stderrText;

        return false;
    }

    return true;
}

// ============================================================
// SIMPLE NMCli COMMAND
// ============================================================

QString NetworkManager::runNmcli(
    const QStringList &arguments,
    int timeout)
{
    QString output;
    QString error;

    if (!runNmcliCommand(
            arguments,
            &output,
            &error,
            timeout)) {

        return "";
    }

    return output;
}

// ============================================================
// CHECK ETH0 EXISTS
// ============================================================

bool NetworkManager::isEthernetAvailable(
    const QString &interfaceName)
{
    QString output =
        runNmcli({
            "-t",
            "-f",
            "DEVICE,TYPE",
            "device",
            "status"
        });

    if (output.isEmpty())
        return false;

    const QStringList lines =
        output.split("\n", Qt::SkipEmptyParts);

    for (const QString &line : lines) {

        QStringList parts =
            line.split(":");

        if (parts.size() < 2)
            continue;

        QString device =
            parts[0].trimmed();

        QString type =
            parts[1].trimmed();

        if (device == interfaceName &&
            type == "ethernet") {

            return true;
        }
    }

    return false;
}

// ============================================================
// CHECK ETHERNET CONNECTION
// ============================================================

bool NetworkManager::isEthernetConnected(
    const QString &interfaceName)
{
    QString output =
        runNmcli({
            "-t",
            "-f",
            "DEVICE,STATE,CONNECTION",
            "device",
            "status"
        });

    if (output.isEmpty())
        return false;

    const QStringList lines =
        output.split("\n", Qt::SkipEmptyParts);

    for (const QString &line : lines) {

        QStringList parts =
            line.split(":");

        if (parts.size() < 3)
            continue;

        QString device =
            parts[0].trimmed();

        QString state =
            parts[1].trimmed();

        if (device == interfaceName &&
            (state == "connected" ||
             state == "connected (externally)")) {

            return true;
        }
    }

    return false;
}

// ============================================================
// GET IP ADDRESS
// ============================================================

QString NetworkManager::getIPAddress(
    const QString &interfaceName)
{
    QString output =
        runNmcli({
            "-t",
            "-f",
            "IP4.ADDRESS",
            "device",
            "show",
            interfaceName
        });

    if (output.isEmpty())
        return "";

    QStringList lines =
        output.split("\n", Qt::SkipEmptyParts);

    for (QString line : lines) {

        line = line.trimmed();

        if (line.startsWith("IP4.ADDRESS")) {

            QString value =
                line.section(":", 1).trimmed();

            // Remove /24, /16 etc.
            return value.section("/", 0, 0);
        }
    }

    return "";
}

// ============================================================
// GET SUBNET PREFIX
// ============================================================

QString NetworkManager::getSubnet(
    const QString &interfaceName)
{
    QString output =
        runNmcli({
            "-t",
            "-f",
            "IP4.ADDRESS",
            "device",
            "show",
            interfaceName
        });

    if (output.isEmpty())
        return "";

    QStringList lines =
        output.split("\n", Qt::SkipEmptyParts);

    for (QString line : lines) {

        line = line.trimmed();

        if (line.startsWith("IP4.ADDRESS")) {

            QString value =
                line.section(":", 1).trimmed();

            return value.section("/", 1, 1);
        }
    }

    return "";
}

// ============================================================
// GET GATEWAY
// ============================================================

QString NetworkManager::getGateway(
    const QString &interfaceName)
{
    QString output =
        runNmcli({
            "-t",
            "-f",
            "IP4.GATEWAY",
            "device",
            "show",
            interfaceName
        });

    if (output.isEmpty())
        return "";

    QStringList lines =
        output.split("\n", Qt::SkipEmptyParts);

    for (QString line : lines) {

        line = line.trimmed();

        if (line.startsWith("IP4.GATEWAY")) {

            return line.section(":", 1).trimmed();
        }
    }

    return "";
}

// ============================================================
// GET DNS
// ============================================================

QString NetworkManager::getDns(
    const QString &interfaceName)
{
    QString output =
        runNmcli({
            "-t",
            "-f",
            "IP4.DNS",
            "device",
            "show",
            interfaceName
        });

    if (output.isEmpty())
        return "";

    QStringList lines =
        output.split("\n", Qt::SkipEmptyParts);

    for (QString line : lines) {

        line = line.trimmed();

        if (line.startsWith("IP4.DNS")) {

            return line.section(":", 1).trimmed();
        }
    }

    return "";
}

// ============================================================
// SET DHCP
// ============================================================

QString NetworkManager::setDhcp(
    const QString &interfaceName)
{
    QString connectionName =
        runNmcli({
            "-t",
            "-f",
            "GENERAL.CONNECTION",
            "device",
            "show",
            interfaceName
        });

    if (connectionName.isEmpty())
        return "No Ethernet connection found";

    connectionName =
        connectionName.trimmed();

    if (connectionName == "--")
        connectionName = interfaceName;

    QString output;
    QString error;

    bool success =
        runNmcliCommand(
            {
                "connection",
                "modify",
                connectionName,
                "ipv4.method",
                "auto",
                "ipv4.addresses",
                "",
                "ipv4.gateway",
                "",
                "ipv4.dns",
                ""
            },
            &output,
            &error
            );

    if (!success)
        return error.isEmpty()
                   ? "Failed to configure DHCP"
                   : error;

    success =
        runNmcliCommand(
            {
                "connection",
                "up",
                "id",
                connectionName
            },
            &output,
            &error
            );

    if (!success)
        return error.isEmpty()
                   ? "Failed to activate DHCP"
                   : error;

    emit networkConfigurationChanged();

    return "LAN configured for DHCP";
}

// ============================================================
// SET STATIC IP
// ============================================================

QString NetworkManager::setStaticIP(
    const QString &interfaceName,
    const QString &ipAddress,
    const QString &subnet,
    const QString &gateway,
    const QString &dns)
{
    if (interfaceName.trimmed().isEmpty())
        return "Invalid network interface";

    if (ipAddress.trimmed().isEmpty())
        return "IP Address is required";

    if (subnet.trimmed().isEmpty())
        return "Subnet is required";

    if (gateway.trimmed().isEmpty())
        return "Gateway is required";

    QString connectionName =
        runNmcli({
            "-t",
            "-f",
            "GENERAL.CONNECTION",
            "device",
            "show",
            interfaceName
        });

    if (connectionName.isEmpty())
        return "Ethernet cable/interface not available";

    connectionName =
        connectionName.trimmed();

    if (connectionName == "--") {

        return "No active Ethernet connection found";
    }

    QString address =
        ipAddress.trimmed()
        + "/"
        + subnet.trimmed();

    QString output;
    QString error;

    QStringList modifyArgs;

    modifyArgs
        << "connection"
        << "modify"
        << connectionName
        << "ipv4.method"
        << "manual"
        << "ipv4.addresses"
        << address
        << "ipv4.gateway"
        << gateway.trimmed();

    if (dns.trimmed().isEmpty()) {

        modifyArgs
            << "ipv4.dns"
            << "";
    }
    else {

        modifyArgs
            << "ipv4.dns"
            << dns.trimmed();
    }

    bool success =
        runNmcliCommand(
            modifyArgs,
            &output,
            &error
            );

    if (!success) {

        return error.isEmpty()
        ? "Failed to configure static IP"
        : error;
    }

    // Re-activate connection
    success =
        runNmcliCommand(
            {
                "connection",
                "up",
                "id",
                connectionName
            },
            &output,
            &error,
            30000
            );

    if (!success) {

        return error.isEmpty()
        ? "Static IP configured but connection could not be activated"
        : error;
    }

    emit networkConfigurationChanged();

    return "Static IP configured successfully";
}
