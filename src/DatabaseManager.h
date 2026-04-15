#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>

class DatabaseManager : public QObject
{
    Q_OBJECT
public:
    explicit DatabaseManager(QObject *parent = nullptr);

    bool initialize();

    // Example functions
    bool insertUser(const QString &fpid, const QString &id,
                    const QString &username, const QString &password);

    void printAllUsers();

private:
    void createTables();
};

#endif // DATABASEMANAGER_H
