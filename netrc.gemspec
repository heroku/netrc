$:.unshift File.expand_path("../lib", __FILE__)
require "netrc"

Gem::Specification.new do |gem|
  gem.name    = "netrc"
  gem.version = Netrc::VERSION

  gem.author      = "Keith Rarick"
  gem.email       = "kr@xph.us"
  gem.homepage    = "https://github.com/kr/netrc"
  gem.summary     = "Library to read and write netrc files."
  gem.description = "This library can read and update netrc files, preserving formatting including comments and whitespace."

  gem.files = %x{ git ls-files }.split("\n").select { |d| d =~ %r{^(Readme.md|data/|lib/|test/)} }
end
