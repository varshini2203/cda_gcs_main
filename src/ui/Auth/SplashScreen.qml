import QtQuick 2.15
import QtQuick.Controls 2.15

// SplashScreen
// ------------
// Branded first screen: shows the Chennai Drone Academy banner image
// full-size, then routes to Home (if a session exists) or Login.

Item {
    id: root

    signal finished(bool alreadyLoggedIn)

    Rectangle {
        anchors.fill:   parent
        color:          "#FFFFFF"
    }

    Image {
        id:                 banner
        source:             "qrc:/qml/Auth/images/SplashScreen.png"
        anchors.centerIn:   parent
        fillMode:           Image.PreserveAspectFit
        width:              Math.min(parent.width * 0.82, 900)
        sourceSize.width:   1600
        opacity:            0
        scale:              0.94

        ParallelAnimation {
            running: true
            NumberAnimation { target: banner; property: "opacity"; to: 1.0; duration: 550; easing.type: Easing.OutCubic }
            NumberAnimation { target: banner; property: "scale";   to: 1.0; duration: 550; easing.type: Easing.OutCubic }
        }
    }

    BusyIndicator {
        anchors.horizontalCenter:  parent.horizontalCenter
        anchors.bottom:            parent.bottom
        anchors.bottomMargin:      parent.height * 0.10
        running:                   true
    }

    Timer {
        interval:   1400
        running:    true
        repeat:     false
        onTriggered: root.finished(AuthManager.isLoggedIn)
    }
}