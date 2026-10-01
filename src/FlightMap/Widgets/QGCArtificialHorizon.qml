/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


/**
 * @file
 *   @brief QGC Artificial Horizon
 *   @author Gus Grubba <gus@auterion.com>
 */

import QtQuick 2.3

Item {
    id: root
    property real rollAngle :   0
    property real pitchAngle:   0
    clip:           true
    anchors.fill:   parent

    property real angularScale: pitchAngle * root.height / 45

    Item {
        id: artificialHorizon
        width:  root.width  * 4
        height: root.height * 8
        anchors.centerIn: parent
        Rectangle {
            id: sky
            anchors.fill: parent
            smooth: true
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.25; color: "#061C3D" }
                GradientStop { position: 0.5;  color: "#2C8FE0" }
            }
        }
        Rectangle {
            id: ground
            height: sky.height / 2
            anchors {
                left:   sky.left;
                right:  sky.right;
                bottom: sky.bottom
            }
            smooth: true
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.0;  color: "#5A4630" }
                GradientStop { position: 0.25; color: "#1E1A14" }
            }
        }
        //-- Horizon line
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width:                  parent.width
            height:                 2
            color:                  "#E6FFFFFF"
            antialiasing:           true
        }
        transform: [
            Translate {
                y:  angularScale
            },
            Rotation {
                origin.x: artificialHorizon.width  / 2
                origin.y: artificialHorizon.height / 2
                angle:    -rollAngle
            }]
    }
}
