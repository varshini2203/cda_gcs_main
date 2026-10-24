import QtQuick 2.15
import QtQuick.Controls 2.15

// SplashScreen
// ------------
// Full-bleed Chennai Drone Academy banner with an animated loading bar
// (progress fill, moving shimmer, glowing head, percentage + status text).
// When loading completes it fades out and routes to Home (if a session
// exists) or Login.

Item {
    id: root

    signal finished(bool alreadyLoggedIn)

    // Total time the loader takes to fill, in ms.
    property int loadDuration: 2800
    // 0.0 - 1.0
    property real progress: 0.0

    readonly property var statusMessages: [
        "Initializing flight systems…",
        "Calibrating sensors…",
        "Loading maps & terrain…",
        "Preparing your dashboard…",
        "Ready for takeoff!"
    ]
    readonly property string statusText:
        statusMessages[Math.min(statusMessages.length - 1, Math.floor(progress * statusMessages.length))]

    Rectangle { anchors.fill: parent; color: "#0B2A4A" }

    // ---- Banner (fills the screen, cropped to fit any aspect ratio) ----
    Image {
        id:             banner
        anchors.fill:   parent
        source:         "qrc:/qml/Auth/images/SplashScreen.png"
        fillMode:       Image.PreserveAspectCrop
        sourceSize.width: 1920
        smooth:         true
        asynchronous:   false
        opacity:        0
        scale:          1.06

        ParallelAnimation {
            running: true
            NumberAnimation { target: banner; property: "opacity"; to: 1.0; duration: 600; easing.type: Easing.OutCubic }
            // slow "Ken Burns" settle that lasts for the whole splash
            NumberAnimation { target: banner; property: "scale"; to: 1.0; duration: root.loadDuration + 600; easing.type: Easing.OutQuad }
        }
    }

    // ---- Bottom scrim so the loader stays readable on any image area ----
    Rectangle {
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        height:         parent.height * 0.28
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#990B2A4A" }
        }
    }

    // ---- Loader ----
    Item {
        id:         loader
        width:      Math.min(parent.width * 0.5, 520)
        height:     64
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(24, parent.height * 0.06)
        opacity:    0

        NumberAnimation on opacity { to: 1; duration: 500; running: true; easing.type: Easing.OutCubic }

        // Status + percent row
        Text {
            id: statusLabel
            anchors.left:   parent.left
            anchors.top:    parent.top
            text:           root.statusText
            color:          "white"
            font.pixelSize: 14
            font.weight:    Font.Medium
            font.letterSpacing: 0.6
            style:          Text.Outline
            styleColor:     "#660B2A4A"
        }
        Text {
            anchors.right:  parent.right
            anchors.top:    parent.top
            text:           Math.round(root.progress * 100) + "%"
            color:          "white"
            font.pixelSize: 14
            font.weight:    Font.Bold
            style:          Text.Outline
            styleColor:     "#660B2A4A"
        }

        // Track
        Rectangle {
            id:             track
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            height:         10
            radius:         height / 2
            color:          "#40FFFFFF"
            border.color:   "#55FFFFFF"
            border.width:   1

            // Fill
            Rectangle {
                id:         fill
                height:     parent.height
                width:      Math.max(height, parent.width * root.progress)
                radius:     height / 2
                clip:       true
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#5BA8E0" }
                    GradientStop { position: 0.6; color: "#1E88E5" }
                    GradientStop { position: 1.0; color: "#FFB547" }   // sunrise-orange head, echoes the banner
                }

                // Moving shimmer
                Rectangle {
                    id:     shimmer
                    width:  fill.height * 4
                    height: parent.height
                    rotation: 0
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#00FFFFFF" }
                        GradientStop { position: 0.5; color: "#80FFFFFF" }
                        GradientStop { position: 1.0; color: "#00FFFFFF" }
                    }
                    NumberAnimation on x {
                        from: -shimmer.width
                        to:   fill.width
                        duration: 1100
                        loops: Animation.Infinite
                        running: true
                    }
                }
            }

            // Glowing head
            Rectangle {
                id:         head
                width:      22
                height:     22
                radius:     11
                x:          fill.width - width / 2
                anchors.verticalCenter: parent.verticalCenter
                color:      "#33FFFFFF"
                visible:    root.progress < 1.0

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: true
                    NumberAnimation { to: 1.35; duration: 450; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0;  duration: 450; easing.type: Easing.InOutSine }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: 10; height: 10; radius: 5
                    color: "white"
                }
            }
        }
    }

    // ---- Fade-out to black-blue before handing over ----
    Rectangle {
        id:             fadeOut
        anchors.fill:   parent
        color:          "#0B2A4A"
        opacity:        0
        NumberAnimation on opacity {
            id:         fadeOutAnim
            running:    false
            to:         1.0
            duration:   350
            onFinished: root.finished(AuthManager.isLoggedIn)
        }
    }

    // ---- Drive progress: eased fill, brief hold at 100%, then fade out ----
    SequentialAnimation {
        running: true
        NumberAnimation { target: root; property: "progress"; from: 0; to: 0.35; duration: root.loadDuration * 0.30; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "progress"; to: 0.80; duration: root.loadDuration * 0.45; easing.type: Easing.InOutSine }
        NumberAnimation { target: root; property: "progress"; to: 1.0;  duration: root.loadDuration * 0.25; easing.type: Easing.OutCubic }
        PauseAnimation  { duration: 350 }
        ScriptAction    { script: fadeOutAnim.start() }
    }
}
