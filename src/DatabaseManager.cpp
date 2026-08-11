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

static QString productLibraryTableName(int groupNo)
{
    if (groupNo < 1 || groupNo > 10)
        return QString();

    return QString("prodlib_grp%1")
        .arg(groupNo, 2, 10, QChar('0'));
}


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


    // AUDIT TRAIL REPORT

    query.exec(R"(
        CREATE TABLE IF NOT EXISTS audittrailreport (
            sr_no INTEGER,
            date TEXT,
            time TEXT,
            user TEXT,
            old_value TEXT,
            new_value TEXT,
            remark TEXT
        );
    )");


    // BATCH REPORT MAIN

    query.exec(R"(
        CREATE TABLE IF NOT EXISTS batchreportmain (
            id INTEGER PRIMARY KEY AUTOINCREMENT,

            batchId TEXT,
            productName TEXT,
            productCode TEXT,
            productSno TEXT,

            startedAt TEXT,
            endedAt TEXT,

            runDuration INTEGER DEFAULT 0,
            pauseDuration INTEGER DEFAULT 0,
            totalDuration INTEGER DEFAULT 0,

            startedBy TEXT,
            endedBy TEXT,

            rejectionCount INTEGER DEFAULT 0,

            status TEXT
        );
    )");


    // ============================================================
    // BATCH REPORT EVENTS
    // ============================================================

    query.exec(R"(
        CREATE TABLE IF NOT EXISTS batchreportevents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,

            batchReportId INTEGER,

            eventType TEXT,
            eventTime TEXT,
            user TEXT,

            FOREIGN KEY(batchReportId)
            REFERENCES batchreportmain(id)
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

    // ============================================================
    // PRODUCT LIBRARY
    // ============================================================

    for (int groupNo = 1; groupNo <= 10; groupNo++)
    {
        if (!createProductLibraryTable(groupNo))
        {
            qDebug()
            << "Failed to create product library table:"
            << groupNo;
        }
    }


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
    QSqlDatabase db = QSqlDatabase::database();

    // =========================================================
    // CHECK DATABASE
    // =========================================================

    if (!db.isValid() || !db.isOpen())
    {
        qDebug()
        << "Database connection is invalid or closed.";

        return false;
    }

    // =========================================================
    // START TRANSACTION
    // =========================================================

    if (!db.transaction())
    {
        qDebug()
        << "Failed to start transaction:"
        << db.lastError().text();

        return false;
    }

    // =========================================================
    // STEP 1
    // UPDATE MACHINE PARAMETERS
    // =========================================================

    QSqlQuery machineQuery(db);

    machineQuery.prepare(R"(
        UPDATE machineparameters
        SET
            machinePhase = ?,
            signalThr = ?,
            ampThr = ?
        WHERE id = 1
    )");

    machineQuery.addBindValue(machinePhase);
    machineQuery.addBindValue(signalThr);
    machineQuery.addBindValue(ampThr);

    if (!machineQuery.exec())
    {
        qDebug()
        << "Failed to update machineparameters:"
        << machineQuery.lastError().text();

        db.rollback();

        return false;
    }


    // =========================================================
    // STEP 2
    // FIND ACTIVE PRODUCT
    // =========================================================

    int activeGroup = -1;
    int activeSrNo = -1;

    for (int groupNo = 1; groupNo <= 10; ++groupNo)
    {
        QString tableName =
            productLibraryTableName(groupNo);

        if (tableName.isEmpty())
            continue;

        if (!productLibraryTableExists(groupNo))
            continue;

        QString sql = QString(R"(
            SELECT sr_no
            FROM %1
            WHERE active = 1
            LIMIT 1
        )").arg(tableName);

        QSqlQuery activeQuery(db);

        if (!activeQuery.exec(sql))
        {
            qDebug()
            << "Failed to find active product:"
            << tableName
            << activeQuery.lastError().text();

            db.rollback();

            return false;
        }

        if (activeQuery.next())
        {
            activeGroup = groupNo;
            activeSrNo =
                activeQuery.value("sr_no").toInt();

            break;
        }
    }


    // =========================================================
    // STEP 3
    // NO ACTIVE PRODUCT
    // =========================================================

    if (activeGroup == -1 || activeSrNo == -1)
    {
        qDebug()
        << "No active product found.";

        // We can still save machineparameters.
        // Commit the machine settings.

        if (!db.commit())
        {
            qDebug()
            << "Failed to commit machineparameters:"
            << db.lastError().text();

            return false;
        }

        emit machineParametersChanged();

        return true;
    }


    // =========================================================
    // STEP 4
    // UPDATE ACTIVE PRODUCT
    // =========================================================

    QString activeTable =
        productLibraryTableName(activeGroup);

    QString updateProductSql =
        QString(R"(
            UPDATE %1
            SET
                machinePhase = ?,
                signalThr = ?,
                ampThr = ?
            WHERE sr_no = ?
              AND active = 1
        )").arg(activeTable);

    QSqlQuery productQuery(db);

    productQuery.prepare(updateProductSql);

    productQuery.addBindValue(machinePhase);
    productQuery.addBindValue(signalThr);
    productQuery.addBindValue(ampThr);
    productQuery.addBindValue(activeSrNo);

    if (!productQuery.exec())
    {
        qDebug()
        << "Failed to update active product:"
        << productQuery.lastError().text();

        db.rollback();

        return false;
    }


    // =========================================================
    // STEP 5
    // VERIFY ACTIVE PRODUCT UPDATE
    // =========================================================

    if (productQuery.numRowsAffected() != 1)
    {
        qDebug()
        << "Active product was NOT updated.";

        qDebug()
            << "Table:"
            << activeTable;

        qDebug()
            << "Group:"
            << activeGroup;

        qDebug()
            << "SR:"
            << activeSrNo;

        qDebug()
            << "Rows affected:"
            << productQuery.numRowsAffected();

        db.rollback();

        return false;
    }

    // =========================================================
    // STEP 6
    // COMMIT EVERYTHING
    // =========================================================

    if (!db.commit())
    {
        qDebug()
        << "Failed to commit machine/product parameters:"
        << db.lastError().text();

        db.rollback();

        return false;
    }


    emit machineParametersChanged();

    return true;
}



