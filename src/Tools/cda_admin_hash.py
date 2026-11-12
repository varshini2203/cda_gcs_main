import hashlib, os, getpass
ITER = 200000
pw = getpass.getpass("New admin password: ")
if pw != getpass.getpass("Repeat: "):
    raise SystemExit("Mismatch")
salt = os.urandom(16)
h = hashlib.pbkdf2_hmac("sha256", pw.encode("utf-8"), salt, ITER, 32)
print('static const char* kAdminSaltHex = "%s";' % salt.hex())
print('static const char* kAdminHashHex = "%s";' % h.hex())
