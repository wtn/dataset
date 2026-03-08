require_relative '../spec_helper'

begin
  require 'cucumber/rails/world'
  require 'cucumber/rails/rspec'

  Cucumber::Rails::World.class_eval do
    include Dataset
  end

  describe Cucumber::Rails::World do
    it 'should have a dataset method' do
      world = Class.new(Cucumber::Rails::World)
      expect(world).to respond_to(:dataset)
    end
  end
rescue LoadError
  # cucumber-rails not available; skip these specs
end
