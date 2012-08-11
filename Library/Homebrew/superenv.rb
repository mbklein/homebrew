# superenv creates a build environment for formula, but it's better and awesome

raise "superenv say no!" if ENV.respond_to? 'j1' or MacOS::Xcode.version < "4.3"

class << ENV
  def reset
    %w{CC CXX LD CPP OBJC CFLAGS CXXFLAGS OBJCFLAGS OBJCXXFLAGS LDFLAGS CPPFLAGS 
      MAKEFLAGS SDKROOT CMAKE_PREFIX_PATH CMAKE_FRAMEWORK_PATH MAKE MAKEJOBS}.
      each{ |x| delete(x) }
    delete('CDPATH') # avoid make issues that depend on changing directories
    delete('GREP_OPTIONS') # can break CMake
    delete('CLICOLOR_FORCE') # autotools doesn't like this
  end

  def setup_build_environment
    reset

    ENV['CC'] = determine_cc
    ENV['CXX'] = determine_cxx
    ENV['LD'] = 'ld'
    ENV['CPP'] = 'cpp'
    ENV['HOMEBREW_PREFIX'] = HOMEBREW_PREFIX.to_s
    ENV['MAKEFLAGS'] ||= "-j#{Hardware.processor_count}"
    ENV['PATH'] = determine_path
    ENV['CMAKE_PREFIX_PATH'] = HOMEBREW_PREFIX.to_s

    macosxsdk(MacOS.version)

    if MacOS.mountain_lion?
      # Fix issue with sed barfing on unicode characters on Mountain Lion
      delete('LC_ALL')
      ENV['LC_CTYPE'] = "C"

      # Mountain Lion no longer ships some .pcs; ensure we pick up our versions
      prepend 'PKG_CONFIG_PATH', "#{HOMEBREW_REPOSITORY}/Library/Homebrew/pkgconfig", ':'
    end
  end

  def macosxsdk version
    #TODO simplify
    delete('MACOSX_DEPLOYMENT_TARGET')
    delete('CMAKE_FRAMEWORK_PATH')

    if version == MacOS.version
      ENV['MACOSX_DEPLOYMENT_TARGET'] = version.to_s
    end
    if not MacOS::CLT.installed?
      remove 'CMAKE_PREFIX_PATH', ENV['SDKROOT']
      sdkroot = MacOS.sdk_path(version.to_s)
      ENV['SDKROOT'] = sdkroot
      prepend 'CMAKE_PREFIX_PATH', "#{sdkroot}/usr", ':'
      ENV['CMAKE_FRAMEWORK_PATH'] = "#{sdkroot}/System/Library/Frameworks"
    else
      ENV['CMAKE_PREFIX_PATH'] = HOMEBREW_PREFIX.to_s
    end
  end

  def universal_binary
    ENV['HOMEBREW_UNIVERSAL'] = "1"
  end

  # Snow Leopard defines an NCURSES value the opposite of most distros
  # See: http://bugs.python.org/issue6848
  def ncurses_define
    append 'CPPFLAGS', "-DNCURSES_OPAQUE=0"
  end

### DEPRECATED or BROKEN
  def m64; end
  def m32; end
  def gcc_4_0_1; end
  def fast; end
  def O4; end
  def O3; end
  def O2; end
  def Os; end
  def Og; end
  def O1; end
  def libxml2; end
  def x11; end
  def minimal_optimization; end
  def no_optimization; end
  def enable_warnings; end
  def fortran; end

