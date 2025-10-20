class GitFoil < Formula
  desc "Quantum-resistant Git encryption with 6-layer defense"
  homepage "https://github.com/code-of-kai/git-foil"
  url "https://github.com/code-of-kai/git-foil/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "2f4c49b6342e92b996ac5e4ef1f931e21e17b0f8dcf07373b305e758d595072e"
  license "MIT"
  head "https://github.com/code-of-kai/git-foil.git", branch: "master"

  depends_on "elixir"
  depends_on "rust" => :build

  def install
    # Set Mix environment to production
    ENV["MIX_ENV"] = "prod"

    # Get dependencies
    system "mix", "local.hex", "--force"
    system "mix", "local.rebar", "--force"
    system "mix", "deps.get"

    # Compile everything (including Rust NIFs via Rustler)
    system "mix", "compile"

    # Build a self-contained escript with all NIFs embedded
    system "mix", "escript.build"

    # Install the compiled escript binary directly
    bin.install "git-foil"
  end

  test do
    system "#{bin}/git-foil", "--version"
  end
end
