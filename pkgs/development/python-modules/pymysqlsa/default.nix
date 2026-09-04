{
  lib,
  buildPythonPackage,
  fetchPypi,
  pymysql,
  sqlalchemy,
}:

buildPythonPackage (finalAttrs: {
  pname = "pymysql-sa";
  version = "1.0";
  format = "setuptools";

  src = fetchPypi {
    inherit (finalAttrs) version;
    pname = "pymysql_sa";
    sha256 = "a2676bce514a29b2d6ab418812259b0c2f7564150ac53455420a20bd7935314a";
  };

  propagatedBuildInputs = [
    pymysql
    sqlalchemy
  ];

  meta = {
    description = "PyMySQL dialect for SQL Alchemy";
    homepage = "https://pypi.org/project/pymysql_sa/";
    license = lib.licenses.mit;
  };
})
