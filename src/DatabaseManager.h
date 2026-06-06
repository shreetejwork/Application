#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QStringList>

class DatabaseManager : public QObject
{
    Q_OBJECT
public:
    explicit DatabaseManager(QObject *parent = nullptr);

    bool initialize();

    // Example functions
    bool insertUser(const QString &fpid,
                    const QString &id,
                    const QString &username,
                    const QString &password,
                    const QString &role);
    bool deleteUser(const QString &username);


    Q_INVOKABLE QStringList getUsersByRole(const QString &role);

    void printAllUsers();

private:
    void createTables();
};

#endif // DATABASEMANAGER_H
