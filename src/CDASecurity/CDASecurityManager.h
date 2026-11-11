#pragma once
#include <QObject>
#include <QString>
#include <QTimer>
#include <QDateTime>

class CDASecurityManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isAdmin   READ isAdmin     NOTIFY adminChanged)
    Q_PROPERTY(bool lockedOut READ isLockedOut NOTIFY adminChanged)

public:
    static CDASecurityManager* instance();

    bool isAdmin() const   { return _admin; }
    bool isLockedOut() const;

    // ---- QML ----
    Q_INVOKABLE bool login(const QString& password);
    Q_INVOKABLE void logout();
    Q_INVOKABLE bool isParameterProtected(const QString& name) const;      // for greying-out UI
    Q_INVOKABLE bool isParameterWriteAllowed(const QString& name) const;   // protected && !admin => false
    Q_INVOKABLE void touchSession();                                       // call on user activity (optional)

    // ---- C++ (hooks) ----
    // remoteFile = what the user picked / the URL; localFile = temp copy QGC will flash
    bool isFirmwareAllowed(const QString& remoteFile, const QString& localFile, QString& reason);
    void notifyParameterBlocked(const QString& name);
    void notifyFirmwareRejected(const QString& reason);

signals:
    void adminChanged();
    void loginResult(bool ok, const QString& message);
    void parameterBlocked(const QString& paramName);
    void firmwareRejected(const QString& reason);

private:
    explicit CDASecurityManager(QObject* parent = nullptr);
    bool _checkPassword(const QString& password) const;

    bool      _admin = false;
    int       _failed = 0;
    QDateTime _lockedUntil;
    QTimer    _sessionTimer;
    QStringList _patterns;
};
