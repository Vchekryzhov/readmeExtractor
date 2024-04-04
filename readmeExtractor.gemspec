# frozen_string_literal: true

require_relative "lib/readmeExtractor/version"

Gem::Specification.new do |spec|
  spec.name = "readmeExtractor"
  spec.version = ReadmeExtractor::VERSION
  spec.authors = ["Viktor C"]
  spec.email = ["vchekryzhov@ya.ru"]

  spec.summary = "Simple gem to extract md and rdoc files from .gem"
  spec.description = "Simple gem to extract md and rdoc files from .gem"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.executables << "readmeExtractor"
end
