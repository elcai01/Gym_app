from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.hmac import HMAC

key = bytes([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16])
data = bytes(range(32))

h = HMAC(key, hashes.SHA256())
h.update(data)
print(h.finalize().hex(" "))
