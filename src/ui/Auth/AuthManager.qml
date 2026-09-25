pragma Singleton
import QtQuick 2.11
import Qt.labs.settings 1.0

// AuthManager
// -----------
// Local-only auth store for the Chennai Drone Academy GCS.
// No backend yet - usernames/passwords are kept in QSettings as a JSON
// blob under the app's org/app name. Passwords are base64-encoded, NOT
// hashed securely - this is a scaffold. Before shipping, swap
// _encode()/_checkPassword() for a real hash (e.g. call into C++ with
// QCryptographicHash) or point registerUser()/login() at a real API.

QtObject {
    id: authManager

    // Emitted when login/register succeeds or fails, so screens can react.
    signal loginSucceeded(string username)
    signal loginFailed(string reason)
    signal registerSucceeded(string username)
    signal registerFailed(string reason)
    signal loggedOut()

    readonly property bool isLoggedIn: settings.loggedInUser !== ""
    readonly property string currentUser: settings.loggedInUser

    property Settings settings: Settings {
        id: settings
        category: "Auth"
        property string usersJson: "{}"     // { "username": "base64pass" }
        property string loggedInUser: ""    // "" when no session
    }

    function _users() {
        try {
            return JSON.parse(settings.usersJson)
        } catch (e) {
            return {}
        }
    }

    function _saveUsers(users) {
        settings.usersJson = JSON.stringify(users)
    }

    function _encode(password) {
        return Qt.btoa(password)
    }

    function registerUser(username, password, confirmPassword) {
        username = (username || "").trim()

        if (username.length === 0 || password.length === 0) {
            registerFailed(qsTr("Username and password are required"))
            return
        }
        if (password !== confirmPassword) {
            registerFailed(qsTr("Passwords do not match"))
            return
        }
        if (password.length < 4) {
            registerFailed(qsTr("Password must be at least 4 characters"))
            return
        }

        var users = _users()
        if (users.hasOwnProperty(username)) {
            registerFailed(qsTr("That username is already taken"))
            return
        }

        users[username] = _encode(password)
        _saveUsers(users)
        settings.loggedInUser = username

        registerSucceeded(username)
    }

    function login(username, password) {
        username = (username || "").trim()

        var users = _users()
        if (!users.hasOwnProperty(username)) {
            loginFailed(qsTr("No account found for that username"))
            return
        }
        if (users[username] !== _encode(password)) {
            loginFailed(qsTr("Incorrect password"))
            return
        }

        settings.loggedInUser = username
        loginSucceeded(username)
    }

    function logout() {
        settings.loggedInUser = ""
        loggedOut()
    }
}
