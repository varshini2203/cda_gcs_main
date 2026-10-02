/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.3
import QtQuick.Layouts  1.11

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

Rectangle {
    color:          "transparent"
    anchors.fill:   parent

    readonly property real _margins: ScreenTools.defaultFontPixelHeight

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    QGCFlickable {
        anchors.fill:       parent
        anchors.margins:    _margins
        contentWidth:       width
        contentHeight:      helpCard.height + (_margins * 2)
        clip:               true

        CDASectionCard {
            id:             helpCard
            width:          Math.min(parent.width, ScreenTools.defaultFontPixelWidth * 110)
            anchors.horizontalCenter: parent.horizontalCenter
            title:          qsTr("Help & Resources")
            subtitle:       qsTr("Training, support and contact links")
            iconName:       "help"
            collapsible:    false

            Column {
                width:      parent.width
                spacing:    _margins * 0.6

                Repeater {
                    // TODO: replace the url values below with the real Chennai Drone Academy links
                    model: [
                        { name: qsTr("Chennai Drone Academy Website"),      url: "https://www.chennaidroneacademy.com" },
                        { name: qsTr("CDA Courses & Training"),             url: "https://www.chennaidroneacademy.com/courses" },
                        { name: qsTr("CDA Support (Email)"),                url: "mailto:support@chennaidroneacademy.com" },
                        { name: qsTr("CDA YouTube Channel"),                url: "https://www.youtube.com/@chennaidroneacademy" }
                    ]

                    delegate: Rectangle {
                        width:          parent.width
                        height:         ScreenTools.defaultFontPixelHeight * 3.6
                        radius:         ScreenTools.defaultFontPixelWidth
                        color:          rowMouse.containsMouse ? "#eef4fb" : "#f8fbff"
                        border.width:   1
                        border.color:   "#d3e1f2"

                        Rectangle {
                            id:                     rowBadge
                            anchors.left:           parent.left
                            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
                            anchors.verticalCenter: parent.verticalCenter
                            width:                  ScreenTools.defaultFontPixelHeight * 2
                            height:                 width
                            radius:                 width / 2
                            color:                  "#dcebfb"

                            QGCColoredImage {
                                anchors.centerIn:   parent
                                width:              parent.width * 0.55
                                height:             width
                                sourceSize.height:  height
                                fillMode:           Image.PreserveAspectFit
                                color:              "#1e6fd0"
                                source:             "qrc:/qml/SettingsIcons/link.svg"
                            }
                        }

                        Column {
                            anchors.left:           rowBadge.right
                            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
                            anchors.right:          openButton.left
                            anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
                            anchors.verticalCenter: parent.verticalCenter
                            spacing:                2

                            QGCLabel {
                                text:       modelData.name
                                color:      "#0b2f66"
                                font.bold:  true
                                width:      parent.width
                                elide:      Text.ElideRight
                            }
                            QGCLabel {
                                text:           modelData.url
                                color:          "#1e6fd0"
                                font.pointSize: ScreenTools.smallFontPointSize
                                width:          parent.width
                                elide:          Text.ElideMiddle
                            }
                        }

                        CDAButton {
                            id:                     openButton
                            anchors.right:          parent.right
                            anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
                            anchors.verticalCenter: parent.verticalCenter
                            text:                   qsTr("Open")
                            primary:                true
                            onClicked:              Qt.openUrlExternally(modelData.url)
                        }

                        MouseArea {
                            id:             rowMouse
                            anchors.fill:   parent
                            hoverEnabled:   true
                            z:              -1
                            cursorShape:    Qt.PointingHandCursor
                            onClicked:      Qt.openUrlExternally(modelData.url)
                        }
                    }
                }
            }
        }
    }
}
