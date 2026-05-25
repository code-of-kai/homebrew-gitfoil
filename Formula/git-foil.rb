class GitFoil < Formula
  desc "Quantum-resistant Git encryption CLI"
  homepage "https://github.com/code-of-kai/git-foil"
  url "https://github.com/code-of-kai/git-foil/archive/refs/tags/v1.0.10.tar.gz"
  sha256 "ce77e8396d1b5ca0ef2dc7bc001c5c4d60c302e583382b0d4d92138c9c216e6a"
  license "MIT"

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
      # For `clean` and `smudge` (git filter subcommands), retries on SIGBUS
      # (exit 138 = 128 + signal 10) which can occur under concurrent
      # invocations during BEAM NIF dlopen on macOS. The race lives in dyld's
      # mmap + unified-buffer-cache interaction: many short-lived processes
      # dlopening the same .so files in parallel can hit a page-translation
      # fault in dyld4::Loader::mapSegments -> MachOFile::isMachO. Triggered
      # most often by `git stash push -u` invoking the clean filter on many
      # files in rapid succession.
      #
      # Retry is safe: clean/smudge are deterministic over their stdin, and
      # the SIGBUS occurs during BEAM startup before stdin is read. Stdin is
      # buffered to a private tempfile (mktemp default mode 0600) so each
      # retry sees the same input.

      set -uo pipefail
      export GIT_FOIL_NIF_DIR="#{libexec}/priv/native"
      BIN="#{libexec}/git-foil"

      case "${1:-}" in
          clean|smudge)
              ;;
          *)
              exec "$BIN" "$@"
              ;;
      esac

      stdin_file=$(mktemp -t gitfoil-stdin.XXXXXX)
      trap 'rm -f "$stdin_file"' EXIT INT TERM
      cat > "$stdin_file"

      rc=0
      for attempt in 1 2 3; do
          "$BIN" "$@" < "$stdin_file"
          rc=$?
          if [ "$rc" -ne 138 ]; then
              break
          fi
          sleep 0.1
      done

      exit "$rc"
    EOS
    (bin/"git-foil").chmod 0o755
  end

  test do
    assert_match "GitFoil version", shell_output("#{bin}/git-foil version")
  end
end
