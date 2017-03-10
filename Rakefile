require 'rake'
require 'tmpdir'
require 'digest'
require 'fileutils'

OPENSSL_VERSION ='1.1.0c'
OPENSSL_TARBALL = ENV["OPENSSL_SRC_URL"] || "https://www.openssl.org/source/openssl-#{OPENSSL_VERSION}.tar.gz"
OPENSSL_SHA256 = 'fc436441a2e05752d31b4e46115eb89709a28aef96d4fe786abe92409b2fd6f5'
OPENSSL_PATCH = 'https://patch-diff.githubusercontent.com/raw/openssl/openssl/pull/1510.patch'

SDK_iOS_DEVICE=%x[xcrun --sdk iphoneos --show-sdk-path].strip
SDK_iOS_SIMULATOR=%x[xcrun --sdk iphonesimulator --show-sdk-path].strip

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

  target="iphoneos-cross no-asm"
  ios_version_min="7.0"

  if arch == 'arm64'
    target="ios64-cross enable-ec_nistp_64_gcc_128"
  elsif arch == "x86_64"
    target="darwin64-x86_64-cc no-asm enable-ec_nistp_64_gcc_128"
  end

  cflag = "-fembed-bitcode -Qunused-arguments -isysroot #{sdk} -arch #{arch} -miphoneos-version-min=#{ios_version_min}"

  Dir.chdir("openssl-#{OPENSSL_VERSION}") do
    unless OPENSSL_PATCH.nil?
      system "wget", OPENSSL_PATCH, "-O", "patch.patch"
      system "git", "apply", "patch.patch"
    end

    system "./Configure #{target} no-shared no-unit-test no-async --prefix='#{install_dir}'"
    inreplace "Makefile", /^CFLAGS=/, "CFLAGS=#{cflag} "
    inreplace "Makefile", "-O3", "-Os"
    inreplace "Makefile", " -isysroot $(CROSS_TOP)/SDKs/$(CROSS_SDK)", ""

    abort "build failed for arch #{arch}" unless system "make install_sw"
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
      system "wget -c #{OPENSSL_TARBALL} -O openssl-#{OPENSSL_VERSION}.tar.gz"

      abort unless Digest::SHA256.hexdigest(File.read("openssl-#{OPENSSL_VERSION}.tar.gz")) == OPENSSL_SHA256

      build_array = [
        build("armv7", SDK_iOS_DEVICE),
        build("arm64", SDK_iOS_DEVICE),
        build("i386", SDK_iOS_SIMULATOR),
        build("x86_64", SDK_iOS_SIMULATOR),
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

  Dir.mktmpdir do |dir|
    archs = nil
    Dir.glob(File.join(dist_dir, "lib/*.a")).each do |file|
      name = File.basename(file)
      archs ||= `lipo -info #{file}`.gsub(/Architectures in the fat file: .+ are: /, "").split(" ")
      archs.each do |arch|
        FileUtils.mkdir "#{dir}/#{arch}" rescue nil
        system "lipo -extract #{arch} #{file} -o #{dir}/#{arch}/#{name}"
      end
    end

    libs = archs.map do |arch|
      Dir.chdir "#{dir}/#{arch}" do
        system "libtool", "-static", *Dir.glob("*"), "-o", "openssl-#{arch}.a"
      end

      "#{dir}/#{arch}/openssl-#{arch}.a"
    end

    system "lipo", "-create", *libs, "-output", File.absolute_path(File.join(framework_dir, "openssl"))
  end
end
