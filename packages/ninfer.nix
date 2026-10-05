{ lib, gcc14Stdenv, fetchFromGitHub, cmake, ninja, pkg-config, cudaPackages_13_1
, ffmpeg, curl, makeWrapper }:
let
  cuda = cudaPackages_13_1;
in gcc14Stdenv.mkDerivation {
  pname = "ninfer";
  version = "0-unstable-2026-10-05";
  src = fetchFromGitHub {
    owner = "Neroued";
    repo = "ninfer";
    rev = "68c54356fd490ab329bd1475d48957f886bb7dd1";
    sha256 = "1ycfaxrsc4ci3niajzxbc61yjcd0riy6z1h53vvspa8j9c0r0mp7";
  };
  nativeBuildInputs = [ cmake ninja pkg-config cuda.cuda_nvcc makeWrapper ];
  buildInputs = [ cuda.cuda_cudart cuda.cccl cuda.cuda_nvtx cuda.libcublas ffmpeg curl ];
  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_CUDA_ARCHITECTURES=120a"
    "-DCMAKE_CUDA_HOST_COMPILER=${gcc14Stdenv.cc}/bin/g++"
    "-DNINFER_BUILD_APPS=ON"
    "-DBUILD_TESTING=OFF"
    "-DNINFER_BUILD_BENCHMARKS=OFF"
  ];
  enableParallelBuilding = true;
  # Upstream has no install target. All frontend resources are in the artifact.
  installPhase = ''
    runHook preInstall
    install -Dm755 apps/ninfer "$out/bin/ninfer"
    install -Dm755 apps/ninfer-serve "$out/bin/ninfer-serve"
    install -Dm755 apps/ninfer-perplexity "$out/bin/ninfer-perplexity"
    install -Dm644 ../LICENSE "$out/share/licenses/ninfer/LICENSE"
    for program in "$out"/bin/*; do
      wrapProgram "$program" --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
    done
    runHook postInstall
  '';
  meta = {
    description = "Pinned single-RTX-5090 inference engine for v3 NInfer artifacts";
    homepage = "https://github.com/Neroued/ninfer";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ninfer";
  };
}
