@echo off
@REM This batch file depends on the output from make_keys.bat

@REM Verify that the required programs are installed
set eflag=0
for %%A in (openssl.exe, ssh-keygen.exe) do (call :check "%%~$PATH:A" %%A)

if %eflag% == 1 exit /B 1

@REM We need the private key created by make_keys.bat
if not exist test1.pem (
	echo Missing required file: test1.pem
	echo Error: Run make_keys.bat first
	exit /B 1
)

REM If test8.pem exists, try to delete it
if exist test8.pem del test8.pem

if exist test8.pem (
	echo Error: Cannot delete test8.pem. This file must be removed first.
	exit /B 1
)

REM Convert the private key from PKCS #1 to PKCS #8
openssl pkcs8 -topk8 -inform pem -in test1.pem -outform PEM -nocrypt -out test8.pem

REM Create an RSA Public Key from the Private Key (requires OpenSSL version 1.0.0 or newer)
openssl rsa -in test1.pem -pubout -out test8.pub

REM ssh-keygen will complain and fail if the permissions for test8.pem are not set to read-only

REM Disable inheritance on test8.pem
icacls test8.pem /inheritance:d > icacls.out

REM Delete "NT AUTHORITY\Authenticated Users" from having any rights
icacls test8.pem /remove "NT AUTHORITY\Authenticated Users" >> icacls.out

REM Delete "BUILTIN\Users" from having any rights
icacls test8.pem /remove "BUILTIN\Users" >> icacls.out

REM Grant Read-Only rights to me
icacls test8.pem /GRANT:R "%USERNAME%:(R)" >> icacls.out

REM Create an OpenSSH Public Key from the Private Key
ssh-keygen -y -f test8.pem > test8.pub.openssh

REM Create an SSH-2 Public Key from the OpenSSH Public Key
ssh-keygen -e -f test8.pub.openssh > test8.pub.ssh2

echo(
echo Created the following files
for %%A in (test8.*) do @echo %%~nA%%~xA

exit /B 0

:check
if [%1] == [""] (
	set eflag=1
	echo Error: Missing required program: %2
	goto :eof
)
