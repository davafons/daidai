# frozen_string_literal: true

require_relative "lib/daidai/version"

Gem::Specification.new do |spec|
  spec.name = "daidai"
  spec.version = Daidai::VERSION
  spec.authors = [ "davafons" ]
  spec.summary = "Pure-Ruby Japanese verb and adjective conjugation"
  spec.description = "Daidai is a table-driven, pure-Ruby port of jconj's conjugation " \
                     "algorithm, built on the JMdictDB conjugation tables. It conjugates " \
                     "Japanese verbs and adjectives from a dictionary-form word and its " \
                     "JMdict part-of-speech code, with no native extension and nothing to " \
                     "download at runtime."
  spec.homepage = "https://github.com/davafons/daidai"
  spec.license = "GPL-3.0-only"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*.rb",
    "lib/daidai/resources/*.csv",
    "LICENSE",
    "NOTICE",
    "README.md"
  ]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "csv"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end
