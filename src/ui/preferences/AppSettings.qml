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
import QtQuick.Layouts  1.2

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

// Chennai Drone Academy themed Application Settings
Rectangle {
    id:     settingsView
    color:  _pageBg
    z:      QGroundControl.zOrderTopMost

    readonly property real _defaultTextHeight:  ScreenTools.defaultFontPixelHeight
    readonly property real _defaultTextWidth:   ScreenTools.defaultFontPixelWidth
    readonly property real _horizontalMargin:   _defaultTextWidth / 2
    readonly property real _verticalMargin:     _defaultTextHeight / 2
    readonly property real _buttonHeight:       ScreenTools.isTinyScreen ? ScreenTools.defaultFontPixelHeight * 3 : ScreenTools.defaultFontPixelHeight * 2.6
    readonly property real _sidebarWidth:       _defaultTextWidth * 24
    readonly property string _iconBase:         "qrc:/qml/SettingsIcons/"

    // CDA colours
    readonly property color _pageBg:        "#f3f7fc"
    readonly property color _navyTop:       "#0b2f66"
    readonly property color _navyBottom:    "#1565c0"
    readonly property color _skyBlue:       "#4fb3f6"
    readonly property color _activeBlue:    "#2f80ed"
    readonly property color _hoverBlue:     "#2a6fc0"
    readonly property color _headingColor:  "#0b2f66"
    readonly property color _accentBlue:    "#1e6fd0"

    QGCPalette { id: qgcPal }

    function _iconFor(title) {
        var t = String(title).toLowerCase()
        if (t.indexOf("general")   >= 0) return "general"
        if (t.indexOf("offline")   >= 0) return "map"
        if (t.indexOf("comm")      >= 0) return "link"
        if (t.indexOf("mavlink")   >= 0) return "link"
        if (t.indexOf("mock")      >= 0) return "link"
        if (t.indexOf("console")   >= 0) return "terminal"
        if (t.indexOf("help")      >= 0) return "help"
        if (t.indexOf("debug")     >= 0) return "bug"
        if (t.indexOf("palette")   >= 0) return "clipboard"
        if (t.indexOf("taisync")   >= 0 || t.indexOf("microhard") >= 0 || t.indexOf("airmap") >= 0) return "radio"
        return "sliders"
    }

    property string _currentTitle:  ""

    function _subtitleFor(title) {
        var t = String(title).toLowerCase()
        if (t.indexOf("general")   >= 0) return qsTr("Configure your drone academy system preferences")
        if (t.indexOf("offline")   >= 0) return qsTr("Download and manage maps for offline flying")
        if (t.indexOf("comm")      >= 0) return qsTr("Manage telemetry and ground station connections")
        if (t.indexOf("mavlink")   >= 0) return qsTr("MAVLink identity, status and log uploads")
        if (t.indexOf("mock")      >= 0) return qsTr("Start simulated vehicles for testing")
        if (t.indexOf("console")   >= 0) return qsTr("Live application log and logging categories")
        if (t.indexOf("help")      >= 0) return qsTr("Guides, forums and support resources")
        if (t.indexOf("debug")     >= 0) return qsTr("Display, font and screen diagnostics")
        if (t.indexOf("palette")   >= 0) return qsTr("Preview and edit the application colour theme")
        return qsTr("Configure your drone academy system preferences")
    }

    Component.onCompleted: {
        //-- Default Settings
        var defPage = QGroundControl.corePlugin.settingsPages[QGroundControl.corePlugin.defaultSettings]
        _currentTitle = defPage.title
        __rightPanel.source = defPage.url
    }

    //-- Navigation sidebar
    Rectangle {
        id:                 sidebar
        width:              _sidebarWidth
        anchors.top:        parent.top
        anchors.bottom:     parent.bottom
        anchors.left:       parent.left
        gradient: Gradient {
            GradientStop { position: 0.0; color: _navyTop }
            GradientStop { position: 1.0; color: _navyBottom }
        }

        //-- Decorative wave at the bottom
        Canvas {
            id:                 waveCanvas
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.bottom:     parent.bottom
            height:             parent.height * 0.22
            onWidthChanged:     requestPaint()
            onHeightChanged:    requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = "rgba(79,179,246,0.18)"
                ctx.beginPath()
                ctx.moveTo(0, height * 0.55)
                ctx.bezierCurveTo(width * 0.25, height * 0.05, width * 0.55, height * 0.95, width, height * 0.35)
                ctx.lineTo(width, height)
                ctx.lineTo(0, height)
                ctx.closePath()
                ctx.fill()
                ctx.fillStyle = "rgba(255,255,255,0.08)"
                ctx.beginPath()
                ctx.moveTo(0, height * 0.75)
                ctx.bezierCurveTo(width * 0.3, height * 0.35, width * 0.7, height * 1.05, width, height * 0.6)
                ctx.lineTo(width, height)
                ctx.lineTo(0, height)
                ctx.closePath()
                ctx.fill()
            }
        }

        //-- Title
        Row {
            id:                     sidebarTitle
            anchors.top:            parent.top
            anchors.topMargin:      _defaultTextHeight * 1.2
            anchors.left:           parent.left
            anchors.leftMargin:     _defaultTextWidth * 2
            spacing:                _defaultTextWidth

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing:                2
                Repeater {
                    model: 3
                    Rectangle { width: _defaultTextWidth * 1.2; height: 2; radius: 1; color: "white" }
                }
            }
            QGCLabel {
                anchors.verticalCenter: parent.verticalCenter
                text:                   qsTr("SETTINGS")
                color:                  "white"
                font.bold:              true
                font.pointSize:         ScreenTools.smallFontPointSize
            }
        }

        QGCFlickable {
            id:                 buttonList
            anchors.top:        sidebarTitle.bottom
            anchors.topMargin:  _defaultTextHeight
            anchors.bottom:     sidebarFooter.top
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.leftMargin: _horizontalMargin * 2
            anchors.rightMargin:_horizontalMargin * 2
            contentHeight:      buttonColumn.height + _verticalMargin
            flickableDirection: Flickable.VerticalFlick
            clip:               true

            ColumnLayout {
                id:         buttonColumn
                width:      buttonList.width
                spacing:    _verticalMargin / 2

                Repeater {
                    model:  QGroundControl.corePlugin.settingsPages

                    Rectangle {
                        id:                 navItem
                        height:             _buttonHeight
                        Layout.fillWidth:   true
                        radius:             height / 3
                        color:              _selected ? _activeBlue : (navMouse.containsMouse ? _hoverBlue : "transparent")

                        property bool _selected: __rightPanel.source.toString() === modelData.url.toString()

                        QGCColoredImage {
                            id:                     navIcon
                            anchors.left:           parent.left
                            anchors.leftMargin:     _defaultTextWidth * 1.5
                            anchors.verticalCenter: parent.verticalCenter
                            width:                  _defaultTextHeight * 1.4
                            height:                 width
                            sourceSize.height:      height
                            fillMode:               Image.PreserveAspectFit
                            color:                  "white"
                            source:                 _iconBase + _iconFor(modelData.title) + ".svg"
                        }

                        QGCLabel {
                            text:                   modelData.title
                            color:                  "white"
                            font.bold:              navItem._selected
                            anchors.left:           navIcon.right
                            anchors.leftMargin:     _defaultTextWidth * 1.5
                            anchors.right:          parent.right
                            anchors.rightMargin:    _defaultTextWidth
                            anchors.verticalCenter: parent.verticalCenter
                            elide:                  Text.ElideRight
                        }

                        MouseArea {
                            id:             navMouse
                            anchors.fill:   parent
                            hoverEnabled:   true
                            cursorShape:    Qt.PointingHandCursor
                            onClicked: {
                                if (mainWindow.preventViewSwitch()) {
                                    return
                                }
                                if (__rightPanel.source !== modelData.url) {
                                    __rightPanel.source = modelData.url
                                }
                                settingsView._currentTitle = modelData.title
                            }
                        }
                    }
                }
            }
        }

        //-- Footer
        Column {
            id:                     sidebarFooter
            anchors.bottom:         parent.bottom
            anchors.bottomMargin:   _defaultTextHeight
            anchors.left:           parent.left
            anchors.leftMargin:     _defaultTextWidth * 2
            spacing:                _defaultTextHeight / 4

            QGCLabel {
                text:               qsTr("Fly Higher With CDA")
                color:              "white"
                font.bold:          true
                font.italic:        true
                font.pointSize:     ScreenTools.mediumFontPointSize
            }
            QGCLabel {
                text:               qsTr("Better Pilots  \u2022  Safer Skies")
                color:              _skyBlue
                font.pointSize:     ScreenTools.smallFontPointSize
            }
        }
    }

    //-- Page header banner
    Rectangle {
        id:                     pageHeader
        anchors.top:            parent.top
        anchors.topMargin:      _defaultTextHeight * 0.8
        anchors.left:           sidebar.right
        anchors.leftMargin:     _defaultTextWidth * 3
        anchors.right:          parent.right
        anchors.rightMargin:    _defaultTextWidth * 3
        height:                 _defaultTextHeight * 4.6
        radius:                 _defaultTextWidth * 1.4
        clip:                   true
        border.width:           1
        border.color:           "#d3e1f2"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#ffffff" }
            GradientStop { position: 0.55; color: "#eaf3ff" }
            GradientStop { position: 1.0; color: "#cfe3fb" }
        }

        //-- Mountains + drone illustration
        Canvas {
            id:                 heroCanvas
            anchors.right:      parent.right
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            width:              Math.min(parent.width * 0.5, _defaultTextWidth * 60)
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
            anchors.leftMargin:     _defaultTextWidth * 2
            anchors.verticalCenter: parent.verticalCenter
            width:                  _defaultTextHeight * 3.2
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
                source:             _iconBase + _iconFor(_currentTitle) + ".svg"
            }
        }

        Column {
            anchors.left:           headerCircle.right
            anchors.leftMargin:     _defaultTextWidth * 1.5
            anchors.verticalCenter: parent.verticalCenter
            spacing:                2

            QGCLabel {
                text:               qsTr("Application Settings")
                color:              _headingColor
                font.bold:          true
                font.pointSize:     ScreenTools.largeFontPointSize * 1.2
            }
            QGCLabel {
                text:               _currentTitle === "" ? "" : _currentTitle + "  \u2022  " + _subtitleFor(_currentTitle)
                color:              "#5a6f8f"
                font.pointSize:     ScreenTools.smallFontPointSize
            }
        }
    }

    //-- Panel Contents
    Loader {
        id:                     __rightPanel
        anchors.leftMargin:     _defaultTextWidth * 2
        anchors.rightMargin:    _defaultTextWidth * 2
        anchors.topMargin:      _verticalMargin
        anchors.bottomMargin:   _verticalMargin
        clip:                   true
        anchors.left:           sidebar.right
        anchors.right:          parent.right
        anchors.top:            pageHeader.bottom
        anchors.bottom:         parent.bottom
    }
}
