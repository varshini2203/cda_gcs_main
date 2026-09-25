import QtQuick 2.11
import QtQuick.Controls 2.4

// AuthTextField
// -------------
// Rounded, blue-on-white text field with a label above it. Exposes
// `text` for two-way binding and `echoMode` for password fields.

Column {
    id: root

    property alias label:          labelText.text
    property alias text:           input.text
    property alias placeholderText: input.placeholderText
    property alias echoMode:       input.echoMode
    property bool  error:          false

    signal accepted()

    spacing:            6
    width:               parent ? parent.width : implicitWidth

    Text {
        id:             labelText
        color:          AuthTheme.textDark
        font.pixelSize: 13
        font.bold:      true
    }

    Rectangle {
        id:             fieldBg
        width:          parent.width
        height:         46
        radius:         AuthTheme.fieldRadius
        color:          AuthTheme.white
        border.width:   root.error ? 2 : 1.5
        border.color:   root.error ? AuthTheme.errorRed
                                    : (input.activeFocus ? AuthTheme.fieldBorderFocused : AuthTheme.fieldBorder)

        Behavior on border.color { ColorAnimation { duration: 120 } }

        TextField {
            id:                 input
            anchors.fill:       parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            verticalAlignment:  TextInput.AlignVCenter
            background:         null
            color:              AuthTheme.textDark
            placeholderTextColor: AuthTheme.textMuted
            font.pixelSize:     15
            selectByMouse:      true
            onAccepted:         root.accepted()
        }
    }
}