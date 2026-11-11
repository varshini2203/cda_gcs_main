#pragma once
// ============================================================================
//  CDA GCS security configuration  --  EDIT THIS FILE FOR YOUR DEPLOYMENT
// ============================================================================
#include <QStringList>
#include <cstdint>

namespace CDASecurityConfig {

// ---- Admin password (PBKDF2-HMAC-SHA256) -----------------------------------
// DEMO password is:  CDA-Change-Me-123   --> CHANGE IT before any release:
//   python tools/cda_admin_hash.py     then paste the two lines it prints.
static const int  kPbkdf2Iterations = 200000;   // must match tools/cda_admin_hash.py
static const char kAdminSaltHex[] = "20a60239711c71773388f8fb1a75c926";
static const char kAdminHashHex[] = "1a1731b06f52ba1c1e301ab5756a7b96eed85194dea4d9f2b8c61fdc94706923";

static const int kAdminSessionTimeoutSec = 600;  // admin auto-logout (10 min)
static const int kMaxFailedLogins        = 5;    // then lock out login
static const int kLockoutSec             = 120;

// ---- Firmware lock ---------------------------------------------------------
// Ed25519 PUBLIC key of CDA. All zeros = "not configured" -> ALL firmware rejected.
//   python tools/cda_sign_firmware.py keygen cda_fw_private.pem   -> paste array here
static const uint8_t kFirmwarePublicKey[32] = {
    0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0
};
// true  = ONLY admin may flash firmware at all (user mode = firmware flashing blocked)
static const bool kFirmwareRequiresAdmin = true;
// true  = Admin may flash unsigned firmware (after logging in)
// false = even Admin can only flash CDA-signed firmware
static const bool kAllowAdminUnsignedFirmware = true;
static const qint64 kMaxFirmwareBytes = 64LL * 1024 * 1024;

// ---- Parameter lock --------------------------------------------------------
// true = user mode cannot change ANY parameter (view only). false = only the list below.
static const bool kLockAllParameters = false;
// Wildcards: * and ?   (case-sensitive).  User mode: view only.  Admin: editable.
inline QStringList protectedParameterPatterns()
{
    return {
        // PX4 -- speed / limits
        "MPC_XY_VEL_MAX", "MPC_Z_VEL_MAX_UP", "MPC_Z_VEL_MAX_DN", "MPC_XY_CRUISE",
        "MPC_TILTMAX_AIR", "MPC_THR_MAX",
        // PX4 -- battery / failsafe
        "BAT?_CAPACITY", "BAT?_N_CELLS", "BAT?_V_EMPTY", "BAT?_V_CHARGED",
        "BAT_LOW_THR", "BAT_CRIT_THR", "BAT_EMERGEN_THR", "COM_LOW_BAT_ACT",
        "NAV_RCL_ACT", "NAV_DLL_ACT", "COM_RC_LOSS_T", "COM_DL_LOSS_T",
        // PX4 -- geofence / identity
        "GF_*", "SYS_AUTOSTART", "SYS_AUTOCONFIG", "MAV_SYS_ID",
        // ArduPilot (remove if you only use PX4)
        "WPNAV_SPEED", "WPNAV_SPEED_UP", "WPNAV_SPEED_DN", "FENCE_*",
        "BATT_CAPACITY", "BATT_LOW_*", "BATT_CRT_*", "BATT_FS_*", "FS_*",
    };
}

} // namespace CDASecurityConfig
