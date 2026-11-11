#include "CDAFirmwareVerifier.h"
#include "CDASecurityConfig.h"

#include <QFile>
#include <QByteArray>

extern "C" {
#include "monocypher/monocypher-ed25519.h"
}

namespace CDAFirmwareVerifier {

bool publicKeyConfigured(const uint8_t publicKey[32])
{
    // An all-zero key is a small-order point: never trust it.
    for (int i = 0; i < 32; ++i) {
        if (publicKey[i] != 0) return true;
    }
    return false;
}

bool verifyFile(const QString& dataPath, const QString& sigPath, const uint8_t publicKey[32], QString& reason)
{
    if (!publicKeyConfigured(publicKey)) {
        reason = QObject::tr("CDA firmware public key is not configured in this GCS build.");
        return false;
    }

    QFile fw(dataPath);
    if (!fw.open(QIODevice::ReadOnly)) {
        reason = QObject::tr("Cannot open firmware file.");
        return false;
    }
    if (fw.size() <= 0 || fw.size() > CDASecurityConfig::kMaxFirmwareBytes) {
        reason = QObject::tr("Firmware file size is invalid.");
        return false;
    }
    const QByteArray data = fw.readAll();
    fw.close();

    QFile sigFile(sigPath);
    if (!sigFile.open(QIODevice::ReadOnly)) {
        reason = QObject::tr("Not CDA-approved: signature file not found (%1).").arg(sigPath);
        return false;
    }
    QByteArray sig = sigFile.readAll().trimmed();
    sigFile.close();
    if (sig.size() == 128) {
        sig = QByteArray::fromHex(sig);
    }
    if (sig.size() != 64) {
        reason = QObject::tr("Signature file is malformed.");
        return false;
    }

    const int rc = crypto_ed25519_check(reinterpret_cast<const uint8_t*>(sig.constData()),
                                        publicKey,
                                        reinterpret_cast<const uint8_t*>(data.constData()),
                                        static_cast<size_t>(data.size()));
    if (rc != 0) {
        reason = QObject::tr("Firmware signature is INVALID. The file was modified or not signed by CDA.");
        return false;
    }
    reason.clear();
    return true;
}

} // namespace
