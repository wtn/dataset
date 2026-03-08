require_relative 'lib/dataset/version'

Gem::Specification.new do |spec|
  spec.name = 'dataset'
  spec.version = Dataset::VERSION
  spec.authors = ['Adam Williams']
  spec.email = ['adam@thewilliams.ws']

  spec.summary = 'A simple API for creating and finding sets of data in your database, built on ActiveRecord.'
  spec.homepage = 'https://github.com/aiwilliams/dataset'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[Gemfile .gitignore spec/])
    end
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 8.0'
  spec.add_dependency 'activerecord', '~> 8.0'
end
