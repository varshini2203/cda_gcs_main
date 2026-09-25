import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// LoginScreen
// -----------
// Chennai Drone Academy branded login screen — sky-blue hero pane on the
// left, white login card on the right.

Item {
    id: root

    signal accepted(string username)
    signal goToRegister()

    Rectangle {
        anchors.fill: parent
        color: "#FFFFFF"
    }

    focus: true

    Component.onCompleted: {
        errorLabel.text = ""
        userField.forceActiveFocus()
    }

    Connections {
        target: AuthManager
        onLoginSucceeded: {
            errorLabel.text = ""
            root.accepted(username)
        }
        onLoginFailed: {
            errorLabel.text = reason
        }
    }

    // Blocks every mouse / wheel / hover event from reaching anything behind this screen
    MouseArea {
        anchors.fill:       parent
        hoverEnabled:       true
        acceptedButtons:    Qt.AllButtons
        onWheel:            function(wheel) { wheel.accepted = true }
    }

    readonly property real _leftFraction: 0.56

    //=====================================================================
    // LEFT: Branding / hero pane (sky-blue gradient)
    //=====================================================================
    Item {
        id: leftPane
        anchors.left:   parent.left
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        width:          root.width * root._leftFraction

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: "#0EA5E9" }
                GradientStop { position: 0.5; color: "#38BDF8" }
                GradientStop { position: 1.0; color: "#7DD3FC" }
            }
        }

        // Soft cloud-like glow accents
        Rectangle {
            width: parent.width * 0.85
            height: width
            radius: width / 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -width * 0.8
            color: "#FFFFFF"
            opacity: 0.18
        }
        Rectangle {
            width: 220; height: 220; radius: 110
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -80
            anchors.topMargin: -60
            color: "#FFFFFF"
            opacity: 0.12
        }

        ColumnLayout {
            anchors.fill:     parent
            anchors.margins:  Math.max(28, leftPane.width * 0.06)
            spacing:          0

            // Brand row
            RowLayout {
                spacing: 12
                Layout.alignment: Qt.AlignLeft

                Rectangle {
                    width: 44; height: 44
                    radius: 22
                    color: "#FFFFFF"
                    opacity: 0.9

                    Label {
                        anchors.centerIn: parent
                        text: "\uD83D\uDE81"
                        font.pointSize: 18
                    }
                }

                ColumnLayout {
                    spacing: 0
                    RowLayout {
                        spacing: 6
                        Label { text: qsTr("Chennai"); color: "white";    font.pointSize: 15; font.bold: true }
                        Label { text: qsTr("Drone");   color: "white";    font.pointSize: 15; font.bold: true }
                        Label { text: qsTr("Academy"); color: "#0C2A43"; font.pointSize: 15; font.bold: true }
                    }
                    Label {
                        text: qsTr("LEARN  \u2022  FLY  \u2022  BUILD  \u2022  INNOVATE")
                        color: "#EAF6FF"
                        font.pointSize: 8
                        font.letterSpacing: 1
                    }
                }
            }

            Item { Layout.preferredHeight: leftPane.height * 0.14 }

            // Headline
            ColumnLayout {
                spacing: 8
                Layout.maximumWidth: leftPane.width * 0.85

                RowLayout {
                    spacing: 10
                    Label { text: qsTr("Welcome"); color: "white";    font.pointSize: 30; font.bold: true }
                    Label { text: qsTr("Back!");   color: "#0C2A43"; font.pointSize: 30; font.bold: true }
                }

                Label {
                    text: qsTr("Sign in to continue your drone journey with Chennai Drone Academy")
                    color: "#F0FAFF"
                    font.pointSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            Item { Layout.fillHeight: true }

            // Feature chips
            RowLayout {
                Layout.fillWidth:    true
                Layout.bottomMargin: Math.max(20, leftPane.height * 0.05)
                spacing: 18

                Repeater {
                    model: [
                        { icon: "\uD83D\uDEF8", label: qsTr("Drone\nTraining"),       bg: "#FFFFFF" },
                        { icon: "\uD83D\uDCCD", label: qsTr("Live\nTracking"),        bg: "#FFFFFF" },
                        { icon: "\u2699\uFE0F",  label: qsTr("Advanced\nTech"),        bg: "#FFFFFF" },
                        { icon: "\uD83C\uDF93", label: qsTr("Skill\nDevelopment"),    bg: "#FFFFFF" }
                    ]

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 44; height: 44
                            radius: 22
                            color: modelData.bg
                            opacity: 0.92

                            Label {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.pointSize: 15
                            }
                        }

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.label
                            color: "#FFFFFF"
                            font.pointSize: 8
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }

    //=====================================================================
    // RIGHT: Login card pane (white, sky-blue accents)
    //=====================================================================
    Item {
        id: rightPane
        anchors.left:   leftPane.right
        anchors.right:  parent.right
        anchors.top:    parent.top
        anchors.bottom: parent.bottom

        Rectangle {
            anchors.fill: parent
            color: "#F5FBFF"
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(340, rightPane.width * 0.8)
            radius: 20
            color: "white"
            border.color: "#CFEBFB"
            border.width: 1
            height: cardContent.implicitHeight + 44

            ColumnLayout {
                id: cardContent
                anchors.fill:    parent
                anchors.margins: 26
                spacing: 14

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 52; height: 52
                    radius: 26
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#0EA5E9" }
                        GradientStop { position: 1.0; color: "#38BDF8" }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "\uD83D\uDE81"
                        font.pointSize: 18
                    }
                }

                Label {
                    text: qsTr("Welcome Back")
                    color: "#0C2A43"
                    font.pointSize: 17
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: qsTr("Log in to your Chennai Drone Academy account")
                    color: "#5C7B92"
                    font.pointSize: 9
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                TextField {
                    id: userField
                    placeholderText: qsTr("Username")
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    color: "#0C2A43"
                    placeholderTextColor: "#8DA9BC"
                    leftPadding: 38
                    KeyNavigation.tab: passField
                    onAccepted: passField.forceActiveFocus()
                    onTextChanged: errorLabel.text = ""

                    background: Rectangle {
                        radius: 10
                        color: "#F0F8FD"
                        border.width: userField.activeFocus ? 2 : 1
                        border.color: userField.activeFocus ? "#0EA5E9" : "#D8ECF7"

                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uD83D\uDC64"
                            font.pointSize: 10
                            opacity: 0.75
                        }
                    }
                }

                TextField {
                    id: passField
                    placeholderText: qsTr("Password")
                    echoMode: TextInput.Password
                    Layout.fillWidth: true
                    color: "#0C2A43"
                    placeholderTextColor: "#8DA9BC"
                    leftPadding: 38
                    onAccepted: loginButton.clicked()
                    onTextChanged: errorLabel.text = ""

                    background: Rectangle {
                        radius: 10
                        color: "#F0F8FD"
                        border.width: passField.activeFocus ? 2 : 1
                        border.color: passField.activeFocus ? "#0EA5E9" : "#D8ECF7"

                        Label {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\uD83D\uDD12"
                            font.pointSize: 10
                            opacity: 0.75
                        }
                    }
                }

                Label {
                    id: errorLabel
                    color: "#E03B3B"
                    visible: text !== ""
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    font.pointSize: 9
                }

                Button {
                    id: loginButton
                    text: qsTr("Log In")
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    onClicked: AuthManager.login(userField.text, passField.text)

                    contentItem: RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignHCenter
                        Label { text: "\u2192"; color: "white"; font.bold: true; Layout.alignment: Qt.AlignVCenter }
                        Label { text: loginButton.text; color: "white"; font.bold: true; Layout.alignment: Qt.AlignVCenter }
                        Item { Layout.fillWidth: true }
                    }

                    background: Rectangle {
                        radius: 10
                        implicitHeight: 42
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: loginButton.pressed ? "#0284C7" : "#0EA5E9" }
                            GradientStop { position: 1.0; color: loginButton.pressed ? "#0EA5E9" : "#38BDF8" }
                        }
                    }
                }

                Button {
                    text: qsTr("Create an account")
                    flat: true
                    Layout.fillWidth: true
                    onClicked: {
                        errorLabel.text = ""
                        root.goToRegister()
                    }

                    contentItem: Label {
                        text: qsTr("Create an account")
                        color: "#0EA5E9"
                        horizontalAlignment: Text.AlignHCenter
                        font.pointSize: 9
                        font.bold: true
                    }

                    background: Item {}
                }
            }
        }
    }
}