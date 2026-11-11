#pragma once
#include <QString>
#include <cstdint>

// Verifies the bytes of dataPath against the detached Ed25519 signature in sigPath
// (64 raw bytes, or 128 hex chars). Fail-closed: any problem = false.
namespace CDAFirmwareVerifier {
bool verifyFile(const QString& dataPath, const QString& sigPath, const uint8_t publicKey[32], QString& reason);
bool publicKeyConfigured(const uint8_t publicKey[32]);
}
