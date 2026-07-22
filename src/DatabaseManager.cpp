#include "DatabaseManager.h"

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QFile>
#include <QDebug>
#include <QDate>
#include <QTime>
#include <QDir>
#include <QVariantMap>


DatabaseManager::DatabaseManager(QObject *parent)
    : QObject(parent)
{
}

bool DatabaseManager::initialize()
{

    QString dbPath = QDir::currentPath() + "/AppDataBase.db";

    qDebug() << "DB Path:" << dbPath;

    bool firstRun = !QFile::exists(dbPath);

    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName(dbPath);

    if (!db.open()) {
        qDebug() << "DB open error:" << db.lastError().text();
        return false;
    }

    if (firstRun) {
        qDebug() << "First run: Creating DB & tables...";

    } else {
        qDebug() << "DB already exists, opening...";
    }

    createTables();

    QSqlQuery query;

    query.exec(
        "ALTER TABLE usertable "
        "ADD COLUMN IF NOT EXISTS password_expiry_date TEXT"
        );

    query.exec(
        "UPDATE usertable "
        "SET password_expiry_date = date('now', '+90 day') "
        "WHERE password_expiry_date IS NULL "
        "OR password_expiry_date = ''");

    return true;
}

// Create Table
void DatabaseManager::createTables()
{
    QSqlQuery query;


    // ENV VARIABLES
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS envvariables (
            data VARCHAR(5000),
            id VARCHAR(20),
            extradata VARCHAR(500)
        );
    )");

    // ADMIN CONFIG
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS adminconfiguration (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT
        );
    )");



    // Machine Info
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS machineinfo(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            supplierName TEXT,
            serialNumber TEXT,
            machineId TEXT,
            userName TEXT,
            location TEXT,
            machineType TEXT
        );
    )");

    // SYSTEM SETTINGS
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS systemsettings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT
        );
    )");

    // AUTO VALIDATE
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS autovalidate (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT
        );
    )");

    // PRODUCT REPORT MAIN
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS productreportmain (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            dt DATETIME,
            sno INTEGER,
            gno INTEGER,
            data TEXT,
            startedAt DATETIME,
            endedAt DATETIME,
            uno VARCHAR(20),
            lastactiveuser VARCHAR(20),
            batchnumber VARCHAR(50),
            productname VARCHAR(50),
            productcode VARCHAR(50)
        );
    )");

    // PRODUCT REPORT
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS productreport (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT
        );
    )");

    // ACTIVE PRODUCT DATA
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS activeProductData (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT
        );
    )");

    // GROUP TABLE
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS group1 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT
        );
    )");

    // DPV TABLE
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS dpv (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT
        );
    )");

    // DEFAULT TABLE
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS default1 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT
        );
    )");

    // LIST OF TABLES
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS listoftables (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
        );
    )");

    QString tableName = "A_" + QDate::currentDate().toString("dd_MM_yyyy");

    query.exec(R"(
    CREATE TABLE IF NOT EXISTS usertable (
        fpid VARCHAR(4),
        id VARCHAR(3),
        username VARCHAR(15),
        password VARCHAR(20),
        role VARCHAR(20),
        password_expiry_date TEXT
    );
    )");



    // Create default admin user if it doesn't exist
    QSqlQuery checkUser;
    checkUser.prepare(
        "SELECT COUNT(*) FROM usertable WHERE username = ?");

    checkUser.addBindValue("DefaultUser");

    if (checkUser.exec() && checkUser.next())
    {
        if (checkUser.value(0).toInt() == 0)
        {
            QSqlQuery insertDefaultUser;

            insertDefaultUser.prepare(
                "INSERT INTO usertable "
                "(fpid, id, username, password, role, password_expiry_date) "
                "VALUES (?, ?, ?, ?, ?, ?)");

            insertDefaultUser.addBindValue("0000");
            insertDefaultUser.addBindValue("001");
            insertDefaultUser.addBindValue("DefaultUser");
            insertDefaultUser.addBindValue("00000");
            insertDefaultUser.addBindValue("Admin");

            insertDefaultUser.addBindValue(
                QDate::currentDate()
                    .addDays(90)
                    .toString(Qt::ISODate));

            if (!insertDefaultUser.exec())
            {
                qDebug() << "Failed to create default admin:"
                         << insertDefaultUser.lastError().text();
            }
            else
            {
                qDebug() << "Default admin user created.";
            }
        }
    }

    query.exec(R"(
        CREATE TABLE IF NOT EXISTS CoilOutputHistory(

            id INTEGER PRIMARY KEY AUTOINCREMENT,

            average INTEGER,

            reading_date TEXT,

            reading_time TEXT,

            created_date TEXT
        );
    )");

    query.exec(R"(
        CREATE TABLE IF NOT EXISTS machineparameters (
            id INTEGER PRIMARY KEY,
            machinePhase INTEGER,
            signalThr INTEGER,
            ampThr INTEGER,
            ddPower INTEGER,
            ddFreq REAL
        );
    )");

    query.exec(R"(
        INSERT OR IGNORE INTO machineparameters
            (id, machinePhase, signalThr, ampThr, ddPower, ddFreq)
            VALUES
        (1, 0, 0, 0, 0, 25.0);

    )");

    // S1 SETTINGS PARAMETERS
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS filtersettings (
            id INTEGER PRIMARY KEY,

            lpf INTEGER,
            hpf INTEGER,

            operateDelay INTEGER,
            holdDelay INTEGER,
            relayDelay INTEGER,

            digitalGain REAL,
            analogGain INTEGER
        );
    )");

    query.exec(R"(
        INSERT OR IGNORE INTO filtersettings
        (
            id,
            lpf,
            hpf,
            operateDelay,
            holdDelay,
            relayDelay,
            digitalGain,
            analogGain
        )
        VALUES
        (
            1,
            10,
            2.0,
            0,
            250,
            250,
            1.0,
            1.0
        );
    )");


    qDebug() << "All tables created!";
}

