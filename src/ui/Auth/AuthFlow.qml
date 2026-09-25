import QtQuick 2.11
import QtQuick.Controls 2.4
import Auth 1.0

// AuthFlow
// --------
// Drop this in place of (or on top of, see integration notes below)
// the existing QGC root content. It shows Splash, then Register or
// Login, then Home. Tapping Start (or Home/Plan/Analyze/Settings on
// the nav bar) tells the host (MainRootWindow) which QGC view to
// switch into.

Item {
    id: root

    signal enterApp()
    signal enterPlanView()
    signal enterAnalyzeTool()
    signal enterSettingsTool()

    StackView {
        id:             stack
        anchors.fill:   parent

        initialItem: splashComponent

        Component {
            id: splashComponent
            SplashScreen {
                onFinished: (alreadyLoggedIn) => {
                    stack.replace(alreadyLoggedIn ? homeComponent : loginComponent)
                }
            }
        }

        Component {
            id: loginComponent
            LoginScreen {
                onAccepted:     (username) => stack.replace(homeComponent)
                onGoToRegister: stack.replace(registerComponent)
            }
        }

        Component {
            id: registerComponent
            RegisterScreen {
                onAccepted:  (username) => stack.replace(homeComponent)
                onGoToLogin: stack.replace(loginComponent)
            }
        }

        Component {
            id: homeComponent
            HomeScreen {
                onEnterApp:        root.enterApp()
                onHomeClicked:     root.enterApp()
                onPlanClicked:     root.enterPlanView()
                onAnalyzeClicked:  root.enterAnalyzeTool()
                onSettingsClicked: root.enterSettingsTool()
            }
        }

        // If the user logs out from HomeScreen while it's on top of the
        // stack, drop them back to Login.
        Connections {
            target: AuthManager
            onLoggedOut: {
                if (stack.currentItem && stack.currentItem.objectName !== "loginScreen") {
                    stack.replace(loginComponent)
                }
            }
        }
    }
}