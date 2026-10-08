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
    // Finger-friendly minimum height (about 10mm) so buttons are easy to hit on a phone
    readonly property real  _minTouchHeight: Math.max(ScreenTools.minTouchPixels, Math.round(ScreenTools.defaultFontPixelHeight * 2.4))

    heightFactor:   0.6
    showBorder:     false
    backRadius:     _radius
    hoverEnabled:   true

    background: Rectangle {
        implicitWidth:  ScreenTools.implicitButtonWidth
        implicitHeight: Math.max(ScreenTools.implicitButtonHeight, cdaBtn._minTouchHeight)
        radius:         cdaBtn._radius
        border.width:   cdaBtn._filled ? 0 : 2
        border.color:   !cdaBtn.enabled ? "#c3d0e2" : ((cdaBtn.hovered || cdaBtn.pressed) ? cdaBtn._accent : "#7fa6d8")
        color:          !cdaBtn.enabled ?
                            (cdaBtn._filled ? "#b9c8dd" : "#e6edf6") :
                            (cdaBtn._filled ?
                                (cdaBtn.danger ? cdaBtn._dangerColor : cdaBtn._accent) :
                                (cdaBtn.pressed ? "#cfe0f8" : (cdaBtn.hovered ? "#e3eefc" : "white")))

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
        id:             cdaContent
        // Based on the raw text width (not the clipped width) so there is no binding loop
        implicitWidth:  label.implicitWidth + (cdaBtn.iconSource !== "" ? label.implicitHeight + row.spacing : 0)
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
                font.bold:      true
                elide:          Text.ElideRight
                // Never let the label grow past the button (phone screens are narrow)
                width:          Math.min(implicitWidth, Math.max(0, cdaContent.width - (cdaBtn.iconSource !== "" ? implicitHeight + row.spacing : 0)))
                horizontalAlignment: Text.AlignHCenter
                color:          !cdaBtn.enabled ? "#7d8ea6" : (cdaBtn._filled ? "white" : cdaBtn._navy)
            }
        }
    }
}
