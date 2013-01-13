# -*- encoding: utf-8 -*-
require File.expand_path('../lib/google_browse/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Bil Bas (Spooner)"]
  gem.email         = ["bil.bagpuss@gmail.com"]
  gem.description   = %q{This is a very simple text browser which aids in searching and navigating on Google.com. Shows results as a simple list, any of which may be opened in a full
browser. Not really intended for real use, since it is only really a toy.}
  gem.summary       = %q{Simple text-browser for Google.com}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "google-browse"
  gem.require_paths = ["lib"]
  gem.version       = GoogleBrowse::VERSION

  gem.add_dependency "slop", "~> 3.3.3"
  gem.add_dependency "mechanize", "~> 2.5.1"
  gem.add_dependency "launchy", "~> 2.1.2"
end
