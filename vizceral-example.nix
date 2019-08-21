{ mkDerivation, aeson, base, bytestring, containers, errors, extra, http-client,  http-types, network, stdenv, streamly, stream-web, mtl, req, basic-prelude
}:
mkDerivation {
  pname = "vizceral-example";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  license = stdenv.lib.licenses.bsd3;
  executableHaskellDepends = [
    aeson base bytestring containers errors extra http-client http-types network streamly stream-web req basic-prelude
  ];
}