// INSERT USER
bool DatabaseManager::insertUser(
    const QString &fpid,
    const QString &id,
    const QString &username,
    const QString &password,
    const QString &role)
{
    QSqlQuery checkQuery;

    checkQuery.prepare(
        "SELECT COUNT(*) "
        "FROM usertable "
        "WHERE username = ? "
        "AND role = ?");

    checkQuery.addBindValue(username);
    checkQuery.addBindValue(role);

    if (checkQuery.exec() && checkQuery.next())
    {
        if (checkQuery.value(0).toInt() > 0)
        {
            qDebug() << "User already exists with same role";
            return false;
        }
    }

    QSqlQuery query;

    query.prepare(
        "INSERT INTO usertable "
        "(fpid, id, username, password, role, password_expiry_date) "
        "VALUES (?, ?, ?, ?, ?, ?)");

    query.addBindValue(fpid);
    query.addBindValue(id);
    query.addBindValue(username);
    query.addBindValue(password);
    query.addBindValue(role);

    query.addBindValue(
        QDate::currentDate()
            .addDays(90)
            .toString(Qt::ISODate));

    if (!query.exec())
    {
        qDebug() << "Insert error:"
                 << query.lastError().text();
        return false;
    }

    return true;
}

bool DatabaseManager::saveMachineInfo(
    const QString &supplierName,
    const QString &serialNumber,
    const QString &machineId,
    const QString &userName,
    const QString &location,
    const QString &machineType)
{
    QSqlQuery query;

    query.exec("DELETE FROM machineinfo");

    query.prepare(
        "INSERT INTO machineinfo "
        "(supplierName, serialNumber, machineId, userName, location, machineType) "
        "VALUES (?, ?, ?, ?, ?, ?)");

    query.addBindValue(supplierName);
    query.addBindValue(serialNumber);
    query.addBindValue(machineId);
    query.addBindValue(userName);
    query.addBindValue(location);
    query.addBindValue(machineType);

    return query.exec();
}

