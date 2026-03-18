# frozen_string_literal: true

require_relative 'lib/legion/extensions/agentic/executive/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-agentic-executive'
  spec.version       = Legion::Extensions::Agentic::Executive::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Agentic Executive'
  spec.description   = 'LEX agentic executive domain: planning, working memory, cognitive control'
  spec.homepage      = 'https://github.com/LegionIO/lex-agentic-executive'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = spec.homepage
  spec.metadata['changelog_uri']     = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    Dir.glob('{lib,spec}/**/*.rb') + %w[lex-agentic-executive.gemspec Gemfile LICENSE README.md CHANGELOG.md]
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.60'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.26'
end
