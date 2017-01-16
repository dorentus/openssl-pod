require 'rake'
require 'tmpdir'
require 'digest'

OPENSSL_VERSION='1.1.0c'
OPENSSL_TARBALL="https://www.openssl.org/source/openssl-#{OPENSSL_VERSION}.tar.gz"
OPENSSL_SHA256='fc436441a2e05752d31b4e46115eb89709a28aef96d4fe786abe92409b2fd6f5'

iOS_DEVICE_SDK=%x[xcrun --sdk iphoneos --show-sdk-path].strip
iOS_SIMULATOR_SDK=%x[xcrun --sdk iphonesimulator --show-sdk-path].strip

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

def build arch, sdk
  install_dir = File.join(Dir.pwd, arch)

  FileUtils.rm_rf "openssl-#{OPENSSL_VERSION}"
  system "tar zxf openssl-#{OPENSSL_VERSION}.tar.gz"

  target="BSD-generic32"
  ios_version_min="7.0.0"

  if arch == 'arm64'
    target="BSD-generic64"
  elsif arch == "x86_64"
    target="BSD-x86_64 no-asm"
  end

  Dir.chdir("openssl-#{OPENSSL_VERSION}") do
    system "./Configure #{target} --openssldir='#{install_dir}'"
    inreplace "Makefile", "CFLAG= ", "CFLAG= -fembed-bitcode -Qunused-arguments -isysroot #{sdk} -arch #{arch} -miphoneos-version-min=#{ios_version_min} "

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
        build("armv7", iOS_DEVICE_SDK),
        build("arm64", iOS_DEVICE_SDK),
        build("i386", iOS_SIMULATOR_SDK),
        build("x86_64", iOS_SIMULATOR_SDK)
      ]

      FileUtils.cp_r File.join(build_array[0], 'include'), dist_dir

      lipo 'libcrypto.a', build_array, dist_dir
      lipo 'libssl.a', build_array, dist_dir
    end
  end

  framework_dir = File.join(dist_dir, "openssl.framework")
  framework_header_dir = File.join(framework_dir, "Headers")

  FileUtils.mkdir_p framework_header_dir
  Dir.glob(File.join(dist_dir, "include/openssl/*.h")).each do |h|
    FileUtils.cp h, framework_header_dir
  end

  system "lipo", "-create", *Dir.glob(File.join(dist_dir, "**/*.a")), "-output", File.join(framework_dir, "openssl")
end
