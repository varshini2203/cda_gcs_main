/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


import QtQuick          2.3
import QtQuick.Controls 1.2
import QtQuick.Dialogs  1.2

import QGroundControl                       1.0
import QGroundControl.Controls              1.0
import QGroundControl.ScreenTools           1.0
import QGroundControl.Palette               1.0

Rectangle {
    id:                 _linkRoot
    color:              "transparent"
    anchors.fill:       parent
    anchors.margins:    ScreenTools.defaultFontPixelWidth

    property var _currentSelection: null
    property int _firstColumn:      ScreenTools.defaultFontPixelWidth * 12
    property int _secondColumn:     ScreenTools.defaultFontPixelWidth * 30

    QGCPalette {
        id:                 qgcPal
        colorGroupEnabled:  enabled
    }

    function openCommSettings(lconf) {
        settingLoader.linkConfig = lconf
        settingLoader.sourceComponent = commSettings
        settingLoader.visible = true
    }

    function closeCommSettings() {
        settingLoader.visible = false
        settingLoader.sourceComponent = null
    }

    CDASectionCard {
        id:                 linkCard
        anchors.top:        parent.top
        anchors.topMargin:  ScreenTools.defaultFontPixelWidth
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.bottom:     buttonBar.top
        anchors.margins:    ScreenTools.defaultFontPixelWidth
        title:              qsTr("Comm Links")
        subtitle:           qsTr("Select a connection, then connect, edit or remove it")
        iconName:           "link"
        collapsible:        false
        fillContent:        true

        QGCFlickable {
            id:                 linkFlick
            clip:               true
            anchors.fill:       parent
            contentHeight:      settingsColumn.height
            contentWidth:       width
            flickableDirection: Flickable.VerticalFlick

            Column {
                id:         settingsColumn
                width:      linkFlick.width
                spacing:    ScreenTools.defaultFontPixelHeight * 0.5

                Repeater {
                    model: QGroundControl.linkManager.linkConfigurations

                    delegate: Rectangle {
                        id:         linkRow
                        width:      settingsColumn.width
                        height:     visible ? ScreenTools.defaultFontPixelHeight * 3.2 : 0
                        visible:    !object.dynamic
                        radius:     ScreenTools.defaultFontPixelWidth
                        color:      _selected ? "#dcebfb" : (rowMouse.containsMouse ? "#eef4fb" : "white")
                        border.width: _selected ? 2 : 1
                        border.color: _selected ? "#1e6fd0" : "#d3e1f2"

                        property bool _selected: _currentSelection === object

                        Rectangle {
                            id:                     rowBadge
                            anchors.left:           parent.left
                            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
                            anchors.verticalCenter: parent.verticalCenter
                            width:                  ScreenTools.defaultFontPixelHeight * 2
                            height:                 width
                            radius:                 width / 2
                            color:                  linkRow._selected ? "#1e6fd0" : "#dcebfb"

                            QGCColoredImage {
                                anchors.centerIn:   parent
                                width:              parent.width * 0.55
                                height:             width
                                sourceSize.height:  height
                                fillMode:           Image.PreserveAspectFit
                                color:              linkRow._selected ? "white" : "#1e6fd0"
                                source:             "qrc:/qml/SettingsIcons/link.svg"
                            }
                        }

                        QGCLabel {
                            anchors.left:           rowBadge.right
                            anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
                            anchors.right:          statusPill.left
                            anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
                            anchors.verticalCenter: parent.verticalCenter
                            text:                   object.name
                            color:                  "#0b2f66"
                            font.bold:              true
                            elide:                  Text.ElideRight
                        }

                        Rectangle {
                            id:                     statusPill
                            anchors.right:          parent.right
                            anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
                            anchors.verticalCenter: parent.verticalCenter
                            width:                  pillLabel.width + ScreenTools.defaultFontPixelWidth * 2
                            height:                 pillLabel.height + ScreenTools.defaultFontPixelHeight * 0.4
                            radius:                 height / 2
                            color:                  object.link ? "#e3f6ea" : "#eef4fb"

                            QGCLabel {
                                id:                 pillLabel
                                anchors.centerIn:   parent
                                text:               object.link ? qsTr("Connected") : qsTr("Idle")
                                color:              object.link ? "#009431" : "#5a6f8f"
                                font.bold:          true
                                font.pointSize:     ScreenTools.smallFontPointSize
                            }
                        }

                        MouseArea {
                            id:             rowMouse
                            anchors.fill:   parent
                            hoverEnabled:   true
                            cursorShape:    Qt.PointingHandCursor
                            onClicked:      _currentSelection = object
                        }
                    }
                }
            }
        }

        //-- Empty state
        Column {
            anchors.centerIn:   parent
            spacing:            ScreenTools.defaultFontPixelHeight * 0.5
            visible:            settingsColumn.height < 1

            Rectangle {
                anchors.horizontalCenter:   parent.horizontalCenter
                width:                      ScreenTools.defaultFontPixelHeight * 4
                height:                     width
                radius:                     width / 2
                color:                      "#eaf3ff"

                QGCColoredImage {
                    anchors.centerIn:   parent
                    width:              parent.width * 0.5
                    height:             width
                    sourceSize.height:  height
                    fillMode:           Image.PreserveAspectFit
                    color:              "#1e6fd0"
                    source:             "qrc:/qml/SettingsIcons/link.svg"
                }
            }
            QGCLabel {
                anchors.horizontalCenter:   parent.horizontalCenter
                text:                       qsTr("No communication links yet")
                color:                      "#0b2f66"
                font.bold:                  true
                font.pointSize:             ScreenTools.mediumFontPointSize
            }
            QGCLabel {
                anchors.horizontalCenter:   parent.horizontalCenter
                text:                       qsTr("Press Add to create a serial, UDP, TCP or Bluetooth connection")
                color:                      "#5a6f8f"
            }
        }
    }

    Rectangle {
        id:                 buttonBar
        anchors.bottom:     parent.bottom
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.margins:    ScreenTools.defaultFontPixelWidth
        height:             buttonRow.height + (ScreenTools.defaultFontPixelHeight * 1.2)
        radius:             ScreenTools.defaultFontPixelWidth * 1.2
        color:              "white"
        border.width:       1
        border.color:       "#d3e1f2"

        Row {
            id:                         buttonRow
            spacing:                    ScreenTools.defaultFontPixelWidth
            anchors.centerIn:           parent

            CDAButton {
                width:      ScreenTools.defaultFontPixelWidth * 12
                text:       qsTr("Delete")
                danger:     true
                enabled:    _currentSelection && !_currentSelection.dynamic
                onClicked: {
                    if(_currentSelection)
                        deleteDialog.visible = true
                }
                MessageDialog {
                    id:         deleteDialog
                    visible:    false
                    icon:       StandardIcon.Warning
                    standardButtons: StandardButton.Yes | StandardButton.No
                    title:      qsTr("Remove Link Configuration")
                    text:       _currentSelection ? qsTr("Remove %1. Is this really what you want?").arg(_currentSelection.name) : ""
                    onYes: {
                        if(_currentSelection)
                            QGroundControl.linkManager.removeConfiguration(_currentSelection)
                        deleteDialog.visible = false
                    }
                    onNo: {
                        deleteDialog.visible = false
                    }
                }
            }
            CDAButton {
                width:      ScreenTools.defaultFontPixelWidth * 12
                text:       qsTr("Edit")
                enabled:    _currentSelection && !_currentSelection.link
                onClicked: {
                    _linkRoot.openCommSettings(_currentSelection)
                }
            }
            CDAButton {
                width:      ScreenTools.defaultFontPixelWidth * 12
                text:       qsTr("Add")
                primary:    true
                onClicked: {
                    _linkRoot.openCommSettings(null)
                }
            }
            CDAButton {
                width:      ScreenTools.defaultFontPixelWidth * 14
                text:       qsTr("Connect")
                primary:    true
                enabled:    _currentSelection && !_currentSelection.link
                onClicked:  QGroundControl.linkManager.createConnectedLink(_currentSelection)
            }
            CDAButton {
                width:      ScreenTools.defaultFontPixelWidth * 14
                text:       qsTr("Disconnect")
                enabled:    _currentSelection && _currentSelection.link
                onClicked:  _currentSelection.link.disconnect()
            }
            CDAButton {
                text:       qsTr("MockLink Options")
                visible:    _currentSelection && _currentSelection.link && _currentSelection.link.isMockLink
                onClicked:  mainWindow.showPopupDialogFromSource("qrc:/unittest/MockLinkOptionsDlg.qml", { link: _currentSelection.link })
            }
        }
    }

    Loader {
        id:             settingLoader
        anchors.fill:   parent
        visible:        false
        property var linkConfig: null
        property var editConfig: null
    }

    //---------------------------------------------
    // Comm Settings
    Component {
        id: commSettings
        Rectangle {
            id:             settingsRect
            color:          "#f3f7fc"
            anchors.fill:   parent
            property real   _panelWidth:    width * 0.8
            Component.onCompleted: {
                // If editing, create copy for editing
                if(linkConfig) {
                    editConfig = QGroundControl.linkManager.startConfigurationEditing(linkConfig)
                } else {
                    // Create new link configuration
                    if(ScreenTools.isSerialAvailable) {
                        editConfig = QGroundControl.linkManager.createConfiguration(LinkConfiguration.TypeSerial, "Unnamed")
                    } else {
                        editConfig = QGroundControl.linkManager.createConfiguration(LinkConfiguration.TypeUdp,    "Unnamed")
                    }
                }
            }
            Component.onDestruction: {
                if(editConfig) {
                    QGroundControl.linkManager.cancelConfigurationEditing(editConfig)
                    editConfig = null
                }
            }
            Column {
                id:                 settingsTitle
                spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                QGCLabel {
                    text:   linkConfig ? qsTr("Edit Link Configuration Settings") : qsTr("Create New Link Configuration")
                    font.pointSize: ScreenTools.mediumFontPointSize
                }
                Rectangle {
                    height: 1
                    width:  settingsRect.width
                    color:  qgcPal.button
                }
            }
            QGCFlickable {
                id:                 settingsFlick
                clip:               true
                anchors.top:        settingsTitle.bottom
                anchors.bottom:     commButtonRow.top
                width:              parent.width
                anchors.margins:    ScreenTools.defaultFontPixelWidth
                contentHeight:      commSettingsColumn.height
                contentWidth:       _linkRoot.width
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior:     Flickable.StopAtBounds
                Column {
                    id:                 commSettingsColumn
                    width:              _linkRoot.width
                    anchors.margins:    ScreenTools.defaultFontPixelWidth
                    spacing:            ScreenTools.defaultFontPixelHeight * 0.5
                    //-----------------------------------------------------------------
                    //-- General
                    Item {
                        width:                      _panelWidth
                        height:                     generalLabel.height
                        anchors.margins:            ScreenTools.defaultFontPixelWidth
                        anchors.horizontalCenter:   parent.horizontalCenter
                        QGCLabel {
                            id:                     generalLabel
                            text:                   qsTr("General")
                            font.bold:            true
                            color:            "#1e6fd0"
                            font.pointSize: ScreenTools.mediumFontPointSize
                        }
                    }
                    Rectangle {
                        height:                     generalCol.height + (ScreenTools.defaultFontPixelHeight * 2)
                        width:                      _panelWidth
                        color:                      "white"
                        radius: ScreenTools.defaultFontPixelWidth * 1.2
                        border.width: 1
                        border.color: "#d3e1f2"
                        Rectangle { z: -1; y: 3; width: parent.width; height: parent.height; radius: parent.radius; color: "#140b2f66" }
                        anchors.margins:            ScreenTools.defaultFontPixelWidth
                        anchors.horizontalCenter:   parent.horizontalCenter
                        Column {
                            id:                     generalCol
                            anchors.centerIn:       parent
                            anchors.margins:        ScreenTools.defaultFontPixelWidth
                            spacing:                ScreenTools.defaultFontPixelHeight * 0.5
                            Row {
                                spacing:    ScreenTools.defaultFontPixelWidth
                                QGCLabel {
                                    text:   qsTr("Name:")
                                    width:  _firstColumn
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                QGCTextField {
                                    id:     nameField
                                    text:   editConfig ? editConfig.name : ""
                                    width:  _secondColumn
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            Row {
                                spacing:            ScreenTools.defaultFontPixelWidth
                                QGCLabel {
                                    text:           qsTr("Type:")
                                    width:          _firstColumn
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                //-----------------------------------------------------
                                // When editing, you can't change the link type
                                QGCLabel {
                                    text:           linkConfig ? QGroundControl.linkManager.linkTypeStrings[linkConfig.linkType] : ""
                                    visible:        linkConfig != null
                                    width:          _secondColumn
                                    anchors.verticalCenter: parent.verticalCenter
                                    Component.onCompleted: {
                                        if(linkConfig != null) {
                                            linkSettingLoader.source  = linkConfig.settingsURL
                                            linkSettingLoader.visible = true
                                        }
                                    }
                                }
                                //-----------------------------------------------------
                                // When creating, select a link type
                                QGCComboBox {
                                    id:             linkTypeCombo
                                    width:          _secondColumn
                                    visible:        linkConfig == null
                                    model:          QGroundControl.linkManager.linkTypeStrings
                                    anchors.verticalCenter: parent.verticalCenter
                                    onActivated: {
                                        if (index != -1 && index !== editConfig.linkType) {
                                            // Destroy current panel
                                            linkSettingLoader.source = ""
                                            linkSettingLoader.visible = false
                                            // Save current name
                                            var name = nameField.text
                                            // Discard link configuration (old type)
                                            QGroundControl.linkManager.cancelConfigurationEditing(editConfig)
                                            // Create new link configuration
                                            editConfig = QGroundControl.linkManager.createConfiguration(index, name)
                                            // Load appropriate configuration panel
                                            linkSettingLoader.source  = editConfig.settingsURL
                                            linkSettingLoader.visible = true
                                        }
                                    }
                                    Component.onCompleted: {
                                        if(linkConfig == null) {
                                            linkTypeCombo.currentIndex = 0
                                            linkSettingLoader.source   = editConfig.settingsURL
                                            linkSettingLoader.visible  = true
                                        }
                                    }
                                }
                            }
                            Item {
                                height: ScreenTools.defaultFontPixelHeight * 0.5
                                width:  parent.width
                            }
                            //-- Auto Connect on Start
                            QGCCheckBox {
                                text:               qsTr("Automatically Connect on Start")
                                checked:            false
                                onCheckedChanged: {
                                    if(editConfig) {
                                        editConfig.autoConnect = checked
                                    }
                                }
                                Component.onCompleted: {
                                    if(editConfig)
                                        checked = editConfig.autoConnect
                                }
                            }
                            QGCCheckBox {
                                text:               qsTr("High Latency")
                                checked:            false
                                onCheckedChanged: {
                                    if(editConfig) {
                                        editConfig.highLatency = checked
                                    }
                                }
                                Component.onCompleted: {
                                    if(editConfig)
                                        checked = editConfig.highLatency
                                }
                            }
                        }
                    }
                    Item {
                        height: ScreenTools.defaultFontPixelHeight
                        width:  parent.width
                    }
                    //-----------------------------------------------------------------
                    //-- Link Specific Settings
                    Item {
                        width:                      _panelWidth
                        height:                     linkLabel.height
                        anchors.margins:            ScreenTools.defaultFontPixelWidth
                        anchors.horizontalCenter:   parent.horizontalCenter
                        QGCLabel {
                            id:                     linkLabel
                            text:                   editConfig ? editConfig.settingsTitle : ""
                            visible:                linkSettingLoader.source != ""
                            font.bold:            true
                            color:            "#1e6fd0"
                            font.pointSize: ScreenTools.mediumFontPointSize
                        }
                    }
                    Rectangle {
                        height:                     linkSettingLoader.height + (ScreenTools.defaultFontPixelHeight * 2)
                        width:                      _panelWidth
                        color:                      "white"
                        radius: ScreenTools.defaultFontPixelWidth * 1.2
                        border.width: 1
                        border.color: "#d3e1f2"
                        Rectangle { z: -1; y: 3; width: parent.width; height: parent.height; radius: parent.radius; color: "#140b2f66" }
                        anchors.margins:            ScreenTools.defaultFontPixelWidth
                        anchors.horizontalCenter:   parent.horizontalCenter
                        Item {
                            height:                 linkSettingLoader.height
                            width:                  linkSettingLoader.width
                            anchors.centerIn:       parent
                            Loader {
                                id:                 linkSettingLoader
                                visible:            false
                                property var subEditConfig: editConfig
                            }
                        }
                    }
                }
            }
            Row {
                id:                 commButtonRow
                spacing:            ScreenTools.defaultFontPixelWidth
                anchors.margins:    ScreenTools.defaultFontPixelWidth
                anchors.bottom:     parent.bottom
                anchors.right:      parent.right
                CDAButton {
                    width:      ScreenTools.defaultFontPixelWidth * 10
                    text:       qsTr("OK")
                    enabled:    nameField.text !== ""
                    onClicked: {
                        // Save editting
                        linkSettingLoader.item.saveSettings()
                        editConfig.name = nameField.text
                        if(linkConfig) {
                            QGroundControl.linkManager.endConfigurationEditing(linkConfig, editConfig)
                        } else {
                            // If it was edited, it's no longer "dynamic"
                            editConfig.dynamic = false
                            QGroundControl.linkManager.endCreateConfiguration(editConfig)
                        }
                        linkSettingLoader.source = ""
                        editConfig = null
                        _linkRoot.closeCommSettings()
                    }
                }
                CDAButton {
                    width:      ScreenTools.defaultFontPixelWidth * 10
                    text:       qsTr("Cancel")
                    onClicked: {
                        QGroundControl.linkManager.cancelConfigurationEditing(editConfig)
                        editConfig = null
                        _linkRoot.closeCommSettings()
                    }
                }
            }
        }
    }
}
