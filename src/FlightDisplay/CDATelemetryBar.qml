import QtQuick                  2.12
import QtQuick.Layouts          1.12

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

// CDA fly-view telemetry panel
//   Left  : 2 rows  ->  [height icon] alt  climb-rate  /  [distance icon] dist  ground-speed
//   Right : flight timer (starts automatically when the drone takes off)
Rectangle {
    id:             root
    color:          "#D9081420"
    radius:         ScreenTools.defaultFontPixelWidth
    border.color:   locked ? "#80FFB020" : "#5538BDF8"
    border.width:   1.5
    implicitWidth:  main.width  + ScreenTools.defaultFontPixelWidth * 3
    implicitHeight: main.height + ScreenTools.defaultFontPixelHeight
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
    Component.onCompleted:  place()
    onWidthChanged:         place()
    onHeightChanged:        place()

    Connections {
        target: root.parent
        function onWidthChanged()  { root.place() }
        function onHeightChanged() { root.place() }
    }

    // ---------------- data ----------------
    property var    _vehicle:       QGroundControl.multiVehicleManager.activeVehicle
    property bool   _flying:        _vehicle ? _vehicle.flying : false
    property real   _startMs:       0
    property int    _elapsedSec:    0
    property real   _iconSize:      ScreenTools.defaultFontPixelHeight * 1.5

    // 0 = waiting for takeoff, 1 = flying, 2 = landed (shows last flight time)
    property int    _state:         !_vehicle ? 0 : (_flying ? 1 : (_elapsedSec > 0 ? 2 : 0))
    property color  _accent:        "#38BDF8"
    property color  _timerColor:    _state === 1 ? "#4ADE80" : (_state === 2 ? "#FBBF24" : "#8CA3B8")

    function _fmt(fact, decimals) {
        if (_vehicle && fact && fact.rawValue !== undefined && !isNaN(fact.rawValue)) {
            return fact.rawValue.toFixed(decimals)
        }
        return "--"
    }

    function _val(fact, decimals, unit) {
        return "<b>" + _fmt(fact, decimals) + "</b><span style='color:#7FD3F7; font-size:11px'> " + unit + "</span>"
    }

    function _two(n) { return (n < 10 ? "0" : "") + n }

    function _timeText(sec) {
        var h = Math.floor(sec / 3600)
        var m = Math.floor((sec % 3600) / 60)
        var s = sec % 60
        return _two(h) + ":" + _two(m) + ":" + _two(s)
    }

    // ---------------- flight timer ----------------
    on_FlyingChanged: {
        if (_flying) {
            _startMs    = Date.now()
            _elapsedSec = 0
            tick.start()
        } else {
            tick.stop()
        }
    }

    on_VehicleChanged: {
        if (!_vehicle) {
            tick.stop()
            _elapsedSec = 0
        }
    }

    Timer {
        id:         tick
        interval:   500
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
        spacing:            ScreenTools.defaultFontPixelWidth * 1.5

        //-------- left : 2 telemetry rows --------
        ColumnLayout {
            spacing: ScreenTools.defaultFontPixelHeight * 0.35

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
                    font.pointSize: ScreenTools.defaultFontPointSize * 1.15
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 9
                }
                QGCLabel {
                    text:       root._val(root._vehicle ? root._vehicle.climbRate : null, 1, "m/s")
                    textFormat: Text.RichText
                    color:      "white"
                    font.pointSize: ScreenTools.defaultFontPointSize * 1.15
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 10
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
                    font.pointSize: ScreenTools.defaultFontPointSize * 1.15
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 9
                }
                QGCLabel {
                    text:       root._val(root._vehicle ? root._vehicle.groundSpeed : null, 1, "m/s")
                    textFormat: Text.RichText
                    color:      "white"
                    font.pointSize: ScreenTools.defaultFontPointSize * 1.15
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 10
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
                    Layout.preferredWidth:  root._iconSize * 1.1
                    Layout.preferredHeight: root._iconSize * 1.1
                    property color tint:    root._timerColor
                    onTintChanged:          requestPaint()
                    onPaint:                root.drawIcon(getContext("2d"), "timer", width, tint)
                }

                QGCLabel {
                    text:           root._timeText(root._elapsedSec)
                    color:          root._timerColor
                    font.bold:      true
                    font.family:    "Consolas"
                    font.pointSize: ScreenTools.defaultFontPointSize * 1.6
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 11
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
                    text:           root._state === 1 ? qsTr("FLYING") : (root._state === 2 ? qsTr("LAST FLIGHT") : qsTr("FLIGHT TIME"))
                    color:          root._timerColor
                    font.pointSize: ScreenTools.defaultFontPointSize * 0.85
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
