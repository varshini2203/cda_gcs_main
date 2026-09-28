import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.0

// ----------------------------------------------------------------------------
// CDA home screen: sky scene, header banner, telemetry panel, drone, compass,
// centre badge with Start button and a floating bottom navigation bar.
// The old "glow circle" (badgeGlow + FastBlur) has been removed.
// ----------------------------------------------------------------------------
Item {
    id: homeScreen
    anchors.fill: parent

    signal startClicked()
    signal enterApp()
    signal homeClicked()
    signal planClicked()
    signal analyzeClicked()
    signal settingsClicked()

    property int currentNavIndex: 0

    // Optional image files (leave empty to use the built-in drawings).
    // Example: property url logoSource: "qrc:/res/CDALogo.png"
    property url backgroundSource: ""
    property url logoSource:       ""
    property url droneSource:      ""

    // Demo telemetry values shown in the top-left panel
    property string batteryText:  "87%"
    property string altitudeText: "120 m"
    property string speedText:    "12.4 m/s"

    readonly property color navy:        "#0A3D91"
    readonly property color accent:      "#1E88E5"
    readonly property color accentDeep:  "#0F5FA8"
    readonly property color accentLight: "#64B5F6"
    readonly property color panel:       "#FFFFFF"
    readonly property color hairline:    "#D5E6F5"
    readonly property color textSecondary: "#6C8AA5"
    readonly property real  navHeight:   84

    // ======================= Background scene ==============================
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0;  color: "#1F7FD6" }
            GradientStop { position: 0.55; color: "#7FC4F2" }
            GradientStop { position: 1.0;  color: "#E3F4FD" }
        }
    }

    Image {
        anchors.fill: parent
        source: homeScreen.backgroundSource
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
    }

    // Clouds
    Repeater {
        model: [ { x: 0.04, y: 0.30, s: 1.2 }, { x: 0.70, y: 0.44, s: 1.0 },
                 { x: 0.38, y: 0.14, s: 0.7 }, { x: 0.86, y: 0.20, s: 0.7 } ]
        delegate: Item {
            x: homeScreen.width  * modelData.x
            y: homeScreen.height * modelData.y
            width: 220 * modelData.s; height: 70 * modelData.s
            opacity: 0.8
            Rectangle { x: 0; y: parent.height * 0.35; width: parent.width * 0.8; height: parent.height * 0.55; radius: height / 2; color: "white" }
            Rectangle { x: parent.width * 0.2; y: 0; width: parent.width * 0.5; height: parent.height * 0.8; radius: height / 2; color: "white" }
            Rectangle { x: parent.width * 0.5; y: parent.height * 0.25; width: parent.width * 0.5; height: parent.height * 0.6; radius: height / 2; color: "white" }
        }
    }

    // Mountains, sea and city skyline
    Canvas {
        id: landscape
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: parent.height * 0.34
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d"); ctx.reset()
            var w = width, h = height
            var sea = ctx.createLinearGradient(0, h * 0.55, 0, h)
            sea.addColorStop(0, "#9FD0F0"); sea.addColorStop(1, "#DDF0FB")
            // far mountains
            ctx.fillStyle = "rgba(120,165,215,0.55)"
            ctx.beginPath(); ctx.moveTo(0, h * 0.6)
            ctx.lineTo(w * 0.10, h * 0.32); ctx.lineTo(w * 0.22, h * 0.5); ctx.lineTo(w * 0.34, h * 0.28)
            ctx.lineTo(w * 0.48, h * 0.55); ctx.lineTo(w * 0.62, h * 0.4); ctx.lineTo(w * 0.78, h * 0.52)
            ctx.lineTo(w * 0.90, h * 0.3); ctx.lineTo(w, h * 0.5); ctx.lineTo(w, h * 0.6); ctx.closePath(); ctx.fill()
            // near hills
            ctx.fillStyle = "rgba(95,145,200,0.65)"
            ctx.beginPath(); ctx.moveTo(0, h * 0.62)
            ctx.lineTo(w * 0.15, h * 0.5); ctx.lineTo(w * 0.3, h * 0.6); ctx.lineTo(w * 0.7, h * 0.6)
            ctx.lineTo(w * 0.85, h * 0.48); ctx.lineTo(w, h * 0.6); ctx.lineTo(w, h * 0.62); ctx.closePath(); ctx.fill()
            // city skyline (left)
            ctx.fillStyle = "rgba(90,135,190,0.8)"
            var bx = w * 0.03
            var bh = [26, 40, 32, 52, 36, 46, 30, 22]
            for (var i = 0; i < bh.length; i++) {
                ctx.fillRect(bx, h * 0.62 - bh[i], 14, bh[i]); bx += 17
            }
            // sea
            ctx.fillStyle = sea
            ctx.fillRect(0, h * 0.62, w, h * 0.38)
        }
    }

    // ======================= Header banner =================================
    Canvas {
        id: banner
        anchors.top: parent.top
        anchors.left: parent.left
        width: Math.min(parent.width * 0.5, 520)
        height: 68
        onWidthChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d"); ctx.reset()
            var g = ctx.createLinearGradient(0, 0, width, 0)
            g.addColorStop(0, "#0A3D91"); g.addColorStop(1, "#1E88E5")
            ctx.fillStyle = g
            ctx.beginPath()
            ctx.moveTo(0, 0); ctx.lineTo(width, 0); ctx.lineTo(width - 44, height); ctx.lineTo(0, height)
            ctx.closePath(); ctx.fill()
        }

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 18
            spacing: 12

            Image {
                source: homeScreen.logoSource
                visible: status === Image.Ready
                Layout.preferredHeight: 44
                Layout.preferredWidth: 90
                fillMode: Image.PreserveAspectFit
            }
            Text {
                visible: homeScreen.logoSource == ""
                text: "CDA"
                color: "white"
                font.pixelSize: 30
                font.weight: Font.Bold
            }
            Rectangle { width: 1; height: 38; color: "#80FFFFFF" }
            ColumnLayout {
                spacing: 2
                Text {
                    text: "CHENNAI DRONE ACADEMY"
                    color: "white"
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    font.letterSpacing: 0.5
                }
                Text {
                    text: "Learn  \u2022  Build  \u2022  Fly"
                    color: "#CFE8FF"
                    font.pixelSize: 12
                }
            }
        }
    }

    // ======================= Logout button =================================
    Rectangle {
        id: logoutButton
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 16
        anchors.rightMargin: 20
        width: logoutRow.implicitWidth + 28
        height: 36
        radius: 18
        color: logoutMouse.pressed ? "#E3F1FD" : homeScreen.panel
        border.width: 1
        border.color: homeScreen.hairline
        z: 10

        RowLayout {
            id: logoutRow
            anchors.centerIn: parent
            spacing: 6

            Canvas {
                width: 14; height: 14
                Layout.alignment: Qt.AlignVCenter
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    ctx.strokeStyle = homeScreen.accent
                    ctx.lineWidth = 1.6
                    ctx.strokeRect(1, 1, 7, 12)
                    ctx.beginPath()
                    ctx.moveTo(5, 7); ctx.lineTo(13, 7)
                    ctx.moveTo(9.5, 3.5); ctx.lineTo(13, 7); ctx.lineTo(9.5, 10.5)
                    ctx.stroke()
                }
            }
            Text {
                text: "Logout"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: homeScreen.navy
            }
        }

        MouseArea {
            id: logoutMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: AuthManager.logout()
        }
    }

    // ======================= Telemetry panel ===============================
    Rectangle {
        id: telemetry
        visible: homeScreen.width > 760
        anchors.left: parent.left
        anchors.leftMargin: 22
        anchors.top: banner.bottom
        anchors.topMargin: 22
        width: 170
        height: telemetryCol.implicitHeight + 24
        radius: 12
        color: "#33FFFFFF"
        border.width: 1
        border.color: "#66FFFFFF"

        Column {
            id: telemetryCol
            anchors.centerIn: parent
            spacing: 12

            Row {
                spacing: 12
                Text { text: "GPS"; width: 36; color: "#E8F4FF"; font.pixelSize: 12 }
                Row {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    Repeater {
                        model: 4
                        Rectangle { width: 4; height: 4 + index * 3; anchors.bottom: parent.bottom; radius: 1; color: "white" }
                    }
                }
            }
            Row { spacing: 12
                Text { text: "BAT"; width: 36; color: "#E8F4FF"; font.pixelSize: 12 }
                Text { text: homeScreen.batteryText; color: "white"; font.pixelSize: 12; font.weight: Font.DemiBold } }
            Row { spacing: 12
                Text { text: "ALT"; width: 36; color: "#E8F4FF"; font.pixelSize: 12 }
                Text { text: homeScreen.altitudeText; color: "white"; font.pixelSize: 12; font.weight: Font.DemiBold } }
            Row { spacing: 12
                Text { text: "SPD"; width: 36; color: "#E8F4FF"; font.pixelSize: 12 }
                Text { text: homeScreen.speedText; color: "white"; font.pixelSize: 12; font.weight: Font.DemiBold } }
        }
    }

    // ======================= Drone (top right) =============================
    Item {
        id: droneArea
        visible: homeScreen.width > 760
        width: 250; height: 120
        anchors.right: parent.right
        anchors.rightMargin: homeScreen.width * 0.12
        anchors.top: parent.top
        anchors.topMargin: 84

        Image {
            anchors.fill: parent
            source: homeScreen.droneSource
            fillMode: Image.PreserveAspectFit
            visible: status === Image.Ready
        }

        Canvas {
            anchors.fill: parent
            visible: homeScreen.droneSource == ""
            onPaint: {
                var ctx = getContext("2d"); ctx.reset()
                var cx = width / 2, cy = height * 0.55
                // motion swoosh
                ctx.strokeStyle = "rgba(255,255,255,0.7)"; ctx.lineWidth = 2
                ctx.beginPath(); ctx.moveTo(cx - 20, cy + 40); ctx.quadraticCurveTo(cx + 60, cy + 55, cx + 120, cy + 20); ctx.stroke()
                // arms
                ctx.strokeStyle = "#EEF4FA"; ctx.lineWidth = 5; ctx.lineCap = "round"
                var tips = [[-95, -22], [95, -22], [-78, 18], [78, 18]]
                for (var i = 0; i < tips.length; i++) {
                    ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(cx + tips[i][0], cy + tips[i][1]); ctx.stroke()
                }
                // rotors
                for (var j = 0; j < tips.length; j++) {
                    ctx.fillStyle = "rgba(255,255,255,0.55)"
                    ctx.strokeStyle = "rgba(200,220,240,0.9)"; ctx.lineWidth = 1
                    ctx.beginPath(); ctx.ellipse(cx + tips[j][0] - 32, cy + tips[j][1] - 5, 64, 10)
                    ctx.fill(); ctx.stroke()
                    ctx.fillStyle = "#1E88E5"
                    ctx.beginPath(); ctx.arc(cx + tips[j][0], cy + tips[j][1], 3.5, 0, Math.PI * 2); ctx.fill()
                }
                // body
                ctx.fillStyle = "#FFFFFF"; ctx.strokeStyle = "#C9D6E4"; ctx.lineWidth = 1.5
                ctx.beginPath(); ctx.ellipse(cx - 30, cy - 14, 60, 30); ctx.fill(); ctx.stroke()
                ctx.fillStyle = "#1E88E5"
                ctx.beginPath(); ctx.ellipse(cx - 16, cy - 6, 32, 10); ctx.fill()
                // camera
                ctx.fillStyle = "#1B2A41"
                ctx.beginPath(); ctx.arc(cx, cy + 20, 9, 0, Math.PI * 2); ctx.fill()
                ctx.fillStyle = "#64B5F6"
                ctx.beginPath(); ctx.arc(cx, cy + 20, 4, 0, Math.PI * 2); ctx.fill()
            }
        }
    }

    // ======================= Compass (right) ===============================
    Canvas {
        id: compass
        visible: homeScreen.width > 760
        width: 112; height: 112
        anchors.right: parent.right
        anchors.rightMargin: 32
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -20
        onPaint: {
            var ctx = getContext("2d"); ctx.reset()
            var cx = width / 2, cy = height / 2, r = width / 2 - 4
            ctx.fillStyle = "rgba(255,255,255,0.14)"
            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill()
            ctx.strokeStyle = "rgba(255,255,255,0.85)"; ctx.lineWidth = 1.5
            ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke()
            for (var i = 0; i < 24; i++) {
                var a = i / 24 * Math.PI * 2
                var r1 = r - (i % 6 === 0 ? 9 : 5)
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r)
                ctx.lineTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1)
                ctx.stroke()
            }
            ctx.fillStyle = "white"; ctx.font = "bold 10px sans-serif"; ctx.textAlign = "center"
            ctx.fillText("N", cx, cy - r + 22); ctx.fillText("S", cx, cy + r - 14)
            ctx.fillText("E", cx + r - 15, cy + 4); ctx.fillText("W", cx - r + 15, cy + 4)
            ctx.fillStyle = "white"
            ctx.beginPath()
            ctx.moveTo(cx, cy - 16); ctx.lineTo(cx + 10, cy + 12); ctx.lineTo(cx, cy + 5); ctx.lineTo(cx - 10, cy + 12)
            ctx.closePath(); ctx.fill()
        }
    }

    // ======================= Centre content ================================
    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -24
        spacing: 16

        // Instrument badge
        Item {
            id: badge
            Layout.alignment: Qt.AlignHCenter
            width: 156; height: 156

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    var cx = width / 2, cy = height / 2, r = width / 2 - 6
                    ctx.fillStyle = "rgba(255,255,255,0.25)"
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.fill()
                    ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.lineWidth = 1.5; ctx.strokeStyle = "rgba(255,255,255,0.9)"; ctx.stroke()
                    ctx.strokeStyle = "rgba(15,95,168,0.75)"
                    for (var i = 0; i < 36; i++) {
                        var a = (i / 36) * Math.PI * 2
                        var r1 = r - (i % 9 === 0 ? 12 : 6)
                        ctx.beginPath()
                        ctx.moveTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r)
                        ctx.lineTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1)
                        ctx.lineWidth = (i % 9 === 0) ? 1.8 : 1
                        ctx.stroke()
                    }
                    ctx.beginPath(); ctx.arc(cx, cy, r + 3, Math.PI * 1.15, Math.PI * 1.7)
                    ctx.lineWidth = 3; ctx.strokeStyle = "#1E88E5"; ctx.stroke()
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 100; height: 100; radius: width / 2
                color: "white"
                border.width: 1
                border.color: homeScreen.hairline

                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#401E88E5"; radius: 12; samples: 25; verticalOffset: 3
                }

                Canvas {
                    anchors.centerIn: parent
                    width: 56; height: 56
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset()
                        ctx.lineWidth = 2
                        ctx.strokeStyle = homeScreen.accentDeep
                        ctx.fillStyle = homeScreen.accent
                        var cx = width / 2, cy = height / 2
                        ctx.beginPath()
                        ctx.moveTo(cx - 19, cy - 19); ctx.lineTo(cx - 6, cy - 6)
                        ctx.moveTo(cx + 19, cy - 19); ctx.lineTo(cx + 6, cy - 6)
                        ctx.moveTo(cx - 19, cy + 19); ctx.lineTo(cx - 6, cy + 6)
                        ctx.moveTo(cx + 19, cy + 19); ctx.lineTo(cx + 6, cy + 6)
                        ctx.stroke()
                        ctx.beginPath(); ctx.rect(cx - 6, cy - 3.5, 12, 7); ctx.fill()
                        var pts = [[cx - 19, cy - 19], [cx + 19, cy - 19], [cx - 19, cy + 19], [cx + 19, cy + 19]]
                        for (var i = 0; i < pts.length; i++) {
                            ctx.beginPath(); ctx.arc(pts[i][0], pts[i][1], 7, 0, Math.PI * 2); ctx.stroke()
                        }
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Chennai Drone Academy"
            font.pixelSize: 34
            font.weight: Font.Bold
            color: homeScreen.navy
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 14
            Rectangle { width: 56; height: 1; color: homeScreen.accentDeep; opacity: 0.6 }
            Text {
                text: "Learn  \u2022  Build  \u2022  Fly"
                font.pixelSize: 15
                color: homeScreen.accentDeep
            }
            Rectangle { width: 56; height: 1; color: homeScreen.accentDeep; opacity: 0.6 }
        }

        Item { Layout.preferredHeight: 4 }

        // Start button
        Rectangle {
            id: startButton
            Layout.alignment: Qt.AlignHCenter
            width: 210; height: 58; radius: 29

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: homeScreen.accentLight }
                GradientStop { position: 1.0; color: homeScreen.accentDeep }
            }

            scale: startMouse.pressed ? 0.97 : 1.0
            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

            layer.enabled: true
            layer.effect: DropShadow {
                color: "#551E88E5"; radius: 14; samples: 29; verticalOffset: 6
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 12

                Canvas {
                    width: 14; height: 14
                    Layout.alignment: Qt.AlignVCenter
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset()
                        ctx.fillStyle = "white"
                        ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(14, 7); ctx.lineTo(0, 14)
                        ctx.closePath(); ctx.fill()
                    }
                }
                Text { text: "Start"; color: "white"; font.pixelSize: 19; font.weight: Font.DemiBold }
                Text { text: "\u203A"; color: "#CFE8FF"; font.pixelSize: 26 }
            }

            MouseArea {
                id: startMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    homeScreen.startClicked()
                    homeScreen.enterApp()
                }
            }
        }
    }

    // ======================= Bottom navigation =============================
    Rectangle {
        id: navBar
        height: homeScreen.navHeight - 8
        radius: 22
        color: homeScreen.panel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.bottomMargin: 8

        layer.enabled: true
        layer.effect: DropShadow {
            color: "#331E88E5"; radius: 12; samples: 25; verticalOffset: -2
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            Repeater {
                model: [
                    { label: "Home",     kind: "home" },
                    { label: "Plan",     kind: "plan" },
                    { label: "Analyze",  kind: "analyze" },
                    { label: "Settings", kind: "settings" }
                ]

                delegate: Item {
                    id: navItem
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    property bool active: index === homeScreen.currentNavIndex

                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: navItem.active ? "#E3F1FD" : (navMouse.containsMouse ? "#F1F8FE" : "transparent")
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        Canvas {
                            id: navIcon
                            Layout.alignment: Qt.AlignHCenter
                            width: 24; height: 24
                            property bool isActive: navItem.active
                            onIsActiveChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset()
                                var c = isActive ? homeScreen.accent : homeScreen.textSecondary
                                ctx.strokeStyle = c; ctx.fillStyle = c; ctx.lineWidth = 1.9
                                var w = width, h = height

                                if (modelData.kind === "home") {
                                    ctx.beginPath()
                                    ctx.moveTo(2, 12); ctx.lineTo(w / 2, 2); ctx.lineTo(w - 2, 12)
                                    ctx.stroke()
                                    if (isActive) ctx.fillRect(5, 12, w - 10, h - 14)
                                    else ctx.strokeRect(5, 12, w - 10, h - 14)
                                } else if (modelData.kind === "plan") {
                                    ctx.beginPath()
                                    ctx.arc(w / 2, h / 2 - 2, 7, 0, Math.PI * 2)
                                    if (isActive) ctx.fill(); else ctx.stroke()
                                    ctx.beginPath()
                                    ctx.moveTo(w / 2 - 5, h / 2 + 4); ctx.lineTo(w / 2, h - 2); ctx.lineTo(w / 2 + 5, h / 2 + 4)
                                    ctx.stroke()
                                } else if (modelData.kind === "analyze") {
                                    ctx.fillRect(3, h - 10, 5, 10)
                                    ctx.fillRect(w / 2 - 2.5, h - 16, 5, 16)
                                    ctx.fillRect(w - 8, h - 7, 5, 7)
                                } else if (modelData.kind === "settings") {
                                    ctx.beginPath()
                                    ctx.arc(w / 2, h / 2, 6, 0, Math.PI * 2)
                                    if (isActive) ctx.fill(); else ctx.stroke()
                                    for (var i = 0; i < 8; i++) {
                                        var a = (i / 8) * Math.PI * 2
                                        ctx.beginPath()
                                        ctx.moveTo(w / 2 + Math.cos(a) * 8, h / 2 + Math.sin(a) * 8)
                                        ctx.lineTo(w / 2 + Math.cos(a) * 11, h / 2 + Math.sin(a) * 11)
                                        ctx.stroke()
                                    }
                                }
                            }
                        }

                        Text {
                            text: modelData.label
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: 12
                            font.weight: navItem.active ? Font.DemiBold : Font.Normal
                            color: navItem.active ? homeScreen.accent : homeScreen.textSecondary
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 22; height: 3; radius: 1.5
                            color: homeScreen.accent
                            opacity: navItem.active ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                        }
                    }

                    MouseArea {
                        id: navMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            homeScreen.currentNavIndex = index
                            switch (modelData.label) {
                            case "Home":     homeScreen.homeClicked();     break
                            case "Plan":     homeScreen.planClicked();     break
                            case "Analyze":  homeScreen.analyzeClicked();  break
                            case "Settings": homeScreen.settingsClicked(); break
                            }
                        }
                    }
                }
            }
        }
    }
}
