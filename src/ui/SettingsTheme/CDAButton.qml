import QtQuick                  2.3
import QtQuick.Controls         2.12

import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

// Chennai Drone Academy styled button (drop-in replacement for QGCButton)
QGCButton {
    id: cdaBtn

    property bool   danger:         false

    readonly property color _navy:          "#0d2a52"
    readonly property color _accent:        "#1e6fd0"
    readonly property color _dangerColor:   "#cc0808"
    readonly property bool  _filled:        primary || danger || checked
    readonly property real  _radius:        Math.round(ScreenTools.defaultFontPixelHeight * 0.55)

    heightFactor:   0.6
    showBorder:     false
    backRadius:     _radius
    hoverEnabled:   true

    background: Rectangle {
        implicitWidth:  ScreenTools.implicitButtonWidth
        implicitHeight: ScreenTools.implicitButtonHeight
        radius:         cdaBtn._radius
        border.width:   cdaBtn._filled ? 0 : 1
        border.color:   !cdaBtn.enabled ? "#d3e1f2" : (cdaBtn.hovered ? cdaBtn._accent : "#b7cbe6")
        color:          !cdaBtn.enabled ?
                            (cdaBtn._filled ? "#c9d6e8" : "#f3f7fc") :
                            (cdaBtn._filled ?
                                (cdaBtn.danger ? cdaBtn._dangerColor : cdaBtn._accent) :
                                (cdaBtn.hovered ? "#e3eefc" : "white"))

        Rectangle {
            anchors.fill:   parent
            radius:         parent.radius
            visible:        cdaBtn._filled && cdaBtn.enabled
            gradient: Gradient {
                GradientStop { position: 0.0; color: cdaBtn.danger ? "#e23a3a" : (cdaBtn.hovered || cdaBtn.pressed ? "#4a94f5" : "#3a8af0") }
                GradientStop { position: 1.0; color: cdaBtn.danger ? "#a80606" : (cdaBtn.hovered || cdaBtn.pressed ? "#1a5fb8" : "#1e6fd0") }
            }
        }
    }

    contentItem: Item {
        implicitWidth:  row.implicitWidth
        implicitHeight: row.implicitHeight
        baselineOffset: label.y + label.baselineOffset

        Row {
            id:                 row
            anchors.centerIn:   parent
            spacing:            ScreenTools.defaultFontPixelWidth * 0.6
            layoutDirection:    cdaBtn.iconLeft ? Qt.LeftToRight : Qt.RightToLeft

            QGCColoredImage {
                visible:                cdaBtn.iconSource !== ""
                source:                 cdaBtn.iconSource
                height:                 visible ? label.implicitHeight : 0
                width:                  height
                color:                  label.color
                fillMode:               Image.PreserveAspectFit
                sourceSize.height:      height
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id:             label
                text:           cdaBtn.text
                antialiasing:   true
                font.pointSize: cdaBtn.pointSize
                font.family:    ScreenTools.normalFontFamily
                font.bold:      cdaBtn._filled
                color:          !cdaBtn.enabled ? "#9aa8bb" : (cdaBtn._filled ? "white" : cdaBtn._navy)
            }
        }
    }
}
