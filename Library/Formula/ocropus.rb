require 'formula'

class Ocropus < Formula
  homepage ''
  url 'https://code.google.com/p/ocropus.ocropy/', :using => :hg, :tag => "ocropus-0.4.4"
  version '0.4.4'

  depends_on :x11
  depends_on 'python'
  depends_on 'iulib'

  def install
    system "#{HOMEBREW_PREFIX}/bin/python ./setup.py install"
  end

  def test
    system "true"
  end
end
