#include "DatabaseManager.h"

#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QFile>
#include <QDebug>
#include <QDate>
#include <QDir>


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
        createTables();
    } else {
        qDebug() << "DB already exists, opening...";
    }

    QSqlQuery query;

    query.exec(
        "ALTER TABLE usertable "
        "ADD COLUMN password_expiry_date TEXT");

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

    // SYSTEM SETTINGS
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS systemsettings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT
        );
    )");

    // FILTER SETTINGS
    query.exec(R"(
        CREATE TABLE IF NOT EXISTS filtersettings (
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
        "WHERE username = ?");

    checkQuery.addBindValue(username);

    if (checkQuery.exec() && checkQuery.next())
    {
        if (checkQuery.value(0).toInt() > 0)
        {
            qDebug() << "Username already exists";
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