bool DatabaseManager::saveDDPower(int ddPower)
{
    QSqlDatabase db = QSqlDatabase::database();


    // =========================================================
    // START TRANSACTION
    // =========================================================

    if (!db.transaction())
    {
        qDebug()
        << "Failed to start DD Power transaction:"
        << db.lastError().text();

        return false;
    }


    // =========================================================
    // STEP 1
    // UPDATE MACHINE PARAMETERS
    // =========================================================

    QSqlQuery machineQuery(db);

    machineQuery.prepare(R"(
        UPDATE machineparameters
        SET ddPower = ?
        WHERE id = 1
    )");

    machineQuery.addBindValue(ddPower);

    if (!machineQuery.exec())
    {
        qDebug()
        << "DD Power machineparameters update failed:"
        << machineQuery.lastError().text();

        db.rollback();

        return false;
    }


    // =========================================================
    // STEP 2
    // FIND ACTIVE PRODUCT
    // =========================================================

    int activeGroup = -1;
    int activeSrNo = -1;

    for (int groupNo = 1; groupNo <= 10; ++groupNo)
    {
        QString tableName =
            productLibraryTableName(groupNo);

        if (tableName.isEmpty())
            continue;

        if (!productLibraryTableExists(groupNo))
            continue;

        QString sql = QString(R"(
            SELECT sr_no
            FROM %1
            WHERE active = 1
            LIMIT 1
        )").arg(tableName);

        QSqlQuery activeQuery(db);

        if (!activeQuery.exec(sql))
        {
            qDebug()
            << "Failed to find active product:"
            << tableName
            << activeQuery.lastError().text();

            db.rollback();

            return false;
        }

        if (activeQuery.next())
        {
            activeGroup = groupNo;
            activeSrNo =
                activeQuery.value("sr_no").toInt();

            break;
        }
    }


    // =========================================================
    // NO ACTIVE PRODUCT
    // =========================================================

    if (activeGroup == -1 || activeSrNo == -1)
    {
        qDebug()
        << "No active product found."
        << "Saving DD Power only to machineparameters.";

        if (!db.commit())
        {
            qDebug()
            << "Failed to commit DD Power:"
            << db.lastError().text();

            return false;
        }

        emit machineParametersChanged();

        return true;
    }


    // =========================================================
    // STEP 3
    // UPDATE ACTIVE PRODUCT
    // =========================================================

    QString activeTable =
        productLibraryTableName(activeGroup);

    QString updateProductSql =
        QString(R"(
            UPDATE %1
            SET ddPower = ?
            WHERE sr_no = ?
              AND active = 1
        )").arg(activeTable);

    QSqlQuery productQuery(db);

    productQuery.prepare(updateProductSql);

    productQuery.addBindValue(ddPower);
    productQuery.addBindValue(activeSrNo);

    if (!productQuery.exec())
    {
        qDebug()
        << "Failed to update active product DD Power:"
        << productQuery.lastError().text();

        db.rollback();

        return false;
    }


    // =========================================================
    // COMMIT
    // =========================================================

    if (!db.commit())
    {
        qDebug()
        << "Failed to commit DD Power:"
        << db.lastError().text();

        db.rollback();

        return false;
    }


    qDebug()
        << "DD Power saved successfully."
        << "Value =" << ddPower
        << "Active Group =" << activeGroup
        << "Active SR =" << activeSrNo;


    emit machineParametersChanged();

    return true;
}




