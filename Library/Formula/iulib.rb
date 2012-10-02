require 'formula'

class Iulib < Formula
  homepage ''
  url 'https://code.google.com/p/iulib/', :using => :hg, :tag => "ocropus-0.4"
  version '0.4'

  depends_on :x11
  depends_on 'python'
  depends_on 'imagemagick'
  depends_on 'scons'
  depends_on 'swig'
  depends_on 'libtiff'
  depends_on 'jpeg'
  depends_on 'sdl'
  depends_on 'sdl_gfx'
  depends_on 'sdl_image'

  def install
    system "scons prefix=#{prefix} install"
  end

  def patches
    DATA
  end
end

__END__
diff -r 757ebf56464a SConstruct
--- a/SConstruct  Sun May 31 21:15:08 2009 +0200
+++ b/SConstruct  Fri Aug 17 10:52:17 2012 -0500
@@ -41,7 +41,15 @@
 opts.Add('prefix', 'The installation root for iulib', "/usr/local")
 
 ### globals
-env = Environment(options=opts, CXXFLAGS="${opt} ${warn}")
+if sys.platform=='darwin':
+    extra_args = dict(
+        CPPPATH=['/usr/X11/include', '/usr/local/include'],
+        LIBPATH=['/usr/X11/lib', '/usr/local/lib'],
+    )
+else:
+    extra_args = {}
+    
+env = Environment(options=opts, CXXFLAGS=["${opt}", "${warn}"], **extra_args)
 Help(opts.GenerateHelpText(env))
 conf = Configure(env)
 if "-DUNSAFE" in env["opt"]:
@@ -60,7 +68,7 @@
     missing += " libpng12-dev"
 if not conf.CheckLibWithHeader('jpeg', 'jconfig.h', 'C', 'jpeg_std_error();', 1):
     missing += " libjpeg62-dev"    
-if not conf.CheckLibWithHeader('tiff', 'tiff.h', 'C', 'inflate();', 1):
+if not conf.CheckLibWithHeader('tiff', 'tiff.h', 'C', 'TIFFOpen();', 1):
    missing += " libtiff4-dev"
 
 if missing:
