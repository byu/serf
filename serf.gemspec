# -*- encoding: utf-8 -*-
require File.expand_path('../lib/serf/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'serf'
  gem.version     = Serf::Version::STRING
  gem.authors     = ['Benjamin Yu']
  gem.email       = 'benjaminlyu@gmail.com'
  gem.description = 'Interactors with policy protection'
  gem.summary     = 'Interactors with policy protection'
  gem.homepage    = 'http://github.com/byu/serf'
  gem.licenses    = ['Apache 2.0']

  gem.rubygems_version = '1.8.17'
  gem.files            = `git ls-files`.split($\)
  gem.executables      = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files       = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths    = ['lib']
  gem.extra_rdoc_files = [
    'LICENSE.txt',
    'NOTICE.txt',
    'README.md'
  ]

  gem.add_runtime_dependency('hashie', ['>= 1.2.0'])
  gem.add_runtime_dependency('ice_nine', ['>= 0.4.0'])
  gem.add_runtime_dependency('optser', ['>= 0.1.0'])
  gem.add_runtime_dependency('uuidtools', ['>= 2.1.3'])
end
