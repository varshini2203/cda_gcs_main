import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.0

// ----------------------------------------------------------------------------
// Light blue / white instrument-panel home screen.
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

    readonly property color skyTop:       "#E4F2FC"
    readonly property color skyBottom:    "#FFFFFF"
    readonly property color panel:        "#FFFFFF"
    readonly property color hairline:     "#D5E6F5"
    readonly property color textPrimary:  "#0F2A44"
    readonly property color textSecondary:"#6C8AA5"
    readonly property color accent:       "#1E88E5"
    readonly property color accentDeep:   "#0F5FA8"
    readonly property color accentLight:  "#64B5F6"

    // ---- Background -----------------------------------------------------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: homeScreen.skyTop }
            GradientStop { position: 1.0; color: homeScreen.skyBottom }
        }
    }

    // ---- Logout button -----------------------------------------------
    Rectangle {
        id: logoutButton
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 18
        anchors.rightMargin: 20
        width: logoutRow.implicitWidth + 24
        height: 36
        radius: 18
        color: logoutMouse.pressed ? "#F0F8FD" : homeScreen.panel
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
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = homeScreen.textSecondary
                    ctx.lineWidth = 1.6
                    // door frame
                    ctx.strokeRect(1, 1, 7, 12)
                    // arrow out
                    ctx.beginPath()
                    ctx.moveTo(5, 7); ctx.lineTo(13, 7)
                    ctx.moveTo(9.5, 3.5); ctx.lineTo(13, 7); ctx.lineTo(9.5, 10.5)
                    ctx.stroke()
                }
            }

            Text {
                text: "Logout"
                font.pixelSize: 13
                font.weight: Font.Medium
                color: homeScreen.textSecondary
            }
        }

        MouseArea {
            id: logoutMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: AuthManager.logout()
        }
    }

    // Soft glow behind the badge
    Rectangle {
        id: badgeGlow
        width: 480; height: 480; radius: width / 2
        anchors.centerIn: badge
        color: homeScreen.accentLight
        opacity: 0.14
        visible: false
    }
    FastBlur {
        anchors.fill: badgeGlow
        source: badgeGlow
        radius: 64
    }

    // ---- Center content ---------------------------------------------------
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 26

        // ---- Instrument badge ----------------------------------------
        Item {
            id: badge
            Layout.alignment: Qt.AlignHCenter
            width: 148; height: 148

            Canvas {
                id: ring
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var cx = width / 2, cy = height / 2, r = width / 2 - 6

                    // outer bezel
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.lineWidth = 1.5
                    ctx.strokeStyle = homeScreen.hairline
                    ctx.stroke()

                    // tick marks
                    ctx.strokeStyle = homeScreen.textSecondary
                    for (var i = 0; i < 36; i++) {
                        var a = (i / 36) * Math.PI * 2
                        var isLong = i % 9 === 0
                        var r1 = r - (isLong ? 12 : 6)
                        ctx.beginPath()
                        ctx.moveTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r)
                        ctx.lineTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1)
                        ctx.lineWidth = isLong ? 1.6 : 1
                        ctx.stroke()
                    }

                    // accent status arc (top-left quadrant)
                    ctx.beginPath()
                    ctx.arc(cx, cy, r + 4, Math.PI * 1.15, Math.PI * 1.55)
                    ctx.lineWidth = 2.4
                    ctx.strokeStyle = homeScreen.accent
                    ctx.stroke()
                }
            }

            Rectangle {
                id: hub
                anchors.centerIn: parent
                width: 96; height: 96; radius: width / 2
                color: homeScreen.panel
                border.width: 1
                border.color: homeScreen.hairline

                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#301E88E5"
                    radius: 10
                    samples: 21
                    verticalOffset: 3
                }

                Canvas {
                    id: droneIcon
                    anchors.centerIn: parent
                    width: 52; height: 52
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        ctx.lineWidth = 2
                        ctx.strokeStyle = homeScreen.accentDeep
                        ctx.fillStyle = homeScreen.accent

                        var cx = width / 2, cy = height / 2
                        ctx.beginPath()
                        ctx.moveTo(cx - 18, cy - 18); ctx.lineTo(cx - 6, cy - 6)
                        ctx.moveTo(cx + 18, cy - 18); ctx.lineTo(cx + 6, cy - 6)
                        ctx.moveTo(cx - 18, cy + 18); ctx.lineTo(cx - 6, cy + 6)
                        ctx.moveTo(cx + 18, cy + 18); ctx.lineTo(cx + 6, cy + 6)
                        ctx.stroke()

                        ctx.beginPath()
                        ctx.rect(cx - 6, cy - 3.5, 12, 7)
                        ctx.fill()

                        var pts = [[cx - 18, cy - 18], [cx + 18, cy - 18],
                                   [cx - 18, cy + 18], [cx + 18, cy + 18]]
                        ctx.strokeStyle = homeScreen.accentDeep
                        for (var i = 0; i < pts.length; i++) {
                            ctx.beginPath()
                            ctx.arc(pts[i][0], pts[i][1], 7, 0, Math.PI * 2)
                            ctx.stroke()
                        }
                    }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Chennai Drone Academy"
            font.pixelSize: 27
            font.weight: Font.DemiBold
            font.letterSpacing: 0.3
            color: homeScreen.textPrimary
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Ready when you are"
            font.pixelSize: 14
            color: homeScreen.textSecondary
        }

        Item { Layout.preferredHeight: 6 }

        // ---- Start pill --------------------------------------------------
        Rectangle {
            id: startButton
            Layout.alignment: Qt.AlignHCenter
            width: 190; height: 54; radius: 12

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: homeScreen.accentLight }
                GradientStop { position: 1.0; color: homeScreen.accentDeep }
            }

            scale: startMouse.pressed ? 0.97 : 1.0
            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }

            layer.enabled: true
            layer.effect: DropShadow {
                color: "#401E88E5"
                radius: 12
                samples: 25
                verticalOffset: 6
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 10

                Canvas {
                    width: 14; height: 14
                    Layout.alignment: Qt.AlignVCenter
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        ctx.fillStyle = "white"
                        ctx.beginPath()
                        ctx.moveTo(0, 0); ctx.lineTo(14, 7); ctx.lineTo(0, 14)
                        ctx.closePath()
                        ctx.fill()
                    }
                }
                Text {
                    text: "Start"
                    color: "white"
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
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

    // ---- Bottom instrument strip -----------------------------------------
    Rectangle {
        id: navBar
        height: 84
        color: homeScreen.panel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        layer.enabled: true
        layer.effect: DropShadow {
            color: "#1E88E522"
            radius: 8
            samples: 17
            verticalOffset: -2
        }

        Rectangle {
            anchors.top: parent.top
            width: parent.width; height: 1
            color: homeScreen.hairline
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Repeater {
                model: [
                    { label: "Home",    kind: "home" },
                    { label: "Plan",    kind: "plan" },
                    { label: "Analyze", kind: "analyze" },
                    { label: "Settings",kind: "settings" }
                ]

                delegate: Item {
                    id: navItem
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    property bool active: index === homeScreen.currentNavIndex

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Canvas {
                            id: navIcon
                            Layout.alignment: Qt.AlignHCenter
                            width: 22; height: 22
                            property bool isActive: navItem.active
                            onIsActiveChanged: requestPaint()

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                var c = isActive ? homeScreen.accent : homeScreen.textSecondary
                                ctx.strokeStyle = c
                                ctx.fillStyle = c
                                ctx.lineWidth = 1.8
                                var w = width, h = height

                                if (modelData.kind === "home") {
                                    ctx.beginPath()
                                    ctx.moveTo(2, 11); ctx.lineTo(w/2, 2); ctx.lineTo(w-2, 11)
                                    ctx.stroke()
                                    ctx.strokeRect(5, 11, w-10, h-13)
                                } else if (modelData.kind === "plan") {
                                    ctx.beginPath()
                                    ctx.arc(w/2, h/2, w/2 - 2, 0, Math.PI * 2)
                                    ctx.stroke()
                                    ctx.beginPath()
                                    ctx.moveTo(w/2 - 4, h/2 + 4); ctx.lineTo(w/2 + 2, h/2 - 6)
                                    ctx.lineTo(w/2 + 4, h/2 - 4); ctx.lineTo(w/2 - 2, h/2 + 6)
                                    ctx.closePath()
                                    ctx.fill()
                                } else if (modelData.kind === "analyze") {
                                    ctx.fillRect(2, h-9, 4, 9)
                                    ctx.fillRect(w/2-2, h-14, 4, 14)
                                    ctx.fillRect(w-6, h-6, 4, 6)
                                } else if (modelData.kind === "settings") {
                                    ctx.beginPath()
                                    ctx.arc(w/2, h/2, 6, 0, Math.PI * 2)
                                    ctx.stroke()
                                    for (var i = 0; i < 8; i++) {
                                        var a = (i / 8) * Math.PI * 2
                                        var x1 = w/2 + Math.cos(a) * 8
                                        var y1 = h/2 + Math.sin(a) * 8
                                        var x2 = w/2 + Math.cos(a) * 11
                                        var y2 = h/2 + Math.sin(a) * 11
                                        ctx.beginPath()
                                        ctx.moveTo(x1, y1); ctx.lineTo(x2, y2)
                                        ctx.stroke()
                                    }
                                }
                            }
                        }

                        Text {
                            text: modelData.label
                            font.pixelSize: 12
                            font.weight: navItem.active ? Font.DemiBold : Font.Normal
                            color: navItem.active ? homeScreen.accent : homeScreen.textSecondary
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 18; height: 2
                            radius: 1
                            color: homeScreen.accent
                            opacity: navItem.active ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
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