{ mkDerivation, aeson, base, bytestring, containers, errors, extra, http-client,  http-types, network, stdenv, streamly, warp , parsec , attoparsec, mtl, fetchgit
}:
mkDerivation {
 pname = "stream-web";
 version = "0.0.1";
 src = fetchgit {
   url = "https://github.com/juspay/stream-web.git";
   rev = "2ee659a34dfc0b196d23b8cf60814df41d603d21";
   sha256 = "10nlxb5lxnjg93252841zgpx3dpkp5wzy2mhspf4mq45k8cdkyab";
   fetchSubmodules = true;
 };
 isLibrary = true;
 isExecutable = true;
 libraryHaskellDepends = [
   aeson attoparsec base bytestring mtl network parsec streamly
 ];
 executableHaskellDepends = [
   aeson base bytestring containers errors extra http-client http-types network streamly warp parsec attoparsec
 ];
 description = "Web Server";
 license = "BSD3";
 hydraPlatforms = stdenv.lib.platforms.none;
}