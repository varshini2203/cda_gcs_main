import QtQuick 2.11

// AuthBrandPanel
// --------------
// The left-hand branding pane used by Login/Register on wide windows:
// gradient background, logo + academy name top-left, drone
// illustration centered, tagline bottom-left.

Rectangle {
    id: root

    property string tagline: qsTr("Precision flight training,\nengineered for professionals.")

    gradient: Gradient {
        GradientStop { position: 0.0; color: AuthTheme.brightBlue }
        GradientStop { position: 1.0; color: AuthTheme.deepBlue }
    }

    Image {
        id:                 hero
        source:             "qrc:/qml/Auth/images/drone_illustration.svg"
        anchors.centerIn:   parent
        anchors.verticalCenterOffset: -10
        fillMode:           Image.PreserveAspectFit
        width:              Math.min(parent.width * 0.82, 420)
        sourceSize.width:   960
        opacity:            0.95
    }

    Row {
        anchors.top:        parent.top
        anchors.left:       parent.left
        anchors.margins:    32
        spacing:            12

        Image {
            source:             "qrc:/qml/Auth/images/logo_mark_white.svg"
            width:              40
            height:             40
            fillMode:           Image.PreserveAspectFit
            sourceSize.width:   80
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text:                    qsTr("Chennai Drone Academy")
            color:                   AuthTheme.white
            font.pixelSize:          19
            font.bold:               true
            anchors.verticalCenter:  parent.verticalCenter
        }
    }

    Text {
        anchors.bottom:     parent.bottom
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.margins:    32
        text:               root.tagline
        color:              AuthTheme.textOnBlueMuted
        font.pixelSize:     15
        lineHeight:         1.3
        wrapMode:           Text.WordWrap
    }
}
