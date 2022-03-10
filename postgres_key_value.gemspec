# frozen_string_literal: true

require_relative "lib/postgres_key_value/version"

Gem::Specification.new do |spec|
  spec.name          = "postgres_key_value"
  spec.version       = PostgresKeyValue::VERSION
  spec.authors       = ["Bèr Kessels\n"]
  spec.email         = ["ber@berk.es"]

  spec.summary       = "Key-Value storage for Posgresql"
  spec.description   = "Performant and simple key-value storage in Posgresql. \
                        With a Hash-like interface. Only dependency is pg gem"
  spec.homepage      = "https://github.com/berkes/postgres_key_value"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org/"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/berkes/postgres_key_value"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
