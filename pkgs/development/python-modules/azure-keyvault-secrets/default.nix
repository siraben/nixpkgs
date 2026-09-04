{
  lib,
  azure-core,
  buildPythonPackage,
  fetchPypi,
  isodate,
  setuptools,
  typing-extensions,
}:

buildPythonPackage (finalAttrs: {
  pname = "azure-keyvault-secrets";
  version = "4.10.0";
  pyproject = true;

  src = fetchPypi {
    pname = "azure_keyvault_secrets";
    inherit (finalAttrs) version;
    hash = "sha256-Zm+kKJL5zudJVj5VGpDwYENauHiXfJUmUXOoJG1UajY=";
  };

  nativeBuildInputs = [ setuptools ];

  propagatedBuildInputs = [
    azure-core
    isodate
    typing-extensions
  ];

  pythonNamespaces = [ "azure.keyvault" ];

  # Tests require checkout from mono-repo
  doCheck = false;

  meta = {
    description = "Microsoft Azure Key Vault Secrets Client Library for Python";
    homepage = "https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/keyvault/azure-keyvault-secrets";
    changelog = "https://github.com/Azure/azure-sdk-for-python/tree/azure-keyvault-secrets_${finalAttrs.version}/sdk/keyvault/azure-keyvault-secrets";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
})