### DEPRECATE THESE
  def compiler
    case ENV['CC']
      when "llvm-gcc" then :llvm
      when "gcc" then :gcc
    else
      :clang
    end
  end
  def deparallelize
    delete('MAKEFLAGS')
  end
  alias_method :j1, :deparallelize
  def gcc
    ENV['CC'] = "gcc"
    ENV['CXX'] = "g++"
  end
  def llvm
    ENV['CC'] = "llvm-gcc"
    ENV['CXX'] = "llvm-g++"
  end
  def clang
    ENV['CC'] = "clang"
    ENV['CXX'] = "clang++"
  end
  def cc_flag_vars
    %w{CFLAGS CXXFLAGS OBJCFLAGS OBJCXXFLAGS}
  end
  def append_to_cflags newflags
    append(cc_flag_vars, newflags)
  end
  def remove_from_cflags f
    remove cc_flag_vars, f
  end
  def append key, value, separator = ' '
    value = value.to_s
    [*key].each do |key|
      unless self[key].to_s.empty?
        self[key] = self[key] + separator + value.to_s
      else
        self[key] = value.to_s
      end
    end
  end
  def prepend key, value, separator = ' '
    [*key].each do |key|
      unless self[key].to_s.empty?
        self[key] = value.to_s + separator + self[key]
      else
        self[key] = value.to_s
      end
    end
  end
  def remove key, value
    [*key].each do |key|
      next unless self[key]
      self[key] = self[key].sub(value, '')
      delete(key) if self[key].to_s.empty?
    end if value
  end
  def make_jobs
    ENV['MAKEFLAGS'] =~ /-j(\d)+/
    [$1.to_i, 1].max
  end
  def remove_cc_etc
    keys = %w{CC CXX LD CPP CFLAGS CXXFLAGS OBJCFLAGS OBJCXXFLAGS LDFLAGS CPPFLAGS}
    removed = Hash[*keys.map{ |key| [key, self[key]] }.flatten]
    keys.each do |key|
      delete(key)
    end
    removed
  end
  def cc; ENV['CC'] end
  def cxx; ENV['CXX'] end
  def cflags; ENV['CFLAGS'] end
  def cxxflags; ENV['CXXFLAGS'] end
  def cppflags; ENV['CPPFLAGS'] end
  def ldflags; ENV['LDFLAGS'] end



  private

  def determine_path
    paths = ORIGINAL_PATHS.dup
    paths.delete(HOMEBREW_PREFIX/:bin)
    paths.unshift("#{HOMEBREW_PREFIX}/bin")
    if not MacOS::CLT.installed?
      xcpath=`xcode-select -print-path`.chomp #TODO future-proofed
      paths.unshift("#{xcpath}/usr/bin")
      paths.unshift("#{xcpath}/Toolchains/XcodeDefault.xctoolchain/usr/bin")
    end
    paths.unshift("#{HOMEBREW_PREFIX}/Library/bin")
    paths.join(":")
  end

  def determine_cc
    if ARGV.include? '--use-gcc'
      "gcc"
    elsif ARGV.include? '--use-llvm'
      "llvm-gcc"
    elsif ARGV.include? '--use-clang'
      "clang"
    elsif ENV['HOMEBREW_USE_CLANG']
      opoo %{HOMEBREW_USE_CLANG is deprecated, use HOMEBREW_CC="clang" instead}
      "clang"
    elsif ENV['HOMEBREW_USE_LLVM']
      opoo %{HOMEBREW_USE_LLVM is deprecated, use HOMEBREW_CC="llvm" instead}
      "llvm-gcc"
    elsif ENV['HOMEBREW_USE_GCC']
      opoo %{HOMEBREW_USE_GCC is deprecated, use HOMEBREW_CC="gcc" instead}
      "gcc"
    elsif ENV['HOMEBREW_CC']
      if %w{clang gcc llvm}.include? ENV['HOMEBREW_CC']
        ENV['HOMEBREW_CC']
      else
        opoo "Invalid value for HOMEBREW_CC: #{ENV['HOMEBREW_CC']}"
        "cc"
      end
    else
      "cc"
    end
  end

  def determine_cxx
    case ENV['CC']
      when "clang" then "clang++"
      when "llvm-gcc" then "llvm-g++"
      when "gcc" then "gcc++"
    else
      "c++"
    end
  end

end
