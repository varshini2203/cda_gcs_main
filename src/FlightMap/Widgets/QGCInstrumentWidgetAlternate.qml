/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick 2.3

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0

Rectangle {
    id:             root
    height:         _outerRadius * 4 + _valuesWidget.height
    radius:         _outerRadius
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#F00F3A66" }
        GradientStop { position: 1.0; color: "#F0071A33" }
    }
    border.width:   1
    border.color:   "#5938BDF8"

    // These properties are expected to be in the Loader
    //  property real maxHeight
    //  property bool showValues - true: show value pages

    property real   _innerRadius:   (width - (_topBottomMargin * 2)) / 2
    property real   _outerRadius:   _innerRadius + _topBottomMargin * 2
    property real   _margins:       (width * 0.05) / 2

    // Prevent all clicks from going through to lower layers
    DeadMouseArea {
        anchors.fill: parent
    }

    QGCPalette { id: qgcPal }

    QGCAttitudeWidget {
        id:                         attitude
        anchors.horizontalCenter:   parent.horizontalCenter
        anchors.margins :           _margins
        anchors.top:                parent.top
        size:                       _innerRadius * 2
        vehicle:                    globals.activeVehicle
    }

    QGCCompassWidget {
        id:                         compass
        anchors.horizontalCenter:   parent.horizontalCenter
        anchors.margins:            _margins
        anchors.top:                attitude.bottom
        size:                       _innerRadius * 2
        vehicle:                    globals.activeVehicle
    }
}
