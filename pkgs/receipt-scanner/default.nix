{ lib, bash, coreutils, curl, file, gnugrep, gnused, sane-backends, stdenvNoCC, writeShellApplication }:

let
  scanDocument = writeShellApplication {
    name = "scan-document";
    runtimeInputs = [ bash coreutils curl file gnugrep gnused sane-backends ];
    text = builtins.readFile ./scan-document.bash;
  };
  scanReceipt = writeShellApplication {
    name = "scan-receipt";
    runtimeInputs = [ bash coreutils scanDocument ];
    text = builtins.readFile ./scan-receipt.bash;
  };
in
stdenvNoCC.mkDerivation {
  pname = "receipt-scanner";
  version = "0.1.0";
  dontUnpack = true;
  installPhase = ''
    install -d "$out/bin"
    ln -s ${scanDocument}/bin/scan-document "$out/bin/scan-document"
    ln -s ${scanReceipt}/bin/scan-receipt "$out/bin/scan-receipt"
  '';
  meta = {
    description = "SANE scanner uploader for Paperless document instances";
    license = lib.licenses.mit;
    mainProgram = "scan-document";
  };
}
