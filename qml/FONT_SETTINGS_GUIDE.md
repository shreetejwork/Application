# Font System Setup - Complete Guide

## Overview

Font settings have been moved to a dedicated `FontSettings.qml` file to keep `Main.qml` clean and maintainable. All fonts are automatically applied throughout the application.

## File Structure

```
qml/
├── Main.qml                    # Main application (now much cleaner!)
├── FontSettings.qml            # All font configuration
├── screens/
├── components/
└── ...
```

## Font Sizes (Optimized for 1024x600 Display)

All sizes are designed for optimal readability on a 1024×600 screen:

| Size Constant | Pixel Size | Use Case                          |
| ------------- | ---------- | --------------------------------- |
| `fontSizeXXL` | 32px       | Extra large titles, main headings |
| `fontSizeXL`  | 28px       | Large titles, section headers     |
| `fontSizeL`   | 22px       | Headings, sub-sections            |
| `fontSizeM`   | 16px       | Normal/Body text (default)        |
| `fontSizeS`   | 14px       | Small text, secondary info        |
| `fontSizeXS`  | 12px       | Extra small text, labels          |
| `fontSizeXXS` | 10px       | Tiny text, hints                  |

## How to Use in Components

### Method 1: Direct Access (Recommended)

```qml
import QtQuick
import QtQuick.Controls

Text {
    id: myText

    // At the top of your component, add:
    // property var fonts: root.fonts  // if inside Main.qml
    // OR
    // FontSettings { id: fonts }     // if in a standalone component

    text: "My Title"
    font.family: fonts.regularFontFamily
    font.pixelSize: fonts.fontSizeL
}
```

### Method 2: In Screens/Components (easiest)

```qml
import QtQuick
import QtQuick.Controls

// If your component is loaded inside Main.qml, access fonts via root:

Text {
    text: "Body Text"
    font.pixelSize: root.width > 0 ? 16 : 14  // or use hardcoded from FontSettings
}

// Better - use FontSettings directly in component:
import QtQuick

FontSettings {
    id: fonts
}

Text {
    text: "Body Text"
    font.pixelSize: fonts.fontSizeM
    font.family: fonts.regularFontFamily
}
```

## Accessing Font Settings

To use fonts in any component:

```qml
// Option 1: Direct import and use
FontSettings {
    id: appFonts
}

Text {
    font.family: appFonts.regularFontFamily
    font.pixelSize: appFonts.fontSizeL
}

// Option 2: From within Main.qml screens
Text {
    font.pixelSize: root.font.pixelSize  // Inherits from root
}
```

## How Font Changes Work

1. **Automatic Propagation**: When you change a font property in `FontSettings.qml`, all components using that property automatically update
2. **Root Font**: The root `ApplicationWindow` sets its font to `fonts.regularFontFamily` and `fonts.fontSizeM`
3. **Font Refresh Timer**: A timer runs every 500ms to apply fonts to any newly created components (popups, dialogs, etc)
4. **Font Application Function**: `applyFontToAllChildren()` recursively applies the font to all child elements

## Making Global Changes

To change fonts app-wide, edit [FontSettings.qml](FontSettings.qml):

### Change Font Family

```qml
// In FontSettings.qml, modify the properties that load fonts:
property string regularFontFamily: "Arial"  // or any other font

// For custom fonts, they're loaded via FontLoader at the top
```

### Change Font Sizes

```qml
// In FontSettings.qml, adjust these values:
property int fontSizeXXL: 32      // was 32
property int fontSizeXL: 28       // was 28
property int fontSizeL: 22        // was 22
property int fontSizeM: 16        // was 16 (body text)
property int fontSizeS: 14        // was 14
property int fontSizeXS: 12       // was 12
property int fontSizeXXS: 10      // was 10
```

### Example: Increase all fonts by 2px

```qml
property int fontSizeXXL: 34      // was 32
property int fontSizeXL: 30       // was 28
property int fontSizeL: 24        // was 22
property int fontSizeM: 18        // was 16
property int fontSizeS: 16        // was 14
property int fontSizeXS: 14       // was 12
property int fontSizeXXS: 12      // was 10
```

**All components will automatically update with the new sizes!**

## Current Font Files

- Regular: `RobotoCondensed-Regular.ttf` (via `appRegularFont`)
- Bold: `RobotoCondensed-Bold.ttf` (via `appBoldFont`)

To use the bold font:

```qml
Text {
    font.family: fonts.boldFontFamily
    font.bold: true
    text: "Bold Text"
}
```

## Debug Information

To check font loading status, the app logs this on startup:

```
===== FONT STATUS =====
Regular Font Status: 1 (Ready)
Regular Font Name: RobotoCondensed
Bold Font Status: 1 (Ready)
Bold Font Name: RobotoCondensed
Regular Font Ready: true
Bold Font Ready: true
Applied Font: RobotoCondensed
```

## Benefits of This Setup

✅ **Clean Code**: Main.qml is now much shorter and focused on UI layout
✅ **Centralized Management**: All font settings in one place
✅ **Global Changes**: Modify fonts once, applies everywhere
✅ **Responsive**: Supports scaled sizes for different screen sizes
✅ **Easy to Maintain**: Adding new screens doesn't require font configuration
✅ **Optimized Sizes**: All sizes calculated for 1024×600 display

## Testing

To verify fonts are working:

1. Look at the "FONT TEST" text in the center of the app (displays in fontSizeXXL)
2. Check the console logs for font status on startup
3. Change any font size in FontSettings.qml and rerun - all fonts update automatically
