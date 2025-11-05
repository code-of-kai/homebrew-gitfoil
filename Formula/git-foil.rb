class GitFoil < Formula
  desc "Quantum-resistant Git encryption CLI"
  homepage "https://github.com/code-of-kai/git-foil"
  url "https://github.com/code-of-kai/git-foil/archive/refs/tags/v1.0.8.tar.gz"
  sha256 "4203662637b5426e048f52dc39d85036499a745ce346f8e6dbf1753d671c379e"
  license "MIT"
  head "https://github.com/code-of-kai/git-foil.git", branch: "master"

  depends_on "elixir"
  depends_on "erlang"
  depends_on "rust" => :build

  def install
    ENV["MIX_ENV"] = "prod"

    system "mix", "local.hex", "--force"
    system "mix", "local.rebar", "--force"
    system "mix", "deps.get"
    system "mix", "compile"
    system "mix", "compile", "lib/git_foil/native/rustler_loader.ex"

    libexec.install "priv"

    system "mix", "escript.build"
    libexec.install "git-foil"

    (bin/"git-foil").write <<~EOS
      #!/bin/bash
      set -euo pipefail
      export GIT_FOIL_NIF_DIR="#{libexec}/priv/native"
      exec "#{libexec}/git-foil" "$@"
    EOS
    (bin/"git-foil").chmod 0o755
  end

  test do
    assert_match "GitFoil version", shell_output("#{bin}/git-foil version")
  end
end
