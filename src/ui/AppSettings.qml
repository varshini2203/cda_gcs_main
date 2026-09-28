/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Layouts  1.2

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

Rectangle {
    id:     settingsView
    color:  qgcPal.window
    z:      QGroundControl.zOrderTopMost

    readonly property real _defaultTextHeight:  ScreenTools.defaultFontPixelHeight
    readonly property real _defaultTextWidth:   ScreenTools.defaultFontPixelWidth
    readonly property real _horizontalMargin:   _defaultTextWidth / 2
    readonly property real _verticalMargin:     _defaultTextHeight / 2
    readonly property real _buttonHeight:       ScreenTools.isTinyScreen ? ScreenTools.defaultFontPixelHeight * 3 : ScreenTools.defaultFontPixelHeight * 2.4
    readonly property real _sidebarWidth:       _defaultTextWidth * 22

    // CDA colours
    readonly property color _navyTop:       "#0b2f66"
    readonly property color _navyBottom:    "#1565c0"
    readonly property color _skyBlue:       "#4fb3f6"
    readonly property color _hoverBlue:     "#2a6fc0"

    QGCPalette { id: qgcPal }

    Component.onCompleted: {
        //-- Default Settings
        __rightPanel.source = QGroundControl.corePlugin.settingsPages[QGroundControl.corePlugin.defaultSettings].url
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

        QGCLabel {
            id:                     sidebarTitle
            anchors.top:            parent.top
            anchors.topMargin:      _defaultTextHeight
            anchors.left:           parent.left
            anchors.leftMargin:     _defaultTextWidth * 1.5
            text:                   qsTr("SETTINGS")
            color:                  _skyBlue
            font.bold:              true
            font.pointSize:         ScreenTools.smallFontPointSize
        }

        QGCFlickable {
            id:                 buttonList
            anchors.top:        sidebarTitle.bottom
            anchors.topMargin:  _verticalMargin
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
                spacing:    _verticalMargin

                Repeater {
                    model:  QGroundControl.corePlugin.settingsPages

                    Rectangle {
                        id:                 navItem
                        height:             _buttonHeight
                        Layout.fillWidth:   true
                        radius:             height / 4
                        color:              _selected ? _skyBlue : (navMouse.containsMouse ? _hoverBlue : "transparent")

                        property bool _selected: __rightPanel.source.toString() === modelData.url.toString()

                        Rectangle {
                            visible:                navItem._selected
                            width:                  _defaultTextWidth / 3
                            height:                 parent.height * 0.6
                            radius:                 width / 2
                            color:                  "white"
                            anchors.left:           parent.left
                            anchors.leftMargin:     _defaultTextWidth / 2
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        QGCLabel {
                            text:                   modelData.title
                            color:                  "white"
                            font.bold:              navItem._selected
                            anchors.left:           parent.left
                            anchors.leftMargin:     _defaultTextWidth * 2
                            anchors.right:          parent.right
                            anchors.rightMargin:    _defaultTextWidth
                            anchors.verticalCenter: parent.verticalCenter
                            elide:                  Text.ElideRight
                        }

                        MouseArea {
                            id:             navMouse
                            anchors.fill:   parent
                            hoverEnabled:   true
                            onClicked: {
                                if (mainWindow.preventViewSwitch()) {
                                    return
                                }
                                if (__rightPanel.source !== modelData.url) {
                                    __rightPanel.source = modelData.url
                                }
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
            anchors.leftMargin:     _defaultTextWidth * 1.5
            spacing:                _defaultTextHeight / 4

            QGCLabel {
                text:               qsTr("Fly Higher With CDA")
                color:              "white"
                font.bold:          true
                font.italic:        true
            }
            QGCLabel {
                text:               qsTr("Better Pilots  \u2022  Safer Skies")
                color:              _skyBlue
                font.pointSize:     ScreenTools.smallFontPointSize
            }
        }
    }

    //-- Panel Contents
    Loader {
        id:                     __rightPanel
        anchors.leftMargin:     _horizontalMargin * 2
        anchors.rightMargin:    _horizontalMargin
        anchors.topMargin:      _verticalMargin
        anchors.bottomMargin:   _verticalMargin
        anchors.left:           sidebar.right
        anchors.right:          parent.right
        anchors.top:            parent.top
        anchors.bottom:         parent.bottom
    }
}
