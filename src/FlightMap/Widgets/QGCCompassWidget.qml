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
 *   @brief QGC Compass Widget
 *   @author Gus Grubba <gus@auterion.com>
 */

import QtQuick              2.3
import QtGraphicalEffects   1.0

import QGroundControl              1.0
import QGroundControl.Controls     1.0
import QGroundControl.ScreenTools  1.0
import QGroundControl.Vehicle      1.0
import QGroundControl.Palette      1.0

Item {
    id:     root
    width:  size
    height: size

    property real size:     _defaultSize
    property var  vehicle:  null

    property var  _activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle
    property real _defaultSize:         ScreenTools.defaultFontPixelHeight * (10)
    property real _sizeRatio:           ScreenTools.isTinyScreen ? (size / _defaultSize) * 0.5 : size / _defaultSize
    property int  _fontSize:            ScreenTools.defaultFontPointSize * _sizeRatio
    property real _heading:             vehicle ? vehicle.heading.rawValue : 0
    property real _headingToHome:       vehicle ? vehicle.headingToHome.rawValue : 0
    property real _groundSpeed:         vehicle ? vehicle.groundSpeed.rawValue : 0
    property real _headingToNextWP:     vehicle ? vehicle.headingToNextWP.rawValue : 0
    property real _courseOverGround:    _activeVehicle ? _activeVehicle.gps.courseOverGround.rawValue : 0

    property bool usedByMultipleVehicleList:  false

    function isCOGAngleOK(){
        if(_groundSpeed < 0.5){
            return false
        }
        else{
            return vehicle && _showAdditionalIndicatorsCompass
        }
    }

    function isHeadingHomeOK(){
        return vehicle && _showAdditionalIndicatorsCompass && !isNaN(_headingToHome)
    }

    function isHeadingToNextWPOK(){
        return vehicle && _showAdditionalIndicatorsCompass && !isNaN(_headingToNextWP)
    }

    function isNoseUpLocked(){
        return _lockNoseUpCompass
    }

    readonly property bool _showAdditionalIndicatorsCompass:     QGroundControl.settingsManager.flyViewSettings.showAdditionalIndicatorsCompass.value && !usedByMultipleVehicleList
    readonly property bool _lockNoseUpCompass:        QGroundControl.settingsManager.flyViewSettings.lockNoseUpCompass.value

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Rectangle {
        id:             borderRect
        anchors.fill:   parent
        radius:         width / 2
        border.color:   "#0B2A4A"
        border.width:   Math.max(3, width * 0.035)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#123B6B" }
            GradientStop { position: 1.0; color: "#061428" }
        }
    }

    Item {
        id:             instrument
        anchors.fill:   parent
        visible:        false


        Image {
            id:                 cOGPointer
            source:             isCOGAngleOK() ? "/qmlimages/cOGPointer.svg" : ""
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.fill:       parent
            sourceSize.height:  parent.height

            transform: Rotation {
                property var _angle:isNoseUpLocked()?_courseOverGround-_heading:_courseOverGround
                origin.x:       cOGPointer.width  / 2
                origin.y:       cOGPointer.height / 2
                angle:         _angle
            }
        }

        Image {
            id:                 nextWPPointer
            source:             isHeadingToNextWPOK() ? "/qmlimages/compassDottedLine.svg":"" 
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.fill:       parent
            sourceSize.height:  parent.height

            transform: Rotation {
                property var _angle: isNoseUpLocked()?_headingToNextWP-_heading:_headingToNextWP
                origin.x:       cOGPointer.width  / 2
                origin.y:       cOGPointer.height / 2
                angle:         _angle
            }
        }

        Image {
            id:                     homePointer
            width:                  size * 0.1
            source:                 isHeadingHomeOK()  ? "/qmlimages/Home.svg" : ""
            mipmap:                 true
            fillMode:               Image.PreserveAspectFit
            anchors.centerIn:   	parent
            sourceSize.width:       width

            transform: Translate {
                property double _angle: isNoseUpLocked()?-_heading+_headingToHome:_headingToHome
                x: size/2.3 * Math.sin((_angle)*(3.14/180))
                y: - size/2.3 * Math.cos((_angle)*(3.14/180))
            }
        }

        Image {
            id:                 pointer
            width:              size * 0.65
            source:             vehicle ? vehicle.vehicleImageCompass : ""
            mipmap:             true
            sourceSize.width:   width
            fillMode:           Image.PreserveAspectFit
            anchors.centerIn:   parent
            transform: Rotation {
                origin.x:       pointer.width  / 2
                origin.y:       pointer.height / 2
                angle:          isNoseUpLocked()?0:_heading
            }
        }


        Canvas {
            id:                 compassDial
            anchors.fill:       parent
            antialiasing:       true
            transform: Rotation {
                origin.x:       compassDial.width  / 2
                origin.y:       compassDial.height / 2
                angle:          isNoseUpLocked()?-_heading:0
            }

            onWidthChanged:     requestPaint()
            onHeightChanged:    requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var w = width
                var c = w / 2
                var cardinals = ["N", "E", "S", "W"]
                ctx.translate(c, c)
                for (var i = 0; i < 72; i++) {
                    var a = i * 5
                    ctx.save()
                    ctx.rotate(a * Math.PI / 180)
                    if (a % 90 === 0) {
                        ctx.translate(0, -(c - w * 0.15))
                        ctx.rotate(-a * Math.PI / 180)
                        ctx.fillStyle = (a === 0) ? "#FF5A5F" : "#E6F1FF"
                        ctx.font = "bold " + Math.round(w * 0.12) + "px sans-serif"
                        ctx.textAlign = "center"
                        ctx.textBaseline = "middle"
                        ctx.fillText(cardinals[a / 90], 0, 0)
                    } else {
                        var major = (a % 30 === 0)
                        var len = major ? w * 0.07 : w * 0.035
                        var r0 = c - w * 0.06
                        ctx.strokeStyle = major ? "#38BDF8" : "#8FB3D9"
                        ctx.lineWidth = major ? 2 : 1
                        ctx.beginPath()
                        ctx.moveTo(0, -r0)
                        ctx.lineTo(0, -(r0 - len))
                        ctx.stroke()
                    }
                    ctx.restore()
                }
            }
        }

        //-- Heading readout
        Rectangle {
            anchors.horizontalCenter:   parent.horizontalCenter
            anchors.bottom:             parent.bottom
            anchors.bottomMargin:       size * 0.2
            width:                      size * 0.36
            height:                     size * 0.17
            radius:                     height / 2
            color:                      "#E6071A33"
            border.color:               "#9938BDF8"
            border.width:               1

            QGCLabel {
                text:               _headingString3
                font.family:        vehicle ? ScreenTools.demiboldFontFamily : ScreenTools.normalFontFamily
                font.pointSize:     _fontSize < 8 ? 8 : _fontSize;
                color:              "#E6F1FF"
                anchors.centerIn:   parent

                property string _headingString: vehicle ? _heading.toFixed(0) : "OFF"
                property string _headingString2: _headingString.length === 1 ? "0" + _headingString : _headingString
                property string _headingString3: _headingString2.length === 2 ? "0" + _headingString2 : _headingString2
            }
        }
    }

    Rectangle {
        id:             mask
        anchors.fill:   instrument
        radius:         width / 2
        color:          "black"
        visible:        false
    }

    OpacityMask {
        anchors.fill:   instrument
        source:         instrument
        maskSource:     mask
    }

    //-- Accent ring
    Rectangle {
        anchors.fill:       parent
        anchors.margins:    borderRect.border.width
        radius:             width / 2
        color:              Qt.rgba(0,0,0,0)
        border.color:       "#9938BDF8"
        border.width:       1
    }

}
