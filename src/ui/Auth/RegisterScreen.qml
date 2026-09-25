import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// RegisterScreen
// --------------
// Chennai Drone Academy branded register screen — sky-blue hero pane on
// the left, white sign-up card on the right.

Item {
    id: root

    signal accepted(string username)
    signal goToLogin()

    Rectangle {
        anchors.fill: parent
        color: "#FFFFFF"
    }

    focus: true

    Component.onCompleted: {
        errorLabel.text = ""
        successLabel.visible = false
        userField.forceActiveFocus()
    }

    Connections {
        target: AuthManager
        onRegisterSucceeded: {
            errorLabel.text = ""
            successLabel.visible = true
            backTimer.start()
        }
        onRegisterFailed: {
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

            ColumnLayout {
                spacing: 8
                Layout.maximumWidth: leftPane.width * 0.85

                RowLayout {
                    spacing: 10
                    Label { text: qsTr("Your Journey to"); color: "white";    font.pointSize: 24; font.bold: true }
                }
                RowLayout {
                    spacing: 10
                    Label { text: qsTr("Skies Begins"); color: "#0C2A43"; font.pointSize: 24; font.bold: true }
                    Label { text: qsTr("Here");         color: "white";    font.pointSize: 24; font.bold: true }
                }

                Label {
                    text: qsTr("Join Chennai Drone Academy and gain hands-on skills in drone technology, aerial mapping, robotics and more")
                    color: "#F0FAFF"
                    font.pointSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth:    true
                Layout.bottomMargin: Math.max(20, leftPane.height * 0.05)
                spacing: 18

                Repeater {
                    model: [
                        { icon: "\uD83D\uDEF8", label: qsTr("Drone\nTraining"), bg: "#FFFFFF" },
                        { icon: "\u2699\uFE0F",  label: qsTr("Advanced\nTech"),  bg: "#FFFFFF" },
                        { icon: "\uD83D\uDCC8", label: qsTr("Career\nGrowth"),  bg: "#FFFFFF" }
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
    // RIGHT: Register card pane (white, sky-blue accents)
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
                spacing: 12

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
                    text: qsTr("Create Account")
                    color: "#0C2A43"
                    font.pointSize: 17
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                TextField {
                    id: userField
                    placeholderText: qsTr("Username")
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    color: "#0C2A43"
                    placeholderTextColor: "#8DA9BC"
                    leftPadding: 38
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
                    onAccepted: confirmField.forceActiveFocus()
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

                TextField {
                    id: confirmField
                    placeholderText: qsTr("Confirm password")
                    echoMode: TextInput.Password
                    Layout.fillWidth: true
                    color: "#0C2A43"
                    placeholderTextColor: "#8DA9BC"
                    leftPadding: 38
                    onAccepted: registerButton.clicked()
                    onTextChanged: errorLabel.text = ""

                    background: Rectangle {
                        radius: 10
                        color: "#F0F8FD"
                        border.width: confirmField.activeFocus ? 2 : 1
                        border.color: confirmField.activeFocus ? "#0EA5E9" : "#D8ECF7"

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

                Label {
                    id: successLabel
                    text: qsTr("Account created. Please log in.")
                    color: "#1DAA6C"
                    visible: false
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    font.pointSize: 9
                    font.bold: true
                }

                Button {
                    id: registerButton
                    text: qsTr("Register")
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    onClicked: AuthManager.registerUser(userField.text, passField.text, confirmField.text)

                    contentItem: RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignHCenter
                        Label { text: "\u2192"; color: "white"; font.bold: true; Layout.alignment: Qt.AlignVCenter }
                        Label { text: registerButton.text; color: "white"; font.bold: true; Layout.alignment: Qt.AlignVCenter }
                        Item { Layout.fillWidth: true }
                    }

                    background: Rectangle {
                        radius: 10
                        implicitHeight: 42
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: registerButton.pressed ? "#0284C7" : "#0EA5E9" }
                            GradientStop { position: 1.0; color: registerButton.pressed ? "#0EA5E9" : "#38BDF8" }
                        }
                    }
                }

                Button {
                    text: qsTr("Back to login")
                    flat: true
                    Layout.fillWidth: true
                    onClicked: {
                        errorLabel.text = ""
                        root.goToLogin()
                    }

                    contentItem: Label {
                        text: qsTr("Back to login")
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

    Timer {
        id: backTimer
        interval: 800
        repeat: false
        onTriggered: {
            errorLabel.text = ""
            root.goToLogin()
        }
    }
}