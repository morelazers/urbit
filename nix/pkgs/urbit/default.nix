{ lib, stdenv, coreutils, pkgconfig                      # build/env
, cacert, ca-bundle, ivory                               # codegen
, curlUrbit, ent, gmp, h2o, libsigsegv, libuv, lmdb      # libs
, murmur3, openssl, openssl-static-osx, softfloat3       #
, urcrypt, zlib, zlib-static-osx                         #
, enableStatic           ? stdenv.hostPlatform.isStatic  # opts
, enableDebug            ? false
, verePace               ? ""
, doCheck                ? true
, enableParallelBuilding ? true
, dontStrip              ? true }:

let

  src = lib.cleanSource ../../../pkg/urbit;

  version = builtins.readFile "${src}/version";

  # See https://github.com/urbit/urbit/issues/5561
  oFlags =
    if stdenv.isDarwin
    then (if enableDebug then [ "-O0" "-g" ] else [ "-O3" ])
    else [ (if enableDebug then "-O0" else "-O3") "-g" ];

in stdenv.mkDerivation {
  inherit src version;

  pname = "urbit" + lib.optionalString enableDebug "-debug"
    + lib.optionalString enableStatic "-static";

  nativeBuildInputs = [ pkgconfig ];

  buildInputs = [
    cacert
    ca-bundle
    curlUrbit
    ent
    gmp
    h2o
    ivory.header
    libsigsegv
    libuv
    lmdb
    murmur3
    (if stdenv.isDarwin && enableStatic then openssl-static-osx else openssl)
    softfloat3
    urcrypt
    (if stdenv.isDarwin && enableStatic then zlib-static-osx else zlib)
  ];

  # Ensure any `/usr/bin/env bash` shebang is patched.
  postPatch = ''
    patchShebangs ./configure
  '';

  checkTarget = "test";

  installPhase = ''
    mkdir -p $out/bin
    cp ./build/urbit $out/bin/urbit
  '';

  dontDisableStatic = enableStatic;

  configureFlags = if enableStatic
    then [ "--disable-shared" "--enable-static" ]
    else [];

  CFLAGS = oFlags ++ lib.optionals (!enableDebug) [ "-Werror" ];

  MEMORY_DEBUG = enableDebug;
  CPU_DEBUG = enableDebug;
  EVENT_TIME_DEBUG = false;
  VERE_PACE = if enableStatic then verePace else "";

  # See https://github.com/NixOS/nixpkgs/issues/18995
  hardeningDisable = lib.optionals enableDebug [ "all" ];

  inherit enableParallelBuilding doCheck dontStrip;

  meta = {
    debug = enableDebug;
    arguments = lib.optionals enableDebug [ "-g" ];
  };
}
