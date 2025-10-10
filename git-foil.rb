class GitFoil < Formula
  desc "Quantum-resistant Git encryption with 6-layer defense"
  homepage "https://github.com/code-of-kai/git-foil"
  url "https://github.com/code-of-kai/git-foil/archive/refs/tags/v0.7.0.tar.gz"
  sha256 "" # Will calculate after first brew install attempt
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

    # Compile Rust NIFs
    system "mix", "compile"

    # Build escript
    system "mix", "escript.build"

    # Install the escript binary
    bin.install "git-foil"
  end

  test do
    system "#{bin}/git-foil", "--help"
  end
end
