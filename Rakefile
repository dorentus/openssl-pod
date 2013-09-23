require 'rake'
require 'tmpdir'
require 'digest'

OPENSSL_VERSION='1.0.1e'
OPENSSL_TARBALL="http://www.openssl.org/source/openssl-#{OPENSSL_VERSION}.tar.gz"
OPENSSL_SHA256='f74f15e8c8ff11aa3d5bb5f276d202ec18d7246e95f961db76054199c69c1ae3'

CC="xcrun clang"
iOS_DEVICE_SDK="`xcrun --sdk iphoneos --show-sdk-path`"
iOS_SIMULATOR_SDK="`xcrun --sdk iphonesimulator --show-sdk-path`"

def inreplace paths, before=nil, after=nil
  Array(paths).each do |path|
    f = File.open(path, 'rb')
    s = f.read

    if before.nil? && after.nil?
      s.extend(StringInreplaceExtension)
      yield s
    else
      after = after.to_s if Symbol === after
      sub = s.gsub!(before, after)
      if sub.nil?
        puts "inreplace in '#{path}' failed"
        puts "Expected replacement of '#{before}' with '#{after}'"
      end
    end

    f.reopen(path, 'wb').write(s)
    f.close
  end
end

def build arch, cc, sdk
  install_dir = File.join(Dir.pwd, arch)

  FileUtils.rm_rf "openssl-#{OPENSSL_VERSION}"
  system "tar zxf openssl-#{OPENSSL_VERSION}.tar.gz"

  target="BSD-generic32"
  ios_version_min="4.0"

  if arch == 'arm64'
    target="BSD-generic64"
    ios_version_min="7.0.0"
  elsif arch == "x86_64"
    target="BSD-x86_64 no-asm"
    ios_version_min="7.0.0"
  end

  Dir.chdir("openssl-#{OPENSSL_VERSION}") do
    system "./Configure #{target} --openssldir='#{install_dir}'"

    inreplace "crypto/ui/ui_openssl.c", "static volatile sig_atomic_t intr_signal", "static volatile int intr_signal"
    inreplace "Makefile", "CC= gcc", "CC= #{cc} -arch #{arch} -miphoneos-version-min=#{ios_version_min}"
    inreplace "Makefile", "CFLAG= ", "CFLAG= -isysroot #{sdk} "
    inreplace "Makefile", "-O3", "-Ofast"

    system "make"
    system "make install"
  end

  install_dir
end

def lipo libname, srcdir_array, dest_dir
  command_array = ['lipo']

  srcdir_array.each do |srcdir|
    command_array.push File.join(srcdir, 'lib', libname)
  end

  command_array.push '-create -output'
  command_array.push File.join(dest_dir, 'lib', libname)

  system command_array.join(" ")
end

task :default => [:build]

desc "Remove all"
task :clean do
  FileUtils.rm_rf "dist"
end

desc "Build all"
task :build => [:clean] do
  dist_dir = File.join(Dir.pwd, "dist")
  lib_dir = File.join(dist_dir, "lib")

  Dir.mkdir dist_dir
  Dir.mkdir lib_dir

  Dir.mktmpdir do |dir|
    Dir.chdir(dir) do
      system "wget -c #{OPENSSL_TARBALL}"

      abort unless Digest::SHA256.hexdigest(File.read("openssl-#{OPENSSL_VERSION}.tar.gz")) == OPENSSL_SHA256

      build_array = [
        build("armv7", CC, iOS_DEVICE_SDK),
        build("armv7s", CC, iOS_DEVICE_SDK),
        build("arm64", CC, iOS_DEVICE_SDK),
        build("i386", CC, iOS_SIMULATOR_SDK),
        build("x86_64", CC, iOS_SIMULATOR_SDK)
      ]

      FileUtils.cp_r File.join(build_array[0], 'include'), dist_dir

      lipo 'libcrypto.a', build_array, dist_dir
      lipo 'libssl.a', build_array, dist_dir
    end
  end

end