QVariantMap DatabaseManager::getMachineInfo()
{

    QVariantMap data;


    QSqlQuery query;

    query.prepare(

        "SELECT * FROM machineinfo "
        "LIMIT 1"

        );


    if(query.exec() && query.next())
    {

        data["supplierName"] =
            query.value("supplierName");

        data["serialNumber"] =
            query.value("serialNumber");

        data["machineId"] =
            query.value("machineId");

        data["userName"] =
            query.value("userName");

        data["location"] =
            query.value("location");

        data["machineType"] =
            query.value("machineType");

    }


    return data;

}

// READ USERS
void DatabaseManager::printAllUsers()
{
    QSqlQuery query("SELECT * FROM usertable");

    while (query.next()) {
        QString username = query.value("username").toString();
        QString password = query.value("password").toString();
        QString role = query.value("role").toString();

        qDebug() << "User:"
                 << username
                 << password
                 << role;
    }
}

// Delete User

bool DatabaseManager::deleteUser(
    const QString &role,
    const QString &username)
{
    if (username == "DefaultUser")
    {
        qDebug() << "DefaultUser cannot be deleted.";
        return false;
    }

    if (role == "Admin")
    {
        QSqlQuery query;

        query.prepare(
            "SELECT COUNT(*) "
            "FROM usertable "
            "WHERE role = 'Admin' "
            "AND username != ?");

        query.addBindValue(username);

        if (!query.exec() || !query.next())
        {
            qDebug() << "Failed to count admins.";
            return false;
        }

        int remainingAdmins = query.value(0).toInt();

        if (remainingAdmins < 1)
        {
            qDebug() << "Cannot delete the last Admin.";
            return false;
        }
    }

    QSqlQuery deleteQuery;

    deleteQuery.prepare(
        "DELETE FROM usertable "
        "WHERE role = ? "
        "AND username = ?");

    deleteQuery.addBindValue(role);
    deleteQuery.addBindValue(username);

    if (!deleteQuery.exec())
    {
        qDebug() << "Delete failed:"
                 << deleteQuery.lastError().text();
        return false;
    }

    return deleteQuery.numRowsAffected() > 0;
}

bool DatabaseManager::updatePassword(
    const QString &role,
    const QString &username,
    const QString &newPassword)
{
    QSqlQuery query;

    query.prepare(
        "UPDATE usertable "
        "SET password = ?, "
        "password_expiry_date = ? "
        "WHERE role = ? "
        "AND username = ?");

    query.addBindValue(newPassword);

    query.addBindValue(
        QDate::currentDate()
            .addDays(90)
            .toString(Qt::ISODate));

    query.addBindValue(role);
    query.addBindValue(username);

    if (!query.exec())
    {
        qDebug() << "Password update failed:"
                 << query.lastError().text();
        return false;
    }

    if (query.numRowsAffected() == 0)
    {
        qDebug() << "User not found.";
        return false;
    }

    qDebug() << "Password updated for:"
             << username;

    return true;
}

QStringList DatabaseManager::getUsersByRole(const QString &role)
{
    QStringList users;

    QSqlQuery query;
    query.prepare(
        "SELECT username "
        "FROM usertable "
        "WHERE role = ? "
        "ORDER BY username");

    query.addBindValue(role);

    if (!query.exec())
    {
        qDebug() << "Failed to fetch users:"
                 << query.lastError().text();
        return users;
    }

    while (query.next())
    {
        users << query.value(0).toString();
    }

    return users;
}

bool DatabaseManager::validateLogin(
    const QString &role,
    const QString &username,
    const QString &password)
{
    QSqlQuery query;

    query.prepare(
        "SELECT COUNT(*) "
        "FROM usertable "
        "WHERE role = :role "
        "AND username = :username "
        "AND password = :password");

    query.bindValue(":role", role);
    query.bindValue(":username", username);
    query.bindValue(":password", password);

    if (!query.exec())
    {
        qDebug() << "Login query failed:"
                 << query.lastError().text();
        return false;
    }

    if (query.next())
    {
        return query.value(0).toInt() > 0;
    }

    return false;
}

