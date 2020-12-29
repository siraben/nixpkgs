{ stdenv, lib, fetchFromGitHub, python3, poetry, asn1crypto
, bcrypt, beautifulsoup4, certifi, cffi, chardet, click
, cryptography, dnspython, flask, future, gevent, greenlet, idna
, impacket, itsdangerous, jinja2, ldap3 }:

python3.pkgs.buildPythonApplication rec {
  pname = "crackmapexec";
  version = "5.1.1dev";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "byt3bl33d3r";
    repo = "CrackMapExec";
    rev = "v${version}";
    sha256 = "18ly2w0vyq3zg6nzjcrs0ssg6l2zv3vxmrbnpfp2z2p0x8jgyxym";
  };

  nativeBuildInputs = [ poetry ];

  propagatedBuildInputs = [
    asn1crypto
    bcrypt
    beautifulsoup4
    certifi
    cffi
    chardet
    click
    cryptography
    dnspython
    flask
    future
    gevent
    greenlet
    idna
    impacket
    itsdangerous
    jinja2
    ldap3
  ];

  # buildInputs = [ python3 ];

  meta = with stdenv.lib; {
    description = "";
    homepage = "https://github.com//crackmapexec";
    license = licenses.bsd2;
    maintainers = with maintainers; [ siraben ];
    platforms = platforms.unix;
  };
}
