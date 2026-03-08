module Dataset
  class TestSuite # :nodoc:
    def initialize(suite, test_class)
      @suite = suite
      @test_class = test_class
    end

    def dataset_session
      @test_class.dataset_session
    end

    def run(worker_context, &progress_block)
      if dataset_session
        load = dataset_session.load_datasets_for(@test_class)
        @suite.tests.each { |e| e.extend_from_dataset_load(load) }
      end
      @suite.run(worker_context, &progress_block)
    end

    def method_missing(method_symbol, *args)
      @suite.send(method_symbol, *args)
    end
  end

  module Extensions # :nodoc:

    module DatasetSuite # :nodoc:
      def suite
        Dataset::TestSuite.new(super, self)
      end
    end

    module TestUnitTestCase # :nodoc:
      def self.extended(test_case)
        test_case.singleton_class.prepend DatasetSuite
      end

      def dataset(*datasets, &block)
        add_dataset(*datasets, &block)
      end
    end

  end
end

Test::Unit::TestCase.extend Dataset::Extensions::TestUnitTestCase
