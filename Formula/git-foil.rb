class GitFoil < Formula
  desc "Quantum-resistant Git encryption with 6-layer defense"
  homepage "https://github.com/code-of-kai/git-foil"
  url "https://github.com/code-of-kai/git-foil/archive/refs/tags/v0.8.4.tar.gz"
  sha256 "eed8150b7c439d85a98c2c7b6ec394cda79356cbea526972b51d3dd67cd3aad7"
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

    # Compile everything (including Rust NIFs)
    system "mix", "compile"

    # Install the entire application to libexec
    libexec.install Dir["*"]

    # Create wrapper script that invokes the application
    (bin/"git-foil").write <<~EOS
      #!/bin/bash
      cd "#{libexec}" && MIX_ENV=prod mix run -e "GitFoil.CLI.main(System.argv())" -- "$@"
    EOS
  end

  test do
    system "#{bin}/git-foil", "--version"
  end
end
