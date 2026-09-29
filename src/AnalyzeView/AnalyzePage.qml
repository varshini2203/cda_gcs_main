/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.12
import QtQuick.Controls 1.2

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

/// Base view control for all Analyze pages
/// Chennai Drone Academy themed: header banner + white content card
Item {
    id:                         _page
    anchors.fill:               parent
    anchors.margins:            ScreenTools.defaultFontPixelWidth

    property alias  pageComponent:      pageLoader.sourceComponent
    property string pageName:           ""
    property string pageDescription:    ""
    property alias  headerComponent:    headerLoader.sourceComponent
    property real   availableWidth:     mainContent.width  - (_contentPad * 2)
    property real   availableHeight:    mainContent.height - (_contentPad * 2)
    property bool   popped:             false
    property real   _margins:           ScreenTools.defaultFontPixelHeight * 0.5

    readonly property real  _contentPad:    ScreenTools.defaultFontPixelWidth * 1.5
    readonly property bool  _showBanner:    !popped && !ScreenTools.isShortScreen
    readonly property string _iconBase:     "qrc:/qml/SettingsIcons/"

    signal popout()

    function _iconFor(title) {
        var t = String(title).toLowerCase()
        if (t.indexOf("log")        >= 0) return "file"
        if (t.indexOf("geotag")     >= 0) return "pin"
        if (t.indexOf("console")    >= 0) return "terminal"
        if (t.indexOf("inspector")  >= 0) return "eye"
        if (t.indexOf("vibration")  >= 0) return "gauge"
        return "sliders"
    }

    //-- Page header banner
    Rectangle {
        id:                     banner
        visible:                _showBanner
        anchors.top:            parent.top
        anchors.left:           parent.left
        anchors.right:          parent.right
        height:                 visible ? ScreenTools.defaultFontPixelHeight * 4.6 : 0
        radius:                 ScreenTools.defaultFontPixelWidth * 1.4
        clip:                   true
        border.width:           1
        border.color:           "#d3e1f2"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0;  color: "#ffffff" }
            GradientStop { position: 0.55; color: "#eaf3ff" }
            GradientStop { position: 1.0;  color: "#cfe3fb" }
        }

        //-- Mountains + drone illustration
        Canvas {
            id:                 heroCanvas
            anchors.right:      parent.right
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            width:              Math.min(parent.width * 0.5, ScreenTools.defaultFontPixelWidth * 60)
            onWidthChanged:     requestPaint()
            onHeightChanged:    requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                // mountains
                ctx.fillStyle = "rgba(120,170,235,0.35)"
                ctx.beginPath()
                ctx.moveTo(width * 0.15, height)
                ctx.lineTo(width * 0.45, height * 0.35)
                ctx.lineTo(width * 0.62, height * 0.65)
                ctx.lineTo(width * 0.78, height * 0.3)
                ctx.lineTo(width, height * 0.7)
                ctx.lineTo(width, height)
                ctx.closePath()
                ctx.fill()
                ctx.fillStyle = "rgba(79,150,230,0.45)"
                ctx.beginPath()
                ctx.moveTo(width * 0.5, height)
                ctx.lineTo(width * 0.72, height * 0.5)
                ctx.lineTo(width * 0.86, height * 0.75)
                ctx.lineTo(width * 0.95, height * 0.55)
                ctx.lineTo(width, height * 0.7)
                ctx.lineTo(width, height)
                ctx.closePath()
                ctx.fill()

                // drone
                var cx = width * 0.66, cy = height * 0.34
                var arm = height * 0.34
                ctx.strokeStyle = "#0b2f66"
                ctx.lineWidth = 3
                ctx.lineCap = "round"
                var dirs = [[-1,-0.35],[1,-0.35],[-1,0.35],[1,0.35]]
                for (var i = 0; i < 4; i++) {
                    var ex = cx + dirs[i][0] * arm * 1.5
                    var ey = cy + dirs[i][1] * arm
                    ctx.beginPath()
                    ctx.moveTo(cx, cy)
                    ctx.lineTo(ex, ey)
                    ctx.stroke()
                    ctx.fillStyle = "rgba(30,111,208,0.35)"
                    ctx.beginPath()
                    ctx.ellipse(ex - arm * 0.55, ey - arm * 0.09 - 2, arm * 1.1, arm * 0.18)
                    ctx.fill()
                    ctx.fillStyle = "#0b2f66"
                    ctx.beginPath()
                    ctx.arc(ex, ey, 3, 0, Math.PI * 2)
                    ctx.fill()
                }
                ctx.fillStyle = "#1e6fd0"
                ctx.beginPath()
                ctx.ellipse(cx - arm * 0.45, cy - arm * 0.22, arm * 0.9, arm * 0.44)
                ctx.fill()
                ctx.fillStyle = "#0b2f66"
                ctx.beginPath()
                ctx.arc(cx, cy + arm * 0.2, arm * 0.13, 0, Math.PI * 2)
                ctx.fill()
            }
        }

        Rectangle {
            id:                     headerCircle
            anchors.left:           parent.left
            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * 2
            anchors.verticalCenter: parent.verticalCenter
            width:                  ScreenTools.defaultFontPixelHeight * 3.2
            height:                 width
            radius:                 width / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#3a8af0" }
                GradientStop { position: 1.0; color: "#1e6fd0" }
            }

            QGCColoredImage {
                anchors.centerIn:   parent
                width:              parent.width * 0.5
                height:             width
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                color:              "white"
                source:             _iconBase + _iconFor(pageName) + ".svg"
            }
        }

        Column {
            anchors.left:           headerCircle.right
            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * 1.5
            anchors.verticalCenter: parent.verticalCenter
            width:                  Math.max(0, banner.width * 0.55 - headerCircle.width - ScreenTools.defaultFontPixelWidth * 3.5)
            spacing:                2

            QGCLabel {
                width:              parent.width
                text:               pageName
                color:              "#0b2f66"
                font.bold:          true
                font.pointSize:     ScreenTools.largeFontPointSize * 1.2
                elide:              Text.ElideRight
            }
            QGCLabel {
                width:              parent.width
                text:               pageDescription
                color:              "#5a6f8f"
                font.pointSize:     ScreenTools.smallFontPointSize
                wrapMode:           Text.WordWrap
                maximumLineCount:   2
                elide:              Text.ElideRight
            }
        }

        //-- Pop out into its own window
        Rectangle {
            id:                     floatIcon
            visible:                !popped && !ScreenTools.isMobile
            anchors.right:          parent.right
            anchors.rightMargin:    ScreenTools.defaultFontPixelWidth * 1.5
            anchors.verticalCenter: parent.verticalCenter
            width:                  ScreenTools.defaultFontPixelHeight * 2.4
            height:                 width
            radius:                 width / 2
            color:                  floatMouse.containsMouse ? "#e3eefc" : "#f2f7fe"
            border.width:           1
            border.color:           "#b7cbe6"

            QGCColoredImage {
                anchors.centerIn:   parent
                width:              parent.width * 0.55
                height:             width
                sourceSize.width:   width
                source:             "/qmlimages/FloatingWindow.svg"
                fillMode:           Image.PreserveAspectFit
                color:              "#0b2f66"
            }
            MouseArea {
                id:                 floatMouse
                anchors.fill:       parent
                hoverEnabled:       true
                cursorShape:        Qt.PointingHandCursor
                onClicked:          popout()
            }
        }
    }

    Loader {
        id:                     headerLoader
        anchors.topMargin:      _margins
        anchors.top:            banner.bottom
        anchors.left:           parent.left
        anchors.right:          parent.right
        visible:                !ScreenTools.isShortScreen && headerLoader.sourceComponent !== null
    }

    //-- Content card
    Rectangle {
        id:                     mainContent
        anchors.topMargin:      ScreenTools.defaultFontPixelHeight * 0.8
        anchors.top:            headerLoader.visible ? headerLoader.bottom : banner.bottom
        anchors.bottom:         parent.bottom
        anchors.left:           parent.left
        anchors.right:          parent.right
        radius:                 ScreenTools.defaultFontPixelWidth
        color:                  "white"
        border.width:           1
        border.color:           "#d3e1f2"
        clip:                   true

        Loader {
            id:                 pageLoader
            x:                  _contentPad
            y:                  _contentPad
        }
    }
}
