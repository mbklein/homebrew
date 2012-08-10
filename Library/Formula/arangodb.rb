require 'formula'

class Arangodb < Formula
  homepage 'http://www.arangodb.org/'
  url "https://github.com/triAGENS/ArangoDB/zipball/v1.0.beta1"
  sha1 '36b280accbe049c509814f1ab8a28837fb0239c2'

  head "https://github.com/triAGENS/ArangoDB.git"

  depends_on 'libev'
  depends_on 'v8'

  def install
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--disable-relative",
                          "--disable-all-in-one",
                          "--enable-mruby",
                          "--datadir=#{share}",
                          "--localstatedir=#{var}"

    system "make install"

    (var+'arangodb').mkpath
    (var+'log/arangodb').mkpath

    plist_path.write startup_plist
    plist_path.chmod 0644
  end

  def caveats
    tod = "~/Library/LaunchAgents"
    to = "#{tod}/#{plist_name}"
    from = "#{opt_prefix}/#{plist_name}"

    <<-EOS.undent
    Please note that this is a very early version if ArangoDB. There will be
    bugs and the ArangoDB team would really appreciate it if you report them:

      https://github.com/triAGENS/ArangoDB/issues

    If this is your first install, automatically load on login with:
        mkdir -p #{tod}
        ln -s #{from} #{tod}
        launchctl load -w #{to}

    If this is an upgrade and you already have #{plist_name} loaded:
        launchctl unload -w #{to}
        launchctl load -w #{to}

    To start the ArangoDB server manually, run:
        /usr/local/sbin/arangod

    To start the ArangoDB shell, run:
        arangosh
    EOS
  end

  def startup_plist
    return <<-EOS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>KeepAlive</key>
    <true/>
    <key>Label</key>
    <string>#{plist_name}</string>
    <key>ProgramArguments</key>
    <array>
      <string>#{HOMEBREW_PREFIX}/sbin/arangod</string>
      <string>-c</string>
      <string>#{etc}/arangodb/arangod.conf</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>UserName</key>
    <string>#{`whoami`.chomp}</string>
  </dict>
</plist>
    EOS
  end
end