bool DatabaseManager::isPasswordExpired(
    const QString &username)
{
    QSqlQuery query;

    query.prepare(
        "SELECT password_expiry_date "
        "FROM usertable "
        "WHERE username = ?");

    query.addBindValue(username);

    if (!query.exec() || !query.next())
        return true;

    QDate expiry =
        QDate::fromString(
            query.value(0).toString(),
            Qt::ISODate);

    return QDate::currentDate() > expiry;
}

int DatabaseManager::daysUntilPasswordExpiry(
    const QString &username)
{
    QSqlQuery query;

    query.prepare(
        "SELECT password_expiry_date "
        "FROM usertable "
        "WHERE username = ?");

    query.addBindValue(username);

    if (!query.exec() || !query.next())
        return -1;

    QDate expiry =
        QDate::fromString(
            query.value(0).toString(),
            Qt::ISODate);

    return QDate::currentDate().daysTo(expiry);
}

bool DatabaseManager::saveCoilOutputAverage(int average)
{
    QDate today =
        QDate::currentDate();

    QString currentTime =
        QTime::currentTime()
            .toString("HH:mm");

    QString displayDate =
        today.toString("dd MMM");

    QString fullDate =
        today.toString("yyyy-MM-dd");

    QSqlQuery query;
    query.prepare(
        "INSERT INTO CoilOutputHistory "
        "(average, reading_date, reading_time, created_date) "
        "VALUES (?, ?, ?, ?)"
        );

    query.addBindValue(average);

    // reading_date — used for display in QML (e.g. "14 Jul")
    query.addBindValue(
        displayDate
        );

    // reading_time — used for display in QML (e.g. "00:05")
    query.addBindValue(
        currentTime
        );

    // created_date — used internally for sorting/deleting (e.g. "2026-07-14")
    query.addBindValue(
        fullDate
        );

    if(!query.exec())
    {
        qDebug()
        << "Failed to save coil average:"
        << query.lastError().text();
        return false;
    }

    /*
        Keep only latest 30 days
        Example:
        31 July:
        delete 01 July
        Keep:
        02 July - 31 July
        01 August:
        delete 02 July
        Keep:
        03 July - 01 August
    */
    QDate deleteLimit =
        today.addDays(-29);

    QString deleteDate =
        deleteLimit.toString("yyyy-MM-dd");

    QSqlQuery deleteQuery;
    deleteQuery.prepare(
        "DELETE FROM CoilOutputHistory "
        "WHERE created_date < ?"
        );
    deleteQuery.addBindValue(
        deleteDate
        );

    if(!deleteQuery.exec())
    {
        qDebug()
        << "Old coil data deletion failed:"
        << deleteQuery.lastError().text();
    }

    qDebug()
        << "Coil Average Saved:"
        << average
        << currentTime
        << displayDate;

    return true;
}

QVariantList DatabaseManager::getCoilOutputHistory()
{
    QVariantList list;

    QSqlQuery query;
    query.prepare(
        "SELECT average, reading_date, reading_time, created_date "
        "FROM CoilOutputHistory "
        "ORDER BY created_date ASC, id ASC"
        );

    if(!query.exec())
    {
        qDebug()
        << "Coil history fetch error:"
        << query.lastError().text();
        return list;
    }

    while(query.next())
    {
        QVariantMap item;

        item["value"] =
            query.value("average");

        item["date"] =
            query.value("reading_date");   // e.g. "14 Jul"

        item["time"] =
            query.value("reading_time");   // e.g. "00:05"

        item["created_date"] =
            query.value("created_date");   // e.g. "2026-07-14" — sortable

        list.append(item);
    }

    return list;
}

// ==================== Machine Parameters ===============================

