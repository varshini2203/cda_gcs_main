/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Layouts  1.11

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.MultiVehicleManager   1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0
import MAVLink                              1.0

//-------------------------------------------------------------------------
//-- Battery Indicator
Item {
    id:             _root
    anchors.top:    parent.top
    anchors.bottom: parent.bottom
    width:          batteryIndicatorRow.width

    property bool showIndicator: true

    property var _activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    property bool _armed:        _activeVehicle ? _activeVehicle.armed : false

    Row {
        id:             batteryIndicatorRow
        anchors.top:    parent.top
        anchors.bottom: parent.bottom

        Repeater {
            model: _activeVehicle ? _activeVehicle.batteries : 0

            Loader {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                sourceComponent:    batteryVisual

                property var battery: object
            }
        }
    }
    MouseArea {
        anchors.fill:   parent
        onClicked: {
            mainWindow.showIndicatorPopup(_root, batteryPopup)
        }
    }

    Component {
        id: batteryVisual

        Row {
            id:             batRow
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            spacing:        ScreenTools.defaultFontPixelWidth * 0.4

            property bool armed:        _root._armed

            // ---- CDA fixed voltage -> % table (pack voltage, drone's own % is NOT used) ----
            //      21.5 V = 100 %,  16 V = 20 %,  15.5 V = 10 %,  15 V = 0 %
            readonly property var cdaTable: [[21.5, 100], [16.0, 20], [15.5, 10], [15.0, 0]]

            // ---- Tuning knobs ----
            readonly property real alphaGround: 0.30    // smoothing on ground (higher = faster)
            readonly property real alphaFlight: 0.03    // smoothing in flight (lower = steadier, ignores throttle sag)
            readonly property real groundStep:  2       // on ground, % changes only if difference >= this

            property real _vSmooth:     NaN             // smoothed pack voltage
            property real _shown:       NaN             // stable % shown on screen
            property real pct:          _shown
            property bool pctValid:     !isNaN(pct)
            property real volts:        _vSmooth

            // GREEN above 50 %, YELLOW 50-20 %, RED 20-0 %
            property color pctColor:    !pctValid ? qgcPal.text : (pct > 50 ? "#22C55E" : (pct > 20 ? "#FACC15" : "#EF4444"))

            function getBatteryColor() {
                switch (battery.chargeState.rawValue) {
                case MAVLink.MAV_BATTERY_CHARGE_STATE_OK:
                    return qgcPal.text
                case MAVLink.MAV_BATTERY_CHARGE_STATE_LOW:
                    return qgcPal.colorOrange
                case MAVLink.MAV_BATTERY_CHARGE_STATE_CRITICAL:
                case MAVLink.MAV_BATTERY_CHARGE_STATE_EMERGENCY:
                case MAVLink.MAV_BATTERY_CHARGE_STATE_FAILED:
                case MAVLink.MAV_BATTERY_CHARGE_STATE_UNHEALTHY:
                    return qgcPal.colorRed
                default:
                    return qgcPal.text
                }
            }

            // Linear interpolation between the CDA table points
            function voltagePercent(v) {
                if (isNaN(v) || v < 5) {
                    return NaN
                }
                var t = cdaTable
                if (v >= t[0][0]) {
                    return 100
                }
                if (v <= t[t.length - 1][0]) {
                    return 0
                }
                for (var i = 0; i < t.length - 1; i++) {
                    var hi = t[i], lo = t[i + 1]
                    if (v <= hi[0] && v >= lo[0]) {
                        return lo[1] + (v - lo[0]) * (hi[1] - lo[1]) / (hi[0] - lo[0])
                    }
                }
                return 0
            }

            // Runs once per second (see Timer below)
            function tick() {
                var raw = battery.voltage.rawValue

                // battery unplugged / no valid data -> reset, next plug-in starts fresh
                if (isNaN(raw) || raw < 5) {
                    _vSmooth = NaN
                    _shown   = NaN
                    return
                }

                // 1) smooth the voltage (EMA)
                if (isNaN(_vSmooth)) {
                    _vSmooth = raw
                } else {
                    var a = armed ? alphaFlight : alphaGround
                    _vSmooth = _vSmooth * (1 - a) + raw * a
                }

                var p = voltagePercent(_vSmooth)

                // 2) hysteresis
                if (isNaN(_shown)) {
                    _shown = p                                  // first reading
                } else if (armed) {
                    if (p < _shown) {                           // in flight: only goes DOWN
                        _shown = p
                    }
                } else {
                    if (Math.abs(p - _shown) >= groundStep) {   // on ground: ignore small jitter
                        _shown = p
                    }
                }
            }

            function pctText() {
                if (pctValid) {
                    return Math.round(pct) + "%"
                }
                if (battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED) {
                    return battery.chargeState.enumStringValue
                }
                return ""
            }

            Timer {
                interval:           1000
                running:            true
                repeat:             true
                triggeredOnStart:   true
                onTriggered:        batRow.tick()
            }

            QGCColoredImage {
                anchors.top:        parent.top
                anchors.bottom:     parent.bottom
                width:              height
                sourceSize.width:   width
                source:             "/qmlimages/Battery.svg"
                fillMode:           Image.PreserveAspectFit
                color:              batRow.pctColor
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing:                ScreenTools.defaultFontPixelHeight * 0.15

                Row {
                    id:         topRow
                    spacing:    ScreenTools.defaultFontPixelWidth * 0.8

                    QGCLabel {
                        text:           batRow.pctText()
                        font.pointSize: ScreenTools.mediumFontPointSize
                        color:          batRow.pctColor
                    }

                    QGCLabel {
                        visible:                !isNaN(batRow.volts) && batRow.volts > 0
                        text:                   batRow.volts.toFixed(1) + " V"
                        font.pointSize:         ScreenTools.smallFontPointSize
                        color:                  "#B8C7D6"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                //-- Voltage / charge line (green >50, yellow 50-20, red 20-0)
                Rectangle {
                    width:      Math.max(topRow.width, ScreenTools.defaultFontPixelWidth * 9)
                    height:     Math.max(4, ScreenTools.defaultFontPixelHeight * 0.3)
                    radius:     height / 2
                    color:      "#40FFFFFF"

                    Rectangle {
                        width:      batRow.pctValid ? parent.width * batRow.pct / 100 : 0
                        height:     parent.height
                        radius:     height / 2
                        color:      batRow.pctColor
                        Behavior on width { NumberAnimation { duration: 300 } }
                    }
                }
            }
        }
    }

    Component {
        id: batteryValuesAvailableComponent

        QtObject {
            property bool functionAvailable:        battery.function.rawValue !== MAVLink.MAV_BATTERY_FUNCTION_UNKNOWN
            property bool temperatureAvailable:     !isNaN(battery.temperature.rawValue)
            property bool currentAvailable:         !isNaN(battery.current.rawValue)
            property bool mahConsumedAvailable:     !isNaN(battery.mahConsumed.rawValue)
            property bool timeRemainingAvailable:   !isNaN(battery.timeRemaining.rawValue)
            property bool chargeStateAvailable:     battery.chargeState.rawValue !== MAVLink.MAV_BATTERY_CHARGE_STATE_UNDEFINED
        }
    }

    Component {
        id: batteryPopup

        Rectangle {
            width:          mainLayout.width   + mainLayout.anchors.margins * 2
            height:         mainLayout.height  + mainLayout.anchors.margins * 2
            radius:         ScreenTools.defaultFontPixelHeight / 2
            color:          qgcPal.window
            border.color:   qgcPal.text

            ColumnLayout {
                id:                 mainLayout
                anchors.margins:    ScreenTools.defaultFontPixelWidth
                anchors.top:        parent.top
                anchors.right:      parent.right
                spacing:            ScreenTools.defaultFontPixelHeight

                QGCLabel {
                    Layout.alignment:   Qt.AlignCenter
                    text:               qsTr("Battery Status")
                    font.family:        ScreenTools.demiboldFontFamily
                }

                RowLayout {
                    spacing: ScreenTools.defaultFontPixelWidth

                    ColumnLayout {
                        Repeater {
                            model: _activeVehicle ? _activeVehicle.batteries : 0

                            ColumnLayout {
                                spacing: 0

                                property var batteryValuesAvailable: nameAvailableLoader.item

                                Loader {
                                    id:                 nameAvailableLoader
                                    sourceComponent:    batteryValuesAvailableComponent

                                    property var battery: object
                                }

                                QGCLabel { text: qsTr("Battery %1").arg(object.id.rawValue) }
                                QGCLabel { text: qsTr("Charge State");                          visible: batteryValuesAvailable.chargeStateAvailable }
                                QGCLabel { text: qsTr("Remaining");                             visible: batteryValuesAvailable.timeRemainingAvailable }
                                QGCLabel { text: qsTr("Remaining") }
                                QGCLabel { text: qsTr("Voltage") }
                                QGCLabel { text: qsTr("Consumed");                              visible: batteryValuesAvailable.mahConsumedAvailable }
                                QGCLabel { text: qsTr("Temperature");                           visible: batteryValuesAvailable.temperatureAvailable }
                                QGCLabel { text: qsTr("Function");                              visible: batteryValuesAvailable.functionAvailable }
                            }
                        }
                    }

                    ColumnLayout {
                        Repeater {
                            model: _activeVehicle ? _activeVehicle.batteries : 0

                            ColumnLayout {
                                spacing: 0

                                property var batteryValuesAvailable: valueAvailableLoader.item

                                Loader {
                                    id:                 valueAvailableLoader
                                    sourceComponent:    batteryValuesAvailableComponent

                                    property var battery: object
                                }

                                QGCLabel { text: "" }
                                QGCLabel { text: object.chargeState.enumStringValue;                                        visible: batteryValuesAvailable.chargeStateAvailable }
                                QGCLabel { text: object.timeRemainingStr.value;                                             visible: batteryValuesAvailable.timeRemainingAvailable }
                                QGCLabel { text: object.percentRemaining.valueString + " " + object.percentRemaining.units }
                                QGCLabel { text: object.voltage.valueString + " " + object.voltage.units }
                                QGCLabel { text: object.mahConsumed.valueString + " " + object.mahConsumed.units;           visible: batteryValuesAvailable.mahConsumedAvailable }
                                QGCLabel { text: object.temperature.valueString + " " + object.temperature.units;           visible: batteryValuesAvailable.temperatureAvailable }
                                QGCLabel { text: object.function.enumStringValue;                                           visible: batteryValuesAvailable.functionAvailable }
                            }
                        }
                    }
                }
            }
        }
    }
}
