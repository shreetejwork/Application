import QtQuick
import AppState 1.0

Item {
    id: sessionBridge

    // =========================================================
    // PURPOSE
    // =========================================================
    // This component bridges C++ SessionManager signals with
    // QML GlobalState property updates
    // Place this in Main.qml to activate session management

    Component.onCompleted: {
        console.log("SessionBridge: Initializing session management bridge")

        // Connect SessionManager signals to GlobalState updates
        if (SessionManager) {
            console.log("SessionManager is available")

            SessionManager.isLoggedInChanged.connect(updateLoginState)
            SessionManager.currentUsernameChanged.connect(updateLoginState)
            SessionManager.currentRoleChanged.connect(updateLoginState)
            SessionManager.sessionTimeoutRemainingChanged.connect(updateLoginState)
            SessionManager.loginSuccessful.connect(onLoginSuccessful)
            SessionManager.logoutRequested.connect(onLogoutRequested)
            SessionManager.sessionExpired.connect(onSessionExpired)
        } else {
            console.warn("SessionManager NOT available - session management disabled")
        }
    }

    function updateLoginState() {
        if (SessionManager) {
            GlobalState.updateSessionState(
                SessionManager.isLoggedIn,
                SessionManager.currentUsername,
                SessionManager.currentRole,
                SessionManager.sessionTimeoutRemaining
            )

            console.log("SessionBridge: Session state updated",
                        "LoggedIn:", SessionManager.isLoggedIn,
                        "User:", SessionManager.currentUsername,
                        "Role:", SessionManager.currentRole,
                        "Timeout:", SessionManager.sessionTimeoutRemaining)
        }
    }

    function onLoginSuccessful(username, role) {
        console.log("SessionBridge: Login successful for", username, "as", role)
        // UI is already updated via property bindings
    }

    function onLogoutRequested() {
        console.log("SessionBridge: Logout executed")
        // UI is already updated via property bindings
    }

    function onSessionExpired() {
        console.log("SessionBridge: Session expired - automatic logout")
        // Show notification
        var topBar = findTopBar()
        if (topBar) {
            topBar.showNotification("Session expired - please login again")
        }
    }

    // =========================================================
    // HELPER FUNCTIONS
    // =========================================================

    function findTopBar() {
        // This is a helper to find TopBar instance if needed
        // In practice, you can pass TopBar reference directly
        return null
    }

    Component.onDestruction: {
        console.log("SessionBridge: Cleaning up session management bridge")

        if (SessionManager) {
            try {
                SessionManager.isLoggedInChanged.disconnect(updateLoginState)
                SessionManager.currentUsernameChanged.disconnect(updateLoginState)
                SessionManager.currentRoleChanged.disconnect(updateLoginState)
                SessionManager.sessionTimeoutRemainingChanged.disconnect(updateLoginState)
                SessionManager.loginSuccessful.disconnect(onLoginSuccessful)
                SessionManager.logoutRequested.disconnect(onLogoutRequested)
                SessionManager.sessionExpired.disconnect(onSessionExpired)
            } catch (e) {
                console.warn("Error disconnecting signals:", e)
            }
        }
    }
}
