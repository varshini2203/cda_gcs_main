import QtQuick                  2.12
import QtQuick.Layouts          1.12

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

// CDA fly-view telemetry panel
//   Left  : 2 rows  ->  [height icon] alt  climb-rate  /  [distance icon] dist  ground-speed
//   Right : flight timer (starts when the drone is armed, stops when disarmed, then shows LAST FLIGHT)
//   Values use QGC's own fact values + units, so they match the normal QGC telemetry (m/ft, m/s ...)
Rectangle {
    id:             root
    color:          "#D9081420"
    radius:         ScreenTools.defaultFontPixelWidth * 0.8
    border.color:   locked ? "#80FFB020" : "#5538BDF8"
    border.width:   1.5
    implicitWidth:  main.width  + ScreenTools.defaultFontPixelWidth * 2
    implicitHeight: main.height + ScreenTools.defaultFontPixelHeight * 0.6
    width:          implicitWidth
    height:         implicitHeight

    // ---------------- drag / lock (same behaviour as the compass) ----------------
    property bool   locked:     false       // double-click the panel to lock / unlock
    property bool   _moved:     false       // becomes true after you drag it once
    property bool   _focused:   dragArea.pressed || dragArea.containsMouse
    property real   _edgeMargin: ScreenTools.defaultFontPixelWidth * 0.75

    // slightly faded while idle, fully visible when you touch / hover it
    opacity: _focused ? 1.0 : 0.88
    Behavior on opacity { NumberAnimation { duration: 250 } }

    // default position: bottom centre (until the user drags it)
    function place() {
        if (!_moved && parent && parent.width > 0 && parent.height > 0) {
            x = (parent.width - width) / 2
            y = parent.height - height - _edgeMargin
        }
    }
    Component.onCompleted:  { place(); _syncTimer() }
    onWidthChanged:         place()
    onHeightChanged:        place()

    Connections {
        target: root.parent
        function onWidthChanged()  { root.place() }
        function onHeightChanged() { root.place() }
    }

    // ---------------- data ----------------
    property var    _vehicle:       QGroundControl.multiVehicleManager.activeVehicle
    property bool   _armed:         _vehicle ? _vehicle.armed : false
    property bool   _flying:        _vehicle ? _vehicle.flying : false
    property bool   _everArmed:     false
    property real   _startMs:       0
    property int    _elapsedSec:    0
    property real   _iconSize:      ScreenTools.defaultFontPixelHeight * 1.1
    property real   _valuePt:       ScreenTools.defaultFontPointSize * 0.95
    property real   _timerPt:       ScreenTools.defaultFontPointSize * 1.3

    // 0 = waiting for arm, 1 = running (armed), 2 = disarmed (shows last flight time)
    property int    _state:         !_vehicle ? 0 : (_armed ? 1 : (_everArmed ? 2 : 0))
    property color  _accent:        "#38BDF8"
    property color  _timerColor:    _state === 1 ? "#4ADE80" : (_state === 2 ? "#FBBF24" : "#8CA3B8")

    // number from a QGC Fact (cooked value, so ft / mph settings are respected). "--" when not available.
    function _fmt(fact, decimals) {
        if (_vehicle && fact && fact.value !== undefined && !isNaN(fact.value)) {
            return Number(fact.value).toFixed(decimals)
        }
        return "--"
    }

    function _unit(fact, fallback) {
        return (_vehicle && fact && fact.units) ? fact.units : fallback
    }

    function _val(fact, decimals, fallbackUnit) {
        return "<b>" + _fmt(fact, decimals) + "</b><span style='color:#7FD3F7; font-size:10px'> " + _unit(fact, fallbackUnit) + "</span>"
    }

    function _two(n) { return (n < 10 ? "0" : "") + n }

    function _timeText(sec) {
        var h = Math.floor(sec / 3600)
        var m = Math.floor((sec % 3600) / 60)
        var s = sec % 60
        return _two(h) + ":" + _two(m) + ":" + _two(s)
    }

    // ---------------- flight timer ----------------
    // Armed = drone started. The time is taken from the system clock (not by counting ticks),
    // so it stays accurate even if the UI lags. It is frozen at disarm and shown as LAST FLIGHT.
    function _syncTimer() {
        if (!_vehicle) {
            tick.stop()
            _elapsedSec = 0
            _everArmed  = false
            return
        }
        if (_armed) {
            if (!tick.running) {
                _startMs    = Date.now()
                _elapsedSec = 0
                tick.start()
            }
            _everArmed = true
        } else if (tick.running) {
            _elapsedSec = Math.floor((Date.now() - _startMs) / 1000)
            tick.stop()
        }
    }

    on_ArmedChanged: _syncTimer()

    on_VehicleChanged: {
        tick.stop()
        _elapsedSec = 0
        _everArmed  = false
        _syncTimer()
    }

    Timer {
        id:         tick
        interval:   250
        repeat:     true
        onTriggered: root._elapsedSec = Math.floor((Date.now() - root._startMs) / 1000)
    }

    // ---------------- icon painter ----------------
    function drawIcon(ctx, type, s, color) {
        ctx.reset()
        ctx.strokeStyle = color
        ctx.fillStyle   = color
        ctx.lineWidth   = Math.max(1.6, s * 0.09)
        ctx.lineCap     = "round"
        ctx.lineJoin    = "round"

        if (type === "height") {
            // up arrow standing on a ground line
            ctx.beginPath(); ctx.moveTo(s*0.15, s*0.90); ctx.lineTo(s*0.85, s*0.90); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(s*0.50, s*0.78); ctx.lineTo(s*0.50, s*0.28); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(s*0.50, s*0.08); ctx.lineTo(s*0.26, s*0.38); ctx.lineTo(s*0.74, s*0.38); ctx.closePath(); ctx.fill()
        } else if (type === "dist") {
            // double-headed arrow between two end caps
            ctx.beginPath(); ctx.moveTo(s*0.08, s*0.22); ctx.lineTo(s*0.08, s*0.78); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(s*0.92, s*0.22); ctx.lineTo(s*0.92, s*0.78); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(s*0.30, s*0.50); ctx.lineTo(s*0.70, s*0.50); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(s*0.16, s*0.50); ctx.lineTo(s*0.36, s*0.33); ctx.lineTo(s*0.36, s*0.67); ctx.closePath(); ctx.fill()
            ctx.beginPath(); ctx.moveTo(s*0.84, s*0.50); ctx.lineTo(s*0.64, s*0.33); ctx.lineTo(s*0.64, s*0.67); ctx.closePath(); ctx.fill()
        } else if (type === "timer") {
            // stopwatch
            ctx.beginPath(); ctx.arc(s*0.50, s*0.57, s*0.34, 0, Math.PI * 2); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(s*0.38, s*0.08); ctx.lineTo(s*0.62, s*0.08); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(s*0.50, s*0.08); ctx.lineTo(s*0.50, s*0.22); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(s*0.50, s*0.57); ctx.lineTo(s*0.50, s*0.36); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(s*0.50, s*0.57); ctx.lineTo(s*0.64, s*0.66); ctx.stroke()
        }
    }

    // ---------------- layout ----------------
    RowLayout {
        id:                 main
        anchors.centerIn:   parent
        spacing:            ScreenTools.defaultFontPixelWidth * 1.0

        //-------- left : 2 telemetry rows --------
        ColumnLayout {
            spacing: ScreenTools.defaultFontPixelHeight * 0.2

            // Row 1 : height + vertical speed
            RowLayout {
                spacing: ScreenTools.defaultFontPixelWidth

                Canvas {
                    Layout.preferredWidth:  root._iconSize
                    Layout.preferredHeight: root._iconSize
                    onPaint:                root.drawIcon(getContext("2d"), "height", width, root._accent)
                }
                QGCLabel {
                    text:       root._val(root._vehicle ? root._vehicle.altitudeRelative : null, 1, "m")
                    textFormat: Text.RichText
                    color:      "white"
                    font.pointSize: root._valuePt
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 7.5
                }
                QGCLabel {
                    text:       root._val(root._vehicle ? root._vehicle.climbRate : null, 1, "m/s")
                    textFormat: Text.RichText
                    color:      "white"
                    font.pointSize: root._valuePt
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8.5
                }
            }

            // Row 2 : distance + ground speed
            RowLayout {
                spacing: ScreenTools.defaultFontPixelWidth

                Canvas {
                    Layout.preferredWidth:  root._iconSize
                    Layout.preferredHeight: root._iconSize
                    onPaint:                root.drawIcon(getContext("2d"), "dist", width, root._accent)
                }
                QGCLabel {
                    text:       root._val(root._vehicle ? root._vehicle.distanceToHome : null, 0, "m")
                    textFormat: Text.RichText
                    color:      "white"
                    font.pointSize: root._valuePt
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 7.5
                }
                QGCLabel {
                    text:       root._val(root._vehicle ? root._vehicle.groundSpeed : null, 1, "m/s")
                    textFormat: Text.RichText
                    color:      "white"
                    font.pointSize: root._valuePt
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 8.5
                }
            }
        }

        //-------- divider --------
        Rectangle {
            Layout.preferredWidth:  1
            Layout.fillHeight:      true
            color:                  "#4038BDF8"
        }

        //-------- right : flight timer --------
        ColumnLayout {
            spacing: ScreenTools.defaultFontPixelHeight * 0.1

            RowLayout {
                spacing: ScreenTools.defaultFontPixelWidth * 0.7

                Canvas {
                    id:                     timerIcon
                    Layout.preferredWidth:  root._iconSize
                    Layout.preferredHeight: root._iconSize
                    property color tint:    root._timerColor
                    onTintChanged:          requestPaint()
                    onPaint:                root.drawIcon(getContext("2d"), "timer", width, tint)
                }

                QGCLabel {
                    text:           root._timeText(root._elapsedSec)
                    color:          root._timerColor
                    font.bold:      true
                    font.family:    "Consolas"
                    font.pointSize: root._timerPt
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 9
                }
            }

            RowLayout {
                Layout.alignment:   Qt.AlignHCenter
                spacing:            ScreenTools.defaultFontPixelWidth * 0.6

                Rectangle {
                    id:         liveDot
                    width:      ScreenTools.defaultFontPixelHeight * 0.5
                    height:     width
                    radius:     width / 2
                    color:      root._timerColor
                    SequentialAnimation on opacity {
                        running:    root._state === 1
                        loops:      Animation.Infinite
                        onRunningChanged: if (!running) liveDot.opacity = 1.0
                        NumberAnimation { to: 0.25; duration: 600 }
                        NumberAnimation { to: 1.0;  duration: 600 }
                    }
                    opacity: 1.0
                }
                QGCLabel {
                    text:           root._state === 1 ? (root._flying ? qsTr("FLYING") : qsTr("ARMED")) : (root._state === 2 ? qsTr("LAST FLIGHT") : qsTr("FLIGHT TIME"))
                    color:          root._timerColor
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.75
                    font.bold:      true
                }
            }
        }
    }

    MouseArea {
        id:             dragArea
        anchors.fill:   parent
        hoverEnabled:   true
        drag.target:    root.locked ? undefined : root
        drag.minimumX:  0
        drag.maximumX:  root.parent ? root.parent.width  - root.width  : 0
        drag.minimumY:  0
        drag.maximumY:  root.parent ? root.parent.height - root.height : 0
        cursorShape:    root.locked ? Qt.ArrowCursor : (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
        onDoubleClicked: root.locked = !root.locked
        drag.onActiveChanged: if (drag.active) root._moved = true
    }
}
