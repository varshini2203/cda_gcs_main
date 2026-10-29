/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                  2.4
import QtPositioning            5.2
import QtQuick.Layouts          1.2
import QtQuick.Controls         1.4
import QtQuick.Dialogs          1.2
import QtGraphicalEffects       1.0

import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.Palette           1.0
import QGroundControl.Vehicle           1.0
import QGroundControl.Controllers       1.0
import QGroundControl.FactSystem        1.0
import QGroundControl.FactControls      1.0

Rectangle {
    id:         _photoVideoRoot
    width:      mainLayout.width
    height:     mainLayout.height
    color:      "transparent"
    visible:    !QGroundControl.settingsManager.flyViewSettings.alternateInstrumentPanel.rawValue && (_mavlinkCamera || _videoStreamAvailable || _simpleCameraAvailable) && multiVehiclePanelSelector.showSingleVehiclePanel

    property real   _margins:                                   ScreenTools.defaultFontPixelHeight / 2
    property var    _activeVehicle:                             QGroundControl.multiVehicleManager.activeVehicle

    // The following properties relate to a simple camera
    property var    _flyViewSettings:                           QGroundControl.settingsManager.flyViewSettings
    property bool   _simpleCameraAvailable:                     !_mavlinkCamera && _activeVehicle && _flyViewSettings.showSimpleCameraControl.rawValue
    property bool   _onlySimpleCameraAvailable:                 !_anyVideoStreamAvailable && _simpleCameraAvailable
    property bool   _simpleCameraIsShootingInCurrentMode:       _onlySimpleCameraAvailable && !_simplePhotoCaptureIsIdle

    // The following properties relate to a simple video stream
    property bool   _videoStreamAvailable:                      _videoStreamManager.hasVideo
    property var    _videoStreamSettings:                       QGroundControl.settingsManager.videoSettings
    property var    _videoStreamManager:                        QGroundControl.videoManager
    property bool   _videoStreamAllowsPhotoWhileRecording:      true
    property bool   _videoStreamIsStreaming:                    _videoStreamManager.streaming
    property bool   _simplePhotoCaptureIsIdle:             true
    property bool   _videoStreamRecording:                      _videoStreamManager.recording
    property bool   _videoStreamCanShoot:                       _videoStreamIsStreaming
    property bool   _videoStreamIsShootingInCurrentMode:        _videoStreamInPhotoMode ? !_simplePhotoCaptureIsIdle : _videoStreamRecording
    property bool   _videoStreamInPhotoMode:                    false

    // The following properties relate to a mavlink protocol camera
    property var    _mavlinkCameraManager:                      _activeVehicle ? _activeVehicle.cameraManager : null
    property int    _mavlinkCameraManagerCurCameraIndex:        _mavlinkCameraManager ? _mavlinkCameraManager.currentCamera : -1
    property bool   _noMavlinkCameras:                          _mavlinkCameraManager ? _mavlinkCameraManager.cameras.count === 0 : true
    property var    _mavlinkCamera:                             !_noMavlinkCameras ? (_mavlinkCameraManager.cameras.get(_mavlinkCameraManagerCurCameraIndex) && _mavlinkCameraManager.cameras.get(_mavlinkCameraManagerCurCameraIndex).paramComplete ? _mavlinkCameraManager.cameras.get(_mavlinkCameraManagerCurCameraIndex) : null) : null
    property bool   _multipleMavlinkCameras:                    _mavlinkCameraManager ? _mavlinkCameraManager.cameras.count > 1 : false
    property string _mavlinkCameraName:                         _mavlinkCamera && _multipleMavlinkCameras ? _mavlinkCamera.modelName : ""
    property bool   _noMavlinkCameraStreams:                    _mavlinkCamera ? _mavlinkCamera.streamLabels.length : true
    property bool   _multipleMavlinkCameraStreams:              _mavlinkCamera ? _mavlinkCamera.streamLabels.length > 1 : false
    property int    _mavlinCameraCurStreamIndex:                _mavlinkCamera ? _mavlinkCamera.currentStream : -1
    property bool   _mavlinkCameraHasThermalVideoStream:        _mavlinkCamera ? _mavlinkCamera.thermalStreamInstance : false
    property bool   _mavlinkCameraModeUndefined:                _mavlinkCamera ? _mavlinkCamera.cameraMode === QGCCameraControl.CAM_MODE_UNDEFINED : true
    property bool   _mavlinkCameraInVideoMode:                  _mavlinkCamera ? _mavlinkCamera.cameraMode === QGCCameraControl.CAM_MODE_VIDEO : false
    property bool   _mavlinkCameraInPhotoMode:                  _mavlinkCamera ? _mavlinkCamera.cameraMode === QGCCameraControl.CAM_MODE_PHOTO : false
    property bool   _mavlinkCameraElapsedMode:                  _mavlinkCamera && _mavlinkCamera.cameraMode === QGCCameraControl.CAM_MODE_PHOTO && _mavlinkCamera.photoMode === QGCCameraControl.PHOTO_CAPTURE_TIMELAPSE
    property bool   _mavlinkCameraHasModes:                     _mavlinkCamera && _mavlinkCamera.hasModes
    property bool   _mavlinkCameraVideoIsRecording:             _mavlinkCamera && _mavlinkCamera.videoStatus === QGCCameraControl.VIDEO_CAPTURE_STATUS_RUNNING
    property bool   _mavlinkCameraPhotoCaptureIsIdle:           _mavlinkCamera && (_mavlinkCamera.photoStatus === QGCCameraControl.PHOTO_CAPTURE_IDLE || _mavlinkCamera.photoStatus >= QGCCameraControl.PHOTO_CAPTURE_LAST)
    property bool   _mavlinkCameraStorageReady:                 _mavlinkCamera && _mavlinkCamera.storageStatus === QGCCameraControl.STORAGE_READY
    property bool   _mavlinkCameraBatteryReady:                 _mavlinkCamera && _mavlinkCamera.batteryRemaining >= 0
    property bool   _mavlinkCameraStorageSupported:             _mavlinkCamera && _mavlinkCamera.storageStatus === QGCCameraControl.STORAGE_NOT_SUPPORTED
    property bool   _mavlinkCameraAllowsPhotoWhileRecording:    false
    property bool   _mavlinkCameraCanShoot:                     (!_mavlinkCameraModeUndefined && ((_mavlinkCameraStorageReady && _mavlinkCamera.storageFree > 0) || _mavlinkCameraStorageSupported)) || _videoStreamManager.streaming
    property bool   _mavlinkCameraIsShooting:                   ((_mavlinkCameraInVideoMode && _mavlinkCameraVideoIsRecording) || (_mavlinkCameraInPhotoMode && !_mavlinkCameraPhotoCaptureIsIdle)) || _videoStreamManager.recording

    // The following settings and functions unify between a mavlink camera and a simple video stream for simple access

    property bool   _anyVideoStreamAvailable:                   _videoStreamManager.hasVideo
    property string _cameraName:                                _mavlinkCamera ? _mavlinkCameraName : ""
    property bool   _showModeIndicator:                         _mavlinkCamera ? _mavlinkCameraHasModes : _videoStreamManager.hasVideo
    property bool   _modeIndicatorPhotoMode:                    _mavlinkCamera ? _mavlinkCameraInPhotoMode : _videoStreamInPhotoMode || _onlySimpleCameraAvailable
    property bool   _allowsPhotoWhileRecording:                  _mavlinkCamera ? _mavlinkCameraAllowsPhotoWhileRecording : _videoStreamAllowsPhotoWhileRecording
    property bool   _switchToPhotoModeAllowed:                  !_modeIndicatorPhotoMode && (_mavlinkCamera ? !_mavlinkCameraIsShooting : true)
    property bool   _switchToVideoModeAllowed:                  _modeIndicatorPhotoMode && (_mavlinkCamera ? !_mavlinkCameraIsShooting : true)
    property bool   _videoIsRecording:                          _mavlinkCamera ? _mavlinkCameraIsShooting : _videoStreamRecording
    property bool   _canShootInCurrentMode:                     _mavlinkCamera ? _mavlinkCameraCanShoot : _videoStreamCanShoot || _simpleCameraAvailable
    property bool   _isShootingInCurrentMode:                   _mavlinkCamera ? _mavlinkCameraIsShooting : _videoStreamIsShootingInCurrentMode || _simpleCameraIsShootingInCurrentMode

    function setCameraMode(photoMode) {
        _videoStreamInPhotoMode = photoMode
        if (_mavlinkCamera) {
            if (_mavlinkCameraInPhotoMode) {
                _mavlinkCamera.setVideoMode()
            } else {
                _mavlinkCamera.setPhotoMode()
            }
        }
    }

    function toggleShooting() {
        console.log("toggleShooting", _anyVideoStreamAvailable)
        if (_mavlinkCamera) {
            if(_mavlinkCameraInVideoMode) {
                _mavlinkCamera.toggleVideo()
            } else {
                if(_mavlinkCameraInPhotoMode && !_mavlinkCameraPhotoCaptureIsIdle && _mavlinkCameraElapsedMode) {
                    _mavlinkCamera.stopTakePhoto()
                } else {
                    _mavlinkCamera.takePhoto()
                }
            }
        } else if (_onlySimpleCameraAvailable || (_simpleCameraAvailable && _anyVideoStreamAvailable && _videoStreamInPhotoMode)) {   // CDA: old 'Video Grab / Camera Trigger' radio buttons removed, camera trigger is used
            _simplePhotoCaptureIsIdle = false
            _activeVehicle.triggerSimpleCamera()
            simplePhotoCaptureTimer.start()
        } else if (_anyVideoStreamAvailable) {
            if (_videoStreamInPhotoMode) {
                _simplePhotoCaptureIsIdle = false
                _videoStreamManager.grabImage()
                simplePhotoCaptureTimer.start()
            } else {
                if (_videoStreamManager.recording) {
                    _videoStreamManager.stopRecording()
                } else {
                    _videoStreamManager.startRecording()
                }
            }
        }
    }

    Timer {
        id:             simplePhotoCaptureTimer
        interval:       500
        onTriggered:    _simplePhotoCaptureIsIdle = true
    }

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    // ------------------------------------------------------------------------------------
    //  CDA simple camera control
    //   - closed : ONE small round camera button (red dot + time while recording)
    //   - tapped : two big, clearly named buttons -> Photo  /  Record
    //  The camera logic above (toggleShooting, setCameraMode ...) is the normal QGC logic and
    //  works for MAVLink cameras, the video stream and the simple camera trigger.
    // ------------------------------------------------------------------------------------
    property bool   _expanded:          false
    property color  _cdaAccent:         "#38BDF8"
    property color  _cdaRed:            "#FF4D4D"
    property real   _btnSize:           ScreenTools.defaultFontPixelHeight * 3
    property bool   _isRecordingVideo:  _mavlinkCamera ? (_mavlinkCameraInVideoMode && _mavlinkCameraVideoIsRecording) : _videoStreamRecording
    property bool   _photoBusy:         !_simplePhotoCaptureIsIdle || (_mavlinkCamera ? (_mavlinkCameraInPhotoMode && !_mavlinkCameraPhotoCaptureIsIdle) : false)
    property real   _recStartMs:        0
    property int    _recSeconds:        0
    property string _recTimeText:       _mavlinkCamera ? (_isRecordingVideo ? _mavlinkCamera.recordTimeStr : "00:00:00") : _fmtTime(_recSeconds)

    function _two(n) { return (n < 10 ? "0" : "") + n }

    function _fmtTime(sec) {
        return _two(Math.floor(sec / 3600)) + ":" + _two(Math.floor((sec % 3600) / 60)) + ":" + _two(sec % 60)
    }

    // keep the panel open a little after the last touch, then fold back to the small button
    function _touched() { autoHide.restart() }

    // photo = true -> take a photo, photo = false -> start / stop recording
    function _shoot(photo) {
        _touched()
        if (_modeIndicatorPhotoMode !== photo) {
            var allowed = photo ? _switchToPhotoModeAllowed : _switchToVideoModeAllowed
            if (!allowed) {
                return                                  // camera is busy (for example recording) - do nothing
            }
            setCameraMode(photo)
            if (_mavlinkCamera) {
                modeChangeTimer.start()                 // a real camera needs a moment to change mode
                return
            }
        }
        toggleShooting()
    }

    Timer {
        id:             modeChangeTimer
        interval:       800
        onTriggered:    toggleShooting()
    }

    Timer {
        id:             autoHide
        interval:       7000
        onTriggered:    _expanded = false
    }

    // recording time for the plain video stream (a MAVLink camera reports its own time)
    Timer {
        id:             recTimer
        interval:       500
        repeat:         true
        running:        _isRecordingVideo && !_mavlinkCamera
        onRunningChanged: {
            if (running) {
                _recStartMs = Date.now()
                _recSeconds = 0
            }
        }
        onTriggered:    _recSeconds = Math.floor((Date.now() - _recStartMs) / 1000)
    }

    Row {
        id:         mainLayout
        spacing:    ScreenTools.defaultFontPixelWidth * 0.8

        //-- small "recording" pill, only while the panel is closed
        Rectangle {
            visible:                _isRecordingVideo && !_expanded
            anchors.verticalCenter: parent.verticalCenter
            width:                  pillLabel.width + ScreenTools.defaultFontPixelWidth * 2
            height:                 pillLabel.height + ScreenTools.defaultFontPixelHeight * 0.4
            radius:                 height / 2
            color:                  "#D9081420"
            border.color:           _cdaRed
            border.width:           1

            QGCLabel {
                id:                 pillLabel
                anchors.centerIn:   parent
                color:              "white"
                font.bold:          true
                text:               _recTimeText
            }
        }

        //-- Photo + Record buttons (shown after tapping the camera button)
        Rectangle {
            id:                     actionPanel
            visible:                _expanded
            anchors.verticalCenter: parent.verticalCenter
            width:                  actionRow.width + ScreenTools.defaultFontPixelWidth * 3
            height:                 actionRow.height + ScreenTools.defaultFontPixelHeight
            radius:                 ScreenTools.defaultFontPixelWidth
            color:                  "#D9081420"
            border.color:           "#5538BDF8"
            border.width:           1.5

            Row {
                id:                 actionRow
                anchors.centerIn:   parent
                spacing:            ScreenTools.defaultFontPixelWidth * 2.2

                //-- PHOTO
                Column {
                    spacing:        ScreenTools.defaultFontPixelHeight * 0.2

                    Rectangle {
                        width:                      _btnSize * 0.9
                        height:                     width
                        radius:                     width / 2
                        anchors.horizontalCenter:   parent.horizontalCenter
                        color:                      photoArea.pressed ? "#4038BDF8" : "#1AFFFFFF"
                        border.color:               _photoBusy ? "white" : _cdaAccent
                        border.width:               2
                        opacity:                    _canShootInCurrentMode ? 1.0 : 0.4

                        QGCColoredImage {
                            anchors.centerIn:   parent
                            width:              parent.width * 0.5
                            height:             width
                            source:             "/qmlimages/camera_photo.svg"
                            sourceSize.height:  height
                            fillMode:           Image.PreserveAspectFit
                            color:              "white"
                        }

                        MouseArea {
                            id:             photoArea
                            anchors.fill:   parent
                            enabled:        _canShootInCurrentMode
                            onClicked:      _shoot(true)
                        }
                    }

                    QGCLabel {
                        anchors.horizontalCenter:   parent.horizontalCenter
                        color:                      "white"
                        font.pointSize:             ScreenTools.smallFontPointSize
                        text:                       qsTr("Photo")
                    }
                }

                //-- RECORD
                Column {
                    visible:        !_onlySimpleCameraAvailable
                    spacing:        ScreenTools.defaultFontPixelHeight * 0.2

                    Rectangle {
                        width:                      _btnSize * 0.9
                        height:                     width
                        radius:                     width / 2
                        anchors.horizontalCenter:   parent.horizontalCenter
                        color:                      recordArea.pressed ? "#40FF4D4D" : "#1AFFFFFF"
                        border.color:               _isRecordingVideo ? _cdaRed : _cdaAccent
                        border.width:               2
                        opacity:                    _canShootInCurrentMode ? 1.0 : 0.4

                        Rectangle {
                            anchors.centerIn:   parent
                            width:              parent.width * (_isRecordingVideo ? 0.38 : 0.5)
                            height:             width
                            radius:             _isRecordingVideo ? width * 0.15 : width / 2
                            color:              _cdaRed
                        }

                        MouseArea {
                            id:             recordArea
                            anchors.fill:   parent
                            enabled:        _canShootInCurrentMode
                            onClicked:      _shoot(false)
                        }
                    }

                    QGCLabel {
                        anchors.horizontalCenter:   parent.horizontalCenter
                        color:                      _isRecordingVideo ? _cdaRed : "white"
                        font.pointSize:             ScreenTools.smallFontPointSize
                        font.bold:                  _isRecordingVideo
                        text:                       _isRecordingVideo ? _recTimeText : qsTr("Record")
                    }
                }

                //-- camera settings (only for a real MAVLink camera)
                QGCColoredImage {
                    visible:                !!_mavlinkCamera
                    anchors.verticalCenter: parent.verticalCenter
                    source:                 "/res/gear-black.svg"
                    mipmap:                 true
                    height:                 ScreenTools.defaultFontPixelHeight * 1.2
                    width:                  height
                    sourceSize.height:      height
                    color:                  "white"
                    fillMode:               Image.PreserveAspectFit

                    QGCMouseArea {
                        fillItem:   parent
                        onClicked:  {
                            _touched()
                            mainWindow.showPopupDialogFromComponent(settingsDialogComponent)
                        }
                    }
                }
            }
        }

        //-- the ONE small camera button
        Rectangle {
            id:                     cameraButton
            anchors.verticalCenter: parent.verticalCenter
            width:                  _btnSize
            height:                 width
            radius:                 width / 2
            color:                  "#D9081420"
            border.color:           _isRecordingVideo ? _cdaRed : (_expanded ? "white" : _cdaAccent)
            border.width:           2
            opacity:                (_expanded || cameraArea.pressed) ? 1.0 : 0.88

            QGCColoredImage {
                anchors.centerIn:   parent
                width:              parent.width * 0.5
                height:             width
                source:             "/qmlimages/camera_photo.svg"
                sourceSize.height:  height
                fillMode:           Image.PreserveAspectFit
                color:              "white"
            }

            //-- red blinking dot while recording
            Rectangle {
                id:                 recDot
                visible:            _isRecordingVideo
                anchors.top:        parent.top
                anchors.right:      parent.right
                width:              parent.width * 0.26
                height:             width
                radius:             width / 2
                color:              _cdaRed

                SequentialAnimation on opacity {
                    running:    recDot.visible
                    loops:      Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 600 }
                    NumberAnimation { to: 1.0;  duration: 600 }
                }
            }

            MouseArea {
                id:             cameraArea
                anchors.fill:   parent
                onClicked: {
                    _expanded = !_expanded
                    if (_expanded) {
                        autoHide.restart()
                    } else {
                        autoHide.stop()
                    }
                }
            }
        }
    }

    Component {
        id: settingsDialogComponent

        QGCPopupDialog {
            title:      qsTr("Settings")
            buttons:    StandardButton.Close

            ColumnLayout {
                spacing: _margins

                GridLayout {
                    id:     gridLayout
                    flow:   GridLayout.TopToBottom
                    rows:   dynamicRows + (_mavlinkCamera ? _mavlinkCamera.activeSettings.length : 0)

                    property int dynamicRows: 10

                    // First column
                    QGCLabel {
                        text:               qsTr("Camera")
                        visible:            _multipleMavlinkCameras
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Video Stream")
                        visible:            _multipleMavlinkCameraStreams
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Thermal View Mode")
                        visible:            _mavlinkCameraHasThermalVideoStream
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Blend Opacity")
                        visible:            _mavlinkCameraHasThermalVideoStream && _mavlinkCamera.thermalMode === QGCCameraControl.THERMAL_BLEND
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    // Mavlink Camera Protocol active settings
                    Repeater {
                        model: _mavlinkCamera ? _mavlinkCamera.activeSettings : []

                        QGCLabel {
                            text: _mavlinkCamera.getFact(modelData).shortDescription
                        }
                    }

                    QGCLabel {
                        text:               qsTr("Photo Mode")
                        visible:            _mavlinkCameraHasModes
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Photo Interval (seconds)")
                        visible:            _mavlinkCameraInPhotoMode && _mavlinkCamera.photoMode === QGCCameraControl.PHOTO_CAPTURE_TIMELAPSE
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Video Grid Lines")
                        visible:            _anyVideoStreamAvailable
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Video Screen Fit")
                        visible:            _anyVideoStreamAvailable
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Reset Camera Defaults")
                        visible:            _mavlinkCamera
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    QGCLabel {
                        text:               qsTr("Storage")
                        visible:            _mavlinkCameraStorageSupported
                        onVisibleChanged:   gridLayout.dynamicRows += visible ? 1 : -1
                    }

                    // Second column
                    QGCComboBox {
                        Layout.fillWidth:   true
                        sizeToContents:     true
                        model:              _mavlinkCameraManager ? _mavlinkCameraManager.cameraLabels : []
                        currentIndex:       _mavlinkCameraManagerCurCameraIndex
                        visible:            _multipleMavlinkCameras
                        onActivated:        _mavlinkCameraManager.currentCamera = index
                    }

                    QGCComboBox {
                        Layout.fillWidth:   true
                        sizeToContents:     true
                        model:              _mavlinkCamera ? _mavlinkCamera.streamLabels : []
                        currentIndex:       _mavlinCameraCurStreamIndex
                        visible:            _multipleMavlinkCameraStreams
                        onActivated:        _mavlinkCamera.currentStream = index
                    }

                    QGCComboBox {
                        Layout.fillWidth:   true
                        sizeToContents:     true
                        model:              [ qsTr("Off"), qsTr("Blend"), qsTr("Full"), qsTr("Picture In Picture") ]
                        currentIndex:       _mavlinkCamera ? _mavlinkCamera.thermalMode : -1
                        visible:            _mavlinkCameraHasThermalVideoStream
                        onActivated:        _mavlinkCamera.thermalMode = index
                    }

                    QGCSlider {
                        Layout.fillWidth:           true
                        maximumValue:               100
                        minimumValue:               0
                        value:                      _mavlinkCamera ? _mavlinkCamera.thermalOpacity : 0
                        updateValueWhileDragging:   true
                        visible:                    _mavlinkCameraHasThermalVideoStream && _mavlinkCamera.thermalMode === QGCCameraControl.THERMAL_BLEND
                        onValueChanged:             _mavlinkCamera.thermalOpacity = value
                    }

                    // Mavlink Camera Protocol active settings
                    Repeater {
                        model: _mavlinkCamera ? _mavlinkCamera.activeSettings : []

                        RowLayout {
                            Layout.fillWidth:   true
                            spacing:            ScreenTools.defaultFontPixelWidth

                            property var    _fact:      _mavlinkCamera.getFact(modelData)
                            property bool   _isBool:    _fact.typeIsBool
                            property bool   _isCombo:   !_isBool && _fact.enumStrings.length > 0
                            property bool   _isSlider:  _fact && !isNaN(_fact.increment)
                            property bool   _isEdit:    !_isBool && !_isSlider && _fact.enumStrings.length < 1

                            FactComboBox {
                                Layout.fillWidth:   true
                                sizeToContents:     true
                                fact:               parent._fact
                                indexModel:         false
                                visible:            parent._isCombo
                            }
                            FactTextField {
                                Layout.fillWidth:   true
                                fact:               parent._fact
                                visible:            parent._isEdit
                            }
                            QGCSlider {
                                Layout.fillWidth:           true
                                maximumValue:               parent._fact.max
                                minimumValue:               parent._fact.min
                                stepSize:                   parent._fact.increment
                                visible:                    parent._isSlider
                                updateValueWhileDragging:   false
                                onValueChanged:             parent._fact.value = value
                                Component.onCompleted:      value = parent._fact.value
                            }
                            QGCSwitch {
                                checked:        parent._fact ? parent._fact.value : false
                                visible:        parent._isBool
                                onClicked:      parent._fact.value = checked ? 1 : 0
                            }
                        }
                    }

                    QGCComboBox {
                        Layout.fillWidth:   true
                        sizeToContents:     true
                        model:              [ qsTr("Single"), qsTr("Time Lapse") ]
                        currentIndex:       _mavlinkCamera ? _mavlinkCamera.photoMode : 0
                        visible:            _mavlinkCameraHasModes
                        onActivated:        _mavlinkCamera.photoMode = index
                    }

                    QGCSlider {
                        Layout.fillWidth:           true
                        maximumValue:               60
                        minimumValue:               1
                        stepSize:                   1
                        value:                      _mavlinkCamera ? _mavlinkCamera.photoLapse : 5
                        displayValue:               true
                        updateValueWhileDragging:   true
                        visible:                    _mavlinkCameraInPhotoMode && _mavlinkCamera.photoMode === QGCCameraControl.PHOTO_CAPTURE_TIMELAPSE
                        onValueChanged: {
                            if (_mavlinkCamera) {
                                _mavlinkCamera.photoLapse = value
                            }
                        }
                    }

                    QGCSwitch {
                        checked:            _videoStreamSettings.gridLines.rawValue
                        visible:            _anyVideoStreamAvailable
                        onClicked:          _videoStreamSettings.gridLines.rawValue = checked ? 1 : 0
                    }

                    FactComboBox {
                        Layout.fillWidth:   true
                        sizeToContents:     true
                        fact:               _videoStreamSettings.videoFit
                        indexModel:         false
                        visible:            _anyVideoStreamAvailable
                    }

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Reset")
                        visible:            _mavlinkCamera
                        onClicked:          resetPrompt.open()
                        MessageDialog {
                            id:                 resetPrompt
                            title:              qsTr("Reset Camera to Factory Settings")
                            text:               qsTr("Confirm resetting all settings?")
                            standardButtons:    StandardButton.Yes | StandardButton.No
                            onNo: resetPrompt.close()
                            onYes: {
                                _mavlinkCamera.resetSettings()
                                resetPrompt.close()
                            }
                        }
                    }

                    QGCButton {
                        Layout.fillWidth:   true
                        text:               qsTr("Format")
                        visible:            _mavlinkCameraStorageSupported
                        onClicked:          formatPrompt.open()
                        MessageDialog {
                            id:                 formatPrompt
                            title:              qsTr("Format Camera Storage")
                            text:               qsTr("Confirm erasing all files?")
                            standardButtons:    StandardButton.Yes | StandardButton.No
                            onNo: formatPrompt.close()
                            onYes: {
                                _mavlinkCamera.formatCard()
                                formatPrompt.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
