require_relative "lib/dataset/version"

Gem::Specification.new do |spec|
  spec.name = "dataset"
  spec.version = Dataset::VERSION
  spec.authors = ["William T. Nelson"]
  spec.email = ["35801+wtn@users.noreply.github.com"]

  spec.summary = "Dataset"
  spec.homepage = "https://github.com/wtn/dataset"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
end
