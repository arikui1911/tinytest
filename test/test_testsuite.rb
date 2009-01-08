require 'test/unit'
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'tinytest/testsuite'

class TC_testsuite < Test::Unit::TestCase
  class TestCase
    class << self
      def new
        @instance ||= super
      end
      
      attr_reader :instance
      
      def to_s
        'TESTCASE'
      end
    end
    
    attr_accessor :suite
  end
  
  class Runner
    def initialize(&block)
      @block = block_given? ? block : nil
    end
    
    def receive_disorder(testcase, testname, exception)
      @block.call(testcase, testname, exception) if @block
    end
  end
  
  def test_inspect
    suite = TinyTest::TestSuite.new(TestCase, 'TESTNAME')
    assert_equal 'TESTCASE#TESTNAME', suite.inspect
  end
  
  class TestRunOrdinaryCase < TestCase
    def history
      @history ||= []
    end
    def setup    ; history << 'SETUP'    ; end
    def TESTNAME ; history << 'TESTNAME' ; end
    def teardown ; history << 'TEARDOWN' ; end
  end
  
  def test_run_ordinary_case
    suite = TinyTest::TestSuite.new(TestRunOrdinaryCase, 'TESTNAME')
    assert_equal '.', suite.run(nil)
    assert_equal ['SETUP', 'TESTNAME', 'TEARDOWN'],
                 TestRunOrdinaryCase.instance.history
  end
  
  class TestRunDisorderCase < TestCase
    def initialize
      @exception = Exception.new
    end
    attr_reader :exception
    def setup    ; end
    def TESTNAME ; raise exception ; end
    def teardown ; end
  end
  
  def test_run_disorder_case
    suite = TinyTest::TestSuite.new(TestRunDisorderCase, 'TESTNAME')
    runner = Runner.new{|*args| args }
    assert_equal [TestRunDisorderCase.instance,
                  'TESTNAME',
                  TestRunDisorderCase.instance.exception], suite.run(runner)
  end
  
  class TestTeardownCalling < TestCase
    attr_accessor :teardown_called
    
    def check(name)
      raise if name == self.class.raiser
    end
    
    def setup    ; check __method__ ; end
    def TESTNAME ; check __method__ ; end
    def teardown ; self.teardown_called = true ; end
  end
  
  class TestRunAccidentInSetupButTeardownCalled < TestTeardownCalling
    def self.raiser ; :setup ; end
  end
  
  def test_run_accident_in_setup_but_teardown_called
    suite = TinyTest::TestSuite.new(
      TestRunAccidentInSetupButTeardownCalled, 'TESTNAME')
    runner = Runner.new
    suite.run(runner)
    assert TestRunAccidentInSetupButTeardownCalled.instance.teardown_called
  end
  
  class TestRunAccidentInTestButTeardownCalled < TestTeardownCalling
    def self.raiser ; :TESTNAME ; end
  end
  
  def test_run_accident_in_test_but_teardown_called
    suite = TinyTest::TestSuite.new(
      TestRunAccidentInTestButTeardownCalled, 'TESTNAME')
    runner = Runner.new
    suite.run(runner)
    assert TestRunAccidentInTestButTeardownCalled.instance.teardown_called
  end
  
  class TestRunAccidentInTeardown < TestCase
    def setup    ; end
    def TESTNAME ; end
    def teardown ; raise ; end
  end
  
  def test_run_accident_in_teardown
    suite = TinyTest::TestSuite.new(TestRunAccidentInTeardown, 'TESTNAME')
    runner = Runner.new{ 'RECEIVE_DISORDER' }
    assert_equal 'RECEIVE_DISORDER', suite.run(runner)
  end
  
  def test_count_assertions
    suite = TinyTest::TestSuite.new(TestCase, 'TESTNAME')
    assert_raise LocalJumpError do
      suite.count_assertions
    end
    assert_equal 0, suite.count_assertions{}
  end
  
  def test_succ_assertion_count
    suite = TinyTest::TestSuite.new(TestCase, 'TESTNAME')
    n = rand(10)
    assert_equal n, suite.count_assertions{
      n.times{ suite.succ_assertion_count }
    }
  end
  
  def test_assertion_count_grouping
    suite = TinyTest::TestSuite.new(TestCase, 'TESTNAME')
    assert_equal 2, suite.count_assertions{
      2.times do
        suite.assertion_count_grouping do
          rand(10).times{ suite.succ_assertion_count }
        end
      end
    }
  end
end
