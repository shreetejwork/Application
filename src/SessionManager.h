#ifndef SESSIONMANAGER_H
#define SESSIONMANAGER_H

#include <QObject>
#include <QTimer>

class DatabaseManager;

class SessionManager : public QObject
{
    Q_OBJECT

    // =========================================================
    // QML PROPERTIES
    // =========================================================
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn NOTIFY isLoggedInChanged)
    Q_PROPERTY(QString currentUsername READ currentUsername NOTIFY currentUsernameChanged)
    Q_PROPERTY(QString currentRole READ currentRole NOTIFY currentRoleChanged)
    Q_PROPERTY(int sessionTimeoutRemaining READ sessionTimeoutRemaining NOTIFY sessionTimeoutRemainingChanged)
    Q_PROPERTY(int sessionTimeoutTotal READ sessionTimeoutTotal WRITE setSessionTimeoutTotal NOTIFY sessionTimeoutTotalChanged)
    Q_PROPERTY(bool sessionActive READ isLoggedIn NOTIFY sessionActiveChanged)

public:
    explicit SessionManager(DatabaseManager *dbManager, QObject *parent = nullptr);
    ~SessionManager();

    // =========================================================
    // GETTERS
    // =========================================================
    bool isLoggedIn() const { return m_isLoggedIn; }
    QString currentUsername() const { return m_currentUsername; }
    QString currentRole() const { return m_currentRole; }
    int sessionTimeoutRemaining() const { return m_sessionTimeoutRemaining; }
    int sessionTimeoutTotal() const { return m_sessionTimeoutTotal; }

    // =========================================================
    // SETTERS
    // =========================================================
    void setSessionTimeoutTotal(int seconds) { m_sessionTimeoutTotal = seconds; }

    // =========================================================
    // INVOKABLE METHODS FOR QML
    // =========================================================
    Q_INVOKABLE bool login(const QString &username, const QString &password);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void resetSessionTimeout();
    Q_INVOKABLE bool isAdmin() const { return m_currentRole == "Admin"; }
    Q_INVOKABLE QString getSessionInfo() const;

signals:
    // =========================================================
    // SIGNALS FOR QML BINDING
    // =========================================================
    void isLoggedInChanged();
    void currentUsernameChanged();
    void currentRoleChanged();
    void sessionTimeoutRemainingChanged();
    void sessionTimeoutTotalChanged();
    void sessionActiveChanged();

    // =========================================================
    // SIGNALS FOR BUSINESS LOGIC
    // =========================================================
    void loginSuccessful(const QString &username, const QString &role);
    void loginFailed(const QString &error);
    void logoutRequested();
    void sessionExpired();
    void sessionTimeoutWarning(int secondsRemaining);

private slots:
    // =========================================================
    // INTERNAL SLOTS
    // =========================================================
    void updateSessionTimeout();

private:
    // =========================================================
    // MEMBER VARIABLES
    // =========================================================
    DatabaseManager *m_dbManager;

    bool m_isLoggedIn = false;
    QString m_currentUsername;
    QString m_currentRole;

    QTimer m_sessionTimer;
    int m_sessionTimeoutRemaining = 0;
    int m_sessionTimeoutTotal = 1800;  // 30 minutes default

    // =========================================================
    // INTERNAL METHODS
    // =========================================================
    void startSessionTimeout();
    void clearSession();
};

#endif // SESSIONMANAGER_H
