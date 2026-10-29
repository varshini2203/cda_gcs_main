/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.12
import QtQuick.Controls         2.4
import QtQuick.Dialogs          1.3
import QtQuick.Layouts          1.12

import QtLocation               5.3
import QtPositioning            5.3
import QtQuick.Window           2.2
import QtQml.Models             2.1

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.Airspace      1.0
import QGroundControl.Airmap        1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

// This is the ui overlay layer for the widgets/tools for Fly View
Item {
    id: _root

    property var    parentToolInsets
    property var    totalToolInsets:        _totalToolInsets
    property var    mapControl

    property var    _activeVehicle:         QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:  globals.planMasterControllerFlyView
    property var    _missionController:     _planMasterController.missionController
    property var    _geoFenceController:    _planMasterController.geoFenceController
    property var    _rallyPointController:  _planMasterController.rallyPointController
    property var    _guidedController:      globals.guidedControllerFlyView
    property real   _margins:               ScreenTools.defaultFontPixelWidth / 2
    property real   _toolsMargin:           ScreenTools.defaultFontPixelWidth * 0.75
    property rect   _centerViewport:        Qt.rect(0, 0, width, height)
    property real   _rightPanelWidth:       ScreenTools.defaultFontPixelWidth * 30

    QGCToolInsets {
        id:                     _totalToolInsets
        leftEdgeTopInset:       toolStrip.leftInset
        leftEdgeCenterInset:    toolStrip.leftInset
        leftEdgeBottomInset:    parentToolInsets.leftEdgeBottomInset
        rightEdgeTopInset:      parentToolInsets.rightEdgeTopInset
        rightEdgeCenterInset:   parentToolInsets.rightEdgeCenterInset
        rightEdgeBottomInset:   parentToolInsets.rightEdgeBottomInset
        topEdgeLeftInset:       parentToolInsets.topEdgeLeftInset
        topEdgeCenterInset:     parentToolInsets.topEdgeCenterInset
        topEdgeRightInset:      parentToolInsets.topEdgeRightInset
        bottomEdgeLeftInset:    parentToolInsets.bottomEdgeLeftInset
        bottomEdgeCenterInset:  mapScale.centerInset
        bottomEdgeRightInset:   telemetryPanel.bottomInset
    }

    FlyViewMissionCompleteDialog {
        missionController:      _missionController
        geoFenceController:     _geoFenceController
        rallyPointController:   _rallyPointController
    }

    Row {
        id:                 multiVehiclePanelSelector
        anchors.margins:    _toolsMargin
        anchors.top:        parent.top
        anchors.right:      parent.right
        width:              _rightPanelWidth
        spacing:            ScreenTools.defaultFontPixelWidth
        visible:            QGroundControl.multiVehicleManager.vehicles.count > 1 && QGroundControl.corePlugin.options.flyView.showMultiVehicleList

        property bool showSingleVehiclePanel:  !visible || singleVehicleRadio.checked

        QGCMapPalette { id: mapPal; lightColors: true }

        QGCRadioButton {
            id:             singleVehicleRadio
            text:           qsTr("Single")
            checked:        true
            textColor:      mapPal.text
        }

        QGCRadioButton {
            text:           qsTr("Multi-Vehicle")
            textColor:      mapPal.text
        }
    }

    MultiVehicleList {
        anchors.margins:    _toolsMargin
        anchors.top:        multiVehiclePanelSelector.bottom
        anchors.right:      parent.right
        width:              _rightPanelWidth
        height:             parent.height - y - _toolsMargin
        visible:            !multiVehiclePanelSelector.showSingleVehiclePanel
    }

    // Old instrument panel (attitude circle + compass) is hidden.
    // Kept in the file because other code may refer to instrumentPanel.rightInset.
    FlyViewInstrumentPanel {
        id:                         instrumentPanel
        anchors.margins:            _toolsMargin
        anchors.top:                multiVehiclePanelSelector.visible ? multiVehiclePanelSelector.bottom : parent.top
        anchors.right:              parent.right
        width:                      _rightPanelWidth
        spacing:                    _toolsMargin
        visible:                    false
        availableHeight:            parent.height - y - _toolsMargin

        property real rightInset: visible ? parent.width - x : 0
    }

    //-- Compass: heading-up rotating dial, degree scale + digital heading readout inside
    Item {
        id:     movableCompass
        width:  ScreenTools.defaultFontPixelHeight * 7.5
        height: width
        z:      QGroundControl.zOrderWidgets + 1

        property bool locked:   false                       // double-click the compass to lock/unlock
        property bool _moved:   false                       // becomes true after you drag it once
        property var  _vehicle: globals.activeVehicle
        property bool _hasHeading: _vehicle !== null && _vehicle !== undefined &&
                                   _vehicle.heading !== undefined && !isNaN(_vehicle.heading.rawValue)
        // Always normalised to 0..360 (the vehicle can report negative or >=360 values)
        property real _heading: _hasHeading ? (((_vehicle.heading.rawValue % 360) + 360) % 360) : 0
        property int  _headingInt: Math.round(_heading) % 360
        property bool _focused: dragArea.pressed || dragArea.containsMouse

        function _pad3(n) { return (n < 10 ? "00" : (n < 100 ? "0" : "")) + n }
        function _cardinal(h) {
            var names = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
            return names[Math.round(h / 45) % 8]
        }

        opacity: _focused ? 1.0 : 0.88
        Behavior on opacity { NumberAnimation { duration: 250 } }

        // Place at top-right once the layer has a real size
        function place() {
            if (!_moved && _root.width > 0 && _root.height > 0) {
                x = _root.width - width - _toolsMargin * 2
                y = _toolsMargin * 2
            }
        }
        Component.onCompleted: place()
        Connections {
            target: _root
            function onWidthChanged()  { movableCompass.place() }
            function onHeightChanged() { movableCompass.place() }
        }

        //-- Glass disc
        Rectangle {
            anchors.fill:   parent
            radius:         width / 2
            color:          "#D9081420"
            border.color:   movableCompass.locked ? "#80FFB020" : "#8038BDF8"
            border.width:   1.5
        }

        //-- Rotating compass card. The card turns by -heading, so the bearing the
        //-- drone is flying is always the one under the fixed marker at the top.
        Item {
            id:             dial
            anchors.fill:   parent
            rotation:       -movableCompass._heading
            Behavior on rotation { RotationAnimation { duration: 150; direction: RotationAnimation.Shortest } }

            Canvas {
                anchors.fill:   parent
                antialiasing:   true
                onWidthChanged:         requestPaint()
                onHeightChanged:        requestPaint()
                Component.onCompleted:  requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var w = width, c = w / 2
                    var cardinals = { 0: "N", 90: "E", 180: "S", 270: "W" }
                    ctx.translate(c, c)
                    ctx.textAlign    = "center"
                    ctx.textBaseline = "middle"
                    for (var a = 0; a < 360; a += 5) {
                        ctx.save()
                        ctx.rotate(a * Math.PI / 180)          // clockwise from North
                        var isCardinal = (a % 90 === 0)
                        var isMajor    = (a % 30 === 0)
                        var isMid      = (a % 10 === 0)
                        ctx.strokeStyle = isMajor ? "#7FD3F7" : (isMid ? "#5B86AD" : "#3F6384")
                        ctx.lineWidth   = isMajor ? 1.6 : 1
                        ctx.beginPath()
                        ctx.moveTo(0, -w * 0.485)
                        ctx.lineTo(0, -w * (isMajor ? 0.425 : (isMid ? 0.45 : 0.46)))
                        ctx.stroke()
                        if (isCardinal) {
                            ctx.fillStyle = (a === 0) ? "#FF6B6B" : "#E6F1FF"
                            ctx.font      = "bold " + Math.round(w * 0.13) + "px sans-serif"
                            ctx.fillText(cardinals[a], 0, -w * 0.35)
                        } else if (isMajor) {
                            ctx.fillStyle = "#BFD9F2"
                            ctx.font      = Math.round(w * 0.085) + "px sans-serif"
                            ctx.fillText(String(a), 0, -w * 0.36)   // 30, 60, 120, 150 ...
                        }
                        ctx.restore()
                    }
                }
            }
        }

        //-- Fixed pointer at the top (the "nose" of the drone)
        Canvas {
            anchors.fill:   parent
            antialiasing:   true
            onWidthChanged:         requestPaint()
            onHeightChanged:        requestPaint()
            Component.onCompleted:  requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var w = width, c = w / 2
                ctx.translate(c, c)
                ctx.fillStyle = "#FFB020"
                ctx.beginPath()
                ctx.moveTo(0,         -w * 0.435)
                ctx.lineTo( w * 0.04, -w * 0.505)
                ctx.lineTo(-w * 0.04, -w * 0.505)
                ctx.closePath()
                ctx.fill()
            }
        }

        //-- Digital heading readout in the middle of the compass
        Column {
            anchors.centerIn:   parent
            spacing:            0

            QGCLabel {
                anchors.horizontalCenter:   parent.horizontalCenter
                color:                      movableCompass._hasHeading ? "#FFFFFF" : "#6F8CA8"
                font.bold:                  true
                font.pixelSize:             movableCompass.width * 0.17
                text:                       movableCompass._hasHeading ?
                                                movableCompass._pad3(movableCompass._headingInt) + "\u00B0" : "---\u00B0"
            }
            QGCLabel {
                anchors.horizontalCenter:   parent.horizontalCenter
                color:                      "#7FD3F7"
                font.pixelSize:             movableCompass.width * 0.095
                text:                       movableCompass._hasHeading ? movableCompass._cardinal(movableCompass._heading) : qsTr("NO DATA")
            }
        }

        MouseArea {
            id:             dragArea
            anchors.fill:   parent
            hoverEnabled:   true
            drag.target:    movableCompass.locked ? undefined : movableCompass
            drag.minimumX:  0
            drag.maximumX:  _root.width  - movableCompass.width
            drag.minimumY:  0
            drag.maximumY:  _root.height - movableCompass.height
            cursorShape:    movableCompass.locked ? Qt.ArrowCursor : (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
            onDoubleClicked: movableCompass.locked = !movableCompass.locked
            drag.onActiveChanged: if (drag.active) movableCompass._moved = true
        }
    }

    PhotoVideoControl {
        anchors.margins:        _toolsMargin
        anchors.verticalCenter: parent.verticalCenter
        anchors.right:          parent.right
        width:                  _rightPanelWidth
    }

    CDATelemetryBar {
        id:     telemetryPanel
        z:      QGroundControl.zOrderWidgets + 1

        // position is handled inside CDATelemetryBar (drag to move, double-click to lock)
        property real bottomInset: height
    }

    //-- Virtual Joystick
    Loader {
        id:                         virtualJoystickMultiTouch
        z:                          QGroundControl.zOrderTopMost + 1
        width:                      parent.width  - (_pipOverlay.width / 2)
        height:                     Math.min(parent.height * 0.25, ScreenTools.defaultFontPixelWidth * 16)
        visible:                    _virtualJoystickEnabled && !QGroundControl.videoManager.fullScreen && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)
        anchors.bottom:             parent.bottom
        anchors.bottomMargin:       parentToolInsets.leftEdgeBottomInset + ScreenTools.defaultFontPixelHeight * 2
        anchors.horizontalCenter:   parent.horizontalCenter
        source:                     "qrc:/qml/VirtualJoystick.qml"
        active:                     _virtualJoystickEnabled && !(_activeVehicle ? _activeVehicle.usingHighLatencyLink : false)

        property bool autoCenterThrottle: QGroundControl.settingsManager.appSettings.virtualJoystickAutoCenterThrottle.rawValue

        property bool _virtualJoystickEnabled: QGroundControl.settingsManager.appSettings.virtualJoystick.rawValue
    }

    FlyViewToolStrip {
        id:                     toolStrip
        anchors.leftMargin:     _toolsMargin + parentToolInsets.leftEdgeCenterInset
        anchors.topMargin:      _toolsMargin + parentToolInsets.topEdgeLeftInset
        anchors.left:           parent.left
        anchors.top:            parent.top
        z:                      QGroundControl.zOrderWidgets
        maxHeight:              parent.height - y - parentToolInsets.bottomEdgeLeftInset - _toolsMargin
        visible:                !QGroundControl.videoManager.fullScreen

        onDisplayPreFlightChecklist: mainWindow.showPopupDialogFromComponent(preFlightChecklistPopup)

        property real leftInset: x + width
    }

    FlyViewAirspaceIndicator {
        anchors.top:                parent.top
        anchors.topMargin:          ScreenTools.defaultFontPixelHeight * 0.25
        anchors.horizontalCenter:   parent.horizontalCenter
        z:                          QGroundControl.zOrderWidgets
        show:                       mapControl.pipState.state !== mapControl.pipState.pipState
    }

    VehicleWarnings {
        anchors.centerIn:   parent
        z:                  QGroundControl.zOrderTopMost
    }

    MapScale {
        id:                 mapScale
        anchors.margins:    _toolsMargin
        anchors.left:       toolStrip.right
        anchors.top:        parent.top
        mapControl:         _mapControl
        buttonsOnLeft:      false
        visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && mapControl.pipState.state === mapControl.pipState.fullState

        property real centerInset: visible ? parent.height - y : 0
    }

    Component {
        id: preFlightChecklistPopup
        FlyViewPreFlightChecklistPopup {
        }
    }
}
