#include "CDASecurityManager.h"
#include "CDASecurityConfig.h"
#include "CDAFirmwareVerifier.h"

#include <QPasswordDigestor>
#include <QCryptographicHash>
#include <QRegularExpression>
#include <QDebug>
#include <QUrl>

CDASecurityManager* CDASecurityManager::instance()
{
    static CDASecurityManager* inst = new CDASecurityManager();
    return inst;
}

CDASecurityManager::CDASecurityManager(QObject* parent)
    : QObject(parent)
    , _patterns(CDASecurityConfig::protectedParameterPatterns())
{
    _sessionTimer.setSingleShot(true);
    _sessionTimer.setInterval(CDASecurityConfig::kAdminSessionTimeoutSec * 1000);
    connect(&_sessionTimer, &QTimer::timeout, this, &CDASecurityManager::logout);
}

bool CDASecurityManager::isLockedOut() const
{
    return _lockedUntil.isValid() && QDateTime::currentDateTimeUtc() < _lockedUntil;
}

bool CDASecurityManager::_checkPassword(const QString& password) const
{
    const QByteArray salt     = QByteArray::fromHex(CDASecurityConfig::kAdminSaltHex);
    const QByteArray expected = QByteArray::fromHex(CDASecurityConfig::kAdminHashHex);
    const QByteArray got = QPasswordDigestor::deriveKeyPbkdf2(
        QCryptographicHash::Sha256, password.toUtf8(), salt,
        CDASecurityConfig::kPbkdf2Iterations, static_cast<quint64>(expected.size()));

    if (got.size() != expected.size() || expected.isEmpty()) return false;
    quint8 diff = 0;                               // constant-time compare
    for (int i = 0; i < expected.size(); ++i) {
        diff |= static_cast<quint8>(got[i]) ^ static_cast<quint8>(expected[i]);
    }
    return diff == 0;
}

bool CDASecurityManager::login(const QString& password)
{
    if (isLockedOut()) {
        const qint64 s = QDateTime::currentDateTimeUtc().secsTo(_lockedUntil);
        emit loginResult(false, tr("Too many attempts. Try again in %1 s.").arg(s));
        return false;
    }
    if (_checkPassword(password)) {
        _failed = 0;
        _lockedUntil = QDateTime();
        _admin = true;
        _sessionTimer.start();
        emit adminChanged();
        emit loginResult(true, tr("Admin mode enabled."));
        return true;
    }
    if (++_failed >= CDASecurityConfig::kMaxFailedLogins) {
        _failed = 0;
        _lockedUntil = QDateTime::currentDateTimeUtc().addSecs(CDASecurityConfig::kLockoutSec);
        emit adminChanged();
        emit loginResult(false, tr("Too many attempts. Login locked for %1 s.").arg(CDASecurityConfig::kLockoutSec));
    } else {
        emit loginResult(false, tr("Wrong password."));
    }
    return false;
}

void CDASecurityManager::logout()
{
    _sessionTimer.stop();
    if (_admin) {
        _admin = false;
        emit adminChanged();
    }
}

void CDASecurityManager::touchSession()
{
    if (_admin) _sessionTimer.start();   // restart idle timer
}

bool CDASecurityManager::isParameterProtected(const QString& name) const
{
    for (const QString& p : _patterns) {
        const QRegularExpression re(QRegularExpression::anchoredPattern(
                                        QRegularExpression::wildcardToRegularExpression(p)));
        if (re.match(name).hasMatch()) return true;
    }
    return false;
}

bool CDASecurityManager::isParameterWriteAllowed(const QString& name) const
{
    if (_admin) return true;
    if (CDASecurityConfig::kLockAllParameters) return false;
    return !isParameterProtected(name);
}

bool CDASecurityManager::isFirmwareAllowed(const QString& remoteFile, const QString& localFile, QString& reason)
{
    if (CDASecurityConfig::kFirmwareRequiresAdmin && !_admin) {
        reason = tr("Firmware update is locked. Admin login is required.");
        return false;
    }

    // Where did the firmware come from?  QGC copies the picked file to a temp file,
    // so the signature must be looked up next to the ORIGINAL file.
    QString origin = remoteFile;
    if (origin.startsWith(QLatin1String("file:"), Qt::CaseInsensitive)) {
        origin = QUrl(origin).toLocalFile();
    }
    const bool isWeb = origin.startsWith(QLatin1String("http:"),  Qt::CaseInsensitive) ||
                       origin.startsWith(QLatin1String("https:"), Qt::CaseInsensitive);

    if (isWeb) {
        reason = tr("Not CDA-approved: firmware downloaded from the internet has no CDA signature.");
    } else if (CDAFirmwareVerifier::verifyFile(localFile, origin + QStringLiteral(".sig"),
                                               CDASecurityConfig::kFirmwarePublicKey, reason)) {
        return true;                                   // CDA-signed
    }

    if (_admin && CDASecurityConfig::kAllowAdminUnsignedFirmware) {
        qWarning() << "CDA SECURITY: admin flashing UNSIGNED firmware:" << remoteFile << reason;
        reason.clear();
        return true;
    }
    return false;
}

void CDASecurityManager::notifyParameterBlocked(const QString& name)
{
    qWarning() << "CDA SECURITY: write to protected parameter blocked:" << name;
    emit parameterBlocked(name);
}

void CDASecurityManager::notifyFirmwareRejected(const QString& reason)
{
    qWarning() << "CDA SECURITY: firmware rejected:" << reason;
    emit firmwareRejected(reason);
}
