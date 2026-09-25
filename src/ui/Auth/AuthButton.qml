import QtQuick 2.11
import QtQuick.Controls 2.4

// AuthButton
// ----------
// Blue-gradient, white-text button used across the Auth screens.
// Set `flat: true` for a secondary/outline style on a white card.

Item {
    id: root

    property string text:      ""
    property bool   flat:      false
    property bool   enabled:   true
    signal clicked()

    implicitHeight: 48
    implicitWidth:  160

    Rectangle {
        id:             bg
        anchors.fill:   parent
        radius:         AuthTheme.buttonRadius
        border.width:   root.flat ? 1.5 : 0
        border.color:   AuthTheme.brightBlue
        color:          root.flat ? "transparent" : (mouseArea.pressed ? AuthTheme.deepBlue : AuthTheme.brightBlue)
        opacity:        root.enabled ? 1.0 : 0.5

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Text {
        anchors.centerIn:  parent
        text:               root.text
        font.pixelSize:     16
        font.bold:          true
        color:              root.flat ? AuthTheme.brightBlue : AuthTheme.white
    }

    MouseArea {
        id:             mouseArea
        anchors.fill:   parent
        enabled:        root.enabled
        cursorShape:    Qt.PointingHandCursor
        onClicked:      root.clicked()
    }
}
