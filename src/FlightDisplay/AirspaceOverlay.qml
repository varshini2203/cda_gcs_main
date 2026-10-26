/****************************************************************************
 * CDA Airspace overlay - draws red / yellow / green zones from a GeoJSON file
 * Qt5 / QGC 4.x style imports (matches FlyViewMap.qml in your source)
 ****************************************************************************/

import QtQuick          2.11
import QtLocation       5.3
import QtPositioning    5.3

MapItemView {
    id: overlay

    property bool showZones:    false
    property var  allZones:     []
    property string sourceUrl:  Qt.resolvedUrl("airspace_zones.geojson")

    // empty model when hidden -> nothing is drawn
    model: showZones ? allZones : []

    function zoneColor(t) {
        if (t === "red")    return "#66ff0000"
        if (t === "yellow") return "#66ffd400"
        return "#3300c853"
    }
    function zoneBorder(t) {
        if (t === "red")    return "#ff0000"
        if (t === "yellow") return "#e6b800"
        return "#00a040"
    }

    delegate: MapPolygon {
        color:          overlay.zoneColor(modelData.zone)
        border.color:   overlay.zoneBorder(modelData.zone)
        border.width:   2
        path:           modelData.path
    }

    function loadFile(url) {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) {
                return
            }
            var gj
            try {
                gj = JSON.parse(xhr.responseText)
            } catch (e) {
                console.log("Airspace: invalid GeoJSON", e)
                return
            }
            var out = []
            for (var i = 0; i < gj.features.length; i++) {
                var f = gj.features[i]
                var polys = (f.geometry.type === "Polygon") ? [f.geometry.coordinates] : f.geometry.coordinates
                for (var p = 0; p < polys.length; p++) {
                    var ring = polys[p][0]          // outer ring only
                    var pts = []
                    for (var k = 0; k < ring.length; k++) {
                        pts.push(QtPositioning.coordinate(ring[k][1], ring[k][0]))   // lat, lon
                    }
                    out.push({ zone: f.properties.zone, path: pts })
                }
            }
            allZones = out
        }
        xhr.send()
    }

    Component.onCompleted: loadFile(sourceUrl)
}