bool DatabaseManager::saveMachinePhaseSettings(
    const QString &machinePhase,
    int signalThr,
    int ampThr)
{
    QSqlQuery query;

    query.prepare(
        "UPDATE machineparameters "
        "SET machinePhase = ?, "
        "signalThr = ?, "
        "ampThr = ? "
        "WHERE id = 1");

    query.addBindValue(machinePhase);
    query.addBindValue(signalThr);
    query.addBindValue(ampThr);

    if (!query.exec())
    {
        qDebug() << query.lastError().text();
        return false;
    }

    return true;
}

bool DatabaseManager::saveDDPower(int ddPower)
{
    QSqlQuery query;

    query.prepare(
        "UPDATE machineparameters "
        "SET ddPower = ? "
        "WHERE id = 1"
        );

    query.addBindValue(ddPower);

    if(!query.exec())
    {
        qDebug() << "DD Power save failed:"
                 << query.lastError().text();

        return false;
    }

    return true;
}

bool DatabaseManager::saveDDFrequency(double ddFreq)
{
    QSqlQuery query;

    query.prepare(
        "UPDATE machineparameters "
        "SET ddFreq = ? "
        "WHERE id = 1"
        );

    query.addBindValue(ddFreq);

    if(!query.exec())
    {
        qDebug() << "DD Frequency save failed:"
                 << query.lastError().text();

        return false;
    }

    return true;
}

QVariantMap DatabaseManager::getMachinePhaseSettings()
{
    QVariantMap data;

    QSqlQuery query;

    query.prepare(
        "SELECT machinePhase, signalThr, ampThr "
        "FROM machineparameters "
        "WHERE id = 1");

    if (query.exec() && query.next())
    {
        data["machinePhase"] = query.value("machinePhase");
        data["signalThr"] = query.value("signalThr");
        data["ampThr"] = query.value("ampThr");
    }

    return data;
}

QVariantMap DatabaseManager::getDDSettings()
{
    QVariantMap data;

    QSqlQuery query;

    query.prepare(
        "SELECT ddPower, ddFreq "
        "FROM machineparameters "
        "WHERE id = 1");

    if (query.exec() && query.next())
    {
        data["ddPower"] = query.value("ddPower");
        data["ddFreq"] = query.value("ddFreq");
    }

    return data;
}


// =================== Filter Settings ======================

bool DatabaseManager::saveS1Settings(
    double lpf,
    double hpf,
    int operateDelay,
    int holdDelay,
    int relayDelay,
    double digitalGain,
    double analogGain)
{
    QSqlQuery query;

    query.prepare(
        "UPDATE filtersettings SET "
        "lpf = ?, "
        "hpf = ?, "
        "operateDelay = ?, "
        "holdDelay = ?, "
        "relayDelay = ?, "
        "digitalGain = ?, "
        "analogGain = ? "
        "WHERE id = 1"
        );


    query.addBindValue(lpf);
    query.addBindValue(hpf);
    query.addBindValue(operateDelay);
    query.addBindValue(holdDelay);
    query.addBindValue(relayDelay);
    query.addBindValue(digitalGain);
    query.addBindValue(analogGain);


    if(!query.exec())
    {
        qDebug() << "S1 settings save failed:"
                 << query.lastError().text();

        return false;
    }


    return true;
}

QVariantMap DatabaseManager::getS1Settings()
{
    QVariantMap data;

    QSqlQuery query;

    query.prepare(
        "SELECT "
        "lpf,"
        "hpf,"
        "operateDelay,"
        "holdDelay,"
        "relayDelay,"
        "digitalGain,"
        "analogGain "
        "FROM filtersettings "
        "WHERE id=1"
        );


    if(query.exec() && query.next())
    {
        data["lpf"] = query.value("lpf");
        data["hpf"] = query.value("hpf");
        data["operateDelay"] = query.value("operateDelay");
        data["holdDelay"] = query.value("holdDelay");
        data["relayDelay"] = query.value("relayDelay");
        data["digitalGain"] = query.value("digitalGain");
        data["analogGain"] = query.value("analogGain");
    }

    return data;
}
