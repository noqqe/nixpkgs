{ stdenv
, python3Packages
, fetchFromGitHub
, systemd
, xrandr
, makeWrapper }:

let
  python = python3Packages.python;
  wrapPython = python3Packages.wrapPython;
  version = "1.4";
in
  stdenv.mkDerivation {
    name = "autorandr-${version}";

    buildInputs = [ python ];
    nativeBuildInputs = [ makeWrapper ];

    installPhase = ''
      runHook preInstall
      make install TARGETS='autorandr' PREFIX=$out

      make install TARGETS='bash_completion' DESTDIR=$out

      make install TARGETS='autostart_config' PREFIX=$out DESTDIR=$out

      ${if systemd != null then ''
        make install TARGETS='systemd udev' PREFIX=$out DESTDIR=$out \
          SYSTEMD_UNIT_DIR=/lib/systemd/system \
          UDEV_RULES_DIR=/etc/udev/rules.d
        substituteInPlace $out/etc/udev/rules.d/40-monitor-hotplug.rules \
          --replace /bin/systemctl "${systemd}/bin/systemctl"
      '' else ''
        make install TARGETS='pmutils' DESTDIR=$out \
          PM_SLEEPHOOKS_DIR=/lib/pm-utils/sleep.d
        make install TARGETS='udev' PREFIX=$out DESTDIR=$out \
          UDEV_RULES_DIR=/etc/udev/rules.d
      ''}

      runHook postInstall
    '';

    postFixup = ''
      wrapProgram $out/bin/autorandr \
        --prefix PATH : ${xrandr}/bin
    '';

    src = fetchFromGitHub {
      owner = "phillipberndt";
      repo = "autorandr";
      rev = "${version}";
      sha256 = "08i71r221ilc8k1c59w89g3iq5m7zwhnjjzapavhqxlr8y9dcpf5";
    };

    meta = {
      homepage = https://github.com/phillipberndt/autorandr/;
      description = "Auto-detect the connect display hardware and load the appropiate X11 setup using xrandr";
      license = stdenv.lib.licenses.gpl3Plus;
      maintainers = [ stdenv.lib.maintainers.coroa ];
      platforms = stdenv.lib.platforms.unix;
    };
  }
