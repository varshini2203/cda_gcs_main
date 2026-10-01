import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.0

// ----------------------------------------------------------------------------
// CDA home screen (redesigned to match the approved mockup)
//   - sunset lake / mountain scene (drawn in code, or your own photo via
//     backgroundSource)
//   - navy header banner with logo, title and tagline (top-left)
//   - download icon (top-right) + small logout icon
//   - drone (top-right), centre badge, title, tagline, Start button
//   - frosted floating bottom navigation bar
//
// All sizes scale with the window through the "u" property.
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
    signal downloadClicked()

    property int currentNavIndex: 0

    // Optional image files. Leave empty to use the built-in drawings.
    // Example: property url backgroundSource: "qrc:/res/home_bg.jpg"
    property url backgroundSource: ""
    property url logoSource:       ""
    property url droneSource:      ""

    // Small logout icon next to the download icon (set false to hide it)
    property bool showLogout: true

    // Kept so existing bindings from other files do not break.
    // The new design does not show the telemetry panel any more.
    property string batteryText:  "87%"
    property string altitudeText: "120 m"
    property string speedText:    "12.4 m/s"

    readonly property color navy:          "#0B3C8C"
    readonly property color accent:        "#1E88E5"
    readonly property color accentDeep:    "#0F5FA8"
    readonly property color accentLight:   "#4FA3F0"
    readonly property color hairline:      "#D5E6F5"
    readonly property color textSecondary: "#5E7184"

    // UI scale (design size is about 960 x 560)
    readonly property real u: Math.max(0.7, Math.min(width / 960, height / 560))

    // ======================= Background ====================================
    Rectangle {
        anchors.fill: parent
        color: "#6FB0E6"
    }

    // Built-in sunset scene
    Canvas {
        id: scene
        anchors.fill: parent
        visible: homeScreen.backgroundSource == "" || bgImage.status !== Image.Ready
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d"); ctx.reset()
            var w = width, h = height
            if (w <= 0 || h <= 0) return
            var hz = h * 0.70

            var seed = 11
            function rnd() { seed = (seed * 9301 + 49297) % 233280; return seed / 233280 }

            function ridge(pts, baseY, fill) {
                ctx.beginPath()
                ctx.moveTo(pts[0][0] * w, baseY * h)
                ctx.lineTo(pts[0][0] * w, pts[0][1] * h)
                for (var i = 1; i < pts.length - 1; i++) {
                    var mx = (pts[i][0] + pts[i + 1][0]) / 2 * w
                    var my = (pts[i][1] + pts[i + 1][1]) / 2 * h
                    ctx.quadraticCurveTo(pts[i][0] * w, pts[i][1] * h, mx, my)
                }
                var l = pts[pts.length - 1]
                ctx.lineTo(l[0] * w, l[1] * h)
                ctx.lineTo(l[0] * w, baseY * h)
                ctx.closePath()
                ctx.fillStyle = fill
                ctx.fill()
            }

            function puff(x, y, r, a, col) {
                var g = ctx.createRadialGradient(x, y, 0, x, y, r)
                g.addColorStop(0, "rgba(" + col + "," + a + ")")
                g.addColorStop(1, "rgba(" + col + ",0)")
                ctx.fillStyle = g
                ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill()
            }
            function cloud(x, y, s, a, col) {
                puff(x,            y,            46 * s, a,        col)
                puff(x + 52 * s,   y - 12 * s,   58 * s, a,        col)
                puff(x + 108 * s,  y + 2 * s,    48 * s, a,        col)
                puff(x + 56 * s,   y + 14 * s,   64 * s, a * 0.8,  col)
            }

            // ---- sky ----
            var sky = ctx.createLinearGradient(0, 0, 0, hz)
            sky.addColorStop(0.00, "#2B7BD6")
            sky.addColorStop(0.45, "#63A8E4")
            sky.addColorStop(0.78, "#B5D3EE")
            sky.addColorStop(1.00, "#F3C890")
            ctx.fillStyle = sky
            ctx.fillRect(0, 0, w, hz + 2)

            // ---- sun glow ----
            var sx = w * 0.085, sy = h * 0.585
            var glow = ctx.createRadialGradient(sx, sy, 0, sx, sy, w * 0.45)
            glow.addColorStop(0.00, "rgba(255,246,205,1)")
            glow.addColorStop(0.07, "rgba(255,218,145,0.95)")
            glow.addColorStop(0.28, "rgba(255,172,102,0.45)")
            glow.addColorStop(1.00, "rgba(255,150,90,0)")
            ctx.fillStyle = glow
            ctx.fillRect(0, 0, w, hz + 2)

            // ---- clouds ----
            var cs = w / 960
            cloud(w * 0.00,  h * 0.22, 1.6 * cs, 0.85, "255,255,255")
            cloud(w * 0.33,  h * 0.05, 1.0 * cs, 0.70, "255,255,255")
            cloud(w * 0.60,  h * 0.10, 1.3 * cs, 0.80, "255,255,255")
            cloud(w * 0.80,  h * 0.46, 1.1 * cs, 0.75, "255,255,255")
            cloud(w * 0.02,  h * 0.46, 1.5 * cs, 0.70, "255,214,176")
            cloud(w * 0.20,  h * 0.36, 1.0 * cs, 0.55, "255,226,196")

            // ---- sun disc ----
            ctx.fillStyle = "rgba(255,251,228,0.98)"
            ctx.beginPath(); ctx.arc(sx, sy, w * 0.016, 0, Math.PI * 2); ctx.fill()

            // ---- far mountains (right peak) ----
            var mt = ctx.createLinearGradient(0, h * 0.55, 0, hz)
            mt.addColorStop(0, "rgba(92,118,158,0.92)")
            mt.addColorStop(1, "rgba(150,170,196,0.85)")
            ridge([[0.28, 0.70], [0.40, 0.665], [0.50, 0.625], [0.60, 0.580],
                   [0.66, 0.566], [0.72, 0.588], [0.80, 0.628], [0.90, 0.660],
                   [1.00, 0.690]], 0.72, mt)

            // ---- left hills behind the sun ----
            ridge([[0.00, 0.615], [0.06, 0.600], [0.14, 0.632], [0.24, 0.664],
                   [0.34, 0.700]], 0.72, "rgba(74,104,118,0.92)")

            // ---- lake ----
            var lake = ctx.createLinearGradient(0, 0, w, 0)
            lake.addColorStop(0.00, "#F3C18C")
            lake.addColorStop(0.30, "#CFCBC8")
            lake.addColorStop(0.65, "#93BCDE")
            lake.addColorStop(1.00, "#7EA9D0")
            ctx.fillStyle = lake
            ctx.fillRect(0, hz, w, h - hz)

            // ---- far shore + city (left) ----
            ridge([[0.00, 0.700], [0.10, 0.722], [0.22, 0.733], [0.33, 0.745],
                   [0.42, 0.754], [0.48, 0.765]], 0.765, "#6B7E5C")
            var bx = w * 0.10
            for (var i = 0; i < 10; i++) {
                var bw = 7 * cs + rnd() * 8 * cs
                var bh = 10 * cs + rnd() * 26 * cs
                ctx.fillStyle = "rgba(216,220,228,0.95)"
                ctx.fillRect(bx, h * 0.728 - bh, bw, bh + 4)
                bx += bw + 2 * cs
            }

            // ---- right shore hill ----
            var rh = ctx.createLinearGradient(0, h * 0.72, 0, h)
            rh.addColorStop(0, "#78914A")
            rh.addColorStop(1, "#2D5A2B")
            ridge([[0.34, 1.000], [0.46, 0.895], [0.55, 0.818], [0.70, 0.778], [0.84, 0.748],
                   [1.00, 0.722]], 1.0, rh)

            // ---- left foreground hill ----
            var lh = ctx.createLinearGradient(0, h * 0.76, 0, h)
            lh.addColorStop(0, "#4A7440")
            lh.addColorStop(1, "#1F441F")
            ridge([[0.00, 0.760], [0.07, 0.800], [0.17, 0.860], [0.30, 0.930],
                   [0.42, 1.000]], 1.0, lh)

            // ---- a few darker tree blobs on the foreground ----
            for (var t = 0; t < 70; t++) {
                var tx = rnd() * w * 0.4
                var ty = h * (0.80 + rnd() * 0.19)
                if (ty < h * (0.76 + 0.46 * (tx / w))) continue
                ctx.fillStyle = "rgba(24,62,26," + (0.35 + rnd() * 0.3) + ")"
                ctx.beginPath(); ctx.arc(tx, ty, (4 + rnd() * 7) * cs, 0, Math.PI * 2); ctx.fill()
            }
            for (var k = 0; k < 70; k++) {
                var kx = w * (0.55 + rnd() * 0.45)
                var ky = h * (0.76 + rnd() * 0.22)
                var topY = h * (0.90 - (kx / w - 0.46) / 0.54 * 0.178)
                if (ky < topY + 6 * cs) continue
                ctx.fillStyle = "rgba(34,78,32," + (0.30 + rnd() * 0.3) + ")"
                ctx.beginPath(); ctx.arc(kx, ky, (4 + rnd() * 7) * cs, 0, Math.PI * 2); ctx.fill()
            }

            // ---- soft vignette so white text stays readable ----
            var vg = ctx.createLinearGradient(0, 0, 0, h)
            vg.addColorStop(0.0, "rgba(10,40,100,0.18)")
            vg.addColorStop(0.5, "rgba(10,40,100,0)")
            vg.addColorStop(1.0, "rgba(0,20,10,0.15)")
            ctx.fillStyle = vg
            ctx.fillRect(0, 0, w, h)
        }
    }

    // Your own background photo (optional)
    Image {
        id: bgImage
        anchors.fill: parent
        source: homeScreen.backgroundSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
    }

    // ======================= Header banner =================================
    Canvas {
        id: banner
        anchors.top: parent.top
        anchors.left: parent.left
        width: Math.min(parent.width * 0.44, 430 * homeScreen.u)
        height: 66 * homeScreen.u
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d"); ctx.reset()
            var slant = 34 * homeScreen.u
            var g = ctx.createLinearGradient(0, 0, width, 0)
            g.addColorStop(0, "#0A3A88"); g.addColorStop(1, "#1565C0")
            ctx.fillStyle = g
            ctx.beginPath()
            ctx.moveTo(0, 0); ctx.lineTo(width, 0)
            ctx.lineTo(width - slant, height); ctx.lineTo(0, height)
            ctx.closePath(); ctx.fill()
        }

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 22 * homeScreen.u
            spacing: 14 * homeScreen.u

            // Logo image (when logoSource is set)
            Image {
                source: homeScreen.logoSource
                visible: status === Image.Ready
                Layout.preferredHeight: 48 * homeScreen.u
                Layout.preferredWidth: 92 * homeScreen.u
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            // Built-in logo (mini drone over "CDA")
            Column {
                visible: homeScreen.logoSource == ""
                spacing: 0
                Layout.alignment: Qt.AlignVCenter

                Canvas {
                    width: 40 * homeScreen.u; height: 14 * homeScreen.u
                    anchors.horizontalCenter: parent.horizontalCenter
                    onWidthChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset()
                        ctx.scale(width / 40, height / 14)
                        ctx.strokeStyle = "white"; ctx.fillStyle = "white"; ctx.lineWidth = 1.2
                        ctx.beginPath()
                        ctx.moveTo(6, 8); ctx.lineTo(16, 6); ctx.moveTo(34, 8); ctx.lineTo(24, 6)
                        ctx.stroke()
                        ctx.beginPath(); ctx.ellipse(1, 5, 11, 3); ctx.stroke()
                        ctx.beginPath(); ctx.ellipse(28, 5, 11, 3); ctx.stroke()
                        ctx.beginPath(); ctx.ellipse(15, 5, 10, 6); ctx.fill()
                    }
                }
                Text {
                    text: "CDA"
                    color: "white"
                    font.pixelSize: 28 * homeScreen.u
                    font.weight: Font.Bold
                    font.italic: true
                }
            }

            ColumnLayout {
                spacing: 2 * homeScreen.u
                Text {
                    text: "CHENNAI DRONE ACADEMY"
                    color: "white"
                    font.pixelSize: 15 * homeScreen.u
                    font.weight: Font.Bold
                    font.letterSpacing: 0.5
                }
                Text {
                    text: "Learn  \u2022  Build  \u2022  Fly"
                    color: "#D6E9FF"
                    font.pixelSize: 12 * homeScreen.u
                }
            }
        }
    }

    // ======================= Top-right icons ===============================
    Row {
        id: topIcons
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: (66 * homeScreen.u - height) / 2
        anchors.rightMargin: 28 * homeScreen.u
        spacing: 22 * homeScreen.u
        z: 10

        // Logout (small door-arrow icon)
        Item {
            visible: homeScreen.showLogout
            width: 26 * homeScreen.u; height: 26 * homeScreen.u

            Canvas {
                anchors.fill: parent
                onWidthChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    ctx.scale(width / 26, height / 26)
                    ctx.strokeStyle = "white"; ctx.lineWidth = 2.2
                    ctx.lineCap = "round"; ctx.lineJoin = "round"
                    ctx.beginPath()
                    ctx.moveTo(10, 4); ctx.lineTo(4, 4); ctx.lineTo(4, 22); ctx.lineTo(10, 22)
                    ctx.moveTo(10, 13); ctx.lineTo(22, 13)
                    ctx.moveTo(17, 8); ctx.lineTo(22, 13); ctx.lineTo(17, 18)
                    ctx.stroke()
                }
            }
            MouseArea {
                id: logoutMouse
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: AuthManager.logout()
                ToolTip.visible: containsMouse
                ToolTip.text: "Logout"
                ToolTip.delay: 400
            }
            opacity: logoutMouse.pressed ? 0.6 : 1.0
        }

        // Download
        Item {
            width: 28 * homeScreen.u; height: 28 * homeScreen.u

            Canvas {
                anchors.fill: parent
                onWidthChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    ctx.scale(width / 28, height / 28)
                    ctx.strokeStyle = "white"; ctx.lineWidth = 2.4
                    ctx.lineCap = "round"; ctx.lineJoin = "round"
                    ctx.beginPath()
                    ctx.moveTo(14, 3); ctx.lineTo(14, 17)
                    ctx.moveTo(8, 11.5); ctx.lineTo(14, 17.5); ctx.lineTo(20, 11.5)
                    ctx.moveTo(4, 18); ctx.lineTo(4, 24); ctx.lineTo(24, 24); ctx.lineTo(24, 18)
                    ctx.stroke()
                }
            }
            MouseArea {
                id: downloadMouse
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: homeScreen.downloadClicked()
                ToolTip.visible: containsMouse
                ToolTip.text: "Download"
                ToolTip.delay: 400
            }
            opacity: downloadMouse.pressed ? 0.6 : 1.0
        }
    }

    // ======================= Drone (top right) =============================
    Item {
        id: droneArea
        visible: homeScreen.width > 700
        width: 270 * homeScreen.u
        height: 156 * homeScreen.u
        anchors.right: parent.right
        anchors.rightMargin: homeScreen.width * 0.03
        anchors.top: parent.top
        anchors.topMargin: homeScreen.height * 0.11

        transform: Translate { id: droneFloat; y: 0 }
        SequentialAnimation {
            running: droneArea.visible
            loops: Animation.Infinite
            NumberAnimation { target: droneFloat; property: "y"; from: 0; to: -7 * homeScreen.u
                              duration: 2200; easing.type: Easing.InOutSine }
            NumberAnimation { target: droneFloat; property: "y"; from: -7 * homeScreen.u; to: 0
                              duration: 2200; easing.type: Easing.InOutSine }
        }

        Image {
            anchors.fill: parent
            source: homeScreen.droneSource
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: status === Image.Ready
        }

        Canvas {
            anchors.fill: parent
            visible: homeScreen.droneSource == ""
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d"); ctx.reset()
                ctx.scale(width / 260, height / 150)
                ctx.lineCap = "round"
                var cx = 130, cy = 80
                // rotor: [x, y, rx, ry]
                var rot = [[44, 70, 38, 8], [216, 52, 38, 8], [92, 36, 30, 6], [174, 30, 30, 6]]

                function rotor(r) {
                    ctx.fillStyle = "rgba(255,255,255,0.42)"
                    ctx.strokeStyle = "rgba(235,244,252,0.85)"; ctx.lineWidth = 1
                    ctx.beginPath(); ctx.ellipse(r[0] - r[2], r[1] - r[3], r[2] * 2, r[3] * 2)
                    ctx.fill(); ctx.stroke()
                    ctx.fillStyle = "#3A4656"
                    ctx.beginPath(); ctx.arc(r[0], r[1] + 3, 4.5, 0, Math.PI * 2); ctx.fill()
                }

                // arms
                ctx.strokeStyle = "#E3EAF1"; ctx.lineWidth = 6
                for (var i = 0; i < rot.length; i++) {
                    ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(rot[i][0], rot[i][1] + 4); ctx.stroke()
                }
                // far rotors
                rotor(rot[2]); rotor(rot[3])

                // landing legs
                ctx.strokeStyle = "#9AA7B5"; ctx.lineWidth = 3
                ctx.beginPath()
                ctx.moveTo(104, 96); ctx.lineTo(96, 116)
                ctx.moveTo(156, 96); ctx.lineTo(164, 116)
                ctx.stroke()

                // body
                var bg = ctx.createLinearGradient(0, 62, 0, 96)
                bg.addColorStop(0, "#FFFFFF"); bg.addColorStop(1, "#C3CEDA")
                ctx.fillStyle = bg; ctx.strokeStyle = "#B4C0CD"; ctx.lineWidth = 1.2
                ctx.beginPath(); ctx.ellipse(92, 62, 76, 36); ctx.fill(); ctx.stroke()
                ctx.fillStyle = "rgba(255,255,255,0.95)"
                ctx.beginPath(); ctx.ellipse(104, 64, 52, 15); ctx.fill()
                ctx.fillStyle = "#1E88E5"
                ctx.beginPath(); ctx.ellipse(112, 76, 36, 7); ctx.fill()

                // gimbal + lens
                ctx.strokeStyle = "#5C6877"; ctx.lineWidth = 3
                ctx.beginPath(); ctx.moveTo(130, 96); ctx.lineTo(130, 102); ctx.stroke()
                ctx.fillStyle = "#1B2230"
                ctx.beginPath(); ctx.arc(130, 108, 9, 0, Math.PI * 2); ctx.fill()
                ctx.fillStyle = "#5B8BD6"
                ctx.beginPath(); ctx.arc(130, 108, 4, 0, Math.PI * 2); ctx.fill()
                ctx.fillStyle = "rgba(255,255,255,0.8)"
                ctx.beginPath(); ctx.arc(128, 106, 1.4, 0, Math.PI * 2); ctx.fill()

                // near rotors
                rotor(rot[0]); rotor(rot[1])
            }
        }
    }

    // ======================= Centre content ================================
    ColumnLayout {
        id: centre
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -homeScreen.height * 0.045
        spacing: 8 * homeScreen.u

        // Badge: white disc, blue ring, drone icon
        Item {
            id: badge
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 104 * homeScreen.u
            Layout.preferredHeight: 104 * homeScreen.u

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "white"
                border.width: Math.max(2, 4 * homeScreen.u)
                border.color: "#1565C0"

                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#55104A9C"; radius: 14; samples: 29; verticalOffset: 4
                }
            }

            Canvas {
                anchors.centerIn: parent
                width: 62 * homeScreen.u; height: 62 * homeScreen.u
                onWidthChanged: requestPaint()
                onPaint: {
                    var ctx = getContext("2d"); ctx.reset()
                    ctx.scale(width / 56, height / 56)
                    ctx.lineWidth = 2.2
                    ctx.strokeStyle = homeScreen.accentDeep
                    ctx.fillStyle = homeScreen.accent
                    var cx = 28, cy = 28
                    ctx.beginPath()
                    ctx.moveTo(cx - 19, cy - 19); ctx.lineTo(cx - 6, cy - 6)
                    ctx.moveTo(cx + 19, cy - 19); ctx.lineTo(cx + 6, cy - 6)
                    ctx.moveTo(cx - 19, cy + 19); ctx.lineTo(cx - 6, cy + 6)
                    ctx.moveTo(cx + 19, cy + 19); ctx.lineTo(cx + 6, cy + 6)
                    ctx.stroke()
                    ctx.beginPath(); ctx.rect(cx - 6, cy - 3.5, 12, 7); ctx.fill()
                    var pts = [[cx - 19, cy - 19], [cx + 19, cy - 19], [cx - 19, cy + 19], [cx + 19, cy + 19]]
                    for (var i = 0; i < pts.length; i++) {
                        ctx.beginPath(); ctx.arc(pts[i][0], pts[i][1], 7.5, 0, Math.PI * 2); ctx.stroke()
                    }
                }
            }
        }

        // Title
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Chennai Drone Academy"
            font.pixelSize: 36 * homeScreen.u
            font.weight: Font.Bold
            color: "white"
            layer.enabled: true
            layer.effect: DropShadow {
                color: "#66062A66"; radius: 8; samples: 17; verticalOffset: 2
            }
        }

        // Tagline with side lines
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 14 * homeScreen.u
            Rectangle { width: 64 * homeScreen.u; height: 1; color: "white"; opacity: 0.75 }
            Text {
                text: "Learn  \u2022  Build  \u2022  Fly"
                font.pixelSize: 16 * homeScreen.u
                color: "white"
                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#55062A66"; radius: 6; samples: 13; verticalOffset: 1
                }
            }
            Rectangle { width: 64 * homeScreen.u; height: 1; color: "white"; opacity: 0.75 }
        }

        Item { Layout.preferredHeight: 10 * homeScreen.u }

        // Start button
        Rectangle {
            id: startButton
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 176 * homeScreen.u
            Layout.preferredHeight: 50 * homeScreen.u
            radius: height / 2

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#2E90F0" }
                GradientStop { position: 1.0; color: "#0B55B8" }
            }

            scale: startMouse.pressed ? 0.97 : 1.0
            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

            layer.enabled: true
            layer.effect: DropShadow {
                color: "#66104A9C"; radius: 14; samples: 29; verticalOffset: 5
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 10 * homeScreen.u

                Canvas {
                    Layout.preferredWidth: 13 * homeScreen.u
                    Layout.preferredHeight: 14 * homeScreen.u
                    Layout.alignment: Qt.AlignVCenter
                    onWidthChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d"); ctx.reset()
                        ctx.scale(width / 13, height / 14)
                        ctx.fillStyle = "white"
                        ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(13, 7); ctx.lineTo(0, 14)
                        ctx.closePath(); ctx.fill()
                    }
                }
                Text {
                    text: "Start"
                    color: "white"
                    font.pixelSize: 19 * homeScreen.u
                    font.weight: Font.DemiBold
                }
                Text {
                    text: "\u203A"
                    color: "#DCEBFF"
                    font.pixelSize: 24 * homeScreen.u
                }
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
        height: 66 * homeScreen.u
        radius: 26 * homeScreen.u
        color: "#B8FFFFFF"
        border.width: 1
        border.color: "#80FFFFFF"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 28 * homeScreen.u
        anchors.rightMargin: 28 * homeScreen.u
        anchors.bottomMargin: 20 * homeScreen.u

        layer.enabled: true
        layer.effect: DropShadow {
            color: "#33104A9C"; radius: 14; samples: 29; verticalOffset: 3
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 5 * homeScreen.u
            spacing: 4 * homeScreen.u

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
                        radius: 22 * homeScreen.u
                        color: navItem.active ? "#E6F1FC"
                                              : (navMouse.containsMouse ? "#66FFFFFF" : "transparent")
                        opacity: navItem.active ? 0.95 : 1.0
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 3 * homeScreen.u

                        Canvas {
                            id: navIcon
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 24 * homeScreen.u
                            Layout.preferredHeight: 24 * homeScreen.u
                            property bool isActive: navItem.active
                            onIsActiveChanged: requestPaint()
                            onWidthChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset()
                                ctx.scale(width / 24, height / 24)
                                var c = isActive ? homeScreen.accent : homeScreen.textSecondary
                                ctx.strokeStyle = c; ctx.fillStyle = c; ctx.lineWidth = 1.8
                                ctx.lineCap = "round"; ctx.lineJoin = "round"
                                var w = 24, h = 24

                                if (modelData.kind === "home") {
                                    ctx.beginPath()
                                    ctx.moveTo(3, 11.5); ctx.lineTo(12, 3.5); ctx.lineTo(21, 11.5)
                                    ctx.moveTo(5.5, 10); ctx.lineTo(5.5, 20.5); ctx.lineTo(18.5, 20.5); ctx.lineTo(18.5, 10)
                                    ctx.stroke()
                                    ctx.beginPath()
                                    ctx.rect(10, 14, 4, 6.5)
                                    ctx.stroke()
                                } else if (modelData.kind === "plan") {
                                    ctx.beginPath()
                                    ctx.moveTo(12, 21.5)
                                    ctx.bezierCurveTo(6, 15, 5, 12.5, 5, 10)
                                    ctx.arc(12, 9.5, 7, Math.PI, 0, false)
                                    ctx.bezierCurveTo(19, 12.5, 18, 15, 12, 21.5)
                                    ctx.closePath()
                                    if (isActive) ctx.fill(); else ctx.stroke()
                                    ctx.fillStyle = isActive ? "#E6F1FC" : "#FFFFFF"
                                    ctx.beginPath(); ctx.arc(12, 9.5, 2.4, 0, Math.PI * 2); ctx.fill()
                                    ctx.stroke()
                                } else if (modelData.kind === "analyze") {
                                    ctx.fillRect(4, 13, 4.5, 8)
                                    ctx.fillRect(9.8, 6, 4.5, 15)
                                    ctx.fillRect(15.6, 10, 4.5, 11)
                                } else if (modelData.kind === "settings") {
                                    ctx.beginPath()
                                    ctx.arc(w / 2, h / 2, 5.2, 0, Math.PI * 2)
                                    if (isActive) ctx.fill(); else ctx.stroke()
                                    for (var i = 0; i < 8; i++) {
                                        var a = (i / 8) * Math.PI * 2
                                        ctx.beginPath()
                                        ctx.moveTo(w / 2 + Math.cos(a) * 8,  h / 2 + Math.sin(a) * 8)
                                        ctx.lineTo(w / 2 + Math.cos(a) * 11, h / 2 + Math.sin(a) * 11)
                                        ctx.stroke()
                                    }
                                }
                            }
                        }

                        Text {
                            text: modelData.label
                            Layout.alignment: Qt.AlignHCenter
                            font.pixelSize: 11.5 * homeScreen.u
                            font.weight: navItem.active ? Font.DemiBold : Font.Normal
                            color: navItem.active ? homeScreen.accent : homeScreen.textSecondary
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 22 * homeScreen.u
                            Layout.preferredHeight: 2.5 * homeScreen.u
                            radius: height / 2
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
