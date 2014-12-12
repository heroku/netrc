$:.unshift File.expand_path("../lib", __FILE__)
require "netrc"

Gem::Specification.new do |gem|
  gem.name    = "netrc"
  gem.version = Netrc::VERSION

  gem.authors     = ["Keith Rarick", "geemus (Wesley Beary)"]
  gem.description = "This library can read and update netrc files, preserving formatting including comments and whitespace."
  gem.email       = "geemus@gmail.com"
  gem.homepage    = "https://github.com/geemus/netrc"
  gem.license     = "MIT"
  gem.summary     = "Library to read and write netrc files."

  gem.files = %x{ git ls-files }.split("\n").select { |d| d =~ %r{^(changelog.txt|LICENSE|Readme.md|data/|lib/|test/)} }

  gem.add_development_dependency "turn"
end
