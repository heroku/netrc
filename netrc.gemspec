$:.unshift File.expand_path("../lib", __FILE__)
require "netrc/version"

Gem::Specification.new do |gem|
  gem.name    = "netrc"
  gem.version = Netrc::VERSION

  gem.author      = "Keith Rarick"
  gem.email       = "kr@xph.us"
  gem.homepage    = "https://github.com/kr/netrc"
  gem.summary     = "Client library and CLI to deploy apps on Netrc."
  gem.description = "Client library and command-line tool to deploy and manage apps on Netrc."

  gem.files = %x{ git ls-files }.split("\n").select { |d| d =~ %r{^(Readme.md||lib/|test/)} }
end
