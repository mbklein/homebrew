require 'formula'

class QtSbtlEmbedder < Formula
  homepage ''
  url 'http://opencast.jira.com/source/browse/~raw,r=9190/MH/trunk/docs/scripts/3rd_party/repository/qt_sbtl_embedder-0.4.tar.gz'
  sha1 'dbed144020e3b5744d820cb41327d483186c5aff'

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make install" # if this fails, try separate make/make install steps
  end

  def test
    system "#{bin}/qtsbtlembedder --help"
  end
end
