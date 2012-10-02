require 'formula'

class Ocropus < Formula
  homepage ''
  url 'https://code.google.com/p/ocropus.ocroold/', :using => :hg, :tag => "'ocropus-0.4'"
  version '0.4'

  depends_on :x11
  depends_on 'python'
  depends_on 'iulib'
  depends_on 'gsl'

  fails_with :clang

  def install
    system "#{HOMEBREW_PREFIX}/bin/python genAM.py > Makefile.am"
    system "autoreconf"
    ENV['CFLAGS']  += " -I/usr/X11/include -I#{HOMEBREW_PREFIX}/include"
    ENV['LDFLAGS'] += " -L/usr/X11/lib -L#{HOMEBREW_PREFIX}/lib"
    system "./configure", "--without-tesseract", "--with-iulib=#{HOMEBREW_PREFIX}",
      "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make install"
  end

  def test
    system "true"
  end

  def patches
    DATA
  end
end

__END__
diff -r 6f0bad470631 SConstruct
--- a/SConstruct  Sun May 31 20:40:47 2009 +0200
+++ b/SConstruct  Tue Aug 21 12:03:29 2012 -0500
@@ -79,7 +79,15 @@
 opts.Add(BoolOption('test', "Run some tests after the build", "no"))
 opts.Add(BoolOption('style', 'Check style', "no"))
 
-env = Environment(options=opts)
+if sys.platform=='darwin':
+    extra_args = dict(
+        CPPPATH=['/usr/X11/include', '/usr/local/include'],
+        LIBPATH=['/usr/X11/lib', '/usr/local/lib'],
+    )
+else:
+    extra_args = {}
+    
+env = Environment(options=opts, **extra_args)
 env.Append(CXXFLAGS=["-g","-fPIC"])
 env.Append(CXXFLAGS=env["opt"])
 env.Append(CXXFLAGS=env["warn"])
diff -r 6f0bad470631 configure.ac
--- a/configure.ac  Sun May 31 20:40:47 2009 +0200
+++ b/configure.ac  Tue Aug 21 12:03:29 2012 -0500
@@ -125,7 +125,7 @@
 
 # --- libtesseract (ahouls become optional) ---
 if test x$notesseract != x1; then
-    AC_CHECK_LIB(tesseract_full, err_exit,, AC_MSG_ERROR([Could not find tesseract! Choose --without-tesseract if you do not want to use it.]))
+    AC_CHECK_LIB(tesseract, err_exit,, AC_MSG_ERROR([Could not find tesseract! Choose --without-tesseract if you do not want to use it.]))
 fi
 
 # --- openFST (optional) ---
diff -r 6f0bad470631 ocr-utils/components.cc
--- a/ocr-utils/components.cc Sun May 31 20:40:47 2009 +0200
+++ b/ocr-utils/components.cc Tue Aug 21 12:03:29 2012 -0500
@@ -27,6 +27,13 @@
 #include "iulib/iulib.h"
 #include "components.h"
 
+#ifdef __APPLE__ && __MACH__
+// this issue was reported in 2009 and still not fixed...
+// http://code.google.com/p/ocropus/issues/detail?id=158
+#include <crt_externs.h>
+#define environ (*_NSGetEnviron())
+#endif
+
 using namespace colib;
 
 namespace {
diff -r 6f0bad470631 ocr-voronoi/read_image.cc
--- a/ocr-voronoi/read_image.cc Sun May 31 20:40:47 2009 +0200
+++ b/ocr-voronoi/read_image.cc Tue Aug 21 12:03:29 2012 -0500
@@ -14,6 +14,11 @@
 #include "read_image.h"
 #include "function.h"
 
+#ifdef __APPLE__ && __MACH__
+#define TIFFHeader TIFFHeaderClassic
+#define TIFF_VERSION TIFF_VERSION_CLASSIC
+#endif
+
 namespace voronoi{
     /* reading image whose format is either sunraster or tiff */
     void read_image(char *fname, ImageData *imgd)
