require_relative '../spec_helper'

require 'test/unit'
Test::Unit::AutoRunner.need_auto_run = false
require 'test/unit/testresult'
class Test::Unit::TestCase
  include Dataset
end

describe Test::Unit::TestCase do
  it 'should have a dataset method' do
    testcase = Class.new(Test::Unit::TestCase)
    expect(testcase).to respond_to(:dataset)
  end

  it 'should accept multiple datasets' do
    load_count = 0
    dataset_one = Class.new(Dataset::Base) do
      define_method(:load) { load_count += 1 }
    end
    dataset_two = Class.new(Dataset::Base) do
      define_method(:load) { load_count += 1 }
    end
    testcase = Class.new(Test::Unit::TestCase) do
      dataset dataset_one, dataset_two
    end
    run_testcase(testcase)
    expect(load_count).to eq(2)
  end

  it 'should provide one dataset session for tests' do
    sessions = []
    testcase = Class.new(Test::Unit::TestCase) do
      dataset Class.new(Dataset::Base)

      define_method(:test_one) do
        sessions << dataset_session
      end
      define_method(:test_two) do
        sessions << dataset_session
      end
    end
    run_testcase(testcase)
    expect(sessions.size).to eq(2)
    expect(sessions.uniq.size).to eq(1)
  end

  it 'should load datasets within class hiearchy' do
    dataset_one = Class.new(Dataset::Base) do
      define_method(:load) do
        Thing.create!
      end
    end
    dataset_two = Class.new(Dataset::Base) do
      define_method(:load) do
        Place.create!
      end
    end

    testcase = Class.new(Test::Unit::TestCase) do
      dataset(dataset_one)
      def test_one; end
    end
    testcase_child = Class.new(testcase) do
      dataset(dataset_two)
      def test_two; end
    end

    run_testcase(testcase)
    expect(Thing.count).to eq(1)
    expect(Place.count).to eq(0)

    run_testcase(testcase_child)
    expect(Thing.count).to eq(1)
    expect(Place.count).to eq(1)
  end

  it 'should forward blocks passed in to the dataset method' do
    load_count = 0
    testcase = Class.new(Test::Unit::TestCase) do
      dataset_class = Class.new(Dataset::Base)
      dataset dataset_class do
        load_count += 1
      end
    end

    run_testcase(testcase)
    expect(load_count).to eq(1)
  end

  it 'should forward blocks passed in to the dataset method that do not use a dataset class' do
    load_count = 0
    testcase = Class.new(Test::Unit::TestCase) do
      dataset do
        load_count += 1
      end
    end

    run_testcase(testcase)
    expect(load_count).to eq(1)
  end

  it 'should copy instance variables from block to tests' do
    value_in_test = nil
    testcase = Class.new(Test::Unit::TestCase) do
      dataset do
        @myvar = 'Hello'
      end
      define_method :test_something do
        value_in_test = @myvar
      end
    end

    run_testcase(testcase)
    expect(value_in_test).to eq('Hello')
  end

  it 'should copy instance variables from block to subclass blocks' do
    value_in_subclass_block = nil
    testcase = Class.new(Test::Unit::TestCase) do
      dataset do
        @myvar = 'Hello'
      end
    end
    subclass = Class.new(testcase) do
      dataset do
        value_in_subclass_block = @myvar
      end
    end

    run_testcase(subclass)
    expect(value_in_subclass_block).to eq('Hello')
  end

  it 'should load the dataset when the suite is run' do
    load_count = 0
    dataset = Class.new(Dataset::Base) do
      define_method(:load) do
        load_count += 1
      end
    end

    testcase = Class.new(Test::Unit::TestCase) do
      self.dataset(dataset)
      def test_one; end
      def test_two; end
    end

    run_testcase(testcase)
    expect(load_count).to eq(1)
  end

  it 'should expose data reading methods from dataset binding to the test methods through the test instances' do
    created_model, found_model = nil
    dataset = Class.new(Dataset::Base) do
      define_method(:load) do
        created_model = create_model(Thing, :mything)
      end
    end

    testcase = Class.new(Test::Unit::TestCase) do
      self.dataset(dataset)
      define_method :test_model_finders do
        found_model = things(:mything)
      end
    end

    run_testcase(testcase)
    expect(testcase).not_to respond_to(:things)
    expect(found_model).not_to be_nil
    expect(found_model).to eq(created_model)
  end

  it 'should expose dataset helper methods to the test methods through the test instances' do
    dataset_one = Class.new(Dataset::Base) do
      helpers do
        def helper_one; end
      end
      def load; end
    end
    dataset_two = Class.new(Dataset::Base) do
      uses dataset_one
      helpers do
        def helper_two; end
      end
      def load; end
    end

    test_instance = nil
    testcase = Class.new(Test::Unit::TestCase) do
      self.dataset(dataset_two)
      define_method :test_model_finders do
        test_instance = self
      end
    end

    run_testcase(testcase)

    expect(testcase).not_to respond_to(:helper_one)
    expect(testcase).not_to respond_to(:helper_two)
    expect(test_instance).to respond_to(:helper_one)
    expect(test_instance).to respond_to(:helper_two)
  end

  def run_testcase(testcase)
    require 'test/unit/worker-context'
    result = Test::Unit::TestResult.new
    worker_context = Test::Unit::WorkerContext.new(nil, nil, result)
    testcase.module_eval { def test_dont_complain; end }
    testcase.suite.run(worker_context) {}
    expect(result.faults.size).to eq(0)
  end
end
