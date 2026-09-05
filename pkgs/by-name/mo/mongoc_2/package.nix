{
  fetchFromGitHub,
  mongoc,
}:

mongoc.overrideAttrs (_: {
  version = "2.5.2";

  src = fetchFromGitHub {
    owner = "mongodb";
    repo = "mongo-c-driver";
    tag = "2.5.2";
    hash = "sha256-XiQP8SnSRVAY3Oao3gOvDqsUse2f0PuMT+KktKyeBfw=";
  };
})
