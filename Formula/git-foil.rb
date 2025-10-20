class GitFoil < Formula
  desc "Quantum-resistant Git encryption with 6-layer defense"
  homepage "https://github.com/code-of-kai/git-foil"
  url "https://github.com/code-of-kai/git-foil/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "7d0f7cc63ff845a6431c311f22930e949942d204508cecf0d2f9e0195178dc7f"
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
