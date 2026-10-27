#include "DigitalSkyZones.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QFile>
#include <QUrl>
#include <QColor>

static QString _zoneOf(const QJsonObject& props)
{
    for (const char* key : {"zone", "type", "category", "zoneType"}) {
        const QString v = props.value(QLatin1String(key)).toString().toLower();
        if (v.contains("red"))    return QStringLiteral("red");
        if (v.contains("yellow")) return QStringLiteral("yellow");
        if (v.contains("green"))  return QStringLiteral("green");
    }
    return QStringLiteral("red");   // unknown -> treat as restricted (safe default)
}

static void _colors(const QString& zone, QColor& fill, QColor& line)
{
    if (zone == "yellow")      { fill = QColor(255, 215, 0, 80);  line = QColor(230, 180, 0); }
    else if (zone == "green")  { fill = QColor(0, 200, 0, 40);    line = QColor(0, 140, 0);   }
    else                       { fill = QColor(230, 40, 40, 90);  line = QColor(200, 0, 0);   }
}

static QVariantList _ringToPath(const QJsonArray& ring)
{
    QVariantList path;
    for (const QJsonValue& v : ring) {
        const QJsonArray p = v.toArray();                       // GeoJSON is [lon, lat]
        if (p.size() >= 2) {
            path.append(QVariant::fromValue(QGeoCoordinate(p[1].toDouble(), p[0].toDouble())));
        }
    }
    return path;
}

DigitalSkyZones::DigitalSkyZones(QObject* parent)
    : QObject(parent)
{
    connect(&_timer, &QTimer::timeout, this, &DigitalSkyZones::reload);
    _timer.setInterval(_refreshMinutes * 60 * 1000);
}

void DigitalSkyZones::setSourceUrl(const QString& url)
{
    if (url == _sourceUrl) return;
    _sourceUrl = url;
    emit sourceUrlChanged();
    reload();
}

void DigitalSkyZones::setRefreshMinutes(int minutes)
{
    _refreshMinutes = qMax(1, minutes);
    _timer.setInterval(_refreshMinutes * 60 * 1000);
    emit refreshMinutesChanged();
}

void DigitalSkyZones::_setStatus(const QString& s)
{
    _status = s;
    emit statusChanged();
}

void DigitalSkyZones::reload()
{
    if (_sourceUrl.isEmpty()) return;

    const QUrl url = QUrl::fromUserInput(_sourceUrl);
    if (url.isLocalFile()) {
        QFile f(url.toLocalFile());
        if (!f.open(QIODevice::ReadOnly)) {
            _setStatus(tr("Cannot open %1").arg(f.fileName()));
            return;
        }
        _parse(f.readAll());
        return;
    }

    _setStatus(tr("Downloading zones..."));
    QNetworkRequest req(url);
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
    QNetworkReply* reply = _nam.get(req);
    connect(reply, &QNetworkReply::finished, this, &DigitalSkyZones::_replyFinished);
    if (!_timer.isActive()) _timer.start();
}

void DigitalSkyZones::_replyFinished()
{
    QNetworkReply* reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) {
        _setStatus(tr("Download failed: %1").arg(reply->errorString()));
        return;                                         // keep last good zones
    }
    _parse(reply->readAll());
}

void DigitalSkyZones::_parse(const QByteArray& json)
{
    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(json, &err);
    if (err.error != QJsonParseError::NoError) {
        _setStatus(tr("Invalid GeoJSON: %1").arg(err.errorString()));
        return;
    }

    QJsonArray features = doc.object().value("features").toArray();
    if (features.isEmpty() && doc.object().value("type").toString() == "Feature") {
        features.append(doc.object());
    }

    QVariantList polys, circles;
    for (const QJsonValue& fv : features) {
        const QJsonObject feat  = fv.toObject();
        const QJsonObject props = feat.value("properties").toObject();
        const QJsonObject geom  = feat.value("geometry").toObject();
        const QString type      = geom.value("type").toString();
        const QJsonArray coords = geom.value("coordinates").toArray();
        const QString zone      = _zoneOf(props);
        const QString name      = props.value("name").toString();
        QColor fill, line;
        _colors(zone, fill, line);

        auto addPoly = [&](const QJsonArray& rings) {
            if (rings.isEmpty()) return;
            QVariantMap m;
            m["path"]      = _ringToPath(rings.first().toArray());   // outer ring only
            m["color"]     = fill;
            m["lineColor"] = line;
            m["zone"]      = zone;
            m["name"]      = name;
            polys.append(m);
        };

        if (type == "Polygon") {
            addPoly(coords);
        } else if (type == "MultiPolygon") {
            for (const QJsonValue& p : coords) addPoly(p.toArray());
        } else if (type == "Point" && coords.size() >= 2) {
            const double radius = props.value("radius").toDouble(props.value("radius_m").toDouble(0));
            if (radius > 0) {
                QVariantMap m;
                m["center"]    = QVariant::fromValue(QGeoCoordinate(coords[1].toDouble(), coords[0].toDouble()));
                m["radius"]    = radius;
                m["color"]     = fill;
                m["lineColor"] = line;
                m["zone"]      = zone;
                m["name"]      = name;
                circles.append(m);
            }
        }
    }

    _polygons = polys;
    _circles  = circles;
    emit zonesChanged();
    _setStatus(tr("%1 polygons, %2 circles loaded").arg(polys.size()).arg(circles.size()));
}

bool DigitalSkyZones::_inRing(const QGeoCoordinate& c, const QVariantList& ring)
{
    bool inside = false;
    for (int i = 0, j = ring.size() - 1; i < ring.size(); j = i++) {
        const QGeoCoordinate a = ring[i].value<QGeoCoordinate>();
        const QGeoCoordinate b = ring[j].value<QGeoCoordinate>();
        if (((a.latitude() > c.latitude()) != (b.latitude() > c.latitude())) &&
            (c.longitude() < (b.longitude() - a.longitude()) * (c.latitude() - a.latitude()) /
                             (b.latitude() - a.latitude()) + a.longitude())) {
            inside = !inside;
        }
    }
    return inside;
}

QString DigitalSkyZones::zoneAt(const QGeoCoordinate& coord) const
{
    int best = 0;                                       // 0 none, 1 green, 2 yellow, 3 red
    auto rank = [](const QString& z) { return z == "red" ? 3 : z == "yellow" ? 2 : 1; };

    for (const QVariant& v : _polygons) {
        const QVariantMap m = v.toMap();
        if (_inRing(coord, m["path"].toList())) best = qMax(best, rank(m["zone"].toString()));
    }
    for (const QVariant& v : _circles) {
        const QVariantMap m = v.toMap();
        if (m["center"].value<QGeoCoordinate>().distanceTo(coord) <= m["radius"].toDouble())
            best = qMax(best, rank(m["zone"].toString()));
    }
    return best == 3 ? "red" : best == 2 ? "yellow" : best == 1 ? "green" : "";
}
