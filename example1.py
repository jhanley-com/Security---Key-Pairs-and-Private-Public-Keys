""" Example program to extract the contents of an OpenSSH public key """

import platform
import sys
import base64
import struct

P2 = platform.sys.version_info.major < 3

# test.pem is a key pair created with openssl: openssl genrsa -out test.pem 2048
# test.pub.openssh is a ssh-rsa public key generated with this command:
# ssh-keygen -y -f test.pem > test.pub.openssh

filename = 'test1.pub.openssh'

# Open the file specified by filename
try:
	f = open(filename, 'r')

except Exception as err:
	print("Exception Type:", sys.exc_info()[0])
	print("Exception Value:", sys.exc_info()[1])
	print("Exception Message:", err)
	sys.exit(1)

# Read the contents
try:
	contents = f.read()

	if len(contents) is 0:
		print("Error: Empty file")
		print("File:", filename)
		sys.exit(1)

except Exception as err:
	print("Exception Type:", sys.exc_info()[0])
	print("Exception Value:", sys.exc_info()[1])
	print("Exception Message:", err)
	sys.exit(1)

# Split the contents. The seperator char is the space following "ssh-rsa"
text_parts = contents.split(None)

if len(text_parts) != 2:
	print("Error: unknown file format")
	print("File:", filename)
	sys.exit(1)

# The base64 encoded public key is parts[1]
# keydata is a byte array from the decode base64
keydata = base64.b64decode(contents.split(None)[1])

# The binary data is a length preceeded set of fields that consist of the Modulus and Public
# Exponent
# The first field <4-byte-len><value> which is the string ssh-rsa (not zero terminated)
# The second field

parts = []
while keydata:
	# read the length of the data
	#
	# '>I' means big-endian unsigned int
	# Reference: https://docs.python.org/3/library/struct.html
	#
	dlen = struct.unpack('>I', keydata[:4])[0]

	# read in dlen bytes
	data, keydata = keydata[4:dlen+4], keydata[4+dlen:]

	parts.append(data)

if len(parts) != 3:
	print("Error: unknown file format (binary portion)")
	print("File:", filename)
	sys.exit(1)

if parts[0] != b'ssh-rsa':
	print("Error: unknown file format (missing ssh-rsa)")
	print("File:", filename)
	sys.exit(1)

# extract (unpack) the Public Key Exponent (e_val) and the Modulus (n_val)

if P2 is True:
	e_val = eval('0x' + ''.join(['%02X' % struct.unpack('B', x)[0] for x in parts[1]]))
	n_val = eval('0x' + ''.join(['%02X' % struct.unpack('B', x)[0] for x in parts[2]]))
else:
	e_val = eval('0x' + ''.join(['%02X' % struct.unpack('B', bytes([x]))[0] for x in parts[1]]))
	n_val = eval('0x' + ''.join(['%02X' % struct.unpack('B', bytes([x]))[0] for x in parts[2]]))

print("PUBLIC KEY EXTRACTION:")
print("")
print("Public Exponent:")
print(e_val)
print("")
print("Public Modulus:")
print(hex(n_val))

sys.exit(1)
