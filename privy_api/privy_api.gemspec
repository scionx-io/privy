# frozen_string_literal: true

require File.expand_path('lib/privy_api/version', __dir__)

Gem::Specification.new do |spec|
  spec.name                  = 'privy_api'
  spec.version               = PrivyApi::VERSION
  spec.authors               = ['Bolo Michelin']
  spec.email                 = ['bolo@scionx.io']

  spec.summary               = 'Ruby gem for Privy API integration'
  spec.description           = 'A Ruby gem that provides easy access to the Privy API for ' \
                               'wallet management and user authentication services.'
  spec.homepage              = 'https://github.com/ScionX/privy_api'
  spec.license               = 'MIT'
  spec.platform              = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 3.2.0'

  # List of files to include in the gem
  spec.files = Dir['README.md', 'LICENSE.md', 'CHANGELOG.md', 'example.rb', 'lib/**/*.rb', 'exe/**/*',
                   'privy_api.gemspec', 'Gemfile', 'Rakefile']

  spec.extra_rdoc_files = ['README.md', 'CHANGELOG.md', 'LICENSE.md']

  # Runtime dependencies
  spec.add_dependency 'httparty', '~> 0.20'
  spec.add_dependency 'json', '~> 2.6'
  spec.add_dependency 'base64', '~> 0.2'

  spec.metadata['rubygems_mfa_required'] = 'true'
end