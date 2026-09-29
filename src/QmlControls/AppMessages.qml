/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Controls.Styles  1.4
import QtQuick.Dialogs          1.2
import QtQuick.Layouts          1.12

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FactControls  1.0
import QGroundControl.Controllers   1.0
import QGroundControl.ScreenTools   1.0

Item {
    id:         _root

    property bool loaded: false

    Item {
        id:             panel
        anchors.fill:   parent

        Rectangle {
            id:              logwindow
            anchors.fill:    parent
            anchors.margins: ScreenTools.defaultFontPixelWidth
            color:           "white"
            radius:          ScreenTools.defaultFontPixelWidth * 1.4
            border.width:    1
            border.color:    "#d3e1f2"

            Item {
                id:              logInner
                anchors.fill:    parent
                anchors.margins: ScreenTools.defaultFontPixelWidth

            Connections {
                target: debugMessageModel

                onDataChanged: {
                    // Keep the view in sync if the button is checked
                    if (loaded) {
                        if (followTail.checked) {
                            listview.positionViewAtEnd();
                        }
                    }
                }
            }

            Component {
                id: delegateItem
                Rectangle {
                    color:  index % 2 == 0 ? "white" : "#f3f8ff"
                    height: Math.round(ScreenTools.defaultFontPixelHeight * 0.5 + field.height)
                    width:  listview.width

                    QGCLabel {
                        id:         field
                        text:       display
                        width:      parent.width
                        wrapMode:   Text.Wrap
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            QGCListView {
                Component.onCompleted: {
                    loaded = true
                }
                anchors.top:     parent.top
                anchors.left:    parent.left
                anchors.right:   parent.right
                anchors.bottom:  followTail.top
                anchors.bottomMargin: ScreenTools.defaultFontPixelWidth
                clip:            true
                id:              listview
                model:           debugMessageModel
                delegate:        delegateItem
            }

            QGCFileDialog {
                id:             writeDialog
                folder:         QGroundControl.settingsManager.appSettings.logSavePath
                nameFilters:    [qsTr("Log files (*.txt)"), qsTr("All Files (*)")]
                selectExisting: false
                title:          qsTr("Select log save file")
                onAcceptedForSave: {
                    debugMessageModel.writeMessages(file);
                    visible = false;
                }
            }

            Connections {
                target:          debugMessageModel
                onWriteStarted:  writeButton.enabled = false;
                onWriteFinished: writeButton.enabled = true;
            }

            CDAButton {
                id:              writeButton
                anchors.bottom:  parent.bottom
                anchors.left:    parent.left
                onClicked:       writeDialog.openForSave()
                text:            qsTr("Save App Log")
            }

            QGCLabel {
                id:                     gstLabel
                anchors.left:           writeButton.right
                anchors.leftMargin:     ScreenTools.defaultFontPixelWidth
                anchors.verticalCenter: gstCombo.verticalCenter
                text:                   qsTr("GStreamer Debug Level")
                visible:                QGroundControl.settingsManager.appSettings.gstDebugLevel.visible
            }

            FactComboBox {
                id:                 gstCombo
                anchors.left:       gstLabel.right
                anchors.leftMargin: ScreenTools.defaultFontPixelWidth / 2
                anchors.bottom:     parent.bottom
                fact:               QGroundControl.settingsManager.appSettings.gstDebugLevel
                visible:            QGroundControl.settingsManager.appSettings.gstDebugLevel.visible
                sizeToContents:     true
            }

            CDAButton {
                id:                     followTail
                anchors.right:          filterButton.left
                anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
                anchors.bottom:         parent.bottom
                text:                   qsTr("Show Latest")
                checkable:              true
                checked:                true
                primary:                true

                onCheckedChanged: {
                    if (checked && loaded) {
                        listview.positionViewAtEnd();
                    }
                }
            }

            CDAButton {
                id:             filterButton
                anchors.bottom: parent.bottom
                anchors.right:  parent.right
                text:           qsTr("Set Logging")
                primary:        true
                onClicked:      mainWindow.showPopupDialogFromComponent(filtersDialogComponent)
            }
            }
        }
    }

    Component {
        id: filtersDialogComponent

        QGCPopupDialog {
            title:   qsTr("Logging categories")
            buttons: StandardButton.Close

            ColumnLayout {
                RowLayout {
                    spacing: ScreenTools.defaultFontPixelHeight / 2
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    QGCLabel {
                        text: qsTr("Search:")
                    }

                    QGCTextField {
                        id: searchText
                        text: ""
                        Layout.fillWidth: true
                        enabled: true
                    }

                    CDAButton {
                        text: qsTr("Clear")
                        onClicked: searchText.text = ""
                    }
                }

                Row {
                    spacing:    ScreenTools.defaultFontPixelHeight / 2
                    CDAButton {
                        text: qsTr("Clear All")
                        onClicked: categoryRepeater.setAllLogs(false)
                    }
                }

                Column {
                    id:         categoryColumn
                    spacing:    ScreenTools.defaultFontPixelHeight / 2

                    Repeater {
                        id:     categoryRepeater
                        model:  QGroundControl.loggingCategories()

                        function setAllLogs(value) {
                            var logCategories = QGroundControl.loggingCategories()
                            for (var category of logCategories) {
                                QGroundControl.setCategoryLoggingOn(category, value)
                            }
                            QGroundControl.updateLoggingFilterRules()
                            // Update model for repeater
                            categoryRepeater.model = undefined
                            categoryRepeater.model = QGroundControl.loggingCategories()
                        }

                        QGCCheckBox {
                            text:       modelData
                            visible:    searchText.text ? text.match(`(${searchText.text})`, "i") : true
                            checked:    QGroundControl.categoryLoggingOn(modelData)
                            onClicked:  {
                                QGroundControl.setCategoryLoggingOn(modelData, checked)
                                QGroundControl.updateLoggingFilterRules()
                            }
                        }
                    }
                }
            }
        }
    }
}

