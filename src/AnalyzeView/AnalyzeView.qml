/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.12
import QtQuick.Window   2.2
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.Controllers   1.0
import QGroundControl.ScreenTools   1.0

// Chennai Drone Academy themed Analyze Tools
Rectangle {
    id:     _root
    color:  _pageBg
    z:      QGroundControl.zOrderTopMost

    signal popout()

    readonly property real  _defaultTextHeight:     ScreenTools.defaultFontPixelHeight
    readonly property real  _defaultTextWidth:      ScreenTools.defaultFontPixelWidth
    readonly property real  _horizontalMargin:      _defaultTextWidth / 2
    readonly property real  _verticalMargin:        _defaultTextHeight / 2
    readonly property real  _buttonHeight:          ScreenTools.isTinyScreen ? ScreenTools.defaultFontPixelHeight * 3 : ScreenTools.defaultFontPixelHeight * 2.6
    readonly property real  _sidebarWidth:          _defaultTextWidth * 24
    readonly property string _iconBase:             "qrc:/qml/SettingsIcons/"

    // CDA colours
    readonly property color _pageBg:        "#f3f7fc"
    readonly property color _navyTop:       "#0b2f66"
    readonly property color _navyBottom:    "#1565c0"
    readonly property color _skyBlue:       "#4fb3f6"
    readonly property color _activeBlue:    "#2f80ed"
    readonly property color _hoverBlue:     "#2a6fc0"

    property int _curIndex: 0

    QGCPalette { id: qgcPal }

    function _iconFor(title) {
        var t = String(title).toLowerCase()
        if (t.indexOf("log")        >= 0) return "file"
        if (t.indexOf("geotag")     >= 0) return "pin"
        if (t.indexOf("console")    >= 0) return "terminal"
        if (t.indexOf("inspector")  >= 0) return "eye"
        if (t.indexOf("vibration")  >= 0) return "gauge"
        return "sliders"
    }

    GeoTagController {
        id: geoController
    }

    LogDownloadController {
        id: logController
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
                text:                   qsTr("ANALYZE")
                color:                  "white"
                font.bold:              true
                font.pointSize:         ScreenTools.smallFontPointSize
            }
        }

        QGCFlickable {
            id:                 buttonScroll
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
                width:      buttonScroll.width
                spacing:    _verticalMargin / 2

                Repeater {
                    id:     buttonRepeater
                    model:  QGroundControl.corePlugin ? QGroundControl.corePlugin.analyzePages : []

                    Rectangle {
                        id:                 navItem
                        height:             _buttonHeight
                        Layout.fillWidth:   true
                        radius:             height / 3
                        color:              _selected ? _activeBlue : (navMouse.containsMouse ? _hoverBlue : "transparent")

                        property bool   _selected:  _curIndex === index
                        property var    window:     analyzeWidgetWindow
                        property var    loader:     analyzeWidgetLoader

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
                                _curIndex = index
                                panelLoader.source = modelData.url
                            }
                        }

                        Window {
                            id:             analyzeWidgetWindow
                            width:          ScreenTools.defaultFontPixelWidth  * 100
                            height:         ScreenTools.defaultFontPixelHeight * 40
                            visible:        false
                            title:          modelData.title
                            Rectangle {
                                color:      _pageBg
                                anchors.fill:  parent
                                Loader {
                                    id:             analyzeWidgetLoader
                                    anchors.fill:   parent
                                }
                            }
                            onClosing: {
                                analyzeWidgetWindow.visible = false
                                analyzeWidgetLoader.source = ""
                                _curIndex = index
                                panelLoader.source = modelData.url
                                navItem.visible = true
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

    Connections {
        target:                 panelLoader.item
        onPopout: {
            buttonRepeater.itemAt(_curIndex).window.visible = true
            var source = panelLoader.source
            panelLoader.source = ""
            buttonRepeater.itemAt(_curIndex).loader.source = source
            buttonRepeater.itemAt(_curIndex).visible = false
            buttonRepeater.itemAt(_curIndex).loader.item.popped = true
            _root.popout()
        }
    }

    //-- Panel Contents
    Loader {
        id:                     panelLoader
        anchors.leftMargin:     _defaultTextWidth * 2
        anchors.rightMargin:    _defaultTextWidth * 2
        anchors.topMargin:      _verticalMargin
        anchors.bottomMargin:   _verticalMargin
        anchors.left:           sidebar.right
        anchors.right:          parent.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
        source:                 "LogDownloadPage.qml"
    }
}
