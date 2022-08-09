class Go < Formula
  desc "Open source programming language to build simple/reliable/efficient software"
  homepage "https://go.dev/"
  url "https://go.dev/dl/go1.19.src.tar.gz"
  mirror "https://fossies.org/linux/misc/go1.19.src.tar.gz"
  sha256 "9419cc70dc5a2523f29a77053cafff658ed21ef3561d9b6b020280ebceab28b9"
  license "BSD-3-Clause"
  head "https://go.googlesource.com/go.git", branch: "master"

  livecheck do
    url "https://go.dev/dl/"
    regex(/href=.*?go[._-]?v?(\d+(?:\.\d+)+)[._-]src\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/jalavosus/formulae"
    rebuild 1
    sha256 monterey:     "a4ebfd41398eec5ca8f4847e4320f2d12a9a742bf7bbc51e28c5b85dfbe93bb1"
    sha256 big_sur:      "ba4f8d4281aea2c8c331974ade2d54309dffe4cc5d5986686f0a12d231845c6f"
    sha256 catalina:     "b224ce9d258c5fb2f9d1f45b8db4c25285a0d84099c06133ab11114749d0c5eb"
    sha256 x86_64_linux: "8d074f0cfdddedb336fbf7466998d207b89a0224f1340382317debdf794007dc"
  end

  # Don't update this unless this version cannot bootstrap the new version.
  resource "gobootstrap" do
    checksums = {
      "darwin-arm64" => "4dac57c00168d30bbd02d95131d5de9ca88e04f2c5a29a404576f30ae9b54810",
      "darwin-amd64" => "6000a9522975d116bf76044967d7e69e04e982e9625330d9a539a8b45395f9a8",
      "linux-arm64"  => "3770f7eb22d05e25fbee8fb53c2a4e897da043eb83c69b9a14f8d98562cd8098",
      "linux-amd64"  => "013a489ebb3e24ef3d915abe5b94c3286c070dfe0818d5bca8108f1d6e8440d2",
    }

    arch = Hardware::CPU.intel? ? :amd64 : Hardware::CPU.arch
    platform = "#{OS.kernel_name.downcase}-#{arch}"
    boot_version = "1.16"

    url "https://storage.googleapis.com/golang/go#{boot_version}.#{platform}.tar.gz"
    version boot_version
    sha256 checksums[platform]
  end

  def install
    (buildpath/"gobootstrap").install resource("gobootstrap")
    ENV["GOROOT_BOOTSTRAP"] = buildpath/"gobootstrap"

    cd "src" do
      ENV["GOROOT_FINAL"] = libexec
      system "./make.bash", "--no-clean"
    end

    (buildpath/"pkg/obj").rmtree
    rm_rf "gobootstrap" # Bootstrap not required beyond compile.
    libexec.install Dir["*"]
    bin.install_symlink Dir[libexec/"bin/go*"]

    system bin/"go", "install", "-race", "std"

    # Remove useless files.
    # Breaks patchelf because folder contains weird debug/test files
    (libexec/"src/debug/elf/testdata").rmtree
    # Binaries built for an incompatible architecture
    (libexec/"src/runtime/pprof/testdata").rmtree
  end

  test do
    (testpath/"hello.go").write <<~EOS
      package main

      import "fmt"

      func main() {
        fmt.Println("Hello World")
      }
    EOS
    # Run go fmt check for no errors then run the program.
    # This is a a bare minimum of go working as it uses fmt, build, and run.
    system bin/"go", "fmt", "hello.go"
    assert_equal "Hello World\n", shell_output("#{bin}/go run hello.go")

    ENV["GOOS"] = "freebsd"
    ENV["GOARCH"] = "amd64"
    system bin/"go", "build", "hello.go"
  end
end
