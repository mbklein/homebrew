require 'formula'

class Iulib < Formula
  homepage ''
  url 'https://code.google.com/p/iulib/', :using => :hg, :tag => "ocropus-0.4.4"
  version '0.4.4'

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
diff -r 629fcf40854d SConstruct
--- a/SConstruct  Wed Mar 24 04:13:37 2010 -0700
+++ b/SConstruct  Thu Aug 16 11:31:17 2012 -0500
@@ -47,7 +47,16 @@
 opts.Add(BoolVariable('test', "Run some tests after the build", "no"))
 # opts.Add(BoolVariable('style', 'Check style', "no"))
 
-env = Environment(options=opts, CXXFLAGS=["${opt}","${warn}"])
+if sys.platform=='darwin':
+    extra_args = dict(
+        CPPPATH=['/usr/X11/include', '/usr/local/include'],
+        LIBPATH=['/usr/X11/lib', '/usr/local/lib'],
+    )
+else:
+    extra_args = {}
+    
+env = Environment(options=opts, CXXFLAGS=["${opt}", "${warn}"], **extra_args)
+
 Help(opts.GenerateHelpText(env))
 
 conf = Configure(env)
@@ -61,7 +70,7 @@
 
 assert conf.CheckLibWithHeader('png', 'png.h', 'C', 'png_byte;', 1),"please install: libpng12-dev"
 assert conf.CheckLibWithHeader('jpeg', 'jconfig.h', 'C', 'jpeg_std_error();', 1),"please install: libjpeg62-dev"    
-assert conf.CheckLibWithHeader('tiff', 'tiff.h', 'C', 'inflate();', 1), "please install: libtiff4-dev"
+assert conf.CheckLibWithHeader('tiff', 'tiff.h', 'C', 'TIFFOpen();', 1), "please install: libtiff4-dev"
 
 ### check for optional parts
 
diff -r 629fcf40854d components/components.cc
--- a/components/components.cc  Wed Mar 24 04:13:37 2010 -0700
+++ b/components/components.cc  Thu Aug 16 11:31:17 2012 -0500
@@ -27,6 +27,13 @@
 #include "iulib.h"
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
