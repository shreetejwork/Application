#include "SessionManager.h"
#include "DatabaseManager.h"
#include <QDebug>

SessionManager::SessionManager(DatabaseManager *dbManager, QObject *parent)
    : QObject(parent), m_dbManager(dbManager)
{
    // =========================================================
    // SETUP SESSION TIMEOUT TIMER
    // =========================================================
    connect(&m_sessionTimer, &QTimer::timeout, this, &SessionManager::updateSessionTimeout);

    // Initialize session timeout
    m_sessionTimeoutRemaining = m_sessionTimeoutTotal;

    qDebug() << "SessionManager initialized with timeout:" << m_sessionTimeoutTotal << "seconds";
}

SessionManager::~SessionManager()
{
    if (m_sessionTimer.isActive()) {
        m_sessionTimer.stop();
    }
}

// =========================================================
// LOGIN
// =========================================================

bool SessionManager::login(const QString &username, const QString &password)
{
    if (!m_dbManager) {
        qWarning() << "Database manager not available";
        emit loginFailed("Database error");
        return false;
    }

    // Validate credentials against database
    QString role;
    if (!m_dbManager->validateLogin(username, password, role)) {
        qWarning() << "Login failed for user:" << username;
        emit loginFailed("Invalid username or password");
        return false;
    }

    // =========================================================
    // LOGIN SUCCESSFUL
    // =========================================================
    m_isLoggedIn = true;
    m_currentUsername = username;
    m_currentRole = role;

    // Start session timeout
    startSessionTimeout();

    qDebug() << "Login successful:" << username << "Role:" << role;

    emit isLoggedInChanged();
    emit currentUsernameChanged();
    emit currentRoleChanged();
    emit loginSuccessful(username, role);
    emit sessionActiveChanged();

    return true;
}

// =========================================================
// LOGOUT
// =========================================================

void SessionManager::logout()
{
    if (!m_isLoggedIn) {
        return;
    }

    qDebug() << "Logout requested by user:" << m_currentUsername;

    clearSession();

    emit isLoggedInChanged();
    emit currentUsernameChanged();
    emit currentRoleChanged();
    emit logoutRequested();
    emit sessionActiveChanged();
}

// =========================================================
// SESSION TIMEOUT MANAGEMENT
// =========================================================

void SessionManager::startSessionTimeout()
{
    // Reset timeout counter
    m_sessionTimeoutRemaining = m_sessionTimeoutTotal;

    // Start timer (update every second)
    m_sessionTimer.start(1000);

    emit sessionTimeoutRemainingChanged();

    qDebug() << "Session timeout started for:" << m_currentUsername;
}

void SessionManager::resetSessionTimeout()
{
    if (m_isLoggedIn) {
        m_sessionTimeoutRemaining = m_sessionTimeoutTotal;
        m_sessionTimer.start(1000);

        emit sessionTimeoutRemainingChanged();

        qDebug() << "Session timeout reset for:" << m_currentUsername;
    }
}

void SessionManager::updateSessionTimeout()
{
    if (!m_isLoggedIn) {
        m_sessionTimer.stop();
        return;
    }

    m_sessionTimeoutRemaining--;

    emit sessionTimeoutRemainingChanged();

    // =========================================================
    // TIMEOUT WARNING (2 MINUTES REMAINING)
    // =========================================================
    if (m_sessionTimeoutRemaining == 120) {
        emit sessionTimeoutWarning(120);
        qDebug() << "Session timeout warning: 2 minutes remaining";
    }

    // =========================================================
    // SESSION EXPIRED
    // =========================================================
    if (m_sessionTimeoutRemaining <= 0) {
        m_sessionTimer.stop();

        qWarning() << "Session expired for user:" << m_currentUsername;

        clearSession();

        emit isLoggedInChanged();
        emit currentUsernameChanged();
        emit currentRoleChanged();
        emit sessionExpired();
        emit sessionActiveChanged();
    }
}

void SessionManager::clearSession()
{
    m_sessionTimer.stop();

    m_isLoggedIn = false;
    m_currentUsername = "";
    m_currentRole = "";
    m_sessionTimeoutRemaining = m_sessionTimeoutTotal;
}

// =========================================================
// DEBUG
// =========================================================

QString SessionManager::getSessionInfo() const
{
    if (!m_isLoggedIn) {
        return "Not logged in";
    }

    return QString("User: %1 | Role: %2 | Timeout: %3s")
        .arg(m_currentUsername, m_currentRole, QString::number(m_sessionTimeoutRemaining));
}