bool DatabaseManager::saveDDFrequency(double ddFreq)
{
    QSqlDatabase db = QSqlDatabase::database();

    // =========================================================
    // CHECK DATABASE
    // =========================================================

    if (!db.isValid() || !db.isOpen())
    {
        qDebug()
        << "Database connection is invalid or closed.";

        return false;
    }


    // =========================================================
    // START TRANSACTION
    // =========================================================

    if (!db.transaction())
    {
        qDebug()
        << "Failed to start DD Frequency transaction:"
        << db.lastError().text();

        return false;
    }


    // =========================================================
    // STEP 1
    // UPDATE MACHINE PARAMETERS
    // =========================================================

    QSqlQuery machineQuery(db);

    machineQuery.prepare(R"(
        UPDATE machineparameters
        SET ddFreq = ?
        WHERE id = 1
    )");

    machineQuery.addBindValue(ddFreq);

    if (!machineQuery.exec())
    {
        qDebug()
        << "DD Frequency machineparameters update failed:"
        << machineQuery.lastError().text();

        db.rollback();

        return false;
    }


    // =========================================================
    // STEP 2
    // FIND ACTIVE PRODUCT
    // =========================================================

    int activeGroup = -1;
    int activeSrNo = -1;

    for (int groupNo = 1; groupNo <= 10; ++groupNo)
    {
        QString tableName =
            productLibraryTableName(groupNo);

        if (tableName.isEmpty())
            continue;

        if (!productLibraryTableExists(groupNo))
            continue;

        QString sql = QString(R"(
            SELECT sr_no
            FROM %1
            WHERE active = 1
            LIMIT 1
        )").arg(tableName);

        QSqlQuery activeQuery(db);

        if (!activeQuery.exec(sql))
        {
            qDebug()
            << "Failed to find active product:"
            << tableName
            << activeQuery.lastError().text();

            db.rollback();

            return false;
        }

        if (activeQuery.next())
        {
            activeGroup = groupNo;
            activeSrNo =
                activeQuery.value("sr_no").toInt();

            break;
        }
    }


    // =========================================================
    // NO ACTIVE PRODUCT
    // =========================================================

    if (activeGroup == -1 || activeSrNo == -1)
    {
        qDebug()
        << "No active product found."
        << "Saving DD Frequency only to machineparameters.";

        if (!db.commit())
        {
            qDebug()
            << "Failed to commit DD Frequency:"
            << db.lastError().text();

            return false;
        }

        emit machineParametersChanged();

        return true;
    }


    // =========================================================
    // STEP 3
    // UPDATE ACTIVE PRODUCT
    // =========================================================

    QString activeTable =
        productLibraryTableName(activeGroup);

    QString updateProductSql =
        QString(R"(
            UPDATE %1
            SET ddFreq = ?
            WHERE sr_no = ?
              AND active = 1
        )").arg(activeTable);

    QSqlQuery productQuery(db);

    productQuery.prepare(updateProductSql);

    productQuery.addBindValue(ddFreq);
    productQuery.addBindValue(activeSrNo);

    if (!productQuery.exec())
    {
        qDebug()
        << "Failed to update active product DD Frequency:"
        << productQuery.lastError().text();

        db.rollback();

        return false;
    }


    // =========================================================
    // VERIFY
    // =========================================================

    if (productQuery.numRowsAffected() != 1)
    {
        qDebug()
        << "Active product DD Frequency was NOT updated.";

        qDebug()
            << "Table:"
            << activeTable;

        qDebug()
            << "Group:"
            << activeGroup;

        qDebug()
            << "SR:"
            << activeSrNo;

        qDebug()
            << "Rows affected:"
            << productQuery.numRowsAffected();

        db.rollback();

        return false;
    }


    // =========================================================
    // COMMIT
    // =========================================================

    if (!db.commit())
    {
        qDebug()
        << "Failed to commit DD Frequency:"
        << db.lastError().text();

        db.rollback();

        return false;
    }


    qDebug()
        << "DD Frequency saved successfully."
        << "Value =" << ddFreq
        << "Active Group =" << activeGroup
        << "Active SR =" << activeSrNo;


    emit machineParametersChanged();

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


//======================== Audit Trail Report ===============

bool DatabaseManager::addAuditTrailRecord(
    const QString &user,
    const QString &oldValue,
    const QString &newValue,
    const QString &remark)
{
    QDate currentDate = QDate::currentDate();
    QTime currentTime = QTime::currentTime();

    QString date =
        currentDate.toString("dd/MM/yyyy");

    QString time =
        currentTime.toString("HH:mm:ss");

    // If old/new values are empty,
    // store "---" instead
    QString finalOldValue =
        oldValue.isEmpty() ? "---" : oldValue;

    QString finalNewValue =
        newValue.isEmpty() ? "---" : newValue;

    int nextSrNo = 1;

    QSqlQuery srQuery;

    if (srQuery.exec("SELECT sr_no FROM audittrailreport ORDER BY rowid DESC LIMIT 1")
        && srQuery.next())
    {
        nextSrNo = srQuery.value(0).toInt() + 1;

        if (nextSrNo > 9999)
            nextSrNo = 1;
    }

    QSqlQuery query;

    query.prepare(
        "INSERT INTO audittrailreport "
        "(sr_no, date, time, user, old_value, new_value, remark) "
        "VALUES (?, ?, ?, ?, ?, ?, ?)"
    );

    query.addBindValue(nextSrNo);
    query.addBindValue(date);
    query.addBindValue(time);
    query.addBindValue(user);
    query.addBindValue(finalOldValue);
    query.addBindValue(finalNewValue);
    query.addBindValue(remark);

    if (!query.exec())
    {
        qDebug()
        << "Failed to save Audit Trail record:"
        << query.lastError().text();

        return false;
    }

    return true;
}


QVariantList DatabaseManager::getAuditTrailReport()
{
    QVariantList list;

    QSqlQuery query;

    query.prepare(
        "SELECT "
        "sr_no, "
        "date, "
        "time, "
        "user, "
        "old_value, "
        "new_value, "
        "remark "
        "FROM audittrailreport "
        "ORDER BY rowid DESC"
    );

    if (!query.exec())
    {
        qDebug() << "AuditTrail Error:"
                 << query.lastError().text();
        return list;
    }

    while (query.next())
    {
        QVariantMap row;

        row["sr"]     = query.value("sr_no");
        row["date"]   = query.value("date");
        row["time"]   = query.value("time");
        row["user"]   = query.value("user");
        row["old"]    = query.value("old_value");
        row["newVal"] = query.value("new_value");
        row["remark"] = query.value("remark");

        list.append(row);
    }

    qDebug() << "Audit records loaded:" << list.count();

    return list;
}

bool DatabaseManager::clearAuditTrail()
{
    QSqlQuery query;

    if (!query.exec("DELETE FROM audittrailreport"))
    {
        qDebug()
        << "Failed to clear audit trail:"
        << query.lastError().text();

        return false;
    }

    qDebug()
        << "Audit trail cleared successfully."
        << "Rows deleted:"
        << query.numRowsAffected();

    return true;
}

//==================== Batch Report =======================

int DatabaseManager::createBatchReport(
    const QString &batchId,
    const QString &productName,
    const QString &productCode,
    const QString &productSno,
    const QString &startedAt,
    const QString &startedBy)
{
    QSqlQuery query;

    query.prepare(R"(
        INSERT INTO batchreportmain
        (
            batchId,
            productName,
            productCode,
            productSno,
            startedAt,
            endedAt,
            runDuration,
            pauseDuration,
            totalDuration,
            startedBy,
            endedBy,
            rejectionCount,
            status
        )
        VALUES (?, ?, ?, ?, ?, '', 0, 0, 0, ?, '', 0, 'Running')
    )");

    query.addBindValue(batchId);
    query.addBindValue(productName);
    query.addBindValue(productCode);
    query.addBindValue(productSno);
    query.addBindValue(startedAt);
    query.addBindValue(startedBy);

    if (!query.exec())
    {
        qDebug()
        << "Failed to create batch report:"
        << query.lastError().text();

        return -1;
    }

    int id = query.lastInsertId().toInt();

    qDebug()
        << "Batch report created:"
        << id
        << batchId;

    return id;
}

bool DatabaseManager::addBatchReportEvent(
    int batchReportId,
    const QString &eventType,
    const QString &eventTime,
    const QString &user)
{
    QSqlQuery query;

    query.prepare(R"(
        INSERT INTO batchreportevents
        (
            batchReportId,
            eventType,
            eventTime,
            user
        )
        VALUES (?, ?, ?, ?)
    )");

    query.addBindValue(batchReportId);
    query.addBindValue(eventType);
    query.addBindValue(eventTime);
    query.addBindValue(user);

    if (!query.exec())
    {
        qDebug()
        << "Failed to save batch event:"
        << query.lastError().text();

        return false;
    }

    return true;
}

bool DatabaseManager::finishBatchReport(
    int batchReportId,
    const QString &endedAt,
    int runDuration,
    int pauseDuration,
    int totalDuration,
    const QString &endedBy,
    int rejectionCount)
{
    QSqlQuery query;

    query.prepare(R"(
        UPDATE batchreportmain
        SET
            endedAt = ?,
            runDuration = ?,
            pauseDuration = ?,
            totalDuration = ?,
            endedBy = ?,
            rejectionCount = ?,
            status = 'Completed'
        WHERE id = ?
    )");

    query.addBindValue(endedAt);
    query.addBindValue(runDuration);
    query.addBindValue(pauseDuration);
    query.addBindValue(totalDuration);
    query.addBindValue(endedBy);
    query.addBindValue(rejectionCount);
    query.addBindValue(batchReportId);

    if (!query.exec())
    {
        qDebug()
        << "Failed to finish batch report:"
        << query.lastError().text();

        return false;
    }

    return query.numRowsAffected() > 0;
}

QVariantList DatabaseManager::getBatchReports()
{
    QVariantList list;

    QSqlQuery query;

    query.prepare(R"(
        SELECT
            id,
            batchId,
            productName,
            productCode,
            productSno,
            startedAt,
            endedAt,
            runDuration,
            pauseDuration,
            totalDuration,
            startedBy,
            endedBy,
            rejectionCount,
            status
        FROM batchreportmain
        ORDER BY id DESC
    )");

    if (!query.exec())
    {
        qDebug()
        << "Failed to load batch reports:"
        << query.lastError().text();

        return list;
    }

    while (query.next())
    {
        QVariantMap row;

        row["id"] =
            query.value("id");

        row["batch"] =
            query.value("batchId");

        row["product"] =
            query.value("productName");

        row["productCode"] =
            query.value("productCode");

        row["productSno"] =
            query.value("productSno");

        row["started"] =
            query.value("startedAt");

        row["ended"] =
            query.value("endedAt");

        row["runDuration"] =
            query.value("runDuration");

        row["pauseDuration"] =
            query.value("pauseDuration");

        row["totalDuration"] =
            query.value("totalDuration");

        row["startedBy"] =
            query.value("startedBy");

        row["endedBy"] =
            query.value("endedBy");

        row["rejectionCount"] =
            query.value("rejectionCount");

        row["status"] =
            query.value("status");

        list.append(row);
    }

    return list;
}

QVariantList DatabaseManager::getBatchReportEvents(
    int batchReportId)
{
    QVariantList list;

    QSqlQuery query;

    query.prepare(R"(
        SELECT
            eventType,
            eventTime,
            user
        FROM batchreportevents
        WHERE batchReportId = ?
        ORDER BY id ASC
    )");

    query.addBindValue(batchReportId);

    if (!query.exec())
    {
        qDebug()
        << "Failed to load batch events:"
        << query.lastError().text();

        return list;
    }

    while (query.next())
    {
        QVariantMap row;

        row["eventType"] =
            query.value("eventType");

        row["eventTime"] =
            query.value("eventTime");

        row["user"] =
            query.value("user");

        list.append(row);
    }

    return list;
}


bool DatabaseManager::deleteAllBatchReports()
{
    QSqlQuery query;

    // =====================================================
    // DELETE BATCH EVENTS
    // =====================================================

    if (!query.exec("DELETE FROM batchreportevents"))
    {
        qWarning()
        << "Failed to delete batch report events:"
        << query.lastError().text();

        return false;
    }

    qDebug()
        << "Batch report events deleted:"
        << query.numRowsAffected();


    // =====================================================
    // DELETE BATCH REPORT MAIN RECORDS
    // =====================================================

    if (!query.exec("DELETE FROM batchreportmain"))
    {
        qWarning()
        << "Failed to delete batch reports:"
        << query.lastError().text();

        return false;
    }

    qDebug()
        << "Batch report main records deleted:"
        << query.numRowsAffected();


    // =====================================================
    // RESET AUTOINCREMENT ID
    // =====================================================

    if (!query.exec(
            "DELETE FROM sqlite_sequence "
            "WHERE name IN "
            "('batchreportevents', 'batchreportmain')"))
    {
        qWarning()
        << "Failed to reset batch report sequence:"
        << query.lastError().text();

        // Records are already deleted, so don't return false here.
    }


    qDebug() << "All batch reports permanently deleted.";

    return true;
}


//========================= Product Library ======================


bool DatabaseManager::createProductLibraryTable(int groupNo)
{
    QString tableName =
        productLibraryTableName(groupNo);

    if (tableName.isEmpty())
    {
        qDebug()
        << "Invalid Product Library group:"
        << groupNo;

        return false;
    }

    QSqlQuery query;

    QString sql = QString(R"(
    CREATE TABLE IF NOT EXISTS %1 (

        id INTEGER PRIMARY KEY AUTOINCREMENT,

        sr_no INTEGER UNIQUE,

        product_name TEXT NOT NULL,

        product_code TEXT UNIQUE NOT NULL,

        machinePhase INTEGER DEFAULT 45,

        signalThr INTEGER DEFAULT 350,

        ampThr INTEGER DEFAULT 14000,

        ddPower INTEGER DEFAULT 40,

        ddFreq REAL DEFAULT 32.1,

        digitalGain REAL DEFAULT 1,

        analogGain REAL DEFAULT 1,

        active INTEGER DEFAULT 0
    )

)").arg(tableName);


    if (!query.exec(sql))
    {
        qDebug()
        << "Failed to create product library table:"
        << tableName
        << query.lastError().text();

        return false;
    }


    qDebug()
        << "Product Library table created/exists:"
        << tableName;

    return true;
}

bool DatabaseManager::productLibraryTableExists(int groupNo)
{
    QString tableName =
        productLibraryTableName(groupNo);

    if (tableName.isEmpty())
        return false;

    QSqlQuery query;

    query.prepare(
        "SELECT COUNT(*) "
        "FROM sqlite_master "
        "WHERE type = 'table' "
        "AND name = ?"
        );

    query.addBindValue(tableName);

    if (!query.exec() || !query.next())
    {
        qDebug()
        << "Failed to check product library table:"
        << query.lastError().text();

        return false;
    }

    return query.value(0).toInt() > 0;
}

bool DatabaseManager::productLibraryProductExists(
    int groupNo,
    int srNo)
{
    QString tableName =
        productLibraryTableName(groupNo);

    if (tableName.isEmpty())
        return false;

    if (!productLibraryTableExists(groupNo))
        return false;

    QSqlQuery query;

    QString sql = QString(
                      "SELECT COUNT(*) "
                      "FROM %1 "
                      "WHERE sr_no = ?"
                      ).arg(tableName);

    query.prepare(sql);

    query.addBindValue(srNo);

    if (!query.exec() || !query.next())
    {
        qDebug()
        << "Failed checking product:"
        << query.lastError().text();

        return false;
    }

    return query.value(0).toInt() > 0;
}

bool DatabaseManager::addProductLibraryProduct(
    int groupNo,
    const QString &productName,
    const QString &productCode)
{
    QString tableName =
        productLibraryTableName(groupNo);

    // ---------------------------------------------------------
    // Validate group
    // ---------------------------------------------------------

    if (tableName.isEmpty())
    {
        qDebug()
        << "Invalid product library group:"
        << groupNo;

        return false;
    }


    // ---------------------------------------------------------
    // Create table if it does not exist
    // ---------------------------------------------------------

    if (!createProductLibraryTable(groupNo))
    {
        qDebug()
        << "Failed to create product library table:"
        << tableName;

        return false;
    }


    // ---------------------------------------------------------
    // Find next free SR number
    // ---------------------------------------------------------

    int srNo = 1;

    QSqlQuery srQuery;

    QString srSql = QString(
                        "SELECT sr_no "
                        "FROM %1 "
                        "ORDER BY sr_no ASC"
                        ).arg(tableName);

    if (!srQuery.exec(srSql))
    {
        qDebug()
        << "Failed to find free SR number:"
        << srQuery.lastError().text();

        return false;
    }


    while (srQuery.next())
    {
        int existingSr =
            srQuery.value(0).toInt();

        if (existingSr == srNo)
        {
            srNo++;
        }
        else if (existingSr > srNo)
        {
            break;
        }
    }


    // ---------------------------------------------------------
    // Maximum 100 products
    // ---------------------------------------------------------

    if (srNo > 100)
    {
        qDebug()
        << "Product library group is full:"
        << groupNo;

        return false;
    }


    // ---------------------------------------------------------
    // Check duplicate product code
    // ---------------------------------------------------------

    QSqlQuery codeQuery;

    QString codeSql = QString(
                          "SELECT COUNT(*) "
                          "FROM %1 "
                          "WHERE product_code = ?"
                          ).arg(tableName);

    codeQuery.prepare(codeSql);

    codeQuery.addBindValue(productCode);

    if (!codeQuery.exec())
    {
        qDebug()
        << "Failed to check product code:"
        << codeQuery.lastError().text();

        return false;
    }

    if (codeQuery.next())
    {
        if (codeQuery.value(0).toInt() > 0)
        {
            qDebug()
            << "Product code already exists:"
            << productCode;

            return false;
        }
    }


    QString sql = QString(R"(
        INSERT INTO %1
        (
            sr_no,
            product_name,
            product_code,
            machinePhase,
            signalThr,
            ampThr,
            ddPower,
            ddFreq,
            digitalGain,
            analogGain,
            active
        )
        VALUES
        (
            ?,
            ?,
            ?,
            45,
            350,
            14000,
            40,
            32.1,
            1,
            1,
            0
        )
    )").arg(tableName);


    QSqlQuery query;

    query.prepare(sql);

    query.addBindValue(srNo);
    query.addBindValue(productName);
    query.addBindValue(productCode);


    // ---------------------------------------------------------
    // Execute
    // ---------------------------------------------------------

    if (!query.exec())
    {
        qDebug()
        << "Failed to add product:"
        << query.lastError().text();

        return false;
    }

    return true;
}

QVariantList DatabaseManager::getProductLibraryProducts(
    int groupNo)
{
    QVariantList list;

    QString tableName =
        productLibraryTableName(groupNo);

    if (tableName.isEmpty())
        return list;

    // Group 02-10 may not exist yet.
    if (!productLibraryTableExists(groupNo))
    {
        qDebug()
        << "Product library table does not exist:"
        << tableName;

        return list;
    }

    QString sql = QString(R"(
        SELECT
            id,
            sr_no,
            product_name,
            product_code,
            machinePhase,
            signalThr,
            ampThr,
            ddPower,
            ddFreq,
            digitalGain,
            analogGain,
            active
        FROM %1
        ORDER BY sr_no ASC
    )").arg(tableName);

    QSqlQuery query;

    if (!query.exec(sql))
    {

        return list;
    }

    while (query.next())
    {
        QVariantMap product;

        product["id"] =
            query.value("id");

        product["sr"] =
            query.value("sr_no");

        product["name"] =
            query.value("product_name");

        product["code"] =
            query.value("product_code");

        product["machinePhase"] =
            query.value("machinePhase");

        product["signalThr"] =
            query.value("signalThr");

        product["ampThr"] =
            query.value("ampThr");

        product["ddPower"] =
            query.value("ddPower");

        product["ddFreq"] =
            query.value("ddFreq");

        product["digitalGain"] =
            query.value("digitalGain");

        product["analogGain"] =
            query.value("analogGain");

        product["active"] =
            query.value("active").toInt() == 1;

        product["selected"] = false;

        product["fixedItem"] =
            (groupNo == 1 &&
             query.value("sr_no").toInt() == 1);

        list.append(product);
    }

    return list;
}

bool DatabaseManager::deleteProductLibraryProduct(
    int groupNo,
    int srNo)
{
    QString tableName =
        productLibraryTableName(groupNo);

    if (tableName.isEmpty())
        return false;

    if (!productLibraryTableExists(groupNo))
        return false;


    // ---------------------------------------------------------
    // Default Product cannot be deleted
    // ---------------------------------------------------------

    if (groupNo == 1 && srNo == 1)
    {

        return false;
    }


    QString sql = QString(
                      "DELETE FROM %1 "
                      "WHERE sr_no = ?"
                      ).arg(tableName);

    QSqlQuery query;

    query.prepare(sql);

    query.addBindValue(srNo);

    if (!query.exec())
    {


        return false;
    }


    return query.numRowsAffected() > 0;
}

bool DatabaseManager::setActiveProductLibraryProduct(
    int groupNo,
    int srNo)
{
    // =========================================================
    // VALIDATE GROUP
    // =========================================================

    QString selectedTable =
        productLibraryTableName(groupNo);

    if (selectedTable.isEmpty())
    {
        qDebug()
        << "Invalid product library group:"
        << groupNo;

        return false;
    }


    // =========================================================
    // CHECK SELECTED GROUP TABLE
    // =========================================================

    if (!productLibraryTableExists(groupNo))
    {
        qDebug()
        << "Product library table does not exist:"
        << selectedTable;

        return false;
    }


    // =========================================================
    // GET DATABASE CONNECTION
    // =========================================================

    QSqlDatabase db =
        QSqlDatabase::database();

    if (!db.isValid())
    {
        qDebug()
        << "Invalid database connection.";

        return false;
    }

    if (!db.isOpen())
    {
        qDebug()
        << "Database is not open.";

        return false;
    }


    // =========================================================
    // STEP 1
    // READ SELECTED PRODUCT PARAMETERS
    // =========================================================

    QString selectSql =
        QString(R"(
            SELECT
                machinePhase,
                signalThr,
                ampThr,
                ddPower,
                ddFreq,
                digitalGain,
                analogGain
            FROM %1
            WHERE sr_no = ?
        )").arg(selectedTable);


    QSqlQuery productQuery(db);

    productQuery.prepare(selectSql);

    productQuery.addBindValue(srNo);


    if (!productQuery.exec())
    {
        qDebug()
        << "Failed to read selected product:"
        << productQuery.lastError().text();

        return false;
    }


    if (!productQuery.next())
    {
        qDebug()
        << "Selected product not found:"
        << "Group =" << groupNo
        << "SR =" << srNo;

        return false;
    }


    // =========================================================
    // GET PRODUCT PARAMETERS
    // =========================================================

    QVariant machinePhase =
        productQuery.value("machinePhase");

    QVariant signalThr =
        productQuery.value("signalThr");

    QVariant ampThr =
        productQuery.value("ampThr");

    QVariant ddPower =
        productQuery.value("ddPower");

    QVariant ddFreq =
        productQuery.value("ddFreq");

    QVariant digitalGain =
        productQuery.value("digitalGain");

    QVariant analogGain =
        productQuery.value("analogGain");


    qDebug()
        << "========================================";

    qDebug()
        << "Selecting Product"
        << "Group =" << groupNo
        << "SR =" << srNo;

    qDebug()
        << "machinePhase =" << machinePhase;

    qDebug()
        << "signalThr =" << signalThr;

    qDebug()
        << "ampThr =" << ampThr;

    qDebug()
        << "ddPower =" << ddPower;

    qDebug()
        << "ddFreq =" << ddFreq;

    qDebug()
        << "digitalGain =" << digitalGain;

    qDebug()
        << "analogGain =" << analogGain;

    qDebug()
        << "========================================";


    // =========================================================
    // STEP 2
    // START TRANSACTION
    // =========================================================

    if (!db.transaction())
    {
        qDebug()
        << "Failed to start transaction:"
        << db.lastError().text();

        return false;
    }


    // =========================================================
    // STEP 3
    // DEACTIVATE ALL PRODUCTS
    // =========================================================

    for (int group = 1; group <= 10; ++group)
    {
        QString tableName =
            productLibraryTableName(group);

        if (tableName.isEmpty())
            continue;


        if (!productLibraryTableExists(group))
            continue;


        QString deactivateSql =
            QString(
                "UPDATE %1 "
                "SET active = 0"
                ).arg(tableName);


        QSqlQuery deactivateQuery(db);


        if (!deactivateQuery.exec(deactivateSql))
        {
            qDebug()
            << "Failed to deactivate products in:"
            << tableName
            << deactivateQuery.lastError().text();

            db.rollback();

            return false;
        }
    }


    // =========================================================
    // STEP 4
    // ACTIVATE SELECTED PRODUCT
    // =========================================================

    QString activateSql =
        QString(
            "UPDATE %1 "
            "SET active = 1 "
            "WHERE sr_no = ?"
            ).arg(selectedTable);


    QSqlQuery activateQuery(db);

    activateQuery.prepare(activateSql);

    activateQuery.addBindValue(srNo);


    if (!activateQuery.exec())
    {
        qDebug()
        << "Failed to activate product:"
        << activateQuery.lastError().text();

        db.rollback();

        return false;
    }


    if (activateQuery.numRowsAffected() != 1)
    {
        qDebug()
        << "Selected product was not activated:"
        << "Group =" << groupNo
        << "SR =" << srNo;

        db.rollback();

        return false;
    }


    // =========================================================
    // STEP 5
    // UPDATE MACHINE PARAMETERS
    // =========================================================

    QSqlQuery machineQuery(db);

    machineQuery.prepare(R"(
        UPDATE machineparameters
        SET
            machinePhase = ?,
            signalThr = ?,
            ampThr = ?,
            ddPower = ?,
            ddFreq = ?
        WHERE id = 1
    )");


    machineQuery.addBindValue(machinePhase);
    machineQuery.addBindValue(signalThr);
    machineQuery.addBindValue(ampThr);
    machineQuery.addBindValue(ddPower);
    machineQuery.addBindValue(ddFreq);


    if (!machineQuery.exec())
    {
        qDebug()
        << "Failed to update machineparameters:"
        << machineQuery.lastError().text();

        db.rollback();

        return false;
    }


    if (machineQuery.numRowsAffected() != 1)
    {
        qDebug()
        << "machineparameters row was not updated.";

        db.rollback();

        return false;
    }


    // =========================================================
    // STEP 6
    // UPDATE FILTER SETTINGS
    // =========================================================

    QSqlQuery filterQuery(db);

    filterQuery.prepare(R"(
        UPDATE filtersettings
        SET
            digitalGain = ?,
            analogGain = ?
        WHERE id = 1
    )");


    filterQuery.addBindValue(digitalGain);
    filterQuery.addBindValue(analogGain);


    if (!filterQuery.exec())
    {
        qDebug()
        << "Failed to update filtersettings:"
        << filterQuery.lastError().text();

        db.rollback();

        return false;
    }


    if (filterQuery.numRowsAffected() != 1)
    {
        qDebug()
        << "filtersettings row was not updated.";

        db.rollback();

        return false;
    }


    // =========================================================
    // STEP 7
    // COMMIT
    // =========================================================

    if (!db.commit())
    {
        qDebug()
        << "Failed to commit active product:"
        << db.lastError().text();

        db.rollback();

        return false;
    }


    // =========================================================
    // STEP 8
    // DATABASE UPDATE SUCCESSFUL
    //
    // IMPORTANT:
    // Emit AFTER successful commit.
    // =========================================================

    qDebug()
        << "Active product successfully selected.";

    qDebug()
        << "Machine parameters updated.";

    qDebug()
        << "Filter settings updated.";

    qDebug()
        << "Emitting machineParametersChanged().";


    emit machineParametersChanged();


    // =========================================================
    // DONE
    // =========================================================

    return true;
}

bool DatabaseManager::applyActiveProductParameters(
    int groupNo,
    int srNo)
{
    QString tableName =
        productLibraryTableName(groupNo);

    if (tableName.isEmpty())
    {
        qDebug()
        << "Invalid product library group:"
        << groupNo;

        return false;
    }

    if (!productLibraryTableExists(groupNo))
    {
        qDebug()
        << "Product library table does not exist:"
        << tableName;

        return false;
    }

    // =========================================================
    // GET ACTIVE PRODUCT PARAMETERS
    // =========================================================

    QString selectSql = QString(R"(
        SELECT
            machinePhase,
            signalThr,
            ampThr,
            ddPower,
            ddFreq,
            digitalGain,
            analogGain
        FROM %1
        WHERE sr_no = ?
    )").arg(tableName);

    QSqlQuery selectQuery;

    selectQuery.prepare(selectSql);
    selectQuery.addBindValue(srNo);

    if (!selectQuery.exec())
    {
        qDebug()
        << "Failed to read active product parameters:"
        << selectQuery.lastError().text();

        return false;
    }

    if (!selectQuery.next())
    {
        qDebug()
        << "Product not found:"
        << "Group =" << groupNo
        << "SR =" << srNo;

        return false;
    }

    // =========================================================
    // READ PRODUCT VALUES
    // =========================================================

    QVariant machinePhase =
        selectQuery.value("machinePhase");

    QVariant signalThr =
        selectQuery.value("signalThr");

    QVariant ampThr =
        selectQuery.value("ampThr");

    QVariant ddPower =
        selectQuery.value("ddPower");

    QVariant ddFreq =
        selectQuery.value("ddFreq");

    QVariant digitalGain =
        selectQuery.value("digitalGain");

    QVariant analogGain =
        selectQuery.value("analogGain");

    qDebug()
        << "Applying active product parameters:"
        << "Group =" << groupNo
        << "SR =" << srNo
        << "machinePhase =" << machinePhase
        << "signalThr =" << signalThr
        << "ampThr =" << ampThr
        << "ddPower =" << ddPower
        << "ddFreq =" << ddFreq
        << "digitalGain =" << digitalGain
        << "analogGain =" << analogGain;

    // =========================================================
    // GET DATABASE CONNECTION
    // =========================================================

    QSqlDatabase db =
        QSqlDatabase::database();

    if (!db.isValid() || !db.isOpen())
    {
        qDebug()
        << "Database connection is invalid or closed.";

        return false;
    }

    // =========================================================
    // START TRANSACTION
    // =========================================================

    if (!db.transaction())
    {
        qDebug()
        << "Failed to start parameter transaction:"
        << db.lastError().text();

        return false;
    }

    // =========================================================
    // UPDATE MACHINE PARAMETERS
    // =========================================================

    QSqlQuery machineQuery(db);

    machineQuery.prepare(R"(
        UPDATE machineparameters
        SET
            machinePhase = ?,
            signalThr = ?,
            ampThr = ?,
            ddPower = ?,
            ddFreq = ?
        WHERE id = 1
    )");

    machineQuery.addBindValue(machinePhase);
    machineQuery.addBindValue(signalThr);
    machineQuery.addBindValue(ampThr);
    machineQuery.addBindValue(ddPower);
    machineQuery.addBindValue(ddFreq);

    if (!machineQuery.exec())
    {
        qDebug()
        << "Failed to update machineparameters:"
        << machineQuery.lastError().text();

        db.rollback();

        return false;
    }

    // =========================================================
    // UPDATE FILTER SETTINGS
    // =========================================================

    QSqlQuery filterQuery(db);

    filterQuery.prepare(R"(
        UPDATE filtersettings
        SET
            digitalGain = ?,
            analogGain = ?
        WHERE id = 1
    )");

    filterQuery.addBindValue(digitalGain);
    filterQuery.addBindValue(analogGain);

    if (!filterQuery.exec())
    {
        qDebug()
        << "Failed to update filtersettings:"
        << filterQuery.lastError().text();

        db.rollback();

        return false;
    }

    // =========================================================
    // COMMIT
    // =========================================================

    if (!db.commit())
    {
        qDebug()
        << "Failed to commit active product parameters:"
        << db.lastError().text();

        db.rollback();

        emit machineParametersChanged();

        return false;
    }

    qDebug()
        << "Active product parameters applied successfully.";

    emit machineParametersChanged();


    return true;
}
