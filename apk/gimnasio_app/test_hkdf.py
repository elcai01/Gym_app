import binascii
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.hkdf import HKDF

token = bytes([1,2,3,4,5,6,7,8,9,10,11,12])
salt = bytes(range(32))

derived = HKDF(
    algorithm=hashes.SHA256(),
    length=64,
    salt=salt,
    info=b"mible-login-info",
    backend=default_backend(),
).derive(token)

print(derived.hex(" "))
