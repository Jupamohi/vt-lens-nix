{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
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
  nix-update-script,
}:

let
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
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "vt-lens";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "ValentinTorassa";
    repo = "VT-Lens";
    tag = "v${finalAttrs.version}";
    hash = lib.fakeHash; # TODO: reemplazar con el hash que imprime el primer build
  };

  cargoHash = lib.fakeHash; # TODO: idem

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ makeWrapper ];

  postInstall = lib.optionalString stdenv.hostPlatform.isLinux ''
    install -Dm644 vt-lens.desktop -t $out/share/applications
  '';

  # eframe/winit cargan estas bibliotecas con dlopen en tiempo de ejecución.
  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    patchelf --add-rpath ${lib.makeLibraryPath runtimeLibs} $out/bin/vt-lens

    # keyring.rs llama a `secret-tool` (libsecret) para guardar la API key.
    wrapProgram $out/bin/vt-lens --prefix PATH : ${lib.makeBinPath [ libsecret ]}
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Minimal native lens for understanding local process and network activity";
    homepage = "https://github.com/ValentinTorassa/VT-Lens";
    changelog = "https://github.com/ValentinTorassa/VT-Lens/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.gpl3Only;
    mainProgram = "vt-lens";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = [ ]; # TODO: tu entrada de maintainers (ver guía)
  };
})
