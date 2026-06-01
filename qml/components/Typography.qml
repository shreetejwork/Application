import QtQuick
import QtQuick.Controls

QtObject {
    id: typography

    // =========================================================
    // RESPONSIVE SCALE
    // =========================================================

    property real scale: 1.0

    // =========================================================
    // TYPOGRAPHY ROLES
    // Optimized for 1024x600 industrial touchscreen display
    // All sizes tuned for maximum readability on touch interface
    // =========================================================

    readonly property real title: Math.round(32 * scale)         // Large page titles - prominent and readable

    readonly property real heading: Math.round(28 * scale)       // Section headers - strong visual hierarchy

    readonly property real subHeading: Math.round(24 * scale)    // Sub-section headers - clear distinction

    readonly property real body: Math.round(22 * scale)          // Main body text - primary reading content, highly readable

    readonly property real bodySmall: Math.round(20 * scale)     // Secondary body text - important but less prominent

    readonly property real caption: Math.round(17 * scale)       // Captions, labels, metadata - still readable

    readonly property real small: Math.round(15 * scale)         // Small text, hints, helper text - minimum for touch readability

    readonly property real tiny: Math.round(13 * scale)          // Tiny text for minimal UI elements (timestamps, version info)

    // =========================================================
    // FONT WEIGHTS
    // =========================================================

    readonly property int weightNormal: Font.Normal

    readonly property int weightMedium: 500

    readonly property int weightBold: Font.Normal

    readonly property int weightExtraBold: Font.Normal

    // =========================================================
    // LINE HEIGHTS
    // =========================================================

    readonly property real lineHeightTight: 1.2

    readonly property real lineHeightNormal: 1.5

    readonly property real lineHeightRelaxed: 1.8

    // =========================================================
    // LETTER SPACING
    // =========================================================

    readonly property real letterSpacingNormal: 0.0

    readonly property real letterSpacingWide: 0.5
}
