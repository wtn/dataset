require_relative '../spec_helper'

RSpec::Core::ExampleGroup.include Dataset

describe RSpec::Core::ExampleGroup do
  it 'should have a dataset method' do
    group = Class.new(RSpec::Core::ExampleGroup)
    expect(group).to respond_to(:dataset)
  end
end
