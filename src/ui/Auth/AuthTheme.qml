pragma Singleton
import QtQuick 2.11

// AuthTheme
// ---------
// Single place for the Auth module's blue/white visual language, so
// Splash/Login/Register/Home all draw from the same palette instead of
// hard-coded colors scattered across files.

QtObject {
    // Core palette
    readonly property color deepBlue:      "#0B2A4A"   // darkest - gradient end, headings on white
    readonly property color primaryBlue:   "#0F62B0"   // main brand blue
    readonly property color brightBlue:    "#1E88E5"   // gradient start, buttons, links
    readonly property color skyBlue:       "#5BA8E0"   // secondary accents
    readonly property color white:         "#FFFFFF"
    readonly property color offWhite:      "#F4F8FC"   // form-side background
    readonly property color fieldBorder:   "#D7E4F2"
    readonly property color fieldBorderFocused: brightBlue
    readonly property color textDark:      "#0B2A4A"
    readonly property color textMuted:     "#5C7A99"
    readonly property color textOnBlue:    "#FFFFFF"
    readonly property color textOnBlueMuted: "#C7DDF3"
    readonly property color errorRed:      "#E5484D"

    readonly property var brandGradient: [
        { position: 0.0, color: brightBlue },
        { position: 1.0, color: deepBlue }
    ]

    // Shape / spacing
    readonly property real cardRadius:     18
    readonly property real fieldRadius:    12
    readonly property real buttonRadius:   12
}
