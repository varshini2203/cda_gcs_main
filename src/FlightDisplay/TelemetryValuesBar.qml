/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                      2.12
import QtQuick.Layouts              1.12

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0

Rectangle {
    id:                 telemetryPanel
    height:             telemetryLayout.height + (_toolsMargin * 2)
    width:              telemetryLayout.width + (_toolsMargin * 2)
    color:              "#F2F6FAFF"
    radius:             ScreenTools.defaultFontPixelWidth * 1.2
    border.width:       1
    border.color:       "#66155EA8"

    property color _baseBGColor: qgcPal.window

    //-- Soft drop shadow
    Rectangle {
        z:          -1
        x:          -1
        y:          3
        width:      parent.width + 2
        height:     parent.height + 2
        radius:     telemetryPanel.radius + 1
        color:      "#4D000000"
    }

    //-- Accent strip
    Rectangle {
        anchors.top:            parent.top
        anchors.topMargin:      1
        anchors.left:           parent.left
        anchors.leftMargin:     telemetryPanel.radius
        anchors.right:          parent.right
        anchors.rightMargin:    telemetryPanel.radius
        height:                 3
        radius:                 1.5
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#1E88E5" }
            GradientStop { position: 1.0; color: "#38BDF8" }
        }
    }

    DeadMouseArea { anchors.fill: parent }

    ColumnLayout {
        id:                 telemetryLayout
        anchors.margins:    _toolsMargin
        anchors.top:        parent.top
        anchors.left:       parent.left

        HorizontalFactValueGrid {
            id:                     valueArea
            userSettingsGroup:      telemetryBarUserSettingsGroup
            defaultSettingsGroup:   telemetryBarDefaultSettingsGroup

            QGCMouseArea {
                anchors.fill:   parent
                visible:        !parent.settingsUnlocked
                onClicked:      parent.settingsUnlocked = true
            }
        }

        GuidedActionConfirm {
            Layout.fillWidth:   true
            guidedController:   _guidedController
            altitudeSlider:     _guidedAltSlider
        }
    }
}
