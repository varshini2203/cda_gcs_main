import QtQuick                  2.3

import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0

// Chennai Drone Academy section card: icon badge + title + subtitle + collapse chevron
Item {
    id: card

    property string title:          ""
    property string subtitle:       ""
    property string iconName:       "sliders"
    property bool   collapsible:    true
    property bool   expanded:       true
    property bool   fillContent:    false       ///< true: content area stretches to the card height (card must be sized by anchors)
    property real   contentMargin:  ScreenTools.defaultFontPixelWidth * 1.5

    default property alias content: contentArea.data

    readonly property real      _headerHeight:  ScreenTools.defaultFontPixelHeight * 3.4
    readonly property real      _radius:        ScreenTools.defaultFontPixelWidth * 1.4
    readonly property string    _iconBase:      "qrc:/qml/SettingsIcons/"

    implicitHeight: _headerHeight + (expanded ? contentArea.height + (contentMargin * 2) : 0)

    //-- Soft shadow
    Rectangle {
        x:          1
        y:          4
        width:      parent.width - 2
        height:     parent.height
        radius:     card._radius
        color:      "#0f0b2f66"
    }
    Rectangle {
        x:          0
        y:          2
        width:      parent.width
        height:     parent.height
        radius:     card._radius
        color:      "#140b2f66"
    }

    Rectangle {
        id:             cardBg
        anchors.fill:   parent
        radius:         card._radius
        color:          "white"
        border.width:   1
        border.color:   "#d3e1f2"
    }

    //-- Header
    Item {
        id:             header
        anchors.top:    parent.top
        anchors.left:   parent.left
        anchors.right:  parent.right
        height:         card._headerHeight

        Rectangle {
            id:                     badge
            anchors.left:           parent.left
            anchors.leftMargin:     card.contentMargin
            anchors.verticalCenter: parent.verticalCenter
            width:                  ScreenTools.defaultFontPixelHeight * 2.4
            height:                 width
            radius:                 width / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#3a8af0" }
                GradientStop { position: 1.0; color: "#1e6fd0" }
            }

            QGCColoredImage {
                anchors.centerIn:   parent
                width:              parent.width * 0.55
                height:             width
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                color:              "white"
                source:             card._iconBase + card.iconName + ".svg"
            }
        }

        Column {
            anchors.left:           badge.right
            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * 1.2
            anchors.right:          chevronArea.left
            anchors.verticalCenter: parent.verticalCenter
            spacing:                2

            QGCLabel {
                text:               card.title
                color:              "#0b2f66"
                font.bold:          true
                font.pointSize:     ScreenTools.mediumFontPointSize * 1.15
                elide:              Text.ElideRight
                width:              parent.width
            }
            QGCLabel {
                visible:            card.subtitle !== ""
                text:               card.subtitle
                color:              "#5a6f8f"
                font.pointSize:     ScreenTools.smallFontPointSize
                elide:              Text.ElideRight
                width:              parent.width
            }
        }

        Item {
            id:                     chevronArea
            visible:                card.collapsible
            anchors.right:          parent.right
            anchors.rightMargin:    card.contentMargin
            anchors.verticalCenter: parent.verticalCenter
            width:                  visible ? ScreenTools.defaultFontPixelHeight * 1.8 : 0
            height:                 ScreenTools.defaultFontPixelHeight * 1.8

            Rectangle {
                anchors.fill:   parent
                radius:         width / 2
                color:          chevronMouse.containsMouse ? "#e3eefc" : "#eef4fb"
            }
            Canvas {
                anchors.centerIn:   parent
                width:              parent.width * 0.5
                height:             width
                rotation:           card.expanded ? 0 : 180
                onWidthChanged:     requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = "#1e6fd0"
                    ctx.lineWidth = 2
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    ctx.moveTo(width * 0.1, height * 0.68)
                    ctx.lineTo(width * 0.5, height * 0.3)
                    ctx.lineTo(width * 0.9, height * 0.68)
                    ctx.stroke()
                }
            }
            MouseArea {
                id:             chevronMouse
                anchors.fill:   parent
                hoverEnabled:   true
                cursorShape:    Qt.PointingHandCursor
                onClicked:      card.expanded = !card.expanded
            }
        }

        MouseArea {
            anchors.fill:   parent
            enabled:        card.collapsible
            z:              -1
            onClicked:      card.expanded = !card.expanded
        }
    }

    Rectangle {
        visible:            card.expanded
        anchors.top:        header.bottom
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.leftMargin: card.contentMargin
        anchors.rightMargin:card.contentMargin
        height:             1
        color:              "#e1ebf7"
    }

    //-- Content
    Item {
        id:                 contentArea
        visible:            card.expanded
        x:                  card.contentMargin
        y:                  card._headerHeight + card.contentMargin
        width:              card.width - (card.contentMargin * 2)
        height:             card.fillContent ? Math.max(0, card.height - card._headerHeight - (card.contentMargin * 2)) : childrenRect.height
    }
}
