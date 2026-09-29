/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick          2.11
import QtQuick.Controls 2.4
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
        contentHeight:      mockCard.height + (_margins * 2)
        clip:               true

        CDASectionCard {
            id:             mockCard
            width:          Math.min(parent.width, ScreenTools.defaultFontPixelWidth * 90)
            anchors.horizontalCenter: parent.horizontalCenter
            title:          qsTr("Mock Link")
            subtitle:       qsTr("Start simulated vehicles for testing without hardware")
            iconName:       "link"
            collapsible:    false

            Column {
                width:      parent.width
                spacing:    _margins

                QGCCheckBox {
                    id:             sendStatusText
                    text:           qsTr("Send status text + voice")
                }

                GridLayout {
                    width:          parent.width
                    columns:        2
                    columnSpacing:  _margins
                    rowSpacing:     _margins

                    CDAButton {
                        text:               qsTr("PX4 Vehicle")
                        primary:            true
                        Layout.fillWidth:   true
                        onClicked:          QGroundControl.startPX4MockLink(sendStatusText.checked)
                    }
                    CDAButton {
                        text:               qsTr("Generic Vehicle")
                        primary:            true
                        Layout.fillWidth:   true
                        onClicked:          QGroundControl.startGenericMockLink(sendStatusText.checked)
                    }
                    CDAButton {
                        text:               qsTr("APM ArduCopter Vehicle")
                        visible:            QGroundControl.hasAPMSupport
                        Layout.fillWidth:   true
                        onClicked:          QGroundControl.startAPMArduCopterMockLink(sendStatusText.checked)
                    }
                    CDAButton {
                        text:               qsTr("APM ArduPlane Vehicle")
                        visible:            QGroundControl.hasAPMSupport
                        Layout.fillWidth:   true
                        onClicked:          QGroundControl.startAPMArduPlaneMockLink(sendStatusText.checked)
                    }
                    CDAButton {
                        text:               qsTr("APM ArduSub Vehicle")
                        visible:            QGroundControl.hasAPMSupport
                        Layout.fillWidth:   true
                        onClicked:          QGroundControl.startAPMArduSubMockLink(sendStatusText.checked)
                    }
                    CDAButton {
                        text:               qsTr("APM ArduRover Vehicle")
                        visible:            QGroundControl.hasAPMSupport
                        Layout.fillWidth:   true
                        onClicked:          QGroundControl.startAPMArduRoverMockLink(sendStatusText.checked)
                    }
                }

                CDAButton {
                    text:               qsTr("Stop One MockLink")
                    danger:             true
                    width:              parent.width
                    onClicked:          QGroundControl.stopOneMockLink()
                }
            }
        }
    }
}
