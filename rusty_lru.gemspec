lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rusty_lru/version'

Gem::Specification.new do |spec|
  spec.name          = 'rusty_lru'
  spec.version       = RustyLRU::VERSION
  spec.authors       = ['Alastair Pharo']
  spec.email         = ['me@asph.dev']

  spec.summary       = 'An LRU cache implemented in Rust'
  spec.description   = <<-DESC
  This gem provides an LRU cache with an interface close to Hash. It uses Rutie
  to wrap the Rust 'lru' crate.
  DESC
  spec.homepage      = 'https://github.com/asppsa/rusty_lru'
  spec.license       = 'Apache-2.0'

  spec.metadata['changelog_uri'] = 'https://github.com/asppsa/rusty_lru/blob/master/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/rusty_lru'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/asppsa/rusty_lru.git'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.extensions << 'ext/Rakefile'

  spec.add_runtime_dependency 'rutie', '~> 0.0.3'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'irb', '~> 1.0.0'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.74.0'
end
