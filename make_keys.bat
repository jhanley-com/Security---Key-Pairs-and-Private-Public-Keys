@echo off
@REM Verify that the required programs are installed
set eflag=0
for %%A in (openssl.exe, ssh-keygen.exe) do (call :check "%%~$PATH:A" %%A)

if %eflag% == 1 exit /B 1

REM If test1.pem exists, try to delete it
if exist test1.pem del test1.pem

if exist test1.pem (
	echo Error: Cannot delete test1.pem. This file must be removed first.
	exit /B 1
)

REM Create an RSA 2048-bit private key
openssl genrsa -out test1.pem 2048

REM Create an RSA Public Key from the Private Key (requires OpenSSL version 1.0.0 or newer)
openssl rsa -in test1.pem -RSAPublicKey_out -out test1.pub

REM ssh-keygen will complain and fail if the permissions for test1.pem are not set to read-only

REM Disable inheritance on test1.pem
icacls test1.pem /inheritance:d > icacls.out

REM Delete "NT AUTHORITY\Authenticated Users" from having any rights
icacls test1.pem /remove "NT AUTHORITY\Authenticated Users" >> icacls.out

REM Delete "BUILTIN\Users" from having any rights
icacls test1.pem /remove "BUILTIN\Users" >> icacls.out

REM Grant Read-Only rights to me
icacls test1.pem /GRANT:R "%USERNAME%:(R)" >> icacls.out

REM Create an OpenSSH Public Key from the Private Key
ssh-keygen -y -f test1.pem > test1.pub.openssh

REM Create an SSH-2 Public Key from the OpenSSH Public Key
ssh-keygen -e -f test1.pub.openssh > test1.pub.ssh2

echo(
echo Created the following files
for %%A in (test1.*) do @echo %%~nA%%~xA

exit /B 0

:check
if [%1] == [""] (
	set eflag=1
	echo Error: Missing required program: %2
	goto :eof
)
