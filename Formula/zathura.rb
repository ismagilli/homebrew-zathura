class Zathura < Formula
  desc "PDF viewer"
  homepage "https://pwmt.org/projects/zathura/"
  url "https://github.com/pwmt/zathura/archive/refs/tags/0.5.11.tar.gz"
  sha256 "32540747a6fe3c4189ec9d5de46a455862c88e11e969adb5bc0ce8f9b25b52d4"
  license "Zlib"
  head "https://github.com/pwmt/zathura.git", branch: "develop"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "sphinx-doc" => :build
  depends_on "adwaita-icon-theme"
  depends_on "desktop-file-utils"
  depends_on "gettext"
  depends_on "girara"
  depends_on "glib"
  depends_on "intltool"
  depends_on "libmagic"
  depends_on "synctex" => :optional
  on_macos do
    depends_on "gtk+3"
    depends_on "gtk-mac-integration"
  end

  patch do
    url "file://#{__dir__}/../patches/mac-integration.diff"
    sha256 "36aee71cd105f31817abdb96dbb9c4a9183c1f4d4a0d7dc3a3e8a31c6ebe3a2f"
  end

  def install
    # Set Homebrew prefix
    ENV["PREFIX"] = prefix
    # Add the pkgconfig for girara to the PKG_CONFIG_PATH
    # TODO: Find out why it is not added correctly for Linux
    ENV["PKG_CONFIG_PATH"] = "#{ENV["PKG_CONFIG_PATH"]}:#{Formula["girara"].prefix}/lib/x86_64-linux-gnu/pkgconfig"

    mkdir "build" do
      system "meson", *std_meson_args, ".."
      system "ninja"
      system "ninja", "install"
    end
  end

  def caveats
    <<~EOS
      To view files you have to install plugins. Currently zathura has 5 official plugins:
        zathura-cb             Comic Book Archive (.cbr, .cbz, .cbt, etc.)
        zathura-djvu           DjVu (.djvu, .djv)
        zathura-pdf-mupdf      PDF via MuPDF backend (.pdf)
        zathura-pdf-poppler    PDF via Poppler backend (.pdf)
        zathura-ps             PostScript (.ps, .eps)

      Zathrua is, by default, only a command line tool. To use it as an app with a .app file, run:
        (curl https://raw.githubusercontent.com/homebrew-zathura/homebrew-zathura/refs/heads/master/convert-into-app.sh | sh)
      If this does not work, try downloading the script from the repo and running it manually.
      Note: after installing new plugins you need to rerun command above.
    EOS
  end

  test do
    system "true" # TODO
  end
end
