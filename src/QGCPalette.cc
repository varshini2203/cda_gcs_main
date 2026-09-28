/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


/// @file
///     @author Don Gagne <don@thegagnes.com>

#include "QGCPalette.h"
#include "QGCApplication.h"
#include "QGCCorePlugin.h"

#include <QApplication>
#include <QPalette>

QList<QGCPalette*>   QGCPalette::_paletteObjects;

QGCPalette::Theme QGCPalette::_theme = QGCPalette::Dark;

QMap<int, QMap<int, QMap<QString, QColor>>> QGCPalette::_colorInfoMap;

QStringList QGCPalette::_colors;

QGCPalette::QGCPalette(QObject* parent) :
    QObject(parent),
    _colorGroupEnabled(true)
{
    if (_colorInfoMap.isEmpty()) {
        _buildMap();
    }

    // We have to keep track of all QGCPalette objects in the system so we can signal theme change to all of them
    _paletteObjects += this;
}

QGCPalette::~QGCPalette()
{
    bool fSuccess = _paletteObjects.removeOne(this);
    if (!fSuccess) {
        qWarning() << "Internal error";
    }
}

void QGCPalette::_buildMap()
{
    //                                      Light                 Dark
    //                                      Disabled   Enabled    Disabled   Enabled
    DECLARE_QGC_COLOR(window,               "#eef4fb", "#eef4fb", "#222222", "#222222")
    DECLARE_QGC_COLOR(windowShadeLight,     "#9fb3c8", "#8aa0b8", "#707070", "#626262")
    DECLARE_QGC_COLOR(windowShade,          "#ffffff", "#ffffff", "#333333", "#333333")
    DECLARE_QGC_COLOR(windowShadeDark,      "#dbe6f3", "#dbe6f3", "#282828", "#282828")
    DECLARE_QGC_COLOR(text,                 "#9aa8b8", "#0d2a52", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(warningText,          "#cc0808", "#cc0808", "#f85761", "#f85761")
    DECLARE_QGC_COLOR(button,               "#ffffff", "#ffffff", "#707070", "#626270")
    DECLARE_QGC_COLOR(buttonText,           "#9aa8b8", "#0d2a52", "#A6A6A6", "#ffffff")
    DECLARE_QGC_COLOR(buttonHighlight,      "#e3eefc", "#1e6fd0", "#3a3a3a", "#4A90E2")
    DECLARE_QGC_COLOR(buttonHighlightText,  "#2c2c2c", "#ffffff", "#2c2c2c", "#ffffff")
    DECLARE_QGC_COLOR(primaryButton,        "#e3eefc", "#1e6fd0", "#585858", "#4A90E2")
    DECLARE_QGC_COLOR(primaryButtonText,    "#2c2c2c", "#ffffff", "#2c2c2c", "#ffffff")
    DECLARE_QGC_COLOR(textField,            "#ffffff", "#ffffff", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(textFieldText,        "#808080", "#000000", "#000000", "#000000")
    DECLARE_QGC_COLOR(mapButton,            "#585858", "#000000", "#585858", "#000000")
    DECLARE_QGC_COLOR(mapButtonHighlight,   "#585858", "#4A90E2", "#585858", "#4A90E2")
    DECLARE_QGC_COLOR(mapIndicator,         "#585858", "#4A90E2", "#585858", "#4A90E2")
    DECLARE_QGC_COLOR(mapIndicatorChild,    "#585858", "#766043", "#585858", "#766043")
    DECLARE_QGC_COLOR(colorGreen,           "#009431", "#009431", "#00e04b", "#00e04b")
    DECLARE_QGC_COLOR(colorOrange,          "#b95604", "#b95604", "#de8500", "#de8500")
    DECLARE_QGC_COLOR(colorRed,             "#ed3939", "#ed3939", "#f32836", "#f32836")
    DECLARE_QGC_COLOR(colorGrey,            "#808080", "#808080", "#bfbfbf", "#bfbfbf")
    DECLARE_QGC_COLOR(colorBlue,            "#1e6fd0", "#1e6fd0", "#4A90E2", "#4A90E2")
    DECLARE_QGC_COLOR(alertBackground,      "#eecc44", "#eecc44", "#eecc44", "#eecc44")
    DECLARE_QGC_COLOR(alertBorder,          "#808080", "#808080", "#808080", "#808080")
    DECLARE_QGC_COLOR(alertText,            "#000000", "#000000", "#000000", "#000000")
    DECLARE_QGC_COLOR(missionItemEditor,    "#585858", "#dbfef8", "#585858", "#585d83")
    DECLARE_QGC_COLOR(toolStripHoverColor,  "#585858", "#9D9D9D", "#585858", "#585d83")
    DECLARE_QGC_COLOR(statusFailedText,     "#9aa8b8", "#0d2a52", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(statusPassedText,     "#9aa8b8", "#0d2a52", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(statusPendingText,    "#9aa8b8", "#0d2a52", "#707070", "#ffffff")
    DECLARE_QGC_COLOR(toolbarBackground,    "#ffffff", "#ffffff", "#222222", "#222222")

    // Colors not affecting by theming
    //                                              Disabled    Enabled
    DECLARE_QGC_NONTHEMED_COLOR(brandingPurple,     "#0b2f66", "#0b2f66")
    DECLARE_QGC_NONTHEMED_COLOR(brandingBlue,       "#1e6fd0", "#1e6fd0")
    DECLARE_QGC_NONTHEMED_COLOR(toolStripFGColor,   "#707070", "#ffffff")

    // Colors not affecting by theming or enable/disable
    DECLARE_QGC_SINGLE_COLOR(mapWidgetBorderLight,          "#ffffff")
    DECLARE_QGC_SINGLE_COLOR(mapWidgetBorderDark,           "#000000")
    DECLARE_QGC_SINGLE_COLOR(mapMissionTrajectory,          "#4A90E2")
    DECLARE_QGC_SINGLE_COLOR(surveyPolygonInterior,         "green")
    DECLARE_QGC_SINGLE_COLOR(surveyPolygonTerrainCollision, "red")
}

void QGCPalette::setColorGroupEnabled(bool enabled)
{
    _colorGroupEnabled = enabled;
    emit paletteChanged();
}

void QGCPalette::setGlobalTheme(Theme newTheme)
{
    // Mobile build does not have themes
    if (_theme != newTheme) {
        _theme = newTheme;
        _signalPaletteChangeToAll();
    }
}

void QGCPalette::_signalPaletteChangeToAll()
{
    // Notify all objects of the new theme
    foreach (QGCPalette* palette, _paletteObjects) {
        palette->_signalPaletteChanged();
    }
}

void QGCPalette::_signalPaletteChanged()
{
    emit paletteChanged();
}