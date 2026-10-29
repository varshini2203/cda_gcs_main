/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                      2.11
import QtQuick.Controls             2.4
import QtLocation                   5.3
import QtPositioning                5.3
import QtQuick.Dialogs              1.2

import QGroundControl               1.0
import QGroundControl.Airspace      1.0
import QGroundControl.DigitalSky     1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

FlightMap {
    id:                         _root
    allowGCSLocationCenter:     true
    allowVehicleLocationCenter: !_keepVehicleCentered
    planView:                   false
    zoomLevel:                  QGroundControl.flightMapZoom
    center:                     QGroundControl.flightMapPosition

    property Item pipState: _pipState
    QGCPipState {
        id:         _pipState
        pipOverlay: _pipOverlay
        isDark:     _isFullWindowItemDark
    }

    property var    rightPanelWidth
    property var    planMasterController
    property bool   pipMode:                    false   // true: map is shown in a small pip mode
    property var    toolInsets                          // Insets for the center viewport area

    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:      planMasterController
    property var    _geoFenceController:        planMasterController.geoFenceController
    property var    _rallyPointController:      planMasterController.rallyPointController
    property var    _activeVehicleCoordinate:   _activeVehicle ? _activeVehicle.coordinate : QtPositioning.coordinate()
    property real   _toolButtonTopMargin:       parent.height - mainWindow.height + (ScreenTools.defaultFontPixelHeight / 2)
    property real   _toolsMargin:               ScreenTools.defaultFontPixelWidth * 0.75
    property bool   _airspaceEnabled:           QGroundControl.airmapSupported ? (QGroundControl.settingsManager.airMapSettings.enableAirMap.rawValue && QGroundControl.airspaceManager.connected): false
    property var    _flyViewSettings:           QGroundControl.settingsManager.flyViewSettings
    property bool   _keepMapCenteredOnVehicle:  _flyViewSettings.keepMapCenteredOnVehicle.rawValue

    property bool   _disableVehicleTracking:    false

    property bool   _digitalSkyVisible:         false   // toggled by the Airspace button
    property bool   _digitalSkyLoaded:          false   // file is only read the first time it is shown
    property bool   _keepVehicleCentered:       pipMode ? true : false
    property bool   _saveZoomLevelSetting:      true

    function updateAirspace(reset) {
        if(_airspaceEnabled) {
            var coordinateNW = _root.toCoordinate(Qt.point(0,0), false /* clipToViewPort */)
            var coordinateSE = _root.toCoordinate(Qt.point(width,height), false /* clipToViewPort */)
            if(coordinateNW.isValid && coordinateSE.isValid) {
                QGroundControl.airspaceManager.setROI(coordinateNW, coordinateSE, false /*planView*/, reset)
            }
        }
    }

    function _adjustMapZoomForPipMode() {
        _saveZoomLevelSetting = false
        if (pipMode) {
            if (QGroundControl.flightMapZoom > 3) {
                zoomLevel = QGroundControl.flightMapZoom - 3
            }
        } else {
            zoomLevel = QGroundControl.flightMapZoom
        }
        _saveZoomLevelSetting = true
    }

    onPipModeChanged: _adjustMapZoomForPipMode()

    onVisibleChanged: {
        if (visible) {
            // Synchronize center position with Plan View
            center = QGroundControl.flightMapPosition
        }
    }

    onZoomLevelChanged: {
        if (_saveZoomLevelSetting) {
            QGroundControl.flightMapZoom = zoomLevel
            updateAirspace(false)
        }
    }
    onCenterChanged: {
        QGroundControl.flightMapPosition = center
        updateAirspace(false)
    }

    on_AirspaceEnabledChanged: {
        updateAirspace(true)
    }

    // We track whether the user has panned or not to correctly handle automatic map positioning
    Connections {
        target: gesture

        onPanStarted:       _disableVehicleTracking = true
        onFlickStarted:     _disableVehicleTracking = true
        onPanFinished:      panRecenterTimer.restart()
        onFlickFinished:    panRecenterTimer.restart()
    }

    function pointInRect(point, rect) {
        return point.x > rect.x &&
                point.x < rect.x + rect.width &&
                point.y > rect.y &&
                point.y < rect.y + rect.height;
    }

    property real _animatedLatitudeStart
    property real _animatedLatitudeStop
    property real _animatedLongitudeStart
    property real _animatedLongitudeStop
    property real animatedLatitude
    property real animatedLongitude

    onAnimatedLatitudeChanged: _root.center = QtPositioning.coordinate(animatedLatitude, animatedLongitude)
    onAnimatedLongitudeChanged: _root.center = QtPositioning.coordinate(animatedLatitude, animatedLongitude)

    NumberAnimation on animatedLatitude { id: animateLat; from: _animatedLatitudeStart; to: _animatedLatitudeStop; duration: 1000 }
    NumberAnimation on animatedLongitude { id: animateLong; from: _animatedLongitudeStart; to: _animatedLongitudeStop; duration: 1000 }

    function animatedMapRecenter(fromCoord, toCoord) {
        _animatedLatitudeStart = fromCoord.latitude
        _animatedLongitudeStart = fromCoord.longitude
        _animatedLatitudeStop = toCoord.latitude
        _animatedLongitudeStop = toCoord.longitude
        animateLat.start()
        animateLong.start()
    }

    function _insetRect() {
        return Qt.rect(toolInsets.leftEdgeCenterInset,
                       toolInsets.topEdgeCenterInset,
                       _root.width - toolInsets.leftEdgeCenterInset - toolInsets.rightEdgeCenterInset,
                       _root.height - toolInsets.topEdgeCenterInset - toolInsets.bottomEdgeCenterInset)
    }

    function recenterNeeded() {
        var vehiclePoint = _root.fromCoordinate(_activeVehicleCoordinate, false /* clipToViewport */)
        var insetRect = _insetRect()
        return !pointInRect(vehiclePoint, insetRect)
    }

    function updateMapToVehiclePosition() {
        if (animateLat.running || animateLong.running) {
            return
        }
        // We let FlightMap handle first vehicle position
        if (!_keepMapCenteredOnVehicle && firstVehiclePositionReceived && _activeVehicleCoordinate.isValid && !_disableVehicleTracking) {
            if (_keepVehicleCentered) {
                _root.center = _activeVehicleCoordinate
            } else {
                if (firstVehiclePositionReceived && recenterNeeded()) {
                    // Move the map such that the vehicle is centered within the inset area
                    var vehiclePoint = _root.fromCoordinate(_activeVehicleCoordinate, false /* clipToViewport */)
                    var insetRect = _insetRect()
                    var centerInsetPoint = Qt.point(insetRect.x + insetRect.width / 2, insetRect.y + insetRect.height / 2)
                    var centerOffset = Qt.point((_root.width / 2) - centerInsetPoint.x, (_root.height / 2) - centerInsetPoint.y)
                    var vehicleOffsetPoint = Qt.point(vehiclePoint.x + centerOffset.x, vehiclePoint.y + centerOffset.y)
                    var vehicleOffsetCoord = _root.toCoordinate(vehicleOffsetPoint, false /* clipToViewport */)
                    animatedMapRecenter(_root.center, vehicleOffsetCoord)
                }
            }
        }
    }

    on_ActiveVehicleCoordinateChanged: {
        if (_keepMapCenteredOnVehicle && _activeVehicleCoordinate.isValid && !_disableVehicleTracking) {
            _root.center = _activeVehicleCoordinate
        }
    }

    Timer {
        id:         panRecenterTimer
        interval:   10000
        running:    false
        onTriggered: {
            _disableVehicleTracking = false
            updateMapToVehiclePosition()
        }
    }

    Timer {
        interval:       500
        running:        true
        repeat:         true
        onTriggered:    updateMapToVehiclePosition()
    }

    QGCMapPalette { id: mapPal; lightColors: isSatelliteMap }

    Connections {
        target:                 _missionController
        ignoreUnknownSignals:   true
        onNewItemsFromVehicle: {
            var visualItems = _missionController.visualItems
            if (visualItems && visualItems.count !== 1) {
                mapFitFunctions.fitMapViewportToMissionItems()
                firstVehiclePositionReceived = true
            }
        }
    }

    MapFitFunctions {
        id:                         mapFitFunctions // The name for this id cannot be changed without breaking references outside of this code. Beware!
        map:                        _root
        usePlannedHomePosition:     false
        planMasterController:       _planMasterController
    }

    // Add trajectory lines to the map
    MapPolyline {
        id:         trajectoryPolyline
        line.width: 3
        line.color: "red"
        z:          QGroundControl.zOrderTrajectoryLines
        visible:    !pipMode

        Connections {
            target:                 QGroundControl.multiVehicleManager
            onActiveVehicleChanged: trajectoryPolyline.path = _activeVehicle ? _activeVehicle.trajectoryPoints.list() : []
        }

        Connections {
            target:                 _activeVehicle ? _activeVehicle.trajectoryPoints : null
            onPointAdded:           trajectoryPolyline.addCoordinate(coordinate)
            onUpdateLastPoint:      trajectoryPolyline.replaceCoordinate(trajectoryPolyline.pathLength() - 1, coordinate)
            onPointsCleared:        trajectoryPolyline.path = []
        }
    }

    // Add the vehicles to the map
    MapItemView {
        model: QGroundControl.multiVehicleManager.vehicles
        delegate: VehicleMapItem {
            vehicle:        object
            coordinate:     object.coordinate
            map:            _root
            size:           pipMode ? ScreenTools.defaultFontPixelHeight : ScreenTools.defaultFontPixelHeight * 3
            z:              QGroundControl.zOrderVehicles
        }
    }
    // Add distance sensor view
    MapItemView{
        model: QGroundControl.multiVehicleManager.vehicles
        delegate: ProximityRadarMapView {
            vehicle:        object
            coordinate:     object.coordinate
            map:            _root
            z:              QGroundControl.zOrderVehicles
        }
    }
    // Add ADSB vehicles to the map
    MapItemView {
        model: QGroundControl.adsbVehicleManager.adsbVehicles
        delegate: VehicleMapItem {
            coordinate:     object.coordinate
            altitude:       object.altitude
            callsign:       object.callsign
            heading:        object.heading
            alert:          object.alert
            map:            _root
            z:              QGroundControl.zOrderVehicles
        }
    }

    // Add the items associated with each vehicles flight plan to the map
    Repeater {
        model: QGroundControl.multiVehicleManager.vehicles

        PlanMapItems {
            map:                    _root
            largeMapView:           !pipMode
            planMasterController:   _planMasterController
            vehicle:                _vehicle

            property var _vehicle: object

            PlanMasterController {
                id: masterController
                Component.onCompleted: startStaticActiveVehicle(object)
            }
        }
    }

    MapItemView {
        model: pipMode ? undefined : _missionController.directionArrows

        delegate: MapLineArrow {
            fromCoord:      object ? object.coordinate1 : undefined
            toCoord:        object ? object.coordinate2 : undefined
            arrowPosition:  2
            z:              QGroundControl.zOrderWaypointLines
        }
    }

    // Allow custom builds to add map items
    CustomMapItems {
        map:            _root
        largeMapView:   !pipMode
    }

    GeoFenceMapVisuals {
        map:                    _root
        myGeoFenceController:   _geoFenceController
        interactive:            false
        planView:               false
        homePosition:           _activeVehicle && _activeVehicle.homePosition.isValid ? _activeVehicle.homePosition :  QtPositioning.coordinate()
    }

    // Rally points on map
    MapItemView {
        model: _rallyPointController.points

        delegate: MapQuickItem {
            id:             itemIndicator
            anchorPoint.x:  sourceItem.anchorPointX
            anchorPoint.y:  sourceItem.anchorPointY
            coordinate:     object.coordinate
            z:              QGroundControl.zOrderMapItems

            sourceItem: MissionItemIndexLabel {
                id:         itemIndexLabel
                label:      qsTr("R", "rally point map item label")
            }
        }
    }

    // Camera trigger points
    MapItemView {
        model: _activeVehicle ? _activeVehicle.cameraTriggerPoints : 0

        delegate: CameraTriggerIndicator {
            coordinate:     object.coordinate
            z:              QGroundControl.zOrderTopMost
        }
    }

    // GoTo Location visuals
    MapQuickItem {
        id:             gotoLocationItem
        visible:        false
        z:              QGroundControl.zOrderMapItems
        anchorPoint.x:  sourceItem.anchorPointX
        anchorPoint.y:  sourceItem.anchorPointY
        sourceItem: MissionItemIndexLabel {
            checked:    true
            index:      -1
            label:      qsTr("Go here", "Go to location waypoint")
        }

        property bool inGotoFlightMode: _activeVehicle ? _activeVehicle.flightMode === _activeVehicle.gotoFlightMode : false

        onInGotoFlightModeChanged: {
            if (!inGotoFlightMode && gotoLocationItem.visible) {
                // Hide goto indicator when vehicle falls out of guided mode
                gotoLocationItem.visible = false
            }
        }

        Connections {
            target: QGroundControl.multiVehicleManager
            onActiveVehicleChanged: {
                if (!activeVehicle) {
                    gotoLocationItem.visible = false
                }
            }
        }

        function show(coord) {
            gotoLocationItem.coordinate = coord
            gotoLocationItem.visible = true
        }

        function hide() {
            gotoLocationItem.visible = false
        }

        function actionConfirmed() {
            // We leave the indicator visible. The handling for onInGuidedModeChanged will hide it.
        }

        function actionCancelled() {
            hide()
        }
    }

    // Orbit editing visuals
    QGCMapCircleVisuals {
        id:             orbitMapCircle
        mapControl:     parent
        mapCircle:      _mapCircle
        visible:        false

        property alias center:              _mapCircle.center
        property alias clockwiseRotation:   _mapCircle.clockwiseRotation
        readonly property real defaultRadius: 30

        Connections {
            target: QGroundControl.multiVehicleManager
            onActiveVehicleChanged: {
                if (!activeVehicle) {
                    orbitMapCircle.visible = false
                }
            }
        }

        function show(coord) {
            _mapCircle.radius.rawValue = defaultRadius
            orbitMapCircle.center = coord
            orbitMapCircle.visible = true
        }

        function hide() {
            orbitMapCircle.visible = false
        }

        function actionConfirmed() {
            // Live orbit status is handled by telemetry so we hide here and telemetry will show again.
            hide()
        }

        function actionCancelled() {
            hide()
        }

        function radius() {
            return _mapCircle.radius.rawValue
        }

        Component.onCompleted: globals.guidedControllerFlyView.orbitMapCircle = orbitMapCircle

        QGCMapCircle {
            id:                 _mapCircle
            interactive:        true
            radius.rawValue:    30
            showRotation:       true
            clockwiseRotation:  true
        }
    }

    // ROI Location visuals
    MapQuickItem {
        id:             roiLocationItem
        visible:        _activeVehicle && _activeVehicle.isROIEnabled
        z:              QGroundControl.zOrderMapItems
        anchorPoint.x:  sourceItem.anchorPointX
        anchorPoint.y:  sourceItem.anchorPointY
        sourceItem: MissionItemIndexLabel {
            checked:    true
            index:      -1
            label:      qsTr("ROI here", "Make this a Region Of Interest")
        }

        //-- Visibilty controlled by actual state
        function show(coord) {
            roiLocationItem.coordinate = coord
        }

        function hide() {
        }

        function actionConfirmed() {
        }

        function actionCancelled() {
        }
    }

    // Orbit telemetry visuals
    QGCMapCircleVisuals {
        id:             orbitTelemetryCircle
        mapControl:     parent
        mapCircle:      _activeVehicle ? _activeVehicle.orbitMapCircle : null
        visible:        _activeVehicle ? _activeVehicle.orbitActive : false
    }

    MapQuickItem {
        id:             orbitCenterIndicator
        anchorPoint.x:  sourceItem.anchorPointX
        anchorPoint.y:  sourceItem.anchorPointY
        coordinate:     _activeVehicle ? _activeVehicle.orbitMapCircle.center : QtPositioning.coordinate()
        visible:        orbitTelemetryCircle.visible

        sourceItem: MissionItemIndexLabel {
            checked:    true
            index:      -1
            label:      qsTr("Orbit", "Orbit waypoint")
        }
    }

    // Handle guided mode clicks
    MouseArea {
        anchors.fill: parent

        QGCMenu {
            id: clickMenu
            property var coord
            QGCMenuItem {
                text:           qsTr("Go to location")
                visible:        globals.guidedControllerFlyView.showGotoLocation

                onTriggered: {
                    gotoLocationItem.show(clickMenu.coord)
                    globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionGoto, clickMenu.coord, gotoLocationItem)
                }
            }
            QGCMenuItem {
                text:           qsTr("Orbit at location")
                visible:        globals.guidedControllerFlyView.showOrbit

                onTriggered: {
                    orbitMapCircle.show(clickMenu.coord)
                    globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionOrbit, clickMenu.coord, orbitMapCircle)
                }
            }
            QGCMenuItem {
                text:           qsTr("ROI at location")
                visible:        globals.guidedControllerFlyView.showROI

                onTriggered: {
                    roiLocationItem.show(clickMenu.coord)
                    globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionROI, clickMenu.coord, roiLocationItem)
                }
            }
        }

        onClicked: {
            if (!globals.guidedControllerFlyView.guidedUIVisible && (globals.guidedControllerFlyView.showGotoLocation || globals.guidedControllerFlyView.showOrbit || globals.guidedControllerFlyView.showROI)) {
                orbitMapCircle.hide()
                gotoLocationItem.hide()
                var clickCoord = _root.toCoordinate(Qt.point(mouse.x, mouse.y), false /* clipToViewPort */)
                clickMenu.coord = clickCoord
                clickMenu.popup()
            }
        }
    }

    // Digital Sky zones (India)
    DigitalSkyZones { id: digitalSkyZones; sourceUrl: _root._digitalSkyLoaded ? "file:///D:/zones/digitalsky.geojson" : "" }
    MapItemView {
        model: _root._digitalSkyVisible ? digitalSkyZones.circles : []
        delegate: MapCircle {
            center:         modelData.center
            radius:         modelData.radius
            color:          modelData.color
            border.color:   modelData.lineColor
            border.width:   2
        }
    }
    MapItemView {
        model: _root._digitalSkyVisible ? digitalSkyZones.polygons : []
        delegate: MapPolygon {
            path:           modelData.path
            color:          modelData.color
            border.color:   modelData.lineColor
            border.width:   modelData.zone === "green" ? 0 : 2
        }
    }

    // Airspace overlap support
    MapItemView {
        model:              _airspaceEnabled && QGroundControl.settingsManager.airMapSettings.enableAirspace && QGroundControl.airspaceManager.airspaceVisible ? QGroundControl.airspaceManager.airspaces.circles : []
        delegate: MapCircle {
            center:         object.center
            radius:         object.radius
            color:          object.color
            border.color:   object.lineColor
            border.width:   object.lineWidth
        }
    }

    MapItemView {
        model:              _airspaceEnabled && QGroundControl.settingsManager.airMapSettings.enableAirspace && QGroundControl.airspaceManager.airspaceVisible ? QGroundControl.airspaceManager.airspaces.polygons : []
        delegate: MapPolygon {
            path:           object.polygon
            color:          object.color
            border.color:   object.lineColor
            border.width:   object.lineWidth
        }
    }

    // ---- CDA Airspace zones (red / yellow / green) ----
    property bool _cdaAirspaceOn: false

    // ---- Approximate India drone airspace (red / yellow / green) ----
    // Generated by tools/build_zones.py. p = [lat,lon,lat,lon,...]. Draw order = list order.
    // Airport circles + 25 km border strip + J&K/Ladakh are APPROXIMATE. Verify on DigitalSky before flight.
    property var _cdaZones: [
        {z:"green",p:[32.994,79.209,32.484,79.176,32.574,78.695,32.521,78.483,32.262,78.549,31.516,78.739,31.209,79.216,30.883,79.721,30.629,80.226,30.183,81.111,30.183,81.111,30.183,81.111,29.756,80.513,29.73,80.477,28.794,80.088,28.416,81.057,27.925,82.0,27.787,82.322,27.365,83.304,27.235,84.675,26.924,85.027,26.726,85.252,26.631,86.024,26.445,86.987,26.398,87.227,26.415,88.06,26.81,88.175,27.446,88.043,27.446,88.043,27.446,88.043,27.877,88.12,28.087,88.73,28.087,88.73,28.087,88.73,27.099,88.836,27.099,88.836,26.719,89.745,26.764,89.924,26.876,90.373,26.829,90.967,26.809,91.218,26.833,91.876,26.838,92.033,27.15,92.069,27.453,92.104,27.772,91.697,27.772,91.697,27.772,91.697,27.897,92.503,28.404,93.124,28.641,93.413,29.277,94.566,29.277,94.566,29.277,94.566,29.208,94.802,29.032,95.405,29.137,95.583,29.453,96.118,28.831,96.587,28.831,96.587,28.831,96.587,28.441,96.273,28.411,96.249,28.262,97.327,28.262,97.327,28.262,97.327,28.026,97.374,27.883,97.403,27.883,97.403,27.883,97.403,27.699,97.052,27.631,97.061,27.084,97.134,27.084,97.134,27.084,97.134,27.265,96.419,26.574,95.125,26.001,95.155,26.001,95.155,25.162,94.603,24.675,94.553,23.851,94.107,23.871,94.036,24.079,93.325,23.093,93.288,23.044,93.286,22.703,93.06,22.278,93.166,22.041,92.673,23.627,92.146,23.624,91.87,22.985,91.706,23.504,91.159,23.504,91.159,23.504,91.159,23.836,91.339,24.073,91.468,24.117,91.812,24.13,91.915,24.402,92.063,24.977,92.376,25.147,91.8,25.142,91.443,25.133,90.872,25.27,89.921,25.965,89.832,26.014,89.355,26.153,89.101,26.447,88.563,26.117,88.392,25.768,88.21,25.657,88.362,25.239,88.932,25.239,88.932,25.239,88.932,25.151,88.784,24.866,88.306,24.55,88.114,24.502,88.084,24.453,88.196,24.234,88.7,24.234,88.7,24.234,88.7,23.817,88.582,23.631,88.53,22.879,88.876,22.694,88.911,22.056,89.032,21.826,88.942,21.826,88.942,21.691,88.889,21.703,88.208,21.496,86.976,20.743,87.033,20.152,86.499,19.479,85.06,18.302,83.941,17.671,83.189,17.017,82.193,16.557,82.191,16.31,81.693,15.952,80.792,15.899,80.325,15.136,80.025,13.836,80.233,13.006,80.286,12.056,79.863,10.357,79.858,10.309,79.341,9.546,78.885,9.217,79.19,8.933,78.278,8.253,77.941,7.966,77.54,8.899,76.593,10.3,76.13,11.308,75.746,11.781,75.396,12.742,74.865,13.993,74.617,14.617,74.444,15.991,73.534,17.929,73.12,19.208,72.821,20.42,72.824,21.356,72.631,20.757,71.175,20.877,70.47,22.089,69.164,22.451,69.645,22.843,69.35,23.551,68.371,23.55,68.371,23.692,68.177,23.692,68.177,23.692,68.177,23.692,68.177,24.308,68.791,24.359,68.843,24.359,69.063,24.357,71.043,25.215,70.845,25.722,70.283,25.949,70.249,26.492,70.169,26.941,69.514,26.941,69.514,26.941,69.514,27.989,70.616,27.943,71.326,27.913,71.778,28.96,72.822,28.962,72.824,29.976,73.451,30.194,73.661,30.98,74.421,31.346,74.413,31.693,74.406,31.693,74.406,31.693,74.406,32.271,75.259,32.391,75.062,32.5,74.7,32.75,74.2,32.9,74.0,34.2,73.4,35.0,73.9,35.6,72.6,36.8,72.9,37.0,74.5,37.1,75.9,35.5,77.8,35.5,78.9,35.3,80.3,33.3,79.5,33.003,79.203]},
        {z:"red",p:[32.994,79.209,32.484,79.176,32.574,78.695,32.521,78.483,31.516,78.739,30.883,79.721,30.183,81.111,29.73,80.477,28.794,80.088,28.416,81.057,27.925,82.0,27.365,83.304,27.235,84.675,26.726,85.252,26.631,86.024,26.398,87.227,26.415,88.06,26.81,88.175,27.446,88.043,27.877,88.12,28.087,88.73,27.099,88.836,26.719,89.745,26.876,90.373,26.809,91.218,26.838,92.033,27.453,92.104,27.772,91.697,27.897,92.503,28.641,93.413,29.277,94.566,29.032,95.405,29.453,96.118,28.831,96.587,28.411,96.249,28.262,97.327,27.883,97.403,27.699,97.052,27.084,97.134,27.265,96.419,26.574,95.125,26.001,95.155,25.162,94.603,24.675,94.553,23.851,94.107,24.079,93.325,23.044,93.286,22.703,93.06,22.278,93.166,22.041,92.673,23.627,92.146,23.624,91.87,22.985,91.706,23.504,91.159,24.073,91.468,24.13,91.915,24.977,92.376,25.147,91.8,25.133,90.872,25.27,89.921,25.965,89.832,26.014,89.355,26.447,88.563,25.768,88.21,25.239,88.932,24.866,88.306,24.502,88.084,24.234,88.7,23.631,88.53,22.879,88.876,22.056,89.032,21.826,88.942,21.977,88.827,22.787,88.673,23.556,88.325,23.689,88.321,24.075,88.429,24.279,87.974,24.439,87.877,24.636,87.901,25.042,88.148,25.262,88.482,25.556,88.083,25.658,88.016,25.865,88.012,26.194,88.179,26.149,88.064,26.133,87.213,26.367,85.998,26.465,85.209,26.973,84.601,27.104,83.254,27.67,81.932,28.159,80.987,28.568,79.971,28.742,79.881,28.925,79.903,29.906,80.314,30.138,80.606,30.63,79.631,31.349,78.569,32.524,78.261,32.569,78.261,32.8,77.8,33.0,76.8,32.7,75.8,32.465,75.398,32.32,75.465,32.106,75.429,31.52,74.619,30.962,74.631,30.795,74.579,29.777,73.599,28.766,72.972,27.699,71.907,27.643,71.767,27.714,70.682,26.976,69.906,26.659,70.335,25.873,70.477,25.355,71.025,24.403,71.254,24.21,71.22,24.097,71.044,24.099,68.919,23.55,68.371,23.692,68.177,24.359,68.843,24.357,71.043,25.215,70.845,25.722,70.283,26.492,70.169,26.941,69.514,27.989,70.616,27.913,71.778,28.962,72.824,29.976,73.451,30.98,74.421,31.693,74.406,32.271,75.259,32.391,75.062,32.5,74.7,32.75,74.2,32.9,74.0,34.2,73.4,35.0,73.9,35.6,72.6,36.8,72.9,37.0,74.5,37.1,75.9,35.5,77.8,35.5,78.9,35.3,80.3,33.3,79.5,33.003,79.203]},
        {z:"green",p:[26.693,88.482,26.707,88.608,26.275,89.408,26.202,89.927,26.055,90.033,25.507,90.106,25.395,90.883,25.409,91.814,25.19,92.5,25.024,92.586,24.854,92.565,23.987,92.093,23.884,91.981,23.875,92.208,23.768,92.326,22.373,92.793,22.427,92.905,22.776,92.854,23.138,93.075,24.211,93.141,24.3,93.214,24.338,93.334,24.145,94.011,24.768,94.347,25.288,94.416,26.088,94.937,26.581,94.912,26.763,94.976,27.521,96.356,27.423,96.874,27.807,96.858,27.925,96.936,28.019,97.105,28.141,96.226,28.203,96.113,28.336,96.046,28.495,96.048,28.836,96.286,29.123,96.07,28.758,95.417,28.99,94.586,28.398,93.512,27.657,92.6,27.591,92.286,27.44,92.315,26.774,92.24,26.658,92.19,26.586,92.102,26.542,91.223,26.607,90.387,26.459,89.699,26.899,88.695,27.036,88.629,27.745,88.553,27.658,88.298,27.45,88.261,26.825,88.387,26.385,88.278]},
        {z:"green",p:[23.56,91.446,23.419,91.593,23.746,91.681,23.851,91.767,23.828,91.591]},
        {z:"yellow",p:[23.203,72.635,23.2,72.665,23.191,72.694,23.176,72.72,23.156,72.742,23.132,72.758,23.105,72.768,23.077,72.771,23.049,72.768,23.023,72.758,22.999,72.742,22.979,72.72,22.964,72.694,22.955,72.665,22.951,72.635,22.955,72.604,22.964,72.575,22.979,72.549,22.999,72.528,23.023,72.512,23.049,72.501,23.077,72.498,23.105,72.501,23.132,72.512,23.156,72.528,23.176,72.549,23.191,72.575,23.2,72.604]},
        {z:"yellow",p:[20.825,77.059,20.822,77.089,20.812,77.117,20.797,77.142,20.777,77.164,20.754,77.18,20.727,77.19,20.699,77.193,20.671,77.19,20.644,77.18,20.621,77.164,20.601,77.142,20.586,77.117,20.576,77.089,20.573,77.059,20.576,77.029,20.586,77.0,20.601,76.975,20.621,76.953,20.644,76.937,20.671,76.928,20.699,76.924,20.727,76.928,20.754,76.937,20.777,76.953,20.797,76.975,20.812,77.0,20.822,77.029]},
        {z:"yellow",p:[19.988,75.398,19.985,75.428,19.976,75.456,19.961,75.481,19.941,75.503,19.917,75.519,19.891,75.528,19.863,75.532,19.835,75.528,19.808,75.519,19.784,75.503,19.764,75.481,19.749,75.456,19.74,75.428,19.737,75.398,19.74,75.368,19.749,75.34,19.764,75.315,19.784,75.294,19.808,75.278,19.835,75.268,19.863,75.264,19.891,75.268,19.917,75.278,19.941,75.294,19.961,75.315,19.976,75.34,19.985,75.368]},
        {z:"yellow",p:[19.214,72.868,19.211,72.898,19.202,72.926,19.187,72.951,19.167,72.972,19.143,72.988,19.117,72.998,19.089,73.001,19.061,72.998,19.034,72.988,19.01,72.972,18.99,72.951,18.975,72.926,18.966,72.898,18.963,72.868,18.966,72.838,18.975,72.81,18.99,72.785,19.01,72.764,19.034,72.748,19.061,72.738,19.089,72.735,19.117,72.738,19.143,72.748,19.167,72.764,19.187,72.785,19.202,72.81,19.211,72.838]},
        {z:"yellow",p:[22.114,82.111,22.111,82.141,22.102,82.17,22.087,82.196,22.067,82.217,22.043,82.233,22.016,82.243,21.988,82.247,21.96,82.243,21.934,82.233,21.91,82.217,21.89,82.196,21.875,82.17,21.866,82.141,21.863,82.111,21.866,82.081,21.875,82.052,21.89,82.026,21.91,82.005,21.934,81.989,21.96,81.979,21.988,81.975,22.016,81.979,22.043,81.989,22.067,82.005,22.087,82.026,22.102,82.052,22.111,82.081]},
        {z:"yellow",p:[23.414,69.67,23.41,69.701,23.401,69.73,23.386,69.756,23.366,69.777,23.342,69.794,23.316,69.804,23.288,69.807,23.26,69.804,23.233,69.794,23.209,69.777,23.189,69.756,23.174,69.73,23.165,69.701,23.162,69.67,23.165,69.64,23.174,69.611,23.189,69.585,23.209,69.563,23.233,69.547,23.26,69.537,23.288,69.533,23.316,69.537,23.342,69.547,23.366,69.563,23.386,69.585,23.401,69.611,23.41,69.64]},
        {z:"yellow",p:[15.985,74.618,15.982,74.647,15.973,74.675,15.958,74.7,15.938,74.721,15.914,74.736,15.887,74.746,15.859,74.749,15.831,74.746,15.805,74.736,15.781,74.721,15.761,74.7,15.746,74.675,15.737,74.647,15.734,74.618,15.737,74.589,15.746,74.562,15.761,74.537,15.781,74.516,15.805,74.501,15.831,74.491,15.859,74.488,15.887,74.491,15.914,74.501,15.938,74.516,15.958,74.537,15.973,74.562,15.982,74.589]},
        {z:"yellow",p:[22.462,73.226,22.459,73.257,22.45,73.285,22.435,73.311,22.415,73.333,22.391,73.349,22.364,73.359,22.336,73.362,22.308,73.359,22.282,73.349,22.258,73.333,22.238,73.311,22.223,73.285,22.214,73.257,22.21,73.226,22.214,73.196,22.223,73.167,22.238,73.142,22.258,73.12,22.282,73.104,22.308,73.094,22.336,73.09,22.364,73.094,22.391,73.104,22.415,73.12,22.435,73.142,22.45,73.167,22.459,73.196]},
        {z:"yellow",p:[23.413,77.337,23.41,77.368,23.401,77.397,23.386,77.423,23.366,77.444,23.342,77.461,23.315,77.471,23.288,77.474,23.26,77.471,23.233,77.461,23.209,77.444,23.189,77.423,23.174,77.397,23.165,77.368,23.162,77.337,23.165,77.307,23.174,77.278,23.189,77.252,23.209,77.23,23.233,77.214,23.26,77.204,23.288,77.2,23.315,77.204,23.342,77.214,23.366,77.23,23.386,77.252,23.401,77.278,23.41,77.307]},
        {z:"yellow",p:[21.878,72.185,21.875,72.215,21.866,72.244,21.851,72.27,21.831,72.291,21.807,72.307,21.78,72.317,21.752,72.321,21.724,72.317,21.698,72.307,21.674,72.291,21.654,72.27,21.639,72.244,21.63,72.215,21.626,72.185,21.63,72.155,21.639,72.126,21.654,72.101,21.674,72.079,21.698,72.063,21.724,72.053,21.752,72.05,21.78,72.053,21.807,72.063,21.831,72.079,21.851,72.101,21.866,72.126,21.875,72.155]},
        {z:"yellow",p:[20.56,72.843,20.557,72.873,20.548,72.901,20.533,72.927,20.513,72.948,20.489,72.964,20.462,72.974,20.434,72.977,20.406,72.974,20.38,72.964,20.356,72.948,20.336,72.927,20.321,72.901,20.312,72.873,20.309,72.843,20.312,72.813,20.321,72.785,20.336,72.76,20.356,72.738,20.38,72.722,20.406,72.712,20.434,72.709,20.462,72.712,20.489,72.722,20.513,72.738,20.533,72.76,20.548,72.785,20.557,72.813]},
        {z:"yellow",p:[24.78,77.347,24.777,77.378,24.768,77.407,24.753,77.434,24.733,77.455,24.709,77.472,24.683,77.482,24.655,77.486,24.627,77.482,24.6,77.472,24.576,77.455,24.556,77.434,24.541,77.407,24.532,77.378,24.529,77.347,24.532,77.317,24.541,77.287,24.556,77.261,24.576,77.239,24.6,77.223,24.627,77.212,24.655,77.209,24.683,77.212,24.709,77.223,24.733,77.239,24.753,77.261,24.768,77.287,24.777,77.317]},
        {z:"yellow",p:[15.507,73.831,15.503,73.86,15.494,73.888,15.479,73.913,15.459,73.933,15.435,73.949,15.409,73.959,15.381,73.962,15.353,73.959,15.326,73.949,15.302,73.933,15.282,73.913,15.267,73.888,15.258,73.86,15.255,73.831,15.258,73.802,15.267,73.775,15.282,73.75,15.302,73.729,15.326,73.714,15.353,73.704,15.381,73.701,15.409,73.704,15.435,73.714,15.459,73.729,15.479,73.75,15.494,73.775,15.503,73.802]},
        {z:"yellow",p:[22.848,75.801,22.844,75.831,22.835,75.86,22.82,75.886,22.8,75.908,22.776,75.924,22.75,75.934,22.722,75.937,22.694,75.934,22.667,75.924,22.643,75.908,22.623,75.886,22.608,75.86,22.599,75.831,22.596,75.801,22.599,75.771,22.608,75.742,22.623,75.716,22.643,75.695,22.667,75.678,22.694,75.668,22.722,75.665,22.75,75.668,22.776,75.678,22.8,75.695,22.82,75.716,22.835,75.742,22.844,75.771]},
        {z:"yellow",p:[23.304,80.052,23.3,80.082,23.291,80.111,23.276,80.137,23.256,80.159,23.232,80.175,23.206,80.185,23.178,80.189,23.15,80.185,23.123,80.175,23.099,80.159,23.079,80.137,23.064,80.111,23.055,80.082,23.052,80.052,23.055,80.022,23.064,79.993,23.079,79.967,23.099,79.945,23.123,79.929,23.15,79.919,23.178,79.915,23.206,79.919,23.232,79.929,23.256,79.945,23.276,79.967,23.291,79.993,23.3,80.022]},
        {z:"yellow",p:[22.591,70.013,22.588,70.043,22.579,70.072,22.564,70.097,22.544,70.119,22.52,70.135,22.493,70.145,22.465,70.149,22.438,70.145,22.411,70.135,22.387,70.119,22.367,70.097,22.352,70.072,22.343,70.043,22.34,70.013,22.343,69.982,22.352,69.954,22.367,69.928,22.387,69.906,22.411,69.89,22.438,69.88,22.465,69.877,22.493,69.88,22.52,69.89,22.544,69.906,22.564,69.928,22.579,69.954,22.588,69.982]},
        {z:"yellow",p:[23.238,70.1,23.235,70.131,23.226,70.16,23.211,70.186,23.191,70.207,23.167,70.224,23.141,70.234,23.113,70.237,23.085,70.234,23.058,70.224,23.034,70.207,23.014,70.186,22.999,70.16,22.99,70.131,22.987,70.1,22.99,70.07,22.999,70.041,23.014,70.015,23.034,69.993,23.058,69.977,23.085,69.967,23.113,69.964,23.141,69.967,23.167,69.977,23.191,69.993,23.211,70.015,23.226,70.041,23.235,70.07]},
        {z:"yellow",p:[24.943,79.919,24.94,79.949,24.931,79.979,24.916,80.005,24.896,80.027,24.872,80.043,24.845,80.054,24.817,80.057,24.789,80.054,24.763,80.043,24.739,80.027,24.719,80.005,24.704,79.979,24.695,79.949,24.691,79.919,24.695,79.888,24.704,79.858,24.719,79.832,24.739,79.81,24.763,79.794,24.789,79.784,24.817,79.78,24.845,79.784,24.872,79.794,24.896,79.81,24.916,79.832,24.931,79.858,24.94,79.888]},
        {z:"yellow",p:[16.79,74.289,16.787,74.319,16.778,74.346,16.763,74.371,16.743,74.392,16.719,74.408,16.693,74.417,16.665,74.421,16.637,74.417,16.61,74.408,16.586,74.392,16.566,74.371,16.551,74.346,16.542,74.319,16.539,74.289,16.542,74.26,16.551,74.232,16.566,74.208,16.586,74.187,16.61,74.171,16.637,74.161,16.665,74.158,16.693,74.161,16.719,74.171,16.743,74.187,16.763,74.208,16.778,74.232,16.787,74.26]},
        {z:"yellow",p:[21.443,70.27,21.44,70.3,21.43,70.329,21.415,70.355,21.396,70.376,21.372,70.392,21.345,70.402,21.317,70.405,21.289,70.402,21.263,70.392,21.239,70.376,21.219,70.355,21.204,70.329,21.194,70.3,21.191,70.27,21.194,70.24,21.204,70.212,21.219,70.186,21.239,70.165,21.263,70.149,21.289,70.139,21.317,70.135,21.345,70.139,21.372,70.149,21.396,70.165,21.415,70.186,21.43,70.212,21.44,70.24]},
        {z:"yellow",p:[21.218,79.047,21.215,79.077,21.206,79.106,21.191,79.131,21.171,79.153,21.147,79.169,21.12,79.179,21.092,79.182,21.064,79.179,21.038,79.169,21.014,79.153,20.994,79.131,20.979,79.106,20.97,79.077,20.966,79.047,20.97,79.017,20.979,78.989,20.994,78.963,21.014,78.942,21.038,78.926,21.064,78.916,21.092,78.912,21.12,78.916,21.147,78.926,21.171,78.942,21.191,78.963,21.206,78.989,21.215,79.017]},
        {z:"yellow",p:[20.245,73.913,20.242,73.943,20.232,73.971,20.217,73.996,20.198,74.018,20.174,74.034,20.147,74.043,20.119,74.047,20.091,74.043,20.065,74.034,20.041,74.018,20.021,73.996,20.006,73.971,19.996,73.943,19.993,73.913,19.996,73.883,20.006,73.855,20.021,73.829,20.041,73.808,20.065,73.792,20.091,73.782,20.119,73.779,20.147,73.782,20.174,73.792,20.198,73.808,20.217,73.829,20.232,73.855,20.242,73.883]},
        {z:"yellow",p:[18.708,73.92,18.705,73.949,18.695,73.977,18.68,74.002,18.661,74.023,18.637,74.039,18.61,74.049,18.582,74.052,18.554,74.049,18.528,74.039,18.504,74.023,18.484,74.002,18.469,73.977,18.459,73.949,18.456,73.92,18.459,73.89,18.469,73.862,18.484,73.837,18.504,73.816,18.528,73.8,18.554,73.79,18.582,73.787,18.61,73.79,18.637,73.8,18.661,73.816,18.68,73.837,18.695,73.862,18.705,73.89]},
        {z:"yellow",p:[21.774,69.657,21.771,69.687,21.762,69.716,21.747,69.742,21.727,69.763,21.703,69.779,21.677,69.789,21.649,69.793,21.621,69.789,21.594,69.779,21.57,69.763,21.55,69.742,21.535,69.716,21.526,69.687,21.523,69.657,21.526,69.627,21.535,69.598,21.55,69.573,21.57,69.551,21.594,69.535,21.621,69.525,21.649,69.522,21.677,69.525,21.703,69.535,21.727,69.551,21.747,69.573,21.762,69.598,21.771,69.627]},
        {z:"yellow",p:[22.435,70.78,22.432,70.81,22.423,70.838,22.408,70.864,22.388,70.886,22.364,70.902,22.337,70.912,22.309,70.915,22.281,70.912,22.255,70.902,22.231,70.886,22.211,70.864,22.196,70.838,22.187,70.81,22.183,70.78,22.187,70.749,22.196,70.721,22.211,70.695,22.231,70.673,22.255,70.657,22.281,70.647,22.309,70.644,22.337,70.647,22.364,70.657,22.388,70.673,22.408,70.695,22.423,70.721,22.432,70.749]},
        {z:"yellow",p:[21.306,81.739,21.303,81.769,21.294,81.797,21.279,81.823,21.259,81.844,21.235,81.86,21.208,81.87,21.18,81.874,21.152,81.87,21.126,81.86,21.102,81.844,21.082,81.823,21.067,81.797,21.058,81.769,21.055,81.739,21.058,81.709,21.067,81.68,21.082,81.655,21.102,81.633,21.126,81.617,21.152,81.607,21.18,81.604,21.208,81.607,21.235,81.617,21.259,81.633,21.279,81.655,21.294,81.68,21.303,81.709]},
        {z:"yellow",p:[17.754,75.935,17.751,75.964,17.741,75.992,17.726,76.017,17.706,76.038,17.683,76.054,17.656,76.063,17.628,76.067,17.6,76.063,17.573,76.054,17.55,76.038,17.53,76.017,17.515,75.992,17.505,75.964,17.502,75.935,17.505,75.905,17.515,75.878,17.53,75.853,17.55,75.832,17.573,75.816,17.6,75.806,17.628,75.803,17.656,75.806,17.683,75.816,17.706,75.832,17.726,75.853,17.741,75.878,17.751,75.905]},
        {z:"yellow",p:[21.24,72.742,21.237,72.772,21.227,72.8,21.212,72.826,21.193,72.847,21.169,72.863,21.142,72.873,21.114,72.877,21.086,72.873,21.06,72.863,21.036,72.847,21.016,72.826,21.001,72.8,20.991,72.772,20.988,72.742,20.991,72.712,21.001,72.683,21.016,72.658,21.036,72.636,21.06,72.62,21.086,72.61,21.114,72.607,21.142,72.61,21.169,72.62,21.193,72.636,21.212,72.658,21.227,72.683,21.237,72.712]},
        {z:"yellow",p:[24.743,73.896,24.74,73.927,24.731,73.956,24.716,73.982,24.696,74.004,24.672,74.021,24.646,74.031,24.618,74.034,24.59,74.031,24.563,74.021,24.539,74.004,24.519,73.982,24.504,73.956,24.495,73.927,24.492,73.896,24.495,73.865,24.504,73.836,24.519,73.81,24.539,73.788,24.563,73.771,24.59,73.761,24.618,73.758,24.646,73.761,24.672,73.771,24.696,73.788,24.716,73.81,24.731,73.836,24.74,73.865]},
        {z:"yellow",p:[28.301,94.802,28.298,94.834,28.289,94.864,28.274,94.891,28.254,94.914,28.23,94.931,28.203,94.941,28.175,94.945,28.147,94.941,28.121,94.931,28.097,94.914,28.077,94.891,28.062,94.864,28.053,94.834,28.05,94.802,28.053,94.77,28.062,94.74,28.077,94.713,28.097,94.69,28.121,94.673,28.147,94.663,28.175,94.659,28.203,94.663,28.23,94.673,28.254,94.69,28.274,94.713,28.289,94.74,28.298,94.77]},
        {z:"yellow",p:[24.013,91.24,24.01,91.271,24.0,91.3,23.985,91.326,23.965,91.348,23.942,91.364,23.915,91.374,23.887,91.378,23.859,91.374,23.832,91.364,23.809,91.348,23.789,91.326,23.774,91.3,23.764,91.271,23.761,91.24,23.764,91.21,23.774,91.181,23.789,91.155,23.809,91.133,23.832,91.116,23.859,91.106,23.887,91.103,23.915,91.106,23.942,91.116,23.965,91.133,23.985,91.155,24.0,91.181,24.01,91.21]},
        {z:"yellow",p:[23.966,92.62,23.963,92.65,23.954,92.679,23.939,92.705,23.919,92.727,23.895,92.744,23.869,92.754,23.841,92.757,23.813,92.754,23.786,92.744,23.762,92.727,23.742,92.705,23.727,92.679,23.718,92.65,23.715,92.62,23.718,92.589,23.727,92.56,23.742,92.534,23.762,92.512,23.786,92.496,23.813,92.486,23.841,92.482,23.869,92.486,23.895,92.496,23.919,92.512,23.939,92.534,23.954,92.56,23.963,92.589]},
        {z:"yellow",p:[26.807,88.329,26.804,88.36,26.795,88.39,26.78,88.416,26.76,88.439,26.736,88.455,26.709,88.466,26.681,88.469,26.653,88.466,26.627,88.455,26.603,88.439,26.583,88.416,26.568,88.39,26.559,88.36,26.555,88.329,26.559,88.297,26.568,88.268,26.583,88.241,26.603,88.219,26.627,88.202,26.653,88.191,26.681,88.188,26.709,88.191,26.736,88.202,26.76,88.219,26.78,88.241,26.795,88.268,26.804,88.297]},
        {z:"yellow",p:[20.37,85.818,20.367,85.848,20.358,85.876,20.343,85.901,20.323,85.923,20.299,85.939,20.272,85.948,20.244,85.952,20.216,85.948,20.19,85.939,20.166,85.923,20.146,85.901,20.131,85.876,20.122,85.848,20.119,85.818,20.122,85.788,20.131,85.76,20.146,85.734,20.166,85.713,20.19,85.697,20.216,85.687,20.244,85.684,20.272,85.687,20.299,85.697,20.323,85.713,20.343,85.734,20.358,85.76,20.367,85.788]},
        {z:"yellow",p:[22.78,88.447,22.777,88.477,22.768,88.506,22.753,88.532,22.733,88.553,22.709,88.569,22.683,88.58,22.655,88.583,22.627,88.58,22.6,88.569,22.576,88.553,22.556,88.532,22.541,88.506,22.532,88.477,22.529,88.447,22.532,88.416,22.541,88.388,22.556,88.362,22.576,88.34,22.6,88.324,22.627,88.314,22.655,88.31,22.683,88.314,22.709,88.324,22.733,88.34,22.753,88.362,22.768,88.388,22.777,88.416]},
        {z:"yellow",p:[26.456,89.467,26.453,89.498,26.444,89.528,26.429,89.555,26.409,89.577,26.385,89.594,26.358,89.604,26.33,89.608,26.303,89.604,26.276,89.594,26.252,89.577,26.232,89.555,26.217,89.528,26.208,89.498,26.205,89.467,26.208,89.436,26.217,89.406,26.232,89.38,26.252,89.357,26.276,89.341,26.303,89.33,26.33,89.327,26.358,89.33,26.385,89.341,26.409,89.357,26.429,89.38,26.444,89.406,26.453,89.436]},
        {z:"yellow",p:[23.96,86.425,23.957,86.456,23.947,86.485,23.932,86.511,23.912,86.533,23.889,86.549,23.862,86.559,23.834,86.563,23.806,86.559,23.779,86.549,23.756,86.533,23.736,86.511,23.721,86.485,23.711,86.456,23.708,86.425,23.711,86.395,23.721,86.366,23.736,86.34,23.756,86.318,23.779,86.301,23.806,86.291,23.834,86.288,23.862,86.291,23.889,86.301,23.912,86.318,23.932,86.34,23.947,86.366,23.957,86.395]},
        {z:"yellow",p:[24.87,84.951,24.867,84.982,24.858,85.011,24.843,85.038,24.823,85.059,24.799,85.076,24.772,85.086,24.744,85.09,24.716,85.086,24.69,85.076,24.666,85.059,24.646,85.038,24.631,85.011,24.622,84.982,24.619,84.951,24.622,84.92,24.631,84.891,24.646,84.865,24.666,84.843,24.69,84.826,24.716,84.816,24.744,84.813,24.772,84.816,24.799,84.826,24.823,84.843,24.843,84.865,24.858,84.891,24.867,84.92]},
        {z:"yellow",p:[24.886,93.897,24.883,93.928,24.873,93.957,24.858,93.983,24.838,94.005,24.815,94.021,24.788,94.032,24.76,94.035,24.732,94.032,24.705,94.021,24.682,94.005,24.662,93.983,24.647,93.957,24.637,93.928,24.634,93.897,24.637,93.866,24.647,93.837,24.662,93.81,24.682,93.788,24.705,93.772,24.732,93.762,24.76,93.758,24.788,93.762,24.815,93.772,24.838,93.788,24.858,93.81,24.873,93.837,24.883,93.866]},
        {z:"yellow",p:[22.939,86.169,22.936,86.199,22.927,86.228,22.912,86.254,22.892,86.275,22.868,86.292,22.841,86.302,22.813,86.305,22.785,86.302,22.759,86.292,22.735,86.275,22.715,86.254,22.7,86.228,22.691,86.199,22.687,86.169,22.691,86.138,22.7,86.11,22.715,86.084,22.735,86.062,22.759,86.046,22.785,86.036,22.813,86.032,22.841,86.036,22.868,86.046,22.892,86.062,22.912,86.084,22.927,86.11,22.936,86.138]},
        {z:"yellow",p:[26.857,94.175,26.854,94.207,26.845,94.237,26.83,94.263,26.81,94.286,26.786,94.302,26.759,94.313,26.732,94.316,26.704,94.313,26.677,94.302,26.653,94.286,26.633,94.263,26.618,94.237,26.609,94.207,26.606,94.175,26.609,94.144,26.618,94.114,26.633,94.088,26.653,94.065,26.677,94.049,26.704,94.038,26.732,94.035,26.759,94.038,26.786,94.049,26.81,94.065,26.83,94.088,26.845,94.114,26.854,94.144]},
        {z:"yellow",p:[24.434,92.007,24.431,92.038,24.422,92.067,24.407,92.093,24.387,92.115,24.363,92.132,24.336,92.142,24.308,92.145,24.28,92.142,24.254,92.132,24.23,92.115,24.21,92.093,24.195,92.067,24.186,92.038,24.182,92.007,24.186,91.976,24.195,91.947,24.21,91.921,24.23,91.899,24.254,91.883,24.28,91.873,24.308,91.869,24.336,91.873,24.363,91.883,24.387,91.899,24.407,91.921,24.422,91.947,24.431,91.976]},
        {z:"yellow",p:[25.039,92.979,25.036,93.01,25.026,93.039,25.011,93.065,24.991,93.087,24.967,93.104,24.941,93.114,24.913,93.117,24.885,93.114,24.858,93.104,24.834,93.087,24.815,93.065,24.8,93.039,24.79,93.01,24.787,92.979,24.79,92.948,24.8,92.919,24.815,92.892,24.834,92.87,24.858,92.854,24.885,92.844,24.913,92.84,24.941,92.844,24.967,92.854,24.991,92.87,25.011,92.892,25.026,92.919,25.036,92.948]},
        {z:"yellow",p:[27.421,94.098,27.418,94.129,27.409,94.159,27.394,94.186,27.374,94.208,27.35,94.225,27.323,94.236,27.295,94.239,27.268,94.236,27.241,94.225,27.217,94.208,27.197,94.186,27.182,94.159,27.173,94.129,27.17,94.098,27.173,94.066,27.182,94.036,27.197,94.009,27.217,93.987,27.241,93.97,27.268,93.96,27.295,93.956,27.323,93.96,27.35,93.97,27.374,93.987,27.394,94.009,27.409,94.036,27.418,94.066]},
        {z:"yellow",p:[27.61,95.017,27.607,95.048,27.597,95.078,27.582,95.105,27.562,95.128,27.538,95.145,27.512,95.155,27.484,95.159,27.456,95.155,27.429,95.145,27.405,95.128,27.386,95.105,27.371,95.078,27.361,95.048,27.358,95.017,27.361,94.985,27.371,94.955,27.386,94.929,27.405,94.906,27.429,94.889,27.456,94.879,27.484,94.875,27.512,94.879,27.538,94.889,27.562,94.906,27.582,94.929,27.597,94.955,27.607,94.985]},
        {z:"yellow",p:[26.245,85.314,26.242,85.345,26.232,85.374,26.217,85.401,26.198,85.423,26.174,85.44,26.147,85.45,26.119,85.454,26.091,85.45,26.065,85.44,26.041,85.423,26.021,85.401,26.006,85.374,25.996,85.345,25.993,85.314,25.996,85.283,26.006,85.253,26.021,85.226,26.041,85.204,26.065,85.188,26.091,85.177,26.119,85.174,26.147,85.177,26.174,85.188,26.198,85.204,26.217,85.226,26.232,85.253,26.242,85.283]},
        {z:"yellow",p:[25.717,85.088,25.714,85.119,25.705,85.148,25.69,85.175,25.67,85.197,25.646,85.214,25.619,85.224,25.591,85.227,25.563,85.224,25.537,85.214,25.513,85.197,25.493,85.175,25.478,85.148,25.469,85.119,25.466,85.088,25.469,85.057,25.478,85.027,25.493,85.001,25.513,84.979,25.537,84.962,25.563,84.952,25.591,84.949,25.619,84.952,25.646,84.962,25.67,84.979,25.69,85.001,25.705,85.027,25.714,85.057]},
        {z:"yellow",p:[23.44,85.322,23.437,85.352,23.428,85.381,23.413,85.407,23.393,85.429,23.369,85.445,23.342,85.455,23.314,85.459,23.286,85.455,23.26,85.445,23.236,85.429,23.216,85.407,23.201,85.381,23.192,85.352,23.189,85.322,23.192,85.291,23.201,85.262,23.216,85.236,23.236,85.215,23.26,85.198,23.286,85.188,23.314,85.185,23.342,85.188,23.369,85.198,23.393,85.215,23.413,85.236,23.428,85.262,23.437,85.291]},
        {z:"yellow",p:[22.382,84.815,22.379,84.845,22.37,84.874,22.355,84.899,22.335,84.921,22.311,84.937,22.285,84.947,22.257,84.95,22.229,84.947,22.202,84.937,22.178,84.921,22.158,84.899,22.143,84.874,22.134,84.845,22.131,84.815,22.134,84.784,22.143,84.756,22.158,84.73,22.178,84.708,22.202,84.692,22.229,84.682,22.257,84.679,22.285,84.682,22.311,84.692,22.335,84.708,22.355,84.73,22.37,84.756,22.379,84.784]},
        {z:"yellow",p:[17.847,83.225,17.844,83.254,17.835,83.282,17.82,83.307,17.8,83.328,17.776,83.343,17.749,83.353,17.721,83.357,17.693,83.353,17.667,83.343,17.643,83.328,17.623,83.307,17.608,83.282,17.599,83.254,17.595,83.225,17.599,83.195,17.608,83.167,17.623,83.142,17.643,83.121,17.667,83.106,17.693,83.096,17.721,83.092,17.749,83.096,17.776,83.106,17.8,83.121,17.82,83.142,17.835,83.167,17.844,83.195]},
        {z:"yellow",p:[27.714,93.828,27.711,93.86,27.702,93.89,27.687,93.917,27.667,93.939,27.643,93.956,27.616,93.966,27.588,93.97,27.56,93.966,27.534,93.956,27.51,93.939,27.49,93.917,27.475,93.89,27.466,93.86,27.463,93.828,27.466,93.797,27.475,93.767,27.49,93.74,27.51,93.717,27.534,93.7,27.56,93.69,27.588,93.686,27.616,93.69,27.643,93.7,27.667,93.717,27.687,93.74,27.702,93.767,27.711,93.797]},
        {z:"yellow",p:[27.282,77.961,27.278,77.992,27.269,78.022,27.254,78.049,27.234,78.071,27.21,78.088,27.184,78.099,27.156,78.102,27.128,78.099,27.101,78.088,27.077,78.071,27.057,78.049,27.042,78.022,27.033,77.992,27.03,77.961,27.033,77.929,27.042,77.9,27.057,77.873,27.077,77.85,27.101,77.834,27.128,77.823,27.156,77.82,27.184,77.823,27.21,77.834,27.234,77.85,27.254,77.873,27.269,77.9,27.278,77.929]},
        {z:"yellow",p:[25.566,81.734,25.563,81.765,25.553,81.794,25.538,81.821,25.519,81.843,25.495,81.859,25.468,81.87,25.44,81.873,25.412,81.87,25.386,81.859,25.362,81.843,25.342,81.821,25.327,81.794,25.317,81.765,25.314,81.734,25.317,81.703,25.327,81.673,25.342,81.647,25.362,81.625,25.386,81.608,25.412,81.598,25.44,81.595,25.468,81.598,25.495,81.608,25.519,81.625,25.538,81.647,25.553,81.673,25.563,81.703]},
        {z:"yellow",p:[31.835,74.797,31.832,74.83,31.823,74.861,31.808,74.889,31.788,74.913,31.764,74.93,31.738,74.941,31.71,74.945,31.682,74.941,31.655,74.93,31.631,74.913,31.611,74.889,31.596,74.861,31.587,74.83,31.584,74.797,31.587,74.764,31.596,74.733,31.611,74.705,31.631,74.682,31.655,74.664,31.682,74.653,31.71,74.649,31.738,74.653,31.764,74.664,31.788,74.682,31.808,74.705,31.823,74.733,31.832,74.764]},
        {z:"yellow",p:[28.196,73.207,28.193,73.239,28.184,73.269,28.169,73.296,28.149,73.319,28.125,73.336,28.099,73.346,28.071,73.35,28.043,73.346,28.016,73.336,27.992,73.319,27.972,73.296,27.957,73.269,27.948,73.239,27.945,73.207,27.948,73.175,27.957,73.145,27.972,73.118,27.992,73.096,28.016,73.079,28.043,73.068,28.071,73.065,28.099,73.068,28.125,73.079,28.149,73.096,28.169,73.118,28.184,73.145,28.193,73.175]},
        {z:"yellow",p:[25.578,82.859,25.575,82.89,25.566,82.92,25.551,82.946,25.531,82.968,25.507,82.985,25.48,82.995,25.452,82.999,25.424,82.995,25.398,82.985,25.374,82.968,25.354,82.946,25.339,82.92,25.33,82.89,25.327,82.859,25.33,82.828,25.339,82.799,25.354,82.772,25.374,82.75,25.398,82.734,25.424,82.724,25.452,82.72,25.48,82.724,25.507,82.734,25.531,82.75,25.551,82.772,25.566,82.799,25.575,82.828]},
        {z:"yellow",p:[32.002,77.154,31.999,77.187,31.99,77.219,31.975,77.247,31.955,77.27,31.931,77.288,31.905,77.299,31.877,77.303,31.849,77.299,31.822,77.288,31.798,77.27,31.778,77.247,31.763,77.219,31.754,77.187,31.751,77.154,31.754,77.121,31.763,77.09,31.778,77.062,31.798,77.039,31.822,77.021,31.849,77.01,31.877,77.006,31.905,77.01,31.931,77.021,31.955,77.039,31.975,77.062,31.99,77.09,31.999,77.121]},
        {z:"yellow",p:[30.396,74.756,30.393,74.788,30.383,74.819,30.368,74.847,30.349,74.87,30.325,74.887,30.298,74.898,30.27,74.901,30.242,74.898,30.216,74.887,30.192,74.87,30.172,74.847,30.157,74.819,30.147,74.788,30.144,74.756,30.147,74.723,30.157,74.693,30.172,74.665,30.192,74.642,30.216,74.625,30.242,74.614,30.27,74.61,30.298,74.614,30.325,74.625,30.349,74.642,30.368,74.665,30.383,74.693,30.393,74.723]},
        {z:"yellow",p:[28.548,79.451,28.545,79.483,28.535,79.513,28.52,79.54,28.501,79.563,28.477,79.58,28.45,79.59,28.422,79.594,28.394,79.59,28.368,79.58,28.344,79.563,28.324,79.54,28.309,79.513,28.299,79.483,28.296,79.451,28.299,79.419,28.309,79.389,28.324,79.362,28.344,79.339,28.368,79.322,28.394,79.311,28.422,79.308,28.45,79.311,28.477,79.322,28.501,79.339,28.52,79.362,28.535,79.389,28.545,79.419]},
        {z:"yellow",p:[30.799,76.788,30.796,76.821,30.787,76.852,30.772,76.88,30.752,76.903,30.728,76.92,30.701,76.931,30.674,76.935,30.646,76.931,30.619,76.92,30.595,76.903,30.575,76.88,30.56,76.852,30.551,76.821,30.548,76.788,30.551,76.756,30.56,76.725,30.575,76.697,30.595,76.674,30.619,76.657,30.646,76.646,30.674,76.642,30.701,76.646,30.728,76.657,30.752,76.674,30.772,76.697,30.787,76.725,30.796,76.756]},
        {z:"yellow",p:[26.53,80.41,26.527,80.441,26.518,80.471,26.503,80.498,26.483,80.52,26.459,80.537,26.432,80.547,26.404,80.551,26.376,80.547,26.35,80.537,26.326,80.52,26.306,80.498,26.291,80.471,26.282,80.441,26.279,80.41,26.282,80.379,26.291,80.349,26.306,80.323,26.326,80.3,26.35,80.284,26.376,80.273,26.404,80.27,26.432,80.273,26.459,80.284,26.483,80.3,26.503,80.323,26.518,80.349,26.527,80.379]},
        {z:"yellow",p:[30.315,78.18,30.312,78.213,30.303,78.243,30.288,78.271,30.268,78.294,30.244,78.311,30.218,78.322,30.19,78.326,30.162,78.322,30.135,78.311,30.111,78.294,30.091,78.271,30.076,78.243,30.067,78.213,30.064,78.18,30.067,78.148,30.076,78.117,30.091,78.09,30.111,78.067,30.135,78.049,30.162,78.038,30.19,78.035,30.218,78.038,30.244,78.049,30.268,78.067,30.288,78.09,30.303,78.117,30.312,78.148]},
        {z:"yellow",p:[28.692,77.103,28.689,77.135,28.68,77.165,28.665,77.192,28.645,77.215,28.621,77.232,28.594,77.243,28.567,77.246,28.539,77.243,28.512,77.232,28.488,77.215,28.468,77.192,28.453,77.165,28.444,77.135,28.441,77.103,28.444,77.071,28.453,77.041,28.468,77.014,28.488,76.991,28.512,76.974,28.539,76.963,28.567,76.96,28.594,76.963,28.621,76.974,28.645,76.991,28.665,77.014,28.68,77.041,28.689,77.071]},
        {z:"yellow",p:[26.419,78.228,26.416,78.259,26.407,78.289,26.392,78.315,26.372,78.337,26.348,78.354,26.321,78.365,26.293,78.368,26.265,78.365,26.239,78.354,26.215,78.337,26.195,78.315,26.18,78.289,26.171,78.259,26.168,78.228,26.171,78.197,26.18,78.167,26.195,78.14,26.215,78.118,26.239,78.101,26.265,78.091,26.293,78.088,26.321,78.091,26.348,78.101,26.372,78.118,26.392,78.14,26.407,78.167,26.416,78.197]},
        {z:"yellow",p:[29.305,75.755,29.302,75.787,29.293,75.818,29.278,75.845,29.258,75.868,29.234,75.885,29.207,75.896,29.179,75.899,29.151,75.896,29.125,75.885,29.101,75.868,29.081,75.845,29.066,75.818,29.057,75.787,29.054,75.755,29.057,75.723,29.066,75.693,29.081,75.665,29.101,75.643,29.125,75.626,29.151,75.615,29.179,75.611,29.207,75.615,29.234,75.626,29.258,75.643,29.278,75.665,29.293,75.693,29.302,75.723]},
        {z:"yellow",p:[26.377,73.049,26.374,73.08,26.364,73.11,26.349,73.136,26.33,73.159,26.306,73.175,26.279,73.186,26.251,73.189,26.223,73.186,26.197,73.175,26.173,73.159,26.153,73.136,26.138,73.11,26.128,73.08,26.125,73.049,26.128,73.018,26.138,72.988,26.153,72.961,26.173,72.939,26.197,72.923,26.223,72.912,26.251,72.909,26.279,72.912,26.306,72.923,26.33,72.939,26.349,72.961,26.364,72.988,26.374,73.018]},
        {z:"yellow",p:[26.95,75.812,26.947,75.844,26.938,75.873,26.923,75.9,26.903,75.922,26.879,75.939,26.852,75.95,26.824,75.953,26.796,75.95,26.77,75.939,26.746,75.922,26.726,75.9,26.711,75.873,26.702,75.844,26.698,75.812,26.702,75.781,26.711,75.751,26.726,75.724,26.746,75.702,26.77,75.685,26.796,75.675,26.824,75.671,26.852,75.675,26.879,75.685,26.903,75.702,26.923,75.724,26.938,75.751,26.947,75.781]},
        {z:"yellow",p:[27.014,70.865,27.011,70.896,27.002,70.926,26.987,70.953,26.967,70.975,26.943,70.992,26.917,71.002,26.889,71.006,26.861,71.002,26.834,70.992,26.81,70.975,26.79,70.953,26.775,70.926,26.766,70.896,26.763,70.865,26.766,70.834,26.775,70.804,26.79,70.777,26.81,70.755,26.834,70.738,26.861,70.728,26.889,70.724,26.917,70.728,26.943,70.738,26.967,70.755,26.987,70.777,27.002,70.804,27.011,70.834]},
        {z:"yellow",p:[32.815,74.837,32.812,74.871,32.802,74.902,32.787,74.931,32.768,74.954,32.744,74.972,32.717,74.983,32.689,74.987,32.661,74.983,32.635,74.972,32.611,74.954,32.591,74.931,32.576,74.902,32.566,74.871,32.563,74.837,32.566,74.804,32.576,74.773,32.591,74.744,32.611,74.721,32.635,74.703,32.661,74.692,32.689,74.688,32.717,74.692,32.744,74.703,32.768,74.721,32.787,74.744,32.802,74.773,32.812,74.804]},
        {z:"yellow",p:[25.286,75.846,25.283,75.877,25.274,75.906,25.259,75.932,25.239,75.954,25.215,75.971,25.188,75.981,25.16,75.985,25.132,75.981,25.106,75.971,25.082,75.954,25.062,75.932,25.047,75.906,25.038,75.877,25.034,75.846,25.038,75.815,25.047,75.785,25.062,75.759,25.082,75.737,25.106,75.72,25.132,75.71,25.16,75.707,25.188,75.71,25.215,75.72,25.239,75.737,25.259,75.759,25.274,75.785,25.283,75.815]},
        {z:"yellow",p:[30.98,75.953,30.977,75.985,30.968,76.016,30.953,76.044,30.933,76.067,30.909,76.085,30.883,76.095,30.855,76.099,30.827,76.095,30.8,76.085,30.776,76.067,30.756,76.044,30.741,76.016,30.732,75.985,30.729,75.953,30.732,75.92,30.741,75.889,30.756,75.861,30.776,75.838,30.8,75.821,30.827,75.81,30.855,75.806,30.883,75.81,30.909,75.821,30.933,75.838,30.953,75.861,30.968,75.889,30.977,75.92]},
        {z:"yellow",p:[34.262,77.547,34.259,77.58,34.249,77.612,34.234,77.641,34.214,77.665,34.19,77.683,34.164,77.695,34.136,77.698,34.108,77.695,34.081,77.683,34.057,77.665,34.038,77.641,34.023,77.612,34.013,77.58,34.01,77.547,34.013,77.513,34.023,77.481,34.038,77.452,34.057,77.428,34.081,77.41,34.108,77.398,34.136,77.395,34.164,77.398,34.19,77.41,34.214,77.428,34.234,77.452,34.249,77.481,34.259,77.513]},
        {z:"yellow",p:[26.886,80.889,26.883,80.921,26.874,80.95,26.859,80.977,26.839,80.999,26.815,81.016,26.789,81.027,26.761,81.03,26.733,81.027,26.706,81.016,26.682,80.999,26.662,80.977,26.647,80.95,26.638,80.921,26.635,80.889,26.638,80.858,26.647,80.828,26.662,80.801,26.682,80.779,26.706,80.762,26.733,80.752,26.761,80.748,26.789,80.752,26.815,80.762,26.839,80.779,26.859,80.801,26.874,80.828,26.883,80.858]},
        {z:"yellow",p:[32.359,75.634,32.356,75.668,32.347,75.699,32.332,75.727,32.312,75.751,32.288,75.768,32.262,75.779,32.234,75.783,32.206,75.779,32.179,75.768,32.155,75.751,32.135,75.727,32.12,75.699,32.111,75.668,32.108,75.634,32.111,75.601,32.12,75.57,32.135,75.542,32.155,75.518,32.179,75.5,32.206,75.489,32.234,75.486,32.262,75.489,32.288,75.5,32.312,75.518,32.332,75.542,32.347,75.57,32.356,75.601]},
        {z:"yellow",p:[29.159,79.474,29.156,79.506,29.147,79.536,29.132,79.563,29.112,79.586,29.088,79.603,29.061,79.614,29.033,79.618,29.005,79.614,28.979,79.603,28.955,79.586,28.935,79.563,28.92,79.536,28.911,79.506,28.908,79.474,28.911,79.442,28.92,79.411,28.935,79.384,28.955,79.361,28.979,79.344,29.005,79.333,29.033,79.33,29.061,79.333,29.088,79.344,29.112,79.361,29.132,79.384,29.147,79.411,29.156,79.442]},
        {z:"yellow",p:[34.113,74.774,34.11,74.808,34.1,74.84,34.085,74.869,34.066,74.893,34.042,74.911,34.015,74.922,33.987,74.926,33.959,74.922,33.933,74.911,33.909,74.893,33.889,74.869,33.874,74.84,33.864,74.808,33.861,74.774,33.864,74.74,33.874,74.708,33.889,74.68,33.909,74.656,33.933,74.638,33.959,74.626,33.987,74.623,34.015,74.626,34.042,74.638,34.066,74.656,34.085,74.68,34.1,74.708,34.11,74.74]},
        {z:"yellow",p:[24.688,80.855,24.685,80.886,24.676,80.915,24.661,80.941,24.641,80.963,24.617,80.979,24.59,80.99,24.562,80.993,24.534,80.99,24.508,80.979,24.484,80.963,24.464,80.941,24.449,80.915,24.44,80.886,24.437,80.855,24.44,80.824,24.449,80.795,24.464,80.769,24.484,80.747,24.508,80.73,24.534,80.72,24.562,80.717,24.59,80.72,24.617,80.73,24.641,80.747,24.661,80.769,24.676,80.795,24.685,80.824]},
        {z:"yellow",p:[10.949,72.176,10.946,72.204,10.937,72.232,10.922,72.256,10.902,72.276,10.878,72.291,10.852,72.301,10.824,72.304,10.796,72.301,10.769,72.291,10.745,72.276,10.725,72.256,10.71,72.232,10.701,72.204,10.698,72.176,10.701,72.148,10.71,72.12,10.725,72.096,10.745,72.076,10.769,72.061,10.796,72.051,10.824,72.048,10.852,72.051,10.878,72.061,10.902,72.076,10.922,72.096,10.937,72.12,10.946,72.148]},
        {z:"yellow",p:[13.324,77.706,13.321,77.735,13.311,77.762,13.296,77.787,13.276,77.807,13.252,77.823,13.226,77.832,13.198,77.835,13.17,77.832,13.143,77.823,13.119,77.807,13.1,77.787,13.085,77.762,13.075,77.735,13.072,77.706,13.075,77.678,13.085,77.65,13.1,77.626,13.119,77.605,13.143,77.59,13.17,77.58,13.198,77.577,13.226,77.58,13.252,77.59,13.276,77.605,13.296,77.626,13.311,77.65,13.321,77.678]},
        {z:"yellow",p:[15.289,76.883,15.285,76.912,15.276,76.939,15.261,76.964,15.241,76.985,15.217,77.0,15.191,77.01,15.163,77.013,15.135,77.01,15.108,77.0,15.084,76.985,15.064,76.964,15.049,76.939,15.04,76.912,15.037,76.883,15.04,76.854,15.049,76.826,15.064,76.802,15.084,76.781,15.108,76.765,15.135,76.756,15.163,76.752,15.191,76.756,15.217,76.765,15.241,76.781,15.261,76.802,15.276,76.826,15.285,76.854]},
        {z:"yellow",p:[16.656,80.797,16.653,80.826,16.644,80.854,16.629,80.879,16.609,80.899,16.585,80.915,16.558,80.925,16.53,80.928,16.502,80.925,16.476,80.915,16.452,80.899,16.432,80.879,16.417,80.854,16.408,80.826,16.405,80.797,16.408,80.768,16.417,80.74,16.432,80.715,16.452,80.694,16.476,80.679,16.502,80.669,16.53,80.666,16.558,80.669,16.585,80.679,16.609,80.694,16.629,80.715,16.644,80.74,16.653,80.768]},
        {z:"yellow",p:[11.156,77.043,11.153,77.072,11.143,77.099,11.128,77.123,11.108,77.144,11.085,77.159,11.058,77.168,11.03,77.172,11.002,77.168,10.975,77.159,10.952,77.144,10.932,77.123,10.917,77.099,10.907,77.072,10.904,77.043,10.907,77.015,10.917,76.988,10.932,76.964,10.952,76.943,10.975,76.928,11.002,76.918,11.03,76.915,11.058,76.918,11.085,76.928,11.108,76.943,11.128,76.964,11.143,76.988,11.153,77.015]},
        {z:"yellow",p:[10.278,76.402,10.275,76.43,10.265,76.457,10.25,76.482,10.23,76.502,10.207,76.517,10.18,76.526,10.152,76.53,10.124,76.526,10.097,76.517,10.074,76.502,10.054,76.482,10.039,76.457,10.029,76.43,10.026,76.402,10.029,76.373,10.039,76.346,10.054,76.322,10.074,76.302,10.097,76.287,10.124,76.277,10.152,76.274,10.18,76.277,10.207,76.287,10.23,76.302,10.25,76.322,10.265,76.346,10.275,76.373]},
        {z:"yellow",p:[11.263,75.955,11.259,75.984,11.25,76.011,11.235,76.035,11.215,76.056,11.191,76.071,11.165,76.08,11.137,76.083,11.109,76.08,11.082,76.071,11.058,76.056,11.038,76.035,11.023,76.011,11.014,75.984,11.011,75.955,11.014,75.927,11.023,75.9,11.038,75.875,11.058,75.855,11.082,75.84,11.109,75.83,11.137,75.827,11.165,75.83,11.191,75.84,11.215,75.855,11.235,75.875,11.25,75.9,11.259,75.927]},
        {z:"yellow",p:[14.636,78.773,14.633,78.802,14.623,78.829,14.608,78.854,14.588,78.874,14.565,78.89,14.538,78.899,14.51,78.903,14.482,78.899,14.455,78.89,14.432,78.874,14.412,78.854,14.397,78.829,14.387,78.802,14.384,78.773,14.387,78.744,14.397,78.716,14.412,78.692,14.432,78.671,14.455,78.656,14.482,78.646,14.51,78.643,14.538,78.646,14.565,78.656,14.588,78.671,14.608,78.692,14.623,78.716,14.633,78.744]},
        {z:"yellow",p:[9.278,92.82,9.275,92.848,9.266,92.875,9.251,92.899,9.231,92.919,9.207,92.934,9.18,92.944,9.153,92.947,9.125,92.944,9.098,92.934,9.074,92.919,9.054,92.899,9.039,92.875,9.03,92.848,9.027,92.82,9.03,92.791,9.039,92.764,9.054,92.74,9.074,92.72,9.098,92.705,9.125,92.695,9.153,92.692,9.18,92.695,9.207,92.705,9.231,92.72,9.251,92.74,9.266,92.764,9.275,92.791]},
        {z:"yellow",p:[17.579,78.468,17.576,78.497,17.566,78.525,17.551,78.55,17.532,78.571,17.508,78.586,17.481,78.596,17.453,78.599,17.425,78.596,17.399,78.586,17.375,78.571,17.355,78.55,17.34,78.525,17.33,78.497,17.327,78.468,17.33,78.438,17.34,78.41,17.355,78.385,17.375,78.365,17.399,78.349,17.425,78.339,17.453,78.336,17.481,78.339,17.508,78.349,17.532,78.365,17.551,78.385,17.566,78.41,17.576,78.438]},
        {z:"yellow",p:[9.96,78.093,9.957,78.122,9.948,78.149,9.933,78.173,9.913,78.193,9.889,78.208,9.862,78.218,9.835,78.221,9.807,78.218,9.78,78.208,9.756,78.193,9.736,78.173,9.721,78.149,9.712,78.122,9.709,78.093,9.712,78.065,9.721,78.038,9.736,78.014,9.756,77.994,9.78,77.978,9.807,77.969,9.835,77.966,9.862,77.969,9.889,77.978,9.913,77.994,9.933,78.014,9.948,78.038,9.957,78.065]},
        {z:"yellow",p:[13.087,74.89,13.084,74.919,13.075,74.946,13.06,74.971,13.04,74.991,13.016,75.006,12.989,75.016,12.961,75.019,12.933,75.016,12.907,75.006,12.883,74.991,12.863,74.971,12.848,74.946,12.839,74.919,12.836,74.89,12.839,74.861,12.848,74.834,12.863,74.81,12.883,74.789,12.907,74.774,12.933,74.764,12.961,74.761,12.989,74.764,13.016,74.774,13.04,74.789,13.06,74.81,13.075,74.834,13.084,74.861]},
        {z:"yellow",p:[13.116,80.169,13.113,80.198,13.103,80.225,13.088,80.25,13.068,80.27,13.045,80.286,13.018,80.295,12.99,80.298,12.962,80.295,12.935,80.286,12.912,80.27,12.892,80.25,12.877,80.225,12.867,80.198,12.864,80.169,12.867,80.141,12.877,80.113,12.892,80.089,12.912,80.068,12.935,80.053,12.962,80.043,12.99,80.04,13.018,80.043,13.045,80.053,13.068,80.068,13.088,80.089,13.103,80.113,13.113,80.141]},
        {z:"yellow",p:[11.767,92.73,11.764,92.758,11.755,92.785,11.74,92.81,11.72,92.83,11.696,92.845,11.669,92.855,11.641,92.858,11.613,92.855,11.587,92.845,11.563,92.83,11.543,92.81,11.528,92.785,11.519,92.758,11.515,92.73,11.519,92.701,11.528,92.674,11.543,92.65,11.563,92.629,11.587,92.614,11.613,92.605,11.641,92.601,11.669,92.605,11.696,92.614,11.72,92.629,11.74,92.65,11.755,92.674,11.764,92.701]},
        {z:"yellow",p:[12.094,79.812,12.091,79.841,12.081,79.868,12.066,79.892,12.046,79.913,12.023,79.928,11.996,79.937,11.968,79.941,11.94,79.937,11.913,79.928,11.89,79.913,11.87,79.892,11.855,79.868,11.845,79.841,11.842,79.812,11.845,79.783,11.855,79.756,11.87,79.732,11.89,79.711,11.913,79.696,11.94,79.687,11.968,79.683,11.996,79.687,12.023,79.696,12.046,79.711,12.066,79.732,12.081,79.756,12.091,79.783]},
        {z:"yellow",p:[17.236,81.818,17.233,81.847,17.224,81.875,17.209,81.9,17.189,81.921,17.165,81.937,17.138,81.946,17.11,81.95,17.082,81.946,17.056,81.937,17.032,81.921,17.012,81.9,16.997,81.875,16.988,81.847,16.985,81.818,16.988,81.789,16.997,81.761,17.012,81.736,17.032,81.715,17.056,81.7,17.082,81.69,17.11,81.687,17.138,81.69,17.165,81.7,17.189,81.715,17.209,81.736,17.224,81.761,17.233,81.789]},
        {z:"yellow",p:[11.909,78.066,11.906,78.094,11.897,78.121,11.882,78.146,11.862,78.166,11.838,78.181,11.811,78.191,11.783,78.194,11.755,78.191,11.729,78.181,11.705,78.166,11.685,78.146,11.67,78.121,11.661,78.094,11.658,78.066,11.661,78.037,11.67,78.01,11.685,77.985,11.705,77.965,11.729,77.95,11.755,77.94,11.783,77.937,11.811,77.94,11.838,77.95,11.862,77.965,11.882,77.985,11.897,78.01,11.906,78.037]},
        {z:"yellow",p:[10.848,79.102,10.845,79.13,10.836,79.157,10.821,79.181,10.801,79.202,10.777,79.217,10.75,79.226,10.722,79.23,10.694,79.226,10.668,79.217,10.644,79.202,10.624,79.181,10.609,79.157,10.6,79.13,10.597,79.102,10.6,79.073,10.609,79.046,10.624,79.022,10.644,79.002,10.668,78.986,10.694,78.977,10.722,78.974,10.75,78.977,10.777,78.986,10.801,79.002,10.821,79.022,10.836,79.046,10.845,79.073]},
        {z:"yellow",p:[13.758,79.543,13.755,79.572,13.746,79.599,13.731,79.624,13.711,79.644,13.687,79.66,13.66,79.669,13.632,79.673,13.605,79.669,13.578,79.66,13.554,79.644,13.534,79.624,13.519,79.599,13.51,79.572,13.507,79.543,13.51,79.515,13.519,79.487,13.534,79.463,13.554,79.442,13.578,79.427,13.605,79.417,13.632,79.414,13.66,79.417,13.687,79.427,13.711,79.442,13.731,79.463,13.746,79.487,13.755,79.515]},
        {z:"yellow",p:[10.891,78.71,10.888,78.738,10.879,78.765,10.864,78.79,10.844,78.81,10.82,78.825,10.793,78.835,10.765,78.838,10.737,78.835,10.711,78.825,10.687,78.81,10.667,78.79,10.652,78.765,10.643,78.738,10.64,78.71,10.643,78.681,10.652,78.654,10.667,78.63,10.687,78.61,10.711,78.594,10.737,78.585,10.765,78.582,10.793,78.585,10.82,78.594,10.844,78.61,10.864,78.63,10.879,78.654,10.888,78.681]},
        {z:"yellow",p:[8.608,76.92,8.605,76.948,8.595,76.975,8.58,76.999,8.561,77.02,8.537,77.035,8.51,77.044,8.482,77.047,8.454,77.044,8.428,77.035,8.404,77.02,8.384,76.999,8.369,76.975,8.36,76.948,8.356,76.92,8.36,76.892,8.369,76.865,8.384,76.841,8.404,76.821,8.428,76.806,8.454,76.796,8.482,76.793,8.51,76.796,8.537,76.806,8.561,76.821,8.58,76.841,8.595,76.865,8.605,76.892]},
        {z:"yellow",p:[20.839,70.921,20.836,70.951,20.826,70.979,20.811,71.005,20.792,71.026,20.768,71.042,20.741,71.052,20.713,71.056,20.685,71.052,20.659,71.042,20.635,71.026,20.615,71.005,20.6,70.979,20.59,70.951,20.587,70.921,20.59,70.891,20.6,70.863,20.615,70.837,20.635,70.816,20.659,70.8,20.685,70.79,20.713,70.787,20.741,70.79,20.768,70.8,20.792,70.816,20.811,70.837,20.826,70.863,20.836,70.891]},
        {z:"yellow",p:[15.487,75.085,15.484,75.114,15.475,75.141,15.46,75.166,15.44,75.187,15.416,75.202,15.39,75.212,15.362,75.215,15.334,75.212,15.307,75.202,15.283,75.187,15.263,75.166,15.248,75.141,15.239,75.114,15.236,75.085,15.239,75.056,15.248,75.028,15.263,75.004,15.283,74.983,15.307,74.967,15.334,74.958,15.362,74.954,15.39,74.958,15.416,74.967,15.44,74.983,15.46,75.004,15.475,75.028,15.484,75.056]},
        {z:"yellow",p:[25.829,91.979,25.826,92.01,25.817,92.039,25.802,92.066,25.782,92.088,25.758,92.104,25.732,92.115,25.704,92.118,25.676,92.115,25.649,92.104,25.625,92.088,25.605,92.066,25.59,92.039,25.581,92.01,25.578,91.979,25.581,91.948,25.59,91.918,25.605,91.892,25.625,91.87,25.649,91.853,25.676,91.843,25.704,91.839,25.732,91.843,25.758,91.853,25.782,91.87,25.802,91.892,25.817,91.918,25.826,91.948]},
        {z:"yellow",p:[26.232,91.586,26.229,91.617,26.219,91.647,26.204,91.673,26.185,91.695,26.161,91.712,26.134,91.722,26.106,91.726,26.078,91.722,26.052,91.712,26.028,91.695,26.008,91.673,25.993,91.647,25.983,91.617,25.98,91.586,25.983,91.555,25.993,91.525,26.008,91.499,26.028,91.476,26.052,91.46,26.078,91.449,26.106,91.446,26.134,91.449,26.161,91.46,26.185,91.476,26.204,91.499,26.219,91.525,26.229,91.555]},
        {z:"yellow",p:[26.01,93.771,26.007,93.802,25.997,93.832,25.982,93.858,25.962,93.88,25.938,93.897,25.912,93.907,25.884,93.911,25.856,93.907,25.829,93.897,25.805,93.88,25.786,93.858,25.771,93.832,25.761,93.802,25.758,93.771,25.761,93.74,25.771,93.71,25.786,93.684,25.805,93.662,25.829,93.645,25.856,93.635,25.884,93.631,25.912,93.635,25.938,93.645,25.962,93.662,25.982,93.684,25.997,93.71,26.007,93.74]},
        {z:"yellow",p:[26.835,92.785,26.832,92.816,26.822,92.846,26.807,92.872,26.788,92.895,26.764,92.912,26.737,92.922,26.709,92.925,26.681,92.922,26.655,92.912,26.631,92.895,26.611,92.872,26.596,92.846,26.586,92.816,26.583,92.785,26.586,92.753,26.596,92.724,26.611,92.697,26.631,92.675,26.655,92.658,26.681,92.647,26.709,92.644,26.737,92.647,26.764,92.658,26.788,92.675,26.807,92.697,26.822,92.724,26.832,92.753]},
        {z:"yellow",p:[26.865,83.45,26.862,83.481,26.853,83.511,26.838,83.538,26.818,83.56,26.794,83.577,26.768,83.587,26.74,83.591,26.712,83.587,26.685,83.577,26.661,83.56,26.641,83.538,26.626,83.511,26.617,83.481,26.614,83.45,26.617,83.418,26.626,83.389,26.641,83.362,26.661,83.34,26.685,83.323,26.712,83.312,26.74,83.309,26.768,83.312,26.794,83.323,26.818,83.34,26.838,83.362,26.853,83.389,26.862,83.418]},
        {z:"yellow",p:[32.291,76.263,32.288,76.296,32.278,76.328,32.263,76.356,32.244,76.38,32.22,76.397,32.193,76.408,32.165,76.412,32.137,76.408,32.111,76.397,32.087,76.38,32.067,76.356,32.052,76.328,32.042,76.296,32.039,76.263,32.042,76.23,32.052,76.199,32.067,76.171,32.087,76.147,32.111,76.13,32.137,76.119,32.165,76.115,32.193,76.119,32.22,76.13,32.244,76.147,32.263,76.171,32.278,76.199,32.288,76.23]},
        {z:"yellow",p:[19.309,77.317,19.306,77.346,19.297,77.374,19.282,77.4,19.262,77.421,19.238,77.437,19.211,77.447,19.183,77.45,19.155,77.447,19.129,77.437,19.105,77.421,19.085,77.4,19.07,77.374,19.061,77.346,19.058,77.317,19.061,77.287,19.07,77.259,19.085,77.234,19.105,77.213,19.129,77.197,19.155,77.187,19.183,77.184,19.211,77.187,19.238,77.197,19.262,77.213,19.282,77.234,19.297,77.259,19.306,77.287]},
        {z:"yellow",p:[31.208,77.068,31.204,77.101,31.195,77.132,31.18,77.16,31.16,77.183,31.136,77.2,31.11,77.211,31.082,77.215,31.054,77.211,31.027,77.2,31.003,77.183,30.983,77.16,30.968,77.132,30.959,77.101,30.956,77.068,30.959,77.035,30.968,77.004,30.983,76.976,31.003,76.953,31.027,76.936,31.054,76.925,31.082,76.921,31.11,76.925,31.136,76.936,31.16,76.953,31.18,76.976,31.195,77.004,31.204,77.035]},
        {z:"yellow",p:[12.356,76.656,12.353,76.684,12.343,76.712,12.328,76.736,12.308,76.756,12.285,76.772,12.258,76.781,12.23,76.785,12.202,76.781,12.175,76.772,12.152,76.756,12.132,76.736,12.117,76.712,12.107,76.684,12.104,76.656,12.107,76.627,12.117,76.6,12.132,76.576,12.152,76.555,12.175,76.54,12.202,76.53,12.23,76.527,12.258,76.53,12.285,76.54,12.308,76.555,12.328,76.576,12.343,76.6,12.353,76.627]},
        {z:"yellow",p:[28.192,95.336,28.189,95.367,28.179,95.397,28.164,95.424,28.145,95.447,28.121,95.464,28.094,95.475,28.066,95.478,28.038,95.475,28.012,95.464,27.988,95.447,27.968,95.424,27.953,95.397,27.943,95.367,27.94,95.336,27.943,95.304,27.953,95.274,27.968,95.247,27.988,95.224,28.012,95.207,28.038,95.197,28.066,95.193,28.094,95.197,28.121,95.207,28.145,95.224,28.164,95.247,28.179,95.274,28.189,95.304]},
        {z:"yellow",p:[17.139,73.328,17.136,73.357,17.127,73.385,17.112,73.41,17.092,73.431,17.068,73.446,17.042,73.456,17.014,73.459,16.986,73.456,16.959,73.446,16.935,73.431,16.915,73.41,16.9,73.385,16.891,73.357,16.888,73.328,16.891,73.299,16.9,73.271,16.915,73.246,16.935,73.225,16.959,73.209,16.986,73.2,17.014,73.196,17.042,73.2,17.068,73.209,17.092,73.225,17.112,73.246,17.127,73.271,17.136,73.299]},
        {z:"yellow",p:[23.748,87.243,23.745,87.274,23.736,87.303,23.721,87.329,23.701,87.35,23.677,87.367,23.65,87.377,23.622,87.38,23.595,87.377,23.568,87.367,23.544,87.35,23.524,87.329,23.509,87.303,23.5,87.274,23.497,87.243,23.5,87.212,23.509,87.183,23.524,87.157,23.544,87.136,23.568,87.119,23.595,87.109,23.622,87.106,23.65,87.109,23.677,87.119,23.701,87.136,23.721,87.157,23.736,87.183,23.745,87.212]},
        {z:"yellow",p:[14.275,77.791,14.272,77.82,14.263,77.847,14.248,77.872,14.228,77.893,14.204,77.908,14.177,77.918,14.149,77.921,14.121,77.918,14.095,77.908,14.071,77.893,14.051,77.872,14.036,77.847,14.027,77.82,14.024,77.791,14.027,77.762,14.036,77.735,14.051,77.71,14.071,77.69,14.095,77.674,14.121,77.665,14.149,77.661,14.177,77.665,14.204,77.674,14.228,77.69,14.248,77.71,14.263,77.735,14.272,77.762]},
        {z:"yellow",p:[17.357,78.43,17.354,78.459,17.345,78.487,17.33,78.512,17.31,78.533,17.286,78.548,17.259,78.558,17.231,78.562,17.203,78.558,17.177,78.548,17.153,78.533,17.133,78.512,17.118,78.487,17.109,78.459,17.106,78.43,17.109,78.401,17.118,78.373,17.133,78.348,17.153,78.327,17.177,78.311,17.203,78.301,17.231,78.298,17.259,78.301,17.286,78.311,17.31,78.327,17.33,78.348,17.345,78.373,17.354,78.401]},
        {z:"yellow",p:[28.067,96.134,28.064,96.166,28.055,96.196,28.04,96.223,28.02,96.246,27.996,96.263,27.969,96.273,27.941,96.277,27.913,96.273,27.887,96.263,27.863,96.246,27.843,96.223,27.828,96.196,27.819,96.166,27.815,96.134,27.819,96.103,27.828,96.073,27.843,96.046,27.863,96.023,27.887,96.006,27.913,95.996,27.941,95.992,27.969,95.996,27.996,96.006,28.02,96.023,28.04,96.046,28.055,96.073,28.064,96.103]},
        {z:"yellow",p:[31.56,75.759,31.556,75.792,31.547,75.823,31.532,75.851,31.512,75.874,31.488,75.892,31.462,75.902,31.434,75.906,31.406,75.902,31.379,75.892,31.355,75.874,31.335,75.851,31.32,75.823,31.311,75.792,31.308,75.759,31.311,75.726,31.32,75.695,31.335,75.667,31.355,75.644,31.379,75.626,31.406,75.615,31.434,75.611,31.462,75.615,31.488,75.626,31.512,75.644,31.532,75.667,31.547,75.695,31.556,75.726]},
        {z:"yellow",p:[15.301,76.635,15.298,76.664,15.288,76.691,15.273,76.716,15.253,76.737,15.23,76.752,15.203,76.762,15.175,76.765,15.147,76.762,15.12,76.752,15.097,76.737,15.077,76.716,15.062,76.691,15.052,76.664,15.049,76.635,15.052,76.606,15.062,76.578,15.077,76.554,15.097,76.533,15.12,76.518,15.147,76.508,15.175,76.505,15.203,76.508,15.23,76.518,15.253,76.533,15.273,76.554,15.288,76.578,15.298,76.606]},
        {z:"yellow",p:[19.814,74.379,19.811,74.409,19.802,74.437,19.787,74.462,19.767,74.483,19.743,74.499,19.717,74.509,19.689,74.512,19.661,74.509,19.634,74.499,19.61,74.483,19.59,74.462,19.575,74.437,19.566,74.409,19.563,74.379,19.566,74.349,19.575,74.321,19.59,74.296,19.61,74.274,19.634,74.259,19.661,74.249,19.689,74.245,19.717,74.249,19.743,74.259,19.767,74.274,19.787,74.296,19.802,74.321,19.811,74.349]},
        {z:"yellow",p:[19.006,82.552,19.003,82.582,18.993,82.61,18.978,82.635,18.958,82.656,18.935,82.672,18.908,82.682,18.88,82.685,18.852,82.682,18.825,82.672,18.802,82.656,18.782,82.635,18.767,82.61,18.757,82.582,18.754,82.552,18.757,82.522,18.767,82.494,18.782,82.469,18.802,82.448,18.825,82.432,18.852,82.422,18.88,82.419,18.908,82.422,18.935,82.432,18.958,82.448,18.978,82.469,18.993,82.494,19.003,82.522]},
        {z:"yellow",p:[26.727,74.814,26.724,74.845,26.715,74.875,26.7,74.902,26.68,74.924,26.656,74.941,26.629,74.951,26.601,74.955,26.573,74.951,26.547,74.941,26.523,74.924,26.503,74.902,26.488,74.875,26.479,74.845,26.476,74.814,26.479,74.783,26.488,74.753,26.503,74.726,26.523,74.704,26.547,74.687,26.573,74.677,26.601,74.673,26.629,74.677,26.656,74.687,26.68,74.704,26.7,74.726,26.715,74.753,26.724,74.783]},
        {z:"yellow",p:[12.044,75.547,12.041,75.576,12.032,75.603,12.017,75.627,11.997,75.648,11.973,75.663,11.947,75.673,11.919,75.676,11.891,75.673,11.864,75.663,11.84,75.648,11.82,75.627,11.805,75.603,11.796,75.576,11.793,75.547,11.796,75.519,11.805,75.491,11.82,75.467,11.84,75.447,11.864,75.431,11.891,75.422,11.919,75.419,11.947,75.422,11.973,75.431,11.997,75.447,12.017,75.467,12.032,75.491,12.041,75.519]},
        {z:"red",p:[23.14,72.635,23.139,72.65,23.134,72.664,23.126,72.677,23.116,72.688,23.104,72.696,23.091,72.701,23.077,72.703,23.063,72.701,23.05,72.696,23.038,72.688,23.028,72.677,23.021,72.664,23.016,72.65,23.014,72.635,23.016,72.619,23.021,72.605,23.028,72.592,23.038,72.581,23.05,72.573,23.063,72.568,23.077,72.566,23.091,72.568,23.104,72.573,23.116,72.581,23.126,72.592,23.134,72.605,23.139,72.619]},
        {z:"red",p:[20.762,77.059,20.76,77.074,20.756,77.088,20.748,77.101,20.738,77.111,20.726,77.119,20.713,77.124,20.699,77.126,20.685,77.124,20.672,77.119,20.66,77.111,20.65,77.101,20.642,77.088,20.638,77.074,20.636,77.059,20.638,77.044,20.642,77.029,20.65,77.017,20.66,77.006,20.672,76.998,20.685,76.993,20.699,76.991,20.713,76.993,20.726,76.998,20.738,77.006,20.748,77.017,20.756,77.029,20.76,77.044]},
        {z:"red",p:[19.926,75.398,19.924,75.413,19.919,75.427,19.912,75.44,19.902,75.45,19.89,75.458,19.877,75.463,19.863,75.465,19.849,75.463,19.835,75.458,19.823,75.45,19.814,75.44,19.806,75.427,19.801,75.413,19.8,75.398,19.801,75.383,19.806,75.369,19.814,75.356,19.823,75.346,19.835,75.338,19.849,75.333,19.863,75.331,19.877,75.333,19.89,75.338,19.902,75.346,19.912,75.356,19.919,75.369,19.924,75.383]},
        {z:"red",p:[19.152,72.868,19.15,72.883,19.145,72.897,19.138,72.909,19.128,72.92,19.116,72.928,19.103,72.933,19.089,72.934,19.075,72.933,19.061,72.928,19.049,72.92,19.04,72.909,19.032,72.897,19.027,72.883,19.026,72.868,19.027,72.853,19.032,72.839,19.04,72.826,19.049,72.816,19.061,72.808,19.075,72.803,19.089,72.801,19.103,72.803,19.116,72.808,19.128,72.816,19.138,72.826,19.145,72.839,19.15,72.853]},
        {z:"red",p:[22.051,82.111,22.05,82.126,22.045,82.14,22.038,82.153,22.028,82.164,22.016,82.172,22.002,82.177,21.988,82.179,21.974,82.177,21.961,82.172,21.949,82.164,21.939,82.153,21.932,82.14,21.927,82.126,21.926,82.111,21.927,82.096,21.932,82.082,21.939,82.069,21.949,82.058,21.961,82.05,21.974,82.045,21.988,82.043,22.002,82.045,22.016,82.05,22.028,82.058,22.038,82.069,22.045,82.082,22.05,82.096]},
        {z:"red",p:[23.351,69.67,23.349,69.685,23.344,69.7,23.337,69.713,23.327,69.724,23.315,69.732,23.302,69.737,23.288,69.739,23.274,69.737,23.261,69.732,23.249,69.724,23.239,69.713,23.231,69.7,23.226,69.685,23.225,69.67,23.226,69.655,23.231,69.64,23.239,69.628,23.249,69.617,23.261,69.609,23.274,69.603,23.288,69.602,23.302,69.603,23.315,69.609,23.327,69.617,23.337,69.628,23.344,69.64,23.349,69.655]},
        {z:"red",p:[15.922,74.618,15.921,74.633,15.916,74.647,15.908,74.659,15.899,74.669,15.887,74.677,15.873,74.682,15.859,74.684,15.845,74.682,15.832,74.677,15.82,74.669,15.81,74.659,15.803,74.647,15.798,74.633,15.796,74.618,15.798,74.604,15.803,74.59,15.81,74.578,15.82,74.567,15.832,74.559,15.845,74.555,15.859,74.553,15.873,74.555,15.887,74.559,15.899,74.567,15.908,74.578,15.916,74.59,15.921,74.604]},
        {z:"red",p:[22.399,73.226,22.398,73.241,22.393,73.256,22.385,73.269,22.375,73.279,22.363,73.288,22.35,73.293,22.336,73.294,22.322,73.293,22.309,73.288,22.297,73.279,22.287,73.269,22.28,73.256,22.275,73.241,22.273,73.226,22.275,73.211,22.28,73.197,22.287,73.184,22.297,73.173,22.309,73.165,22.322,73.16,22.336,73.158,22.35,73.16,22.363,73.165,22.375,73.173,22.385,73.184,22.393,73.197,22.398,73.211]},
        {z:"red",p:[23.35,77.337,23.349,77.353,23.344,77.367,23.337,77.38,23.327,77.391,23.315,77.399,23.301,77.404,23.288,77.406,23.274,77.404,23.26,77.399,23.248,77.391,23.238,77.38,23.231,77.367,23.226,77.353,23.225,77.337,23.226,77.322,23.231,77.308,23.238,77.295,23.248,77.284,23.26,77.276,23.274,77.271,23.288,77.269,23.301,77.271,23.315,77.276,23.327,77.284,23.337,77.295,23.344,77.308,23.349,77.322]},
        {z:"red",p:[21.815,72.185,21.814,72.2,21.809,72.215,21.801,72.227,21.791,72.238,21.779,72.246,21.766,72.251,21.752,72.253,21.738,72.251,21.725,72.246,21.713,72.238,21.703,72.227,21.696,72.215,21.691,72.2,21.689,72.185,21.691,72.17,21.696,72.156,21.703,72.143,21.713,72.132,21.725,72.124,21.738,72.119,21.752,72.118,21.766,72.119,21.779,72.124,21.791,72.132,21.801,72.143,21.809,72.156,21.814,72.17]},
        {z:"red",p:[20.497,72.843,20.496,72.858,20.491,72.872,20.484,72.885,20.474,72.896,20.462,72.904,20.448,72.909,20.434,72.91,20.42,72.909,20.407,72.904,20.395,72.896,20.385,72.885,20.378,72.872,20.373,72.858,20.372,72.843,20.373,72.828,20.378,72.814,20.385,72.801,20.395,72.791,20.407,72.783,20.42,72.778,20.434,72.776,20.448,72.778,20.462,72.783,20.474,72.791,20.484,72.801,20.491,72.814,20.496,72.828]},
        {z:"red",p:[24.718,77.347,24.716,77.363,24.711,77.377,24.704,77.39,24.694,77.401,24.682,77.41,24.669,77.415,24.655,77.416,24.641,77.415,24.627,77.41,24.615,77.401,24.606,77.39,24.598,77.377,24.593,77.363,24.592,77.347,24.593,77.332,24.598,77.317,24.606,77.304,24.615,77.293,24.627,77.285,24.641,77.28,24.655,77.278,24.669,77.28,24.682,77.285,24.694,77.293,24.704,77.304,24.711,77.317,24.716,77.332]},
        {z:"red",p:[15.444,73.831,15.442,73.846,15.437,73.86,15.43,73.872,15.42,73.882,15.408,73.89,15.395,73.895,15.381,73.897,15.367,73.895,15.354,73.89,15.342,73.882,15.332,73.872,15.324,73.86,15.319,73.846,15.318,73.831,15.319,73.817,15.324,73.803,15.332,73.791,15.342,73.78,15.354,73.773,15.367,73.768,15.381,73.766,15.395,73.768,15.408,73.773,15.42,73.78,15.43,73.791,15.437,73.803,15.442,73.817]},
        {z:"red",p:[22.785,75.801,22.783,75.816,22.778,75.831,22.771,75.844,22.761,75.854,22.749,75.863,22.736,75.868,22.722,75.869,22.708,75.868,22.695,75.863,22.683,75.854,22.673,75.844,22.665,75.831,22.66,75.816,22.659,75.801,22.66,75.786,22.665,75.772,22.673,75.759,22.683,75.748,22.695,75.74,22.708,75.735,22.722,75.733,22.736,75.735,22.749,75.74,22.761,75.748,22.771,75.759,22.778,75.772,22.783,75.786]},
        {z:"red",p:[23.241,80.052,23.239,80.067,23.234,80.082,23.227,80.095,23.217,80.105,23.205,80.114,23.192,80.119,23.178,80.12,23.164,80.119,23.151,80.114,23.139,80.105,23.129,80.095,23.121,80.082,23.116,80.067,23.115,80.052,23.116,80.037,23.121,80.022,23.129,80.009,23.139,79.999,23.151,79.99,23.164,79.985,23.178,79.984,23.192,79.985,23.205,79.99,23.217,79.999,23.227,80.009,23.234,80.022,23.239,80.037]},
        {z:"red",p:[22.528,70.013,22.527,70.028,22.522,70.042,22.515,70.055,22.505,70.066,22.493,70.074,22.479,70.079,22.465,70.081,22.452,70.079,22.438,70.074,22.426,70.066,22.416,70.055,22.409,70.042,22.404,70.028,22.403,70.013,22.404,69.997,22.409,69.983,22.416,69.97,22.426,69.959,22.438,69.951,22.452,69.946,22.465,69.945,22.479,69.946,22.493,69.951,22.505,69.959,22.515,69.97,22.522,69.983,22.527,69.997]},
        {z:"red",p:[23.176,70.1,23.174,70.116,23.169,70.13,23.162,70.143,23.152,70.154,23.14,70.162,23.127,70.167,23.113,70.169,23.099,70.167,23.085,70.162,23.073,70.154,23.064,70.143,23.056,70.13,23.051,70.116,23.05,70.1,23.051,70.085,23.056,70.071,23.064,70.058,23.073,70.047,23.085,70.039,23.099,70.034,23.113,70.032,23.127,70.034,23.14,70.039,23.152,70.047,23.162,70.058,23.169,70.071,23.174,70.085]},
        {z:"red",p:[24.88,79.919,24.879,79.934,24.874,79.949,24.866,79.962,24.856,79.973,24.844,79.981,24.831,79.986,24.817,79.988,24.803,79.986,24.79,79.981,24.778,79.973,24.768,79.962,24.761,79.949,24.756,79.934,24.754,79.919,24.756,79.903,24.761,79.889,24.768,79.875,24.778,79.864,24.79,79.856,24.803,79.851,24.817,79.849,24.831,79.851,24.844,79.856,24.856,79.864,24.866,79.875,24.874,79.889,24.879,79.903]},
        {z:"red",p:[16.728,74.289,16.726,74.304,16.721,74.318,16.714,74.33,16.704,74.341,16.692,74.349,16.679,74.353,16.665,74.355,16.651,74.353,16.637,74.349,16.625,74.341,16.616,74.33,16.608,74.318,16.603,74.304,16.602,74.289,16.603,74.275,16.608,74.261,16.616,74.248,16.625,74.238,16.637,74.23,16.651,74.225,16.665,74.224,16.679,74.225,16.692,74.23,16.704,74.238,16.714,74.248,16.721,74.261,16.726,74.275]},
        {z:"red",p:[21.38,70.27,21.378,70.285,21.374,70.3,21.366,70.312,21.356,70.323,21.344,70.331,21.331,70.336,21.317,70.338,21.303,70.336,21.29,70.331,21.278,70.323,21.268,70.312,21.26,70.3,21.256,70.285,21.254,70.27,21.256,70.255,21.26,70.241,21.268,70.228,21.278,70.218,21.29,70.21,21.303,70.205,21.317,70.203,21.331,70.205,21.344,70.21,21.356,70.218,21.366,70.228,21.374,70.241,21.378,70.255]},
        {z:"red",p:[21.155,79.047,21.154,79.062,21.149,79.076,21.141,79.089,21.131,79.1,21.119,79.108,21.106,79.113,21.092,79.115,21.078,79.113,21.065,79.108,21.053,79.1,21.043,79.089,21.036,79.076,21.031,79.062,21.029,79.047,21.031,79.032,21.036,79.018,21.043,79.005,21.053,78.995,21.065,78.986,21.078,78.981,21.092,78.98,21.106,78.981,21.119,78.986,21.131,78.995,21.141,79.005,21.149,79.018,21.154,79.032]},
        {z:"red",p:[20.182,73.913,20.18,73.928,20.176,73.942,20.168,73.955,20.158,73.965,20.146,73.973,20.133,73.978,20.119,73.98,20.105,73.978,20.092,73.973,20.08,73.965,20.07,73.955,20.062,73.942,20.058,73.928,20.056,73.913,20.058,73.898,20.062,73.884,20.07,73.871,20.08,73.861,20.092,73.853,20.105,73.848,20.119,73.846,20.133,73.848,20.146,73.853,20.158,73.861,20.168,73.871,20.176,73.884,20.18,73.898]},
        {z:"red",p:[18.645,73.92,18.643,73.934,18.639,73.948,18.631,73.961,18.621,73.972,18.609,73.979,18.596,73.984,18.582,73.986,18.568,73.984,18.555,73.979,18.543,73.972,18.533,73.961,18.525,73.948,18.521,73.934,18.519,73.92,18.521,73.905,18.525,73.891,18.533,73.878,18.543,73.868,18.555,73.86,18.568,73.855,18.582,73.853,18.596,73.855,18.609,73.86,18.621,73.868,18.631,73.878,18.639,73.891,18.643,73.905]},
        {z:"red",p:[21.712,69.657,21.71,69.672,21.705,69.687,21.698,69.699,21.688,69.71,21.676,69.718,21.663,69.723,21.649,69.725,21.635,69.723,21.621,69.718,21.609,69.71,21.6,69.699,21.592,69.687,21.587,69.672,21.586,69.657,21.587,69.642,21.592,69.628,21.6,69.615,21.609,69.604,21.621,69.596,21.635,69.591,21.649,69.59,21.663,69.591,21.676,69.596,21.688,69.604,21.698,69.615,21.705,69.628,21.71,69.642]},
        {z:"red",p:[22.372,70.78,22.371,70.795,22.366,70.809,22.358,70.822,22.348,70.833,22.336,70.841,22.323,70.846,22.309,70.847,22.295,70.846,22.282,70.841,22.27,70.833,22.26,70.822,22.253,70.809,22.248,70.795,22.246,70.78,22.248,70.764,22.253,70.75,22.26,70.737,22.27,70.726,22.282,70.718,22.295,70.713,22.309,70.712,22.323,70.713,22.336,70.718,22.348,70.726,22.358,70.737,22.366,70.75,22.371,70.764]},
        {z:"red",p:[21.243,81.739,21.242,81.754,21.237,81.768,21.23,81.781,21.22,81.792,21.208,81.8,21.194,81.805,21.18,81.806,21.166,81.805,21.153,81.8,21.141,81.792,21.131,81.781,21.124,81.768,21.119,81.754,21.118,81.739,21.119,81.724,21.124,81.71,21.131,81.697,21.141,81.686,21.153,81.678,21.166,81.673,21.18,81.671,21.194,81.673,21.208,81.678,21.22,81.686,21.23,81.697,21.237,81.71,21.242,81.724]},
        {z:"red",p:[17.691,75.935,17.689,75.949,17.685,75.963,17.677,75.976,17.667,75.986,17.655,75.994,17.642,75.999,17.628,76.001,17.614,75.999,17.601,75.994,17.589,75.986,17.579,75.976,17.571,75.963,17.567,75.949,17.565,75.935,17.567,75.92,17.571,75.906,17.579,75.894,17.589,75.883,17.601,75.875,17.614,75.87,17.628,75.869,17.642,75.87,17.655,75.875,17.667,75.883,17.677,75.894,17.685,75.906,17.689,75.92]},
        {z:"red",p:[21.177,72.742,21.175,72.757,21.171,72.771,21.163,72.784,21.153,72.794,21.141,72.803,21.128,72.808,21.114,72.809,21.1,72.808,21.087,72.803,21.075,72.794,21.065,72.784,21.057,72.771,21.053,72.757,21.051,72.742,21.053,72.727,21.057,72.713,21.065,72.7,21.075,72.689,21.087,72.681,21.1,72.676,21.114,72.674,21.128,72.676,21.141,72.681,21.153,72.689,21.163,72.7,21.171,72.713,21.175,72.727]},
        {z:"red",p:[24.681,73.896,24.679,73.911,24.674,73.926,24.667,73.939,24.657,73.95,24.645,73.958,24.632,73.964,24.618,73.965,24.604,73.964,24.59,73.958,24.578,73.95,24.569,73.939,24.561,73.926,24.556,73.911,24.555,73.896,24.556,73.881,24.561,73.866,24.569,73.853,24.578,73.842,24.59,73.834,24.604,73.829,24.618,73.827,24.632,73.829,24.645,73.834,24.657,73.842,24.667,73.853,24.674,73.866,24.679,73.881]},
        {z:"red",p:[28.238,94.802,28.237,94.818,28.232,94.833,28.224,94.846,28.215,94.858,28.203,94.866,28.189,94.872,28.175,94.873,28.161,94.872,28.148,94.866,28.136,94.858,28.126,94.846,28.119,94.833,28.114,94.818,28.112,94.802,28.114,94.786,28.119,94.771,28.126,94.758,28.136,94.746,28.148,94.738,28.161,94.732,28.175,94.731,28.189,94.732,28.203,94.738,28.215,94.746,28.224,94.758,28.232,94.771,28.237,94.786]},
        {z:"red",p:[23.95,91.24,23.948,91.256,23.944,91.27,23.936,91.283,23.926,91.294,23.914,91.302,23.901,91.307,23.887,91.309,23.873,91.307,23.86,91.302,23.848,91.294,23.838,91.283,23.83,91.27,23.826,91.256,23.824,91.24,23.826,91.225,23.83,91.211,23.838,91.198,23.848,91.187,23.86,91.178,23.873,91.173,23.887,91.172,23.901,91.173,23.914,91.178,23.926,91.187,23.936,91.198,23.944,91.211,23.948,91.225]},
        {z:"red",p:[23.903,92.62,23.902,92.635,23.897,92.65,23.89,92.663,23.88,92.673,23.868,92.682,23.855,92.687,23.841,92.688,23.827,92.687,23.813,92.682,23.801,92.673,23.791,92.663,23.784,92.65,23.779,92.635,23.778,92.62,23.779,92.604,23.784,92.59,23.791,92.577,23.801,92.566,23.813,92.558,23.827,92.553,23.841,92.551,23.855,92.553,23.868,92.558,23.88,92.566,23.89,92.577,23.897,92.59,23.902,92.604]},
        {z:"red",p:[26.744,88.329,26.743,88.344,26.738,88.359,26.73,88.372,26.72,88.384,26.708,88.392,26.695,88.397,26.681,88.399,26.667,88.397,26.654,88.392,26.642,88.384,26.632,88.372,26.625,88.359,26.62,88.344,26.618,88.329,26.62,88.313,26.625,88.298,26.632,88.285,26.642,88.274,26.654,88.265,26.667,88.26,26.681,88.258,26.695,88.26,26.708,88.265,26.72,88.274,26.73,88.285,26.738,88.298,26.743,88.313]},
        {z:"red",p:[20.307,85.818,20.306,85.833,20.301,85.847,20.294,85.86,20.284,85.87,20.272,85.878,20.258,85.883,20.244,85.885,20.23,85.883,20.217,85.878,20.205,85.87,20.195,85.86,20.188,85.847,20.183,85.833,20.182,85.818,20.183,85.803,20.188,85.789,20.195,85.776,20.205,85.765,20.217,85.757,20.23,85.752,20.244,85.751,20.258,85.752,20.272,85.757,20.284,85.765,20.294,85.776,20.301,85.789,20.306,85.803]},
        {z:"red",p:[22.718,88.447,22.716,88.462,22.711,88.476,22.704,88.489,22.694,88.5,22.682,88.508,22.669,88.513,22.655,88.515,22.641,88.513,22.627,88.508,22.615,88.5,22.606,88.489,22.598,88.476,22.593,88.462,22.592,88.447,22.593,88.432,22.598,88.417,22.606,88.404,22.615,88.393,22.627,88.385,22.641,88.38,22.655,88.379,22.669,88.38,22.682,88.385,22.694,88.393,22.704,88.404,22.711,88.417,22.716,88.432]},
        {z:"red",p:[26.393,89.467,26.392,89.483,26.387,89.498,26.38,89.511,26.37,89.522,26.358,89.53,26.344,89.536,26.33,89.537,26.317,89.536,26.303,89.53,26.291,89.522,26.281,89.511,26.274,89.498,26.269,89.483,26.268,89.467,26.269,89.452,26.274,89.437,26.281,89.423,26.291,89.412,26.303,89.404,26.317,89.399,26.33,89.397,26.344,89.399,26.358,89.404,26.37,89.412,26.38,89.423,26.387,89.437,26.392,89.452]},
        {z:"red",p:[23.897,86.425,23.895,86.441,23.891,86.455,23.883,86.468,23.873,86.479,23.861,86.487,23.848,86.492,23.834,86.494,23.82,86.492,23.807,86.487,23.795,86.479,23.785,86.468,23.777,86.455,23.773,86.441,23.771,86.425,23.773,86.41,23.777,86.395,23.785,86.382,23.795,86.372,23.807,86.363,23.82,86.358,23.834,86.357,23.848,86.358,23.861,86.363,23.873,86.372,23.883,86.382,23.891,86.395,23.895,86.41]},
        {z:"red",p:[24.807,84.951,24.806,84.967,24.801,84.981,24.793,84.994,24.784,85.005,24.772,85.014,24.758,85.019,24.744,85.02,24.73,85.019,24.717,85.014,24.705,85.005,24.695,84.994,24.688,84.981,24.683,84.967,24.681,84.951,24.683,84.936,24.688,84.921,24.695,84.908,24.705,84.897,24.717,84.889,24.73,84.884,24.744,84.882,24.758,84.884,24.772,84.889,24.784,84.897,24.793,84.908,24.801,84.921,24.806,84.936]},
        {z:"red",p:[24.823,93.897,24.821,93.912,24.817,93.927,24.809,93.94,24.799,93.951,24.787,93.959,24.774,93.964,24.76,93.966,24.746,93.964,24.733,93.959,24.721,93.951,24.711,93.94,24.703,93.927,24.699,93.912,24.697,93.897,24.699,93.881,24.703,93.867,24.711,93.854,24.721,93.843,24.733,93.834,24.746,93.829,24.76,93.827,24.774,93.829,24.787,93.834,24.799,93.843,24.809,93.854,24.817,93.867,24.821,93.881]},
        {z:"red",p:[22.876,86.169,22.875,86.184,22.87,86.198,22.862,86.211,22.852,86.222,22.84,86.23,22.827,86.235,22.813,86.237,22.799,86.235,22.786,86.23,22.774,86.222,22.764,86.211,22.757,86.198,22.752,86.184,22.75,86.169,22.752,86.154,22.757,86.139,22.764,86.126,22.774,86.115,22.786,86.107,22.799,86.102,22.813,86.101,22.827,86.102,22.84,86.107,22.852,86.115,22.862,86.126,22.87,86.139,22.875,86.154]},
        {z:"red",p:[26.794,94.175,26.793,94.191,26.788,94.206,26.781,94.219,26.771,94.231,26.759,94.239,26.745,94.244,26.732,94.246,26.718,94.244,26.704,94.239,26.692,94.231,26.682,94.219,26.675,94.206,26.67,94.191,26.669,94.175,26.67,94.16,26.675,94.145,26.682,94.132,26.692,94.12,26.704,94.112,26.718,94.107,26.732,94.105,26.745,94.107,26.759,94.112,26.771,94.12,26.781,94.132,26.788,94.145,26.793,94.16]},
        {z:"red",p:[24.371,92.007,24.37,92.023,24.365,92.037,24.357,92.05,24.347,92.061,24.335,92.069,24.322,92.074,24.308,92.076,24.294,92.074,24.281,92.069,24.269,92.061,24.259,92.05,24.252,92.037,24.247,92.023,24.245,92.007,24.247,91.992,24.252,91.977,24.259,91.964,24.269,91.953,24.281,91.945,24.294,91.94,24.308,91.938,24.322,91.94,24.335,91.945,24.347,91.953,24.357,91.964,24.365,91.977,24.37,91.992]},
        {z:"red",p:[24.976,92.979,24.974,92.994,24.97,93.009,24.962,93.022,24.952,93.033,24.94,93.041,24.927,93.046,24.913,93.048,24.899,93.046,24.886,93.041,24.874,93.033,24.864,93.022,24.856,93.009,24.852,92.994,24.85,92.979,24.852,92.963,24.856,92.949,24.864,92.935,24.874,92.924,24.886,92.916,24.899,92.911,24.913,92.909,24.927,92.911,24.94,92.916,24.952,92.924,24.962,92.935,24.97,92.949,24.974,92.963]},
        {z:"red",p:[27.358,94.098,27.357,94.113,27.352,94.128,27.345,94.142,27.335,94.153,27.323,94.161,27.309,94.167,27.295,94.168,27.282,94.167,27.268,94.161,27.256,94.153,27.246,94.142,27.239,94.128,27.234,94.113,27.233,94.098,27.234,94.082,27.239,94.067,27.246,94.053,27.256,94.042,27.268,94.034,27.282,94.029,27.295,94.027,27.309,94.029,27.323,94.034,27.335,94.042,27.345,94.053,27.352,94.067,27.357,94.082]},
        {z:"red",p:[27.547,95.017,27.545,95.033,27.541,95.048,27.533,95.061,27.523,95.072,27.511,95.081,27.498,95.086,27.484,95.088,27.47,95.086,27.457,95.081,27.445,95.072,27.435,95.061,27.427,95.048,27.423,95.033,27.421,95.017,27.423,95.001,27.427,94.986,27.435,94.973,27.445,94.961,27.457,94.953,27.47,94.948,27.484,94.946,27.498,94.948,27.511,94.953,27.523,94.961,27.533,94.973,27.541,94.986,27.545,95.001]},
        {z:"red",p:[26.182,85.314,26.18,85.329,26.176,85.344,26.168,85.357,26.158,85.368,26.146,85.377,26.133,85.382,26.119,85.384,26.105,85.382,26.092,85.377,26.08,85.368,26.07,85.357,26.062,85.344,26.058,85.329,26.056,85.314,26.058,85.298,26.062,85.283,26.07,85.27,26.08,85.259,26.092,85.251,26.105,85.245,26.119,85.244,26.133,85.245,26.146,85.251,26.158,85.259,26.168,85.27,26.176,85.283,26.18,85.298]},
        {z:"red",p:[25.654,85.088,25.653,85.104,25.648,85.118,25.64,85.131,25.631,85.143,25.619,85.151,25.605,85.156,25.591,85.158,25.577,85.156,25.564,85.151,25.552,85.143,25.542,85.131,25.535,85.118,25.53,85.104,25.528,85.088,25.53,85.072,25.535,85.058,25.542,85.045,25.552,85.033,25.564,85.025,25.577,85.02,25.591,85.018,25.605,85.02,25.619,85.025,25.631,85.033,25.64,85.045,25.648,85.058,25.653,85.072]},
        {z:"red",p:[23.377,85.322,23.376,85.337,23.371,85.351,23.363,85.364,23.354,85.375,23.342,85.383,23.328,85.388,23.314,85.39,23.3,85.388,23.287,85.383,23.275,85.375,23.265,85.364,23.258,85.351,23.253,85.337,23.251,85.322,23.253,85.306,23.258,85.292,23.265,85.279,23.275,85.268,23.287,85.26,23.3,85.255,23.314,85.253,23.328,85.255,23.342,85.26,23.354,85.268,23.363,85.279,23.371,85.292,23.376,85.306]},
        {z:"red",p:[22.32,84.815,22.318,84.83,22.313,84.844,22.306,84.857,22.296,84.868,22.284,84.876,22.271,84.881,22.257,84.883,22.243,84.881,22.229,84.876,22.217,84.868,22.208,84.857,22.2,84.844,22.195,84.83,22.194,84.815,22.195,84.799,22.2,84.785,22.208,84.772,22.217,84.761,22.229,84.753,22.243,84.748,22.257,84.747,22.271,84.748,22.284,84.753,22.296,84.761,22.306,84.772,22.313,84.785,22.318,84.799]},
        {z:"red",p:[17.784,83.225,17.783,83.239,17.778,83.253,17.77,83.266,17.76,83.276,17.748,83.284,17.735,83.289,17.721,83.291,17.707,83.289,17.694,83.284,17.682,83.276,17.672,83.266,17.665,83.253,17.66,83.239,17.658,83.225,17.66,83.21,17.665,83.196,17.672,83.183,17.682,83.173,17.694,83.165,17.707,83.16,17.721,83.158,17.735,83.16,17.748,83.165,17.76,83.173,17.77,83.183,17.778,83.196,17.783,83.21]},
        {z:"red",p:[27.651,93.828,27.65,93.844,27.645,93.859,27.637,93.872,27.628,93.884,27.616,93.892,27.602,93.897,27.588,93.899,27.574,93.897,27.561,93.892,27.549,93.884,27.539,93.872,27.532,93.859,27.527,93.844,27.525,93.828,27.527,93.812,27.532,93.797,27.539,93.784,27.549,93.773,27.561,93.764,27.574,93.759,27.588,93.757,27.602,93.759,27.616,93.764,27.628,93.773,27.637,93.784,27.645,93.797,27.65,93.812]},
        {z:"red",p:[27.219,77.961,27.217,77.977,27.212,77.992,27.205,78.005,27.195,78.016,27.183,78.025,27.17,78.03,27.156,78.032,27.142,78.03,27.129,78.025,27.117,78.016,27.107,78.005,27.099,77.992,27.094,77.977,27.093,77.961,27.094,77.945,27.099,77.93,27.107,77.917,27.117,77.906,27.129,77.897,27.142,77.892,27.156,77.89,27.17,77.892,27.183,77.897,27.195,77.906,27.205,77.917,27.212,77.93,27.217,77.945]},
        {z:"red",p:[25.503,81.734,25.501,81.749,25.497,81.764,25.489,81.777,25.479,81.788,25.467,81.797,25.454,81.802,25.44,81.804,25.426,81.802,25.413,81.797,25.401,81.788,25.391,81.777,25.383,81.764,25.379,81.749,25.377,81.734,25.379,81.718,25.383,81.704,25.391,81.69,25.401,81.679,25.413,81.671,25.426,81.666,25.44,81.664,25.454,81.666,25.467,81.671,25.479,81.679,25.489,81.69,25.497,81.704,25.501,81.718]},
        {z:"red",p:[31.772,74.797,31.771,74.814,31.766,74.829,31.759,74.843,31.749,74.855,31.737,74.864,31.724,74.869,31.71,74.871,31.696,74.869,31.682,74.864,31.67,74.855,31.66,74.843,31.653,74.829,31.648,74.814,31.647,74.797,31.648,74.781,31.653,74.765,31.66,74.751,31.67,74.74,31.682,74.731,31.696,74.725,31.71,74.723,31.724,74.725,31.737,74.731,31.749,74.74,31.759,74.751,31.766,74.765,31.771,74.781]},
        {z:"red",p:[28.133,73.207,28.132,73.223,28.127,73.238,28.12,73.252,28.11,73.263,28.098,73.271,28.085,73.277,28.071,73.278,28.057,73.277,28.043,73.271,28.031,73.263,28.021,73.252,28.014,73.238,28.009,73.223,28.008,73.207,28.009,73.191,28.014,73.176,28.021,73.163,28.031,73.151,28.043,73.143,28.057,73.138,28.071,73.136,28.085,73.138,28.098,73.143,28.11,73.151,28.12,73.163,28.127,73.176,28.132,73.191]},
        {z:"red",p:[25.515,82.859,25.514,82.875,25.509,82.89,25.502,82.903,25.492,82.914,25.48,82.922,25.466,82.927,25.452,82.929,25.438,82.927,25.425,82.922,25.413,82.914,25.403,82.903,25.396,82.89,25.391,82.875,25.39,82.859,25.391,82.844,25.396,82.829,25.403,82.816,25.413,82.805,25.425,82.797,25.438,82.791,25.452,82.79,25.466,82.791,25.48,82.797,25.492,82.805,25.502,82.816,25.509,82.829,25.514,82.844]},
        {z:"red",p:[31.94,77.154,31.938,77.171,31.933,77.187,31.926,77.201,31.916,77.212,31.904,77.221,31.891,77.227,31.877,77.228,31.863,77.227,31.849,77.221,31.837,77.212,31.828,77.201,31.82,77.187,31.815,77.171,31.814,77.154,31.815,77.138,31.82,77.122,31.828,77.108,31.837,77.097,31.849,77.088,31.863,77.082,31.877,77.08,31.891,77.082,31.904,77.088,31.916,77.097,31.926,77.108,31.933,77.122,31.938,77.138]},
        {z:"red",p:[30.333,74.756,30.331,74.772,30.327,74.787,30.319,74.801,30.309,74.813,30.297,74.821,30.284,74.827,30.27,74.829,30.256,74.827,30.243,74.821,30.231,74.813,30.221,74.801,30.213,74.787,30.209,74.772,30.207,74.756,30.209,74.74,30.213,74.724,30.221,74.71,30.231,74.699,30.243,74.69,30.256,74.685,30.27,74.683,30.284,74.685,30.297,74.69,30.309,74.699,30.319,74.71,30.327,74.724,30.331,74.74]},
        {z:"red",p:[28.485,79.451,28.483,79.467,28.479,79.482,28.471,79.495,28.461,79.507,28.449,79.515,28.436,79.521,28.422,79.522,28.408,79.521,28.395,79.515,28.383,79.507,28.373,79.495,28.365,79.482,28.361,79.467,28.359,79.451,28.361,79.435,28.365,79.42,28.373,79.406,28.383,79.395,28.395,79.386,28.408,79.381,28.422,79.379,28.436,79.381,28.449,79.386,28.461,79.395,28.471,79.406,28.479,79.42,28.483,79.435]},
        {z:"red",p:[30.736,76.788,30.735,76.805,30.73,76.82,30.723,76.834,30.713,76.846,30.701,76.854,30.687,76.86,30.674,76.862,30.66,76.86,30.646,76.854,30.634,76.846,30.624,76.834,30.617,76.82,30.612,76.805,30.611,76.788,30.612,76.772,30.617,76.757,30.624,76.743,30.634,76.731,30.646,76.723,30.66,76.717,30.674,76.715,30.687,76.717,30.701,76.723,30.713,76.731,30.723,76.743,30.73,76.757,30.735,76.772]},
        {z:"red",p:[26.467,80.41,26.466,80.426,26.461,80.441,26.453,80.454,26.444,80.465,26.432,80.473,26.418,80.479,26.404,80.48,26.39,80.479,26.377,80.473,26.365,80.465,26.355,80.454,26.348,80.441,26.343,80.426,26.341,80.41,26.343,80.394,26.348,80.38,26.355,80.366,26.365,80.355,26.377,80.347,26.39,80.342,26.404,80.34,26.418,80.342,26.432,80.347,26.444,80.355,26.453,80.366,26.461,80.38,26.466,80.394]},
        {z:"red",p:[30.253,78.18,30.251,78.196,30.246,78.212,30.239,78.226,30.229,78.237,30.217,78.246,30.204,78.251,30.19,78.253,30.176,78.251,30.162,78.246,30.15,78.237,30.141,78.226,30.133,78.212,30.128,78.196,30.127,78.18,30.128,78.164,30.133,78.149,30.141,78.135,30.15,78.123,30.162,78.115,30.176,78.109,30.19,78.108,30.204,78.109,30.217,78.115,30.229,78.123,30.239,78.135,30.246,78.149,30.251,78.164]},
        {z:"red",p:[28.629,77.103,28.628,77.119,28.623,77.134,28.616,77.148,28.606,77.159,28.594,77.168,28.58,77.173,28.567,77.175,28.553,77.173,28.539,77.168,28.527,77.159,28.517,77.148,28.51,77.134,28.505,77.119,28.504,77.103,28.505,77.087,28.51,77.072,28.517,77.058,28.527,77.047,28.539,77.039,28.553,77.033,28.567,77.032,28.58,77.033,28.594,77.039,28.606,77.047,28.616,77.058,28.623,77.072,28.628,77.087]},
        {z:"red",p:[26.356,78.228,26.355,78.243,26.35,78.258,26.342,78.272,26.333,78.283,26.321,78.291,26.307,78.296,26.293,78.298,26.279,78.296,26.266,78.291,26.254,78.283,26.244,78.272,26.237,78.258,26.232,78.243,26.23,78.228,26.232,78.212,26.237,78.197,26.244,78.184,26.254,78.173,26.266,78.165,26.279,78.159,26.293,78.158,26.307,78.159,26.321,78.165,26.333,78.173,26.342,78.184,26.35,78.197,26.355,78.212]},
        {z:"red",p:[29.242,75.755,29.241,75.771,29.236,75.787,29.229,75.8,29.219,75.812,29.207,75.82,29.193,75.826,29.179,75.827,29.165,75.826,29.152,75.82,29.14,75.812,29.13,75.8,29.123,75.787,29.118,75.771,29.117,75.755,29.118,75.739,29.123,75.724,29.13,75.71,29.14,75.699,29.152,75.69,29.165,75.685,29.179,75.683,29.193,75.685,29.207,75.69,29.219,75.699,29.229,75.71,29.236,75.724,29.241,75.739]},
        {z:"red",p:[26.314,73.049,26.312,73.064,26.308,73.079,26.3,73.093,26.29,73.104,26.278,73.112,26.265,73.117,26.251,73.119,26.237,73.117,26.224,73.112,26.212,73.104,26.202,73.093,26.194,73.079,26.19,73.064,26.188,73.049,26.19,73.033,26.194,73.018,26.202,73.005,26.212,72.994,26.224,72.986,26.237,72.981,26.251,72.979,26.265,72.981,26.278,72.986,26.29,72.994,26.3,73.005,26.308,73.018,26.312,73.033]},
        {z:"red",p:[26.887,75.812,26.886,75.828,26.881,75.843,26.873,75.856,26.863,75.867,26.851,75.876,26.838,75.881,26.824,75.883,26.81,75.881,26.797,75.876,26.785,75.867,26.775,75.856,26.768,75.843,26.763,75.828,26.761,75.812,26.763,75.797,26.768,75.782,26.775,75.768,26.785,75.757,26.797,75.749,26.81,75.744,26.824,75.742,26.838,75.744,26.851,75.749,26.863,75.757,26.873,75.768,26.881,75.782,26.886,75.797]},
        {z:"red",p:[26.952,70.865,26.95,70.881,26.945,70.896,26.938,70.909,26.928,70.92,26.916,70.929,26.903,70.934,26.889,70.936,26.875,70.934,26.861,70.929,26.849,70.92,26.84,70.909,26.832,70.896,26.827,70.881,26.826,70.865,26.827,70.849,26.832,70.834,26.84,70.821,26.849,70.81,26.861,70.801,26.875,70.796,26.889,70.794,26.903,70.796,26.916,70.801,26.928,70.81,26.938,70.821,26.945,70.834,26.95,70.849]},
        {z:"red",p:[32.752,74.837,32.75,74.854,32.746,74.87,32.738,74.884,32.728,74.896,32.716,74.905,32.703,74.91,32.689,74.912,32.675,74.91,32.662,74.905,32.65,74.896,32.64,74.884,32.632,74.87,32.628,74.854,32.626,74.837,32.628,74.821,32.632,74.805,32.64,74.791,32.65,74.779,32.662,74.77,32.675,74.765,32.689,74.763,32.703,74.765,32.716,74.77,32.728,74.779,32.738,74.791,32.746,74.805,32.75,74.821]},
        {z:"red",p:[25.223,75.846,25.222,75.861,25.217,75.876,25.209,75.889,25.199,75.9,25.187,75.908,25.174,75.913,25.16,75.915,25.146,75.913,25.133,75.908,25.121,75.9,25.111,75.889,25.104,75.876,25.099,75.861,25.097,75.846,25.099,75.83,25.104,75.815,25.111,75.802,25.121,75.791,25.133,75.783,25.146,75.778,25.16,75.776,25.174,75.778,25.187,75.783,25.199,75.791,25.209,75.802,25.217,75.815,25.222,75.83]},
        {z:"red",p:[30.918,75.953,30.916,75.969,30.911,75.984,30.904,75.998,30.894,76.01,30.882,76.019,30.869,76.024,30.855,76.026,30.841,76.024,30.827,76.019,30.815,76.01,30.806,75.998,30.798,75.984,30.793,75.969,30.792,75.953,30.793,75.936,30.798,75.921,30.806,75.907,30.815,75.895,30.827,75.887,30.841,75.881,30.855,75.879,30.869,75.881,30.882,75.887,30.894,75.895,30.904,75.907,30.911,75.921,30.916,75.936]},
        {z:"red",p:[34.199,77.547,34.197,77.563,34.193,77.579,34.185,77.594,34.175,77.606,34.163,77.615,34.15,77.621,34.136,77.622,34.122,77.621,34.109,77.615,34.097,77.606,34.087,77.594,34.079,77.579,34.075,77.563,34.073,77.547,34.075,77.53,34.079,77.514,34.087,77.499,34.097,77.487,34.109,77.478,34.122,77.472,34.136,77.471,34.15,77.472,34.163,77.478,34.175,77.487,34.185,77.499,34.193,77.514,34.197,77.53]},
        {z:"red",p:[26.823,80.889,26.822,80.905,26.817,80.92,26.81,80.933,26.8,80.944,26.788,80.953,26.775,80.958,26.761,80.96,26.747,80.958,26.733,80.953,26.721,80.944,26.711,80.933,26.704,80.92,26.699,80.905,26.698,80.889,26.699,80.874,26.704,80.859,26.711,80.845,26.721,80.834,26.733,80.826,26.747,80.821,26.761,80.819,26.775,80.821,26.788,80.826,26.8,80.834,26.81,80.845,26.817,80.859,26.822,80.874]},
        {z:"red",p:[32.296,75.634,32.295,75.651,32.29,75.667,32.283,75.681,32.273,75.693,32.261,75.701,32.248,75.707,32.234,75.709,32.22,75.707,32.206,75.701,32.194,75.693,32.184,75.681,32.177,75.667,32.172,75.651,32.171,75.634,32.172,75.618,32.177,75.602,32.184,75.588,32.194,75.576,32.206,75.567,32.22,75.562,32.234,75.56,32.248,75.562,32.261,75.567,32.273,75.576,32.283,75.588,32.29,75.602,32.295,75.618]},
        {z:"red",p:[29.096,79.474,29.095,79.49,29.09,79.505,29.083,79.519,29.073,79.53,29.061,79.538,29.047,79.544,29.033,79.546,29.019,79.544,29.006,79.538,28.994,79.53,28.984,79.519,28.977,79.505,28.972,79.49,28.971,79.474,28.972,79.458,28.977,79.442,28.984,79.429,28.994,79.417,29.006,79.409,29.019,79.404,29.033,79.402,29.047,79.404,29.061,79.409,29.073,79.417,29.083,79.429,29.09,79.442,29.095,79.458]},
        {z:"red",p:[34.05,74.774,34.048,74.791,34.044,74.807,34.036,74.821,34.026,74.833,34.014,74.843,34.001,74.848,33.987,74.85,33.973,74.848,33.96,74.843,33.948,74.833,33.938,74.821,33.93,74.807,33.926,74.791,33.924,74.774,33.926,74.757,33.93,74.741,33.938,74.727,33.948,74.715,33.96,74.706,33.973,74.7,33.987,74.698,34.001,74.7,34.014,74.706,34.026,74.715,34.036,74.727,34.044,74.741,34.048,74.757]},
        {z:"red",p:[24.625,80.855,24.624,80.87,24.619,80.885,24.611,80.898,24.602,80.909,24.59,80.917,24.576,80.922,24.562,80.924,24.548,80.922,24.535,80.917,24.523,80.909,24.513,80.898,24.506,80.885,24.501,80.87,24.499,80.855,24.501,80.84,24.506,80.825,24.513,80.812,24.523,80.801,24.535,80.793,24.548,80.787,24.562,80.786,24.576,80.787,24.59,80.793,24.602,80.801,24.611,80.812,24.619,80.825,24.624,80.84]},
        {z:"red",p:[10.887,72.176,10.885,72.19,10.88,72.204,10.873,72.216,10.863,72.226,10.851,72.234,10.838,72.238,10.824,72.24,10.81,72.238,10.796,72.234,10.784,72.226,10.775,72.216,10.767,72.204,10.762,72.19,10.761,72.176,10.762,72.162,10.767,72.148,10.775,72.136,10.784,72.126,10.796,72.118,10.81,72.114,10.824,72.112,10.838,72.114,10.851,72.118,10.863,72.126,10.873,72.136,10.88,72.148,10.885,72.162]},
        {z:"red",p:[13.261,77.706,13.259,77.721,13.255,77.734,13.247,77.747,13.237,77.757,13.225,77.764,13.212,77.769,13.198,77.771,13.184,77.769,13.171,77.764,13.159,77.757,13.149,77.747,13.141,77.734,13.137,77.721,13.135,77.706,13.137,77.692,13.141,77.678,13.149,77.666,13.159,77.656,13.171,77.648,13.184,77.643,13.198,77.642,13.212,77.643,13.225,77.648,13.237,77.656,13.247,77.666,13.255,77.678,13.259,77.692]},
        {z:"red",p:[15.226,76.883,15.224,76.897,15.219,76.911,15.212,76.923,15.202,76.934,15.19,76.941,15.177,76.946,15.163,76.948,15.149,76.946,15.136,76.941,15.124,76.934,15.114,76.923,15.106,76.911,15.101,76.897,15.1,76.883,15.101,76.868,15.106,76.855,15.114,76.842,15.124,76.832,15.136,76.824,15.149,76.819,15.163,76.818,15.177,76.819,15.19,76.824,15.202,76.832,15.212,76.842,15.219,76.855,15.224,76.868]},
        {z:"red",p:[16.593,80.797,16.592,80.811,16.587,80.825,16.58,80.838,16.57,80.848,16.558,80.856,16.544,80.861,16.53,80.862,16.516,80.861,16.503,80.856,16.491,80.848,16.481,80.838,16.474,80.825,16.469,80.811,16.468,80.797,16.469,80.782,16.474,80.768,16.481,80.756,16.491,80.746,16.503,80.738,16.516,80.733,16.53,80.731,16.544,80.733,16.558,80.738,16.57,80.746,16.58,80.756,16.587,80.768,16.592,80.782]},
        {z:"red",p:[11.093,77.043,11.091,77.058,11.087,77.071,11.079,77.083,11.069,77.093,11.057,77.101,11.044,77.106,11.03,77.107,11.016,77.106,11.003,77.101,10.991,77.093,10.981,77.083,10.973,77.071,10.969,77.058,10.967,77.043,10.969,77.029,10.973,77.016,10.981,77.003,10.991,76.993,11.003,76.986,11.016,76.981,11.03,76.979,11.044,76.981,11.057,76.986,11.069,76.993,11.079,77.003,11.087,77.016,11.091,77.029]},
        {z:"red",p:[10.215,76.402,10.213,76.416,10.209,76.43,10.201,76.442,10.191,76.452,10.179,76.459,10.166,76.464,10.152,76.466,10.138,76.464,10.125,76.459,10.113,76.452,10.103,76.442,10.095,76.43,10.091,76.416,10.089,76.402,10.091,76.388,10.095,76.374,10.103,76.362,10.113,76.352,10.125,76.344,10.138,76.34,10.152,76.338,10.166,76.34,10.179,76.344,10.191,76.352,10.201,76.362,10.209,76.374,10.213,76.388]},
        {z:"red",p:[11.2,75.955,11.198,75.97,11.193,75.983,11.186,75.995,11.176,76.005,11.164,76.013,11.151,76.018,11.137,76.019,11.123,76.018,11.11,76.013,11.098,76.005,11.088,75.995,11.08,75.983,11.075,75.97,11.074,75.955,11.075,75.941,11.08,75.927,11.088,75.915,11.098,75.905,11.11,75.898,11.123,75.893,11.137,75.891,11.151,75.893,11.164,75.898,11.176,75.905,11.186,75.915,11.193,75.927,11.198,75.941]},
        {z:"red",p:[14.573,78.773,14.571,78.787,14.567,78.801,14.559,78.813,14.549,78.824,14.537,78.831,14.524,78.836,14.51,78.838,14.496,78.836,14.483,78.831,14.471,78.824,14.461,78.813,14.453,78.801,14.449,78.787,14.447,78.773,14.449,78.758,14.453,78.745,14.461,78.732,14.471,78.722,14.483,78.714,14.496,78.709,14.51,78.708,14.524,78.709,14.537,78.714,14.549,78.722,14.559,78.732,14.567,78.745,14.571,78.758]},
        {z:"red",p:[9.215,92.82,9.214,92.834,9.209,92.847,9.202,92.859,9.192,92.869,9.18,92.877,9.167,92.882,9.153,92.883,9.139,92.882,9.125,92.877,9.113,92.869,9.103,92.859,9.096,92.847,9.091,92.834,9.09,92.82,9.091,92.805,9.096,92.792,9.103,92.78,9.113,92.77,9.125,92.762,9.139,92.758,9.153,92.756,9.167,92.758,9.18,92.762,9.192,92.77,9.202,92.78,9.209,92.792,9.214,92.805]},
        {z:"red",p:[17.516,78.468,17.514,78.482,17.51,78.496,17.502,78.509,17.492,78.519,17.48,78.527,17.467,78.532,17.453,78.534,17.439,78.532,17.426,78.527,17.414,78.519,17.404,78.509,17.396,78.496,17.392,78.482,17.39,78.468,17.392,78.453,17.396,78.439,17.404,78.426,17.414,78.416,17.426,78.408,17.439,78.403,17.453,78.402,17.467,78.403,17.48,78.408,17.492,78.416,17.502,78.426,17.51,78.439,17.514,78.453]},
        {z:"red",p:[9.897,78.093,9.896,78.108,9.891,78.121,9.884,78.133,9.874,78.143,9.862,78.151,9.849,78.156,9.835,78.157,9.821,78.156,9.807,78.151,9.795,78.143,9.785,78.133,9.778,78.121,9.773,78.108,9.772,78.093,9.773,78.079,9.778,78.066,9.785,78.054,9.795,78.044,9.807,78.036,9.821,78.031,9.835,78.03,9.849,78.031,9.862,78.036,9.874,78.044,9.884,78.054,9.891,78.066,9.896,78.079]},
        {z:"red",p:[13.024,74.89,13.023,74.904,13.018,74.918,13.01,74.93,13.001,74.941,12.989,74.948,12.975,74.953,12.961,74.955,12.947,74.953,12.934,74.948,12.922,74.941,12.912,74.93,12.905,74.918,12.9,74.904,12.898,74.89,12.9,74.876,12.905,74.862,12.912,74.85,12.922,74.84,12.934,74.832,12.947,74.827,12.961,74.826,12.975,74.827,12.989,74.832,13.001,74.84,13.01,74.85,13.018,74.862,13.023,74.876]},
        {z:"red",p:[13.053,80.169,13.051,80.184,13.047,80.197,13.039,80.21,13.029,80.22,13.017,80.227,13.004,80.232,12.99,80.234,12.976,80.232,12.963,80.227,12.951,80.22,12.941,80.21,12.933,80.197,12.929,80.184,12.927,80.169,12.929,80.155,12.933,80.141,12.941,80.129,12.951,80.119,12.963,80.111,12.976,80.106,12.99,80.105,13.004,80.106,13.017,80.111,13.029,80.119,13.039,80.129,13.047,80.141,13.051,80.155]},
        {z:"red",p:[11.704,92.73,11.703,92.744,11.698,92.758,11.69,92.77,11.68,92.78,11.668,92.788,11.655,92.792,11.641,92.794,11.627,92.792,11.614,92.788,11.602,92.78,11.592,92.77,11.585,92.758,11.58,92.744,11.578,92.73,11.58,92.715,11.585,92.702,11.592,92.69,11.602,92.68,11.614,92.672,11.627,92.667,11.641,92.665,11.655,92.667,11.668,92.672,11.68,92.68,11.69,92.69,11.698,92.702,11.703,92.715]},
        {z:"red",p:[12.031,79.812,12.029,79.826,12.025,79.84,12.017,79.852,12.007,79.862,11.995,79.87,11.982,79.875,11.968,79.876,11.954,79.875,11.941,79.87,11.929,79.862,11.919,79.852,11.911,79.84,11.907,79.826,11.905,79.812,11.907,79.798,11.911,79.784,11.919,79.772,11.929,79.762,11.941,79.754,11.954,79.749,11.968,79.748,11.982,79.749,11.995,79.754,12.007,79.762,12.017,79.772,12.025,79.784,12.029,79.798]},
        {z:"red",p:[17.173,81.818,17.172,81.833,17.167,81.847,17.16,81.859,17.15,81.87,17.138,81.877,17.124,81.882,17.11,81.884,17.096,81.882,17.083,81.877,17.071,81.87,17.061,81.859,17.054,81.847,17.049,81.833,17.048,81.818,17.049,81.804,17.054,81.79,17.061,81.777,17.071,81.767,17.083,81.759,17.096,81.754,17.11,81.752,17.124,81.754,17.138,81.759,17.15,81.767,17.16,81.777,17.167,81.79,17.172,81.804]},
        {z:"red",p:[11.846,78.066,11.845,78.08,11.84,78.093,11.832,78.106,11.823,78.116,11.811,78.123,11.797,78.128,11.783,78.13,11.769,78.128,11.756,78.123,11.744,78.116,11.734,78.106,11.727,78.093,11.722,78.08,11.72,78.066,11.722,78.051,11.727,78.038,11.734,78.026,11.744,78.015,11.756,78.008,11.769,78.003,11.783,78.001,11.797,78.003,11.811,78.008,11.823,78.015,11.832,78.026,11.84,78.038,11.845,78.051]},
        {z:"red",p:[10.785,79.102,10.784,79.116,10.779,79.129,10.772,79.142,10.762,79.152,10.75,79.159,10.736,79.164,10.722,79.166,10.708,79.164,10.695,79.159,10.683,79.152,10.673,79.142,10.666,79.129,10.661,79.116,10.66,79.102,10.661,79.087,10.666,79.074,10.673,79.062,10.683,79.052,10.695,79.044,10.708,79.039,10.722,79.038,10.736,79.039,10.75,79.044,10.762,79.052,10.772,79.062,10.779,79.074,10.784,79.087]},
        {z:"red",p:[13.695,79.543,13.694,79.558,13.689,79.571,13.682,79.584,13.672,79.594,13.66,79.602,13.646,79.606,13.632,79.608,13.619,79.606,13.605,79.602,13.593,79.594,13.583,79.584,13.576,79.571,13.571,79.558,13.57,79.543,13.571,79.529,13.576,79.515,13.583,79.503,13.593,79.493,13.605,79.485,13.619,79.48,13.632,79.479,13.646,79.48,13.66,79.485,13.672,79.493,13.682,79.503,13.689,79.515,13.694,79.529]},
        {z:"red",p:[10.828,78.71,10.827,78.724,10.822,78.737,10.815,78.75,10.805,78.76,10.793,78.767,10.779,78.772,10.765,78.774,10.751,78.772,10.738,78.767,10.726,78.76,10.716,78.75,10.709,78.737,10.704,78.724,10.703,78.71,10.704,78.695,10.709,78.682,10.716,78.67,10.726,78.66,10.738,78.652,10.751,78.647,10.765,78.646,10.779,78.647,10.793,78.652,10.805,78.66,10.815,78.67,10.822,78.682,10.827,78.695]},
        {z:"red",p:[8.545,76.92,8.543,76.934,8.539,76.948,8.531,76.96,8.521,76.97,8.509,76.977,8.496,76.982,8.482,76.984,8.468,76.982,8.455,76.977,8.443,76.97,8.433,76.96,8.425,76.948,8.421,76.934,8.419,76.92,8.421,76.906,8.425,76.893,8.433,76.88,8.443,76.87,8.455,76.863,8.468,76.858,8.482,76.857,8.496,76.858,8.509,76.863,8.521,76.87,8.531,76.88,8.539,76.893,8.543,76.906]},
        {z:"red",p:[20.776,70.921,20.774,70.936,20.77,70.95,20.762,70.963,20.752,70.974,20.74,70.982,20.727,70.987,20.713,70.988,20.699,70.987,20.686,70.982,20.674,70.974,20.664,70.963,20.656,70.95,20.652,70.936,20.65,70.921,20.652,70.906,20.656,70.892,20.664,70.879,20.674,70.869,20.686,70.861,20.699,70.856,20.713,70.854,20.727,70.856,20.74,70.861,20.752,70.869,20.762,70.879,20.77,70.892,20.774,70.906]},
        {z:"red",p:[15.425,75.085,15.423,75.099,15.418,75.113,15.411,75.126,15.401,75.136,15.389,75.144,15.376,75.148,15.362,75.15,15.348,75.148,15.334,75.144,15.322,75.136,15.313,75.126,15.305,75.113,15.3,75.099,15.299,75.085,15.3,75.07,15.305,75.057,15.313,75.044,15.322,75.034,15.334,75.026,15.348,75.021,15.362,75.02,15.376,75.021,15.389,75.026,15.401,75.034,15.411,75.044,15.418,75.057,15.423,75.07]},
        {z:"red",p:[25.766,91.979,25.765,91.994,25.76,92.009,25.753,92.022,25.743,92.033,25.731,92.042,25.718,92.047,25.704,92.048,25.69,92.047,25.676,92.042,25.664,92.033,25.654,92.022,25.647,92.009,25.642,91.994,25.641,91.979,25.642,91.963,25.647,91.948,25.654,91.935,25.664,91.924,25.676,91.916,25.69,91.911,25.704,91.909,25.718,91.911,25.731,91.916,25.743,91.924,25.753,91.935,25.76,91.948,25.765,91.963]},
        {z:"red",p:[26.169,91.586,26.167,91.601,26.163,91.616,26.155,91.63,26.145,91.641,26.133,91.649,26.12,91.654,26.106,91.656,26.092,91.654,26.079,91.649,26.067,91.641,26.057,91.63,26.049,91.616,26.045,91.601,26.043,91.586,26.045,91.57,26.049,91.556,26.057,91.542,26.067,91.531,26.079,91.523,26.092,91.518,26.106,91.516,26.12,91.518,26.133,91.523,26.145,91.531,26.155,91.542,26.163,91.556,26.167,91.57]},
        {z:"red",p:[25.947,93.771,25.945,93.787,25.941,93.801,25.933,93.815,25.923,93.826,25.911,93.834,25.898,93.839,25.884,93.841,25.87,93.839,25.857,93.834,25.845,93.826,25.835,93.815,25.827,93.801,25.823,93.787,25.821,93.771,25.823,93.756,25.827,93.741,25.835,93.728,25.845,93.716,25.857,93.708,25.87,93.703,25.884,93.701,25.898,93.703,25.911,93.708,25.923,93.716,25.933,93.728,25.941,93.741,25.945,93.756]},
        {z:"red",p:[26.772,92.785,26.77,92.8,26.766,92.815,26.758,92.829,26.748,92.84,26.736,92.848,26.723,92.853,26.709,92.855,26.695,92.853,26.682,92.848,26.67,92.84,26.66,92.829,26.652,92.815,26.648,92.8,26.646,92.785,26.648,92.769,26.652,92.754,26.66,92.741,26.67,92.73,26.682,92.721,26.695,92.716,26.709,92.714,26.723,92.716,26.736,92.721,26.748,92.73,26.758,92.741,26.766,92.754,26.77,92.769]},
        {z:"red",p:[26.803,83.45,26.801,83.465,26.796,83.48,26.789,83.494,26.779,83.505,26.767,83.513,26.754,83.518,26.74,83.52,26.726,83.518,26.712,83.513,26.7,83.505,26.691,83.494,26.683,83.48,26.678,83.465,26.677,83.45,26.678,83.434,26.683,83.419,26.691,83.406,26.7,83.395,26.712,83.386,26.726,83.381,26.74,83.379,26.754,83.381,26.767,83.386,26.779,83.395,26.789,83.406,26.796,83.419,26.801,83.434]},
        {z:"red",p:[32.228,76.263,32.226,76.28,32.222,76.296,32.214,76.31,32.204,76.321,32.192,76.33,32.179,76.336,32.165,76.338,32.151,76.336,32.138,76.33,32.126,76.321,32.116,76.31,32.108,76.296,32.104,76.28,32.102,76.263,32.104,76.247,32.108,76.231,32.116,76.217,32.126,76.205,32.138,76.196,32.151,76.191,32.165,76.189,32.179,76.191,32.192,76.196,32.204,76.205,32.214,76.217,32.222,76.231,32.226,76.247]},
        {z:"red",p:[19.246,77.317,19.245,77.332,19.24,77.346,19.232,77.358,19.223,77.369,19.211,77.377,19.197,77.382,19.183,77.383,19.169,77.382,19.156,77.377,19.144,77.369,19.134,77.358,19.127,77.346,19.122,77.332,19.12,77.317,19.122,77.302,19.127,77.288,19.134,77.275,19.144,77.265,19.156,77.257,19.169,77.252,19.183,77.25,19.197,77.252,19.211,77.257,19.223,77.265,19.232,77.275,19.24,77.288,19.245,77.302]},
        {z:"red",p:[31.145,77.068,31.143,77.084,31.138,77.1,31.131,77.114,31.121,77.125,31.109,77.134,31.096,77.14,31.082,77.141,31.068,77.14,31.055,77.134,31.043,77.125,31.033,77.114,31.025,77.1,31.02,77.084,31.019,77.068,31.02,77.052,31.025,77.036,31.033,77.022,31.043,77.011,31.055,77.002,31.068,76.996,31.082,76.995,31.096,76.996,31.109,77.002,31.121,77.011,31.131,77.022,31.138,77.036,31.143,77.052]},
        {z:"red",p:[12.293,76.656,12.291,76.67,12.287,76.684,12.279,76.696,12.269,76.706,12.257,76.714,12.244,76.719,12.23,76.72,12.216,76.719,12.203,76.714,12.191,76.706,12.181,76.696,12.173,76.684,12.169,76.67,12.167,76.656,12.169,76.642,12.173,76.628,12.181,76.616,12.191,76.606,12.203,76.598,12.216,76.593,12.23,76.591,12.244,76.593,12.257,76.598,12.269,76.606,12.279,76.616,12.287,76.628,12.291,76.642]},
        {z:"red",p:[28.129,95.336,28.127,95.351,28.123,95.367,28.115,95.38,28.105,95.391,28.093,95.4,28.08,95.405,28.066,95.407,28.052,95.405,28.039,95.4,28.027,95.391,28.017,95.38,28.009,95.367,28.005,95.351,28.003,95.336,28.005,95.32,28.009,95.305,28.017,95.291,28.027,95.28,28.039,95.271,28.052,95.266,28.066,95.264,28.08,95.266,28.093,95.271,28.105,95.28,28.115,95.291,28.123,95.305,28.127,95.32]},
        {z:"red",p:[17.076,73.328,17.075,73.342,17.07,73.356,17.063,73.369,17.053,73.379,17.041,73.387,17.028,73.392,17.014,73.394,17.0,73.392,16.986,73.387,16.974,73.379,16.964,73.369,16.957,73.356,16.952,73.342,16.951,73.328,16.952,73.313,16.957,73.299,16.964,73.287,16.974,73.276,16.986,73.269,17.0,73.264,17.014,73.262,17.028,73.264,17.041,73.269,17.053,73.276,17.063,73.287,17.07,73.299,17.075,73.313]},
        {z:"red",p:[23.685,87.243,23.684,87.258,23.679,87.273,23.672,87.286,23.662,87.297,23.65,87.305,23.636,87.31,23.622,87.312,23.609,87.31,23.595,87.305,23.583,87.297,23.573,87.286,23.566,87.273,23.561,87.258,23.56,87.243,23.561,87.228,23.566,87.213,23.573,87.2,23.583,87.189,23.595,87.181,23.609,87.176,23.622,87.174,23.636,87.176,23.65,87.181,23.662,87.189,23.672,87.2,23.679,87.213,23.684,87.228]},
        {z:"red",p:[14.212,77.791,14.211,77.806,14.206,77.819,14.198,77.832,14.189,77.842,14.177,77.85,14.163,77.854,14.149,77.856,14.135,77.854,14.122,77.85,14.11,77.842,14.1,77.832,14.093,77.819,14.088,77.806,14.086,77.791,14.088,77.777,14.093,77.763,14.1,77.751,14.11,77.74,14.122,77.733,14.135,77.728,14.149,77.726,14.163,77.728,14.177,77.733,14.189,77.74,14.198,77.751,14.206,77.763,14.211,77.777]},
        {z:"red",p:[17.294,78.43,17.293,78.445,17.288,78.458,17.28,78.471,17.271,78.481,17.259,78.489,17.245,78.494,17.231,78.496,17.217,78.494,17.204,78.489,17.192,78.481,17.182,78.471,17.175,78.458,17.17,78.445,17.168,78.43,17.17,78.415,17.175,78.401,17.182,78.389,17.192,78.378,17.204,78.371,17.217,78.366,17.231,78.364,17.245,78.366,17.259,78.371,17.271,78.378,17.28,78.389,17.288,78.401,17.293,78.415]},
        {z:"red",p:[28.004,96.134,28.003,96.15,27.998,96.165,27.99,96.179,27.98,96.19,27.968,96.199,27.955,96.204,27.941,96.206,27.927,96.204,27.914,96.199,27.902,96.19,27.892,96.179,27.885,96.165,27.88,96.15,27.878,96.134,27.88,96.119,27.885,96.104,27.892,96.09,27.902,96.079,27.914,96.07,27.927,96.065,27.941,96.063,27.955,96.065,27.968,96.07,27.98,96.079,27.99,96.09,27.998,96.104,28.003,96.119]},
        {z:"red",p:[31.497,75.759,31.495,75.775,31.49,75.791,31.483,75.805,31.473,75.816,31.461,75.825,31.448,75.831,31.434,75.832,31.42,75.831,31.407,75.825,31.395,75.816,31.385,75.805,31.377,75.791,31.372,75.775,31.371,75.759,31.372,75.742,31.377,75.727,31.385,75.713,31.395,75.701,31.407,75.692,31.42,75.687,31.434,75.685,31.448,75.687,31.461,75.692,31.473,75.701,31.483,75.713,31.49,75.727,31.495,75.742]},
        {z:"red",p:[15.238,76.635,15.236,76.649,15.232,76.663,15.224,76.676,15.214,76.686,15.202,76.694,15.189,76.698,15.175,76.7,15.161,76.698,15.148,76.694,15.136,76.686,15.126,76.676,15.118,76.663,15.114,76.649,15.112,76.635,15.114,76.62,15.118,76.607,15.126,76.594,15.136,76.584,15.148,76.576,15.161,76.571,15.175,76.57,15.189,76.571,15.202,76.576,15.214,76.584,15.224,76.594,15.232,76.607,15.236,76.62]},
        {z:"red",p:[19.751,74.379,19.75,74.394,19.745,74.408,19.738,74.421,19.728,74.431,19.716,74.439,19.703,74.444,19.689,74.446,19.675,74.444,19.661,74.439,19.649,74.431,19.639,74.421,19.632,74.408,19.627,74.394,19.626,74.379,19.627,74.364,19.632,74.35,19.639,74.337,19.649,74.327,19.661,74.319,19.675,74.314,19.689,74.312,19.703,74.314,19.716,74.319,19.728,74.327,19.738,74.337,19.745,74.35,19.75,74.364]},
        {z:"red",p:[18.943,82.552,18.941,82.567,18.937,82.581,18.929,82.593,18.919,82.604,18.907,82.612,18.894,82.617,18.88,82.618,18.866,82.617,18.853,82.612,18.841,82.604,18.831,82.593,18.823,82.581,18.819,82.567,18.817,82.552,18.819,82.537,18.823,82.523,18.831,82.511,18.841,82.5,18.853,82.492,18.866,82.487,18.88,82.486,18.894,82.487,18.907,82.492,18.919,82.5,18.929,82.511,18.937,82.523,18.941,82.537]},
        {z:"red",p:[26.664,74.814,26.663,74.83,26.658,74.845,26.651,74.858,26.641,74.869,26.629,74.878,26.615,74.883,26.601,74.884,26.587,74.883,26.574,74.878,26.562,74.869,26.552,74.858,26.545,74.845,26.54,74.83,26.539,74.814,26.54,74.798,26.545,74.784,26.552,74.77,26.562,74.759,26.574,74.751,26.587,74.746,26.601,74.744,26.615,74.746,26.629,74.751,26.641,74.759,26.651,74.77,26.658,74.784,26.663,74.798]},
        {z:"red",p:[11.981,75.547,11.98,75.562,11.975,75.575,11.968,75.587,11.958,75.597,11.946,75.605,11.933,75.61,11.919,75.611,11.905,75.61,11.891,75.605,11.879,75.597,11.869,75.587,11.862,75.575,11.857,75.562,11.856,75.547,11.857,75.533,11.862,75.519,11.869,75.507,11.879,75.497,11.891,75.489,11.905,75.485,11.919,75.483,11.933,75.485,11.946,75.489,11.958,75.497,11.968,75.507,11.975,75.519,11.98,75.533]}
    ]

    function _cdaPath(p) {
        var out = []
        for (var i = 0; i < p.length; i += 2) {
            out.push(QtPositioning.coordinate(p[i], p[i + 1]))
        }
        return out
    }

    MapItemView {
        model: _root._cdaAirspaceOn ? _root._cdaZones : []
        delegate: MapPolygon {
            color:          modelData.z === "red" ? "#66ff0000" : (modelData.z === "yellow" ? "#80ffd400" : "#2600c853")
            border.color:   modelData.z === "red" ? "#ff0000"   : (modelData.z === "yellow" ? "#e6b800"   : "#00a040")
            border.width:   modelData.z === "green" ? 1 : 2
            path:           _root._cdaPath(modelData.p)
        }
    }

    QGCButton {
        id:                 cdaAirspaceButton
        text:               _root._cdaAirspaceOn ? qsTr("Hide Airspace") : qsTr("Airspace")
        visible:            !pipMode
        anchors.right:          parent.right
        anchors.rightMargin:    24
        anchors.bottom:         parent.bottom
        anchors.bottomMargin:   24
        onClicked:          _root._cdaAirspaceOn = !_root._cdaAirspaceOn
    }

    MapScale {
        id:                 mapScale
        anchors.margins:    _toolsMargin
        anchors.left:       parent.left
        anchors.top:        parent.top
        mapControl:         _root
        buttonsOnLeft:      false
        visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && mapControl.pipState.state === mapControl.pipState.windowState

        property real centerInset: visible ? parent.height - y : 0
    }

}
