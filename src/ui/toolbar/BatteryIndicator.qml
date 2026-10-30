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

    // CDA: number of LiPo cells in the drone battery (3S = 3, 4S = 4, 6S = 6 ...).
    // 0 = auto detect (reliable only up to 4S). Set it for 5S / 6S / 12S batteries.
    property int cellCount: 0

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
            property real fcPct:        battery.percentRemaining.rawValue   // % reported by the drone
            property real volts:        battery.voltage.rawValue            // pack voltage
            property real _estSmooth:   NaN                                 // % worked out from voltage (smoothed)
            property real _baseline:    NaN                                 // real % when the drone was armed
            property real _fcAtArm:     NaN                                 // drone's own % when it was armed
            property real pct:          computePct()
            property bool pctValid:     !isNaN(pct)
            // GREEN 100-60 %, YELLOW 60-30 %, RED 30-0 %
            property color pctColor:    !pctValid ? qgcPal.text : (pct > 60 ? "#22C55E" : (pct > 30 ? "#FACC15" : "#EF4444"))

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

            // LiPo resting voltage per cell -> percent (linear between points)
            function voltagePercent(packVoltage) {
                if (isNaN(packVoltage) || packVoltage <= 0) {
                    return NaN
                }
                var cells = _root.cellCount > 0 ? _root.cellCount : Math.max(1, Math.ceil(packVoltage / 4.25))
                var v     = packVoltage / cells
                var table = [[4.20, 100], [4.15, 95], [4.11, 90], [4.08, 85], [4.02, 80], [3.98, 75], [3.95, 70],
                             [3.91, 65], [3.87, 60], [3.85, 55], [3.84, 50], [3.82, 45], [3.80, 40], [3.79, 35],
                             [3.77, 30], [3.75, 25], [3.73, 20], [3.71, 15], [3.69, 10], [3.61, 5], [3.27, 0]]
                if (v >= table[0][0]) {
                    return 100
                }
                for (var i = 1; i < table.length; i++) {
                    if (v >= table[i][0]) {
                        var hi = table[i - 1], lo = table[i]
                        return lo[1] + (v - lo[0]) / (hi[0] - lo[0]) * (hi[1] - lo[1])
                    }
                }
                return 0
            }

            function clamp(v) {
                return Math.max(0, Math.min(100, v))
            }

            function updateEst() {
                var e = voltagePercent(battery.voltage.rawValue)
                if (isNaN(e)) {
                    return
                }
                _estSmooth = isNaN(_estSmooth) ? e : (_estSmooth * 0.85 + e * 0.15)
            }

            // Battery just plugged in / drone on the ground: ArduPilot always starts at 100 % after power-up,
            // so a half-empty battery also shows 100 %. The pack voltage tells the truth.
            // If the drone's % and the voltage % agree (smart battery) the drone's value is used.
            function restingPct() {
                var est = _estSmooth, fc = fcPct
                if (isNaN(est)) {
                    return fc
                }
                if (isNaN(fc)) {
                    return est
                }
                return Math.abs(fc - est) <= 10 ? fc : est
            }

            // In flight: real % at arm time minus what the drone has consumed since then.
            // Never shows more than the voltage allows (+15 % for voltage sag under load).
            function computePct() {
                var est = _estSmooth, fc = fcPct
                var v
                if (!armed) {
                    v = restingPct()
                } else if (isNaN(fc) || isNaN(_baseline) || isNaN(_fcAtArm)) {
                    v = isNaN(fc) ? est : fc
                } else {
                    v = _baseline - (_fcAtArm - fc)
                    if (!isNaN(est)) {
                        v = Math.min(v, est + 15)
                    }
                }
                return isNaN(v) ? NaN : clamp(v)
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

            onArmedChanged: {
                if (armed) {
                    _baseline = restingPct()
                    _fcAtArm  = fcPct
                }
            }

            Connections {
                target: battery.voltage
                function onRawValueChanged() { batRow.updateEst() }
            }

            Component.onCompleted: updateEst()

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

                //-- Voltage / charge line (green 100-60, yellow 60-30, red 30-0)
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
