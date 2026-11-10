{
  lib,
  stdenv,
  rustPlatform,
  makeWrapper,
  libsecret,
  wayland,
  libxkbcommon,
  libGL,
  vulkan-loader,
  libx11,
  libxcursor,
  libxi,
  libxrandr,
  # Código fuente de VT Lens (lo aporta flake.nix desde el input `vt-lens-src`).
  src,
}:

let
  cargoToml = (lib.importTOML "${src}/Cargo.toml").package;

  # eframe/winit cargan estas bibliotecas con dlopen en tiempo de ejecución,
  # así que no aparecen en el ELF y hay que añadirlas al rpath a mano.
  runtimeLibs = lib.optionals stdenv.hostPlatform.isLinux [
    wayland
    libxkbcommon
    libGL
    vulkan-loader
    libx11
    libxcursor
    libxi
    libxrandr
  ];
in
rustPlatform.buildRustPackage {
  pname = cargoToml.name;
  version = cargoToml.version;

  inherit src;

  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ makeWrapper ];

  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    install -Dm644 vt-lens.desktop -t $out/share/applications
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    patchelf --add-rpath ${lib.makeLibraryPath runtimeLibs} $out/bin/vt-lens

    # keyring.rs llama a `secret-tool` (libsecret) para guardar la API key.
    wrapProgram $out/bin/vt-lens --prefix PATH : ${lib.makeBinPath [ libsecret ]}
  '';

  meta = {
    description = cargoToml.description;
    homepage = "https://github.com/ValentinTorassa/VT-Lens";
    license = lib.licenses.gpl3Only;
    mainProgram = "vt-lens";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
