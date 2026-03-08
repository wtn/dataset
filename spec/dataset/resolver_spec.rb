require_relative '../spec_helper'

ResolveThis = Class.new(Dataset::Base)
ResolveDataset = Class.new(Dataset::Base)
SomeModelNotDs = Class.new
SomeModelNotDsDataset = Class.new(Dataset::Base)
NotADataset = Class.new
TheModule = Module.new
TheModuleDataset = Class.new(Dataset::Base)

describe Dataset::Resolver do
  before do
    @resolver = Dataset::Resolver.new
  end

  it 'should skip modules' do
    expect(@resolver.resolve(:the_module)).to eq(TheModuleDataset)
  end

  it 'should find simply classified' do
    expect(@resolver.resolve(:resolve_this)).to eq(ResolveThis)
  end

  it 'should find ending with Dataset' do
    expect(@resolver.resolve(:resolve)).to eq(ResolveDataset)
  end

  it 'should keep looking if first try is not a dataset' do
    dataset = @resolver.resolve(:some_model_not_ds)
    expect(dataset).not_to be(SomeModelNotDs)
    expect(dataset).to eq(SomeModelNotDsDataset)
  end

  it 'should indicate when found class is not a dataset' do
    expect {
      @resolver.resolve(:not_a_dataset)
    }.to raise_error(
      Dataset::DatasetNotFound,
      "Found a class 'NotADataset', but it does not subclass 'Dataset::Base'.",
    )
  end

  it 'should indicate that it could not find a dataset' do
    expect {
      @resolver.resolve(:undefined)
    }.to raise_error(
      Dataset::DatasetNotFound,
      "Could not find a dataset 'Undefined' or 'UndefinedDataset'.",
    )
  end
end

describe Dataset::DirectoryResolver do
  before do
    @resolver = Dataset::DirectoryResolver.new(File.join(SPEC_ROOT, 'fixtures/datasets'))
  end

  it 'should not look for a file if the constant is already defined' do
    expect(@resolver.resolve(:resolve)).to be(ResolveDataset)
  end

  it 'should find file with exact name match' do
    expect(defined?(ExactName)).to be_nil
    dataset = @resolver.resolve(:exact_name)
    expect(defined?(ExactName)).to eq('constant')
    expect(dataset).to eq(ExactName)
  end

  it 'should find file with name ending in _dataset' do
    expect(defined?(EndingWithDataset)).to be_nil
    dataset = @resolver.resolve(:ending_with)
    expect(defined?(EndingWithDataset)).to eq('constant')
    expect(dataset).to eq(EndingWithDataset)
  end

  it 'should indicate that it could not find a dataset file' do
    expect {
      @resolver.resolve(:undefined)
    }.to raise_error(
      Dataset::DatasetNotFound,
      %(Could not find a dataset file in ["#{File.join(SPEC_ROOT, 'fixtures/datasets')}"] having the name 'undefined.rb' or 'undefined_dataset.rb'.),
    )
  end

  it 'should indicate when it finds a file, but the constant is not defined after loading the file' do
    expect {
      @resolver.resolve(:constant_not_defined)
    }.to raise_error(
      Dataset::DatasetNotFound,
      "Found the dataset file '#{SPEC_ROOT + '/fixtures/datasets/constant_not_defined.rb'}', but it did not define a dataset 'ConstantNotDefined' or 'ConstantNotDefinedDataset'.",
    )
  end

  it 'should indicate when it finds a file, but the constant defined is not a subclass of Dataset::Base' do
    expect {
      @resolver.resolve(:not_a_dataset_base)
    }.to raise_error(
      Dataset::DatasetNotFound,
      "Found the dataset file '#{SPEC_ROOT + '/fixtures/datasets/not_a_dataset_base.rb'}' and a class 'NotADatasetBase', but it does not subclass 'Dataset::Base'.",
    )
  end

  it 'should support adding multiple directories' do
    @resolver << (File.join(SPEC_ROOT, 'fixtures/more_datasets'))
    expect(defined?(InAnotherDirectoryDataset)).to be_nil
    dataset = @resolver.resolve(:in_another_directory)
    expect(defined?(InAnotherDirectoryDataset)).to eq('constant')
    expect(dataset).to eq(InAnotherDirectoryDataset)
  end
end
