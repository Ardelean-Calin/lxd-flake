{
  lib,
  hwdata,
  pkg-config,
  lxc,
  buildGo122Module,
  fetchFromGitHub,
  acl,
  libcap,
  dqlite,
  raft-canonical,
  sqlite,
  udev,
  installShellFiles,
  nixosTests,
  nix-update-script,
  pkgs,
}:
buildGo122Module rec {
  pname = "lxd-unwrapped-lts";
  # major/minor are used in updateScript to pin to LTS
  version = "5.21.1";

  src = fetchFromGitHub {
    owner = "canonical";
    repo = "lxd";
    rev = "refs/tags/lxd-${version}";
    hash = "sha256-6php6dThpyADOY+2PZ38WxK2jPKd61D0OCwTKjAhAUg=";
  };

  vendorHash = "sha256-iGW2FQjuqANadFuMHa+2VXiUgoU0VFBJYUyh0pMIdWY=";

  postPatch = ''
    substituteInPlace shared/usbid/load.go \
      --replace "/usr/share/misc/usb.ids" "${hwdata}/share/hwdata/usb.ids"
  '';

  excludedPackages = [
    "test"
    "lxd/db/generate"
    "lxd-agent"
    "lxd-migrate"
  ];

  nativeBuildInputs = [
    installShellFiles
    pkg-config
  ];
  buildInputs = [
    lxc
    acl
    libcap
    dqlite.dev
    raft-canonical.dev
    sqlite
    udev.dev
    pkgs.iproute2
  ];

  ldflags = [
    "-s"
    "-w"
  ];
  tags = ["libsqlite3"];

  patches = [
    ./patches/0001-feat-virtiofsd-added-support-for-extended-attributes.patch
  ];

  preBuild = ''
    # required for go-dqlite. See: https://github.com/canonical/lxd/pull/8939
    export CGO_LDFLAGS_ALLOW="(-Wl,-wrap,pthread_create)|(-Wl,-z,now)"
  '';

  # build static binaries: https://github.com/canonical/lxd/blob/6fd175c45e65cd475d198db69d6528e489733e19/Makefile#L43-L51
  postBuild = ''
    make lxd-agent lxd-migrate
  '';

  checkFlags = let
    skippedTests = [
      "TestValidateConfig"
      "TestConvertNetworkConfig"
      "TestConvertStorageConfig"
      "TestSnapshotCommon"
      "TestContainerTestSuite"
    ];
  in ["-skip=^${builtins.concatStringsSep "$|^" skippedTests}$"];

  postInstall = ''
    installShellCompletion --bash --name lxd ./scripts/bash/lxd-client
  '';

  passthru = {
    tests.lxd = nixosTests.lxd;
    tests.lxd-to-incus = nixosTests.incus.lxd-to-incus;

    updateScript = nix-update-script {
      extraArgs = [
        "--version-regex"
        "lxd-(5.21.*)"
      ];
    };
  };

  meta = with lib; {
    description = "Daemon based on liblxc offering a REST API to manage containers";
    homepage = "https://ubuntu.com/lxd";
    changelog = "https://github.com/canonical/lxd/releases/tag/lxd-${version}";
    license = with licenses; [
      asl20
      agpl3Plus
    ];
    maintainers = teams.lxc.members;
    platforms = platforms.linux;
  };
}
