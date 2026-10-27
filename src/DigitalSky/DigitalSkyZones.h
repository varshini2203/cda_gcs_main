#pragma once

#include <QObject>
#include <QVariantList>
#include <QGeoCoordinate>
#include <QNetworkAccessManager>
#include <QTimer>

/// Loads Digital Sky (India) drone zones from a GeoJSON source (URL or local file)
/// and exposes them to QML as map-ready polygons/circles.
///
/// Expected GeoJSON per feature:
///   geometry : Polygon | MultiPolygon | Point (Point needs properties.radius in metres)
///   properties.zone (or .type / .category) : "red" | "yellow" | "green"
///   properties.name (optional)
class DigitalSkyZones : public QObject
{
    Q_OBJECT
public:
    explicit DigitalSkyZones(QObject* parent = nullptr);

    Q_PROPERTY(QString       sourceUrl  READ sourceUrl  WRITE setSourceUrl  NOTIFY sourceUrlChanged)
    Q_PROPERTY(QVariantList  polygons   READ polygons   NOTIFY zonesChanged)   ///< [{path, color, lineColor, zone, name}]
    Q_PROPERTY(QVariantList  circles    READ circles    NOTIFY zonesChanged)   ///< [{center, radius, color, lineColor, zone, name}]
    Q_PROPERTY(QString       status     READ status     NOTIFY statusChanged)
    Q_PROPERTY(int           refreshMinutes READ refreshMinutes WRITE setRefreshMinutes NOTIFY refreshMinutesChanged)

    QString      sourceUrl      () const { return _sourceUrl; }
    QVariantList polygons       () const { return _polygons; }
    QVariantList circles        () const { return _circles; }
    QString      status         () const { return _status; }
    int          refreshMinutes () const { return _refreshMinutes; }

    void setSourceUrl       (const QString& url);
    void setRefreshMinutes  (int minutes);

    Q_INVOKABLE void reload ();
    /// Returns "red", "yellow", "green" or "" (not inside any loaded zone). Red wins over yellow.
    Q_INVOKABLE QString zoneAt(const QGeoCoordinate& coord) const;

signals:
    void sourceUrlChanged       ();
    void zonesChanged           ();
    void statusChanged          ();
    void refreshMinutesChanged  ();

private slots:
    void _replyFinished         ();

private:
    void _parse                 (const QByteArray& json);
    void _setStatus             (const QString& s);
    static bool _inRing         (const QGeoCoordinate& c, const QVariantList& ring);

    QNetworkAccessManager   _nam;
    QTimer                  _timer;
    QString                 _sourceUrl;
    QString                 _status = QStringLiteral("No source set");
    QVariantList            _polygons;
    QVariantList            _circles;
    int                     _refreshMinutes = 30;
};
