/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick 2.12

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.Controllers   1.0
import QGroundControl.ScreenTools   1.0

Item {
    id:         _root
    visible:    true    // Camera view is always available next to the map, even before a stream is configured
    clip:       true

    property Item pipState: videoPipState
    QGCPipState {
        id:         videoPipState
        pipOverlay: _pipOverlay
        isDark:     true

        onWindowAboutToOpen: {
            QGroundControl.videoManager.stopVideo()
            videoStartDelay.start()
        }

        onWindowAboutToClose: {
            QGroundControl.videoManager.stopVideo()
            videoStartDelay.start()
        }

        onStateChanged: {
            if (videoPipState.state !== videoPipState.fullState) {
                QGroundControl.videoManager.fullScreen = false
            }
        }
    }

    Timer {
        id:           videoStartDelay
        interval:     2000;
        running:      false
        repeat:       false
        onTriggered:  QGroundControl.videoManager.startVideo()
    }

    //-- Video Streaming
    FlightDisplayViewVideo {
        id:             videoStreaming
        anchors.fill:   parent
        useSmallFont:   _root.pipState.state !== _root.pipState.fullState
        visible:        QGroundControl.videoManager.isGStreamer
    }
    //-- UVC Video (USB Camera or Video Device)
    Loader {
        id:             cameraLoader
        anchors.fill:   parent
        visible:        !QGroundControl.videoManager.isGStreamer
        source:         visible ? (QGroundControl.videoManager.uvcEnabled ? "qrc:/qml/FlightDisplayViewUVC.qml" : "qrc:/qml/FlightDisplayViewDummy.qml") : ""
    }

    //-- Placeholder shown when no video source has been configured yet
    Rectangle {
        anchors.fill:   parent
        color:          Qt.rgba(0,0,0,0.85)
        visible:        !QGroundControl.videoManager.hasVideo
        QGCLabel {
            anchors.centerIn:       parent
            width:                  parent.width * 0.9
            horizontalAlignment:    Text.AlignHCenter
            wrapMode:               Text.WordWrap
            color:                  "white"
            font.family:            ScreenTools.demiboldFontFamily
            font.pointSize:         _root.pipState.state === _root.pipState.fullState ? ScreenTools.largeFontPointSize : ScreenTools.smallFontPointSize
            text: {
                if (_root.pipState.state !== _root.pipState.fullState) {
                    return qsTr("NO CAMERA")
                }
                if (!QGroundControl.videoManager.gstreamerAvailable && !QGroundControl.videoManager.uvcEnabled) {
                    return qsTr("NO DRONE CAMERA\nThis build has no video support (GStreamer not found). Install GStreamer (MSVC 64-bit) and rebuild, or plug in a USB camera.")
                }
                return qsTr("NO DRONE CAMERA\nSet the Video Source in Application Settings > General > Video\n(UDP h.264 port 5600 is the usual drone default)")
            }
        }
    }

    MouseArea {
        anchors.fill:       parent
        enabled:            pipState.state === pipState.fullState
        onDoubleClicked:    QGroundControl.videoManager.fullScreen = !QGroundControl.videoManager.fullScreen
    }

    ProximityRadarVideoView{
        anchors.fill:   parent
        vehicle:        QGroundControl.multiVehicleManager.activeVehicle
    }
}
