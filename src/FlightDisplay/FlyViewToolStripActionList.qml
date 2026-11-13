/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                      2.12
import QtQuick.Layouts              1.12
import QtQml.Models                 2.12
import Qt.labs.settings             1.0

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0

ToolStripActionList {
    id: _root

    signal displayPreFlightChecklist

    model: [
        ToolStripAction {
            text:           qsTr("Plan")
            iconSource:     "/qmlimages/Plan.svg"
            onTriggered:    mainWindow.showPlanView()
        },
        PreFlightCheckListShowAction { onTriggered: displayPreFlightChecklist() },
        GuidedActionTakeoff { },
        GuidedActionLand { },
        GuidedActionRTL { },
        GuidedActionPause { },
        GuidedActionActionList { },

        // ---------------------------------------------------------------
        // CDA: EKF Mode ON / OFF  (ArduPilot Copter, EKF3, 4.1+)
        //
        //   OFF = normal. The app writes NOTHING to the drone.
        //   ON  = Indoor (no GPS): EK3_SRC1_* -> Optical Flow, GPS_TYPE -> 0.
        //         The values that were on the drone before are saved first,
        //         and turning OFF restores exactly those values.
        // ---------------------------------------------------------------
        ToolStripAction {
            id:                 cdaEkfModeAction
            text:               qsTr("EKF Mode")
            iconSource:         "/qmlimages/Gps.svg"

            // !!! TEST ONLY: shows the button even without a drone.
            // !!! BEFORE REAL DRONE USE, replace "true" with the line below:
            // !!! _ekfVehicle ? (_ekfVehicle.apmFirmware && _ekfVehicle.multiRotor) : false
            visible:            true

            enabled:            true
            dropPanelComponent: cdaEkfDropPanel

            property var _ekfVehicle: QGroundControl.multiVehicleManager.activeVehicle

            property Component cdaEkfDropPanel: Component {

                ColumnLayout {
                    id:         ekfPanel
                    spacing:    ScreenTools.defaultFontPixelHeight * 0.5

                    QGCPalette { id: qgcPal; colorGroupEnabled: true }

                    FactPanelController { id: ekfController }

                    // Saved "before ON" values, one entry per drone (by hardware UID)
                    Settings {
                        id:         backupStore
                        category:   "CDAEkfModeBackup"
                        property string json: "{}"
                    }

                    // ---- parameters this feature manages ----
                    readonly property var _names:         [ "EK3_SRC1_POSXY", "EK3_SRC1_VELXY", "EK3_SRC1_POSZ", "EK3_SRC1_VELZ", "EK3_SRC1_YAW", "GPS_TYPE" ]
                    readonly property var _ek3Names:      [ "EK3_SRC1_POSXY", "EK3_SRC1_VELXY", "EK3_SRC1_POSZ", "EK3_SRC1_VELZ", "EK3_SRC1_YAW" ]
                    // ON preset: Optical Flow for XY, Baro for height, Compass yaw, GPS driver off
                    readonly property var _indoorValues:  ({ "EK3_SRC1_POSXY": 0, "EK3_SRC1_VELXY": 5, "EK3_SRC1_POSZ": 1, "EK3_SRC1_VELZ": 0, "EK3_SRC1_YAW": 1, "GPS_TYPE": 0 })
                    // ArduPilot factory defaults (only used if no saved backup exists)
                    readonly property var _defaultValues: ({ "EK3_SRC1_POSXY": 3, "EK3_SRC1_VELXY": 3, "EK3_SRC1_POSZ": 1, "EK3_SRC1_VELZ": 3, "EK3_SRC1_YAW": 1, "GPS_TYPE": 1 })

                    property var    _vehicle:       QGroundControl.multiVehicleManager.activeVehicle
                    property bool   _armed:         _vehicle ? _vehicle.armed : true
                    property bool   _paramsReady:   _vehicle ? _vehicle.parameterManager.parametersReady : false
                    property string _uid:           _vehicle ? _vehicle.vehicleUIDStr : ""
                    property string _pending:       ""      // "", "on", "off"
                    property bool   _rebootAsk:     false
                    property bool   _rebootNeeded:  false
                    property string _resultText:    ""

                    // Parameter value, or -1 if the parameter does not exist
                    function _val(name) {
                        if (!_vehicle || ekfController.vehicle !== _vehicle || !ekfController.parameterExists(-1, name)) {
                            return -1
                        }
                        return ekfController.getParameterFact(-1, name, false).rawValue
                    }

                    function _allPresent() {
                        for (var i = 0; i < _names.length; i++) {
                            if (_val(_names[i]) < 0) {
                                return false
                            }
                        }
                        return true
                    }

                    function _matches(values, names) {
                        for (var i = 0; i < names.length; i++) {
                            if (_val(names[i]) !== values[names[i]]) {
                                return false
                            }
                        }
                        return true
                    }

                    property bool _paramsOk:    _paramsReady && _allPresent()
                    property bool _ekf3Active:  _val("EK3_ENABLE") === 1 && _val("AHRS_EKF_TYPE") === 3
                    property bool _flowReady:   _val("FLOW_TYPE") > 0 && _val("RNGFND1_TYPE") > 0
                    property bool _isOn:        _paramsOk && _matches(_indoorValues, _names)

                    // Why can the switch NOT be used right now? ("" = it can)
                    function _blockReason(turningOn) {
                        if (!_vehicle)      return qsTr("No vehicle connected.")
                        if (!_paramsReady)  return qsTr("Parameters are still downloading. Please wait.")
                        if (_armed)         return qsTr("Vehicle is armed. Disarm first.")
                        if (!_paramsOk)     return qsTr("Required parameters not found (needs ArduCopter 4.1 or newer: EK3_SRC1_*, GPS_TYPE).")
                        if (turningOn) {
                            if (!_ekf3Active)   return qsTr("EKF3 is not active. Set EK3_ENABLE = 1 and AHRS_EKF_TYPE = 3, then reboot.")
                            if (!_flowReady)    return qsTr("Indoor needs an Optical Flow sensor and a Rangefinder. Set FLOW_TYPE and RNGFND1_TYPE, then reboot.")
                            if (_uid === "")    return qsTr("Vehicle ID not received yet. Wait a few seconds and reopen.")
                        }
                        return ""
                    }

                    // ---- backup store ----
                    function _loadAll() {
                        try { return JSON.parse(backupStore.json) } catch (e) { return {} }
                    }

                    function _saveBackupBeforeOn() {
                        var all = _loadAll()
                        // If the drone already has the Indoor EK3 values AND a backup exists, we were ON before: keep the old backup.
                        if (all[_uid] && _matches(_indoorValues, _ek3Names)) {
                            return
                        }
                        var b = {}
                        for (var i = 0; i < _names.length; i++) {
                            var n = _names[i]
                            var cur = _val(n)
                            // value already equals the ON value but we have no backup: assume factory default was the "before"
                            b[n] = (cur === _indoorValues[n] && _defaultValues[n] !== cur) ? _defaultValues[n] : cur
                        }
                        all[_uid] = b
                        backupStore.json = JSON.stringify(all)
                    }

                    function _writeValues(values) {
                        for (var i = 0; i < _names.length; i++) {
                            var n = _names[i]
                            ekfController.getParameterFact(-1, n, false).rawValue = values[n]
                        }
                    }

                    function _turnOn() {
                        if (_blockReason(true) !== "") {
                            _resultText = qsTr("Not applied: safety check failed.")
                            return
                        }
                        _saveBackupBeforeOn()
                        _writeValues(_indoorValues)
                        _rebootNeeded = true
                        _resultText = qsTr("EKF Mode ON written to the drone. Reboot the vehicle to apply it.")
                    }

                    function _turnOff() {
                        if (_blockReason(false) !== "") {
                            _resultText = qsTr("Not applied: safety check failed.")
                            return
                        }
                        var all = _loadAll()
                        var target = all[_uid] ? all[_uid] : _defaultValues
                        _writeValues(target)
                        _rebootNeeded = true
                        _resultText = all[_uid] ?
                                    qsTr("EKF Mode OFF. Your previous settings were restored. Reboot the vehicle to apply.") :
                                    qsTr("EKF Mode OFF. No saved backup found, so ArduPilot default values were used. Reboot the vehicle to apply.")
                    }

                    // Remove a saved backup once the drone really holds those values again (checked when the panel opens)
                    Component.onCompleted: {
                        if (!_uid || !_paramsOk || _isOn) {
                            return
                        }
                        var all = _loadAll()
                        var b = all[_uid]
                        if (b && _matches(b, _names)) {
                            delete all[_uid]
                            backupStore.json = JSON.stringify(all)
                        }
                    }

                    // ---------------- UI ----------------
                    readonly property real _panelWidth: ScreenTools.defaultFontPixelWidth * 40

                    QGCLabel {
                        text:               qsTr("EKF Mode")
                        font.bold:          true
                        Layout.fillWidth:   true
                    }

                    QGCLabel {
                        text:               !_paramsOk ? qsTr("Status: unknown") :
                                            _isOn ? qsTr("Status: ON  (Indoor, no GPS)") :
                                                    qsTr("Status: OFF  (normal, nothing changed)")
                        font.bold:          true
                        color:              _isOn ? qgcPal.colorGreen : qgcPal.text
                        Layout.fillWidth:   true
                    }

                    QGCLabel {
                        visible:            _blockReason(!_isOn) !== ""
                        text:               _blockReason(!_isOn)
                        color:              qgcPal.colorOrange
                        wrapMode:           Text.WordWrap
                        Layout.fillWidth:   true
                        Layout.preferredWidth: _panelWidth
                    }

                    QGCLabel {
                        visible:            _isOn && _blockReason(false) === ""
                        text:               qsTr("Indoor mode is ON: position comes from Optical Flow, GPS is disabled. RTL and other GPS modes will not work. Fly low in AltHold / Loiter.")
                        wrapMode:           Text.WordWrap
                        Layout.fillWidth:   true
                        Layout.preferredWidth: _panelWidth
                    }

                    QGCButton {
                        visible:            _pending === "" && _paramsOk
                        text:               _isOn ? qsTr("Turn OFF") : qsTr("Turn ON")
                        primary:            !_isOn
                        enabled:            _blockReason(!_isOn) === ""
                        onClicked: {
                            _resultText = ""
                            _rebootAsk = false
                            _pending = _isOn ? "off" : "on"
                        }
                    }

                    // ---- confirm step ----
                    QGCLabel {
                        visible:            _pending !== ""
                        text:               _pending === "on" ?
                                                qsTr("Turn EKF Mode ON?\n\n- Optical Flow is used instead of GPS\n- GPS is disabled (GPS_TYPE = 0)\n- Your current settings are saved first, OFF restores them exactly\n- Vehicle reboot needed afterwards") :
                                                qsTr("Turn EKF Mode OFF?\n\nYour settings from before ON are restored (GPS works as before). Vehicle reboot needed afterwards.")
                        wrapMode:           Text.WordWrap
                        Layout.fillWidth:   true
                        Layout.preferredWidth: _panelWidth
                    }

                    RowLayout {
                        visible:            _pending !== ""
                        spacing:            ScreenTools.defaultFontPixelWidth

                        QGCButton {
                            text:           qsTr("Confirm")
                            primary:        true
                            onClicked: {
                                var p = _pending
                                _pending = ""
                                if (p === "on") { _turnOn() } else { _turnOff() }
                            }
                        }

                        QGCButton {
                            text:           qsTr("Cancel")
                            onClicked:      _pending = ""
                        }
                    }

                    QGCLabel {
                        visible:            _resultText !== ""
                        text:               _resultText
                        wrapMode:           Text.WordWrap
                        Layout.fillWidth:   true
                        Layout.preferredWidth: _panelWidth
                    }

                    // ---- reboot (needed after every ON / OFF) ----
                    QGCButton {
                        visible:            _rebootNeeded && _pending === "" && !_rebootAsk
                        enabled:            _vehicle && !_armed
                        text:               qsTr("Reboot vehicle")
                        onClicked:          _rebootAsk = true
                    }

                    RowLayout {
                        visible:            _rebootAsk
                        spacing:            ScreenTools.defaultFontPixelWidth

                        QGCButton {
                            text:           qsTr("Yes, reboot now")
                            enabled:        _vehicle && !_armed
                            onClicked: {
                                _rebootAsk = false
                                _rebootNeeded = false
                                _vehicle.rebootVehicle()
                            }
                        }

                        QGCButton {
                            text:           qsTr("Cancel")
                            onClicked:      _rebootAsk = false
                        }
                    }
                }
            }
        }
    ]
}