require 'test/unit'
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'test')
require 'tinytestutil'
require 'tinytest/testrunner'
require 'tinytest/exceptions'
require 'tinytest/testcase'

class TC_testrunner < Test::Unit::TestCase
  def basename
    @basename ||= $0.sub(/\.rb\Z/, '')
  end
  
  def testdata
    @testdata ||= TinyTestUtil.load_data(__FILE__)
  end
  
  def lines(key, *args)
    result = testdata[key].join("\n")
    result << "\n"
    result % args
  end
  
  def setup
    @runner = TinyTest::TestRunner.new
    TinyTest::TestCase.testcases_container_caller do
      @runner.testcases
    end
  end
  
  def test_run_without_errors_failures_skips
    buf = ''
    @runner.output = buf
    TinyTestUtil.time_stopper do
      @runner.run
      assert_equal lines(:run_without_testcases, basename), buf
    end
  end
  
  def test_run_succeeded
    buf = ''
    @runner.output = buf
    Class.new(TinyTest::TestCase) do
      def self.name ; 'a' ; end
      def test_foo ; assert true ; end
      attr_accessor :suite
    end
    Class.new(TinyTest::TestCase) do
      def self.name ; 'b' ; end
      def test_bar ; 2.times{ assert true } ; end
      attr_accessor :suite
    end
    TinyTestUtil.time_stopper{ @runner.run }
    assert_equal lines(:run_succeeded, basename), buf
  end
  
  def test_disorder_error_report
    backtrace = TinyTestUtil.expand(testdata[:error_backtrace])
    ex = Exception.new('MESSAGE')
    ex.set_backtrace backtrace
    expected_info = ['TESTCASE', 'TESTNAME', ex]
    assert_equal 'E', @runner.receive_disorder(*expected_info)
    assert_equal lines(:error_report, 'TESTNAME'), @runner.report.last
    assert_equal expected_info, @runner.errors.last
    assert_equal 1, @runner.errors.size
  end
  
  class TestCase
    def self.to_s
      'TESTCASE'
    end
    
    def refer_to_assertion?(s)
      /assert/ === s
    end
  end
  
  def test_disorder_failure_report
    ex = TinyTest::Assertion.new('MESSAGE')
    ex.set_backtrace TinyTestUtil.expand(testdata[:failure_backtrace])
    testcase = TestCase.new
    expected_info = [testcase, 'TESTNAME', ex]
    assert_equal 'F', @runner.receive_disorder(*expected_info)
    assert_equal lines(:failure_report, 'TESTNAME', 'TESTCASE'),
                 @runner.report.last
    assert_equal expected_info, @runner.failures.last
    assert_equal 1, @runner.failures.size
  end
  
  def test_disorder_skip_report
    ex = TinyTest::Skip.new('MESSAGE')
    ex.set_backtrace TinyTestUtil.expand(testdata[:skip_backtrace])
    testcase = TestCase.new
    expected_info = [testcase, 'TESTNAME', ex]
    assert_equal 'S', @runner.receive_disorder(*expected_info)
    assert_equal lines(:skip_report, 'TESTNAME', 'TESTCASE'),
                 @runner.report.last
    assert_equal expected_info, @runner.skips.last
    assert_equal 1, @runner.skips.size
  end
  
  def test_run_with_1_error
    buf = ''
    @runner.output = buf
    backtrace = TinyTestUtil.expand(testdata[:error_backtrace])
    ex = Exception.new('MESSAGE')
    ex.set_backtrace backtrace
    Class.new(TinyTest::TestCase) do
      def to_s ; 'TESTCASE' ; end
      define_method(:test_ref_undef_var){ raise ex }
      attr_accessor :suite
    end
    TinyTestUtil.time_stopper{ @runner.run }
    assert_equal lines(
      :run_with_1_error,
      basename,
      lines(:error_report, 'test_ref_undef_var')
    ), buf
  end
  
  def test_run_with_asserion_and_skip
    buf = ''
    @runner.output = buf
    assertion = TinyTest::Assertion.new('MESSAGE')
    assertion.set_backtrace TinyTestUtil.expand(testdata[:failure_backtrace])
    skip = TinyTest::Skip.new('MESSAGE')
    skip.set_backtrace TinyTestUtil.expand(testdata[:skip_backtrace])
    Class.new(TinyTest::TestCase) do
      def self.sort_my_tests(list) ; list.sort ; end
      def self.to_s ; 'TESTCASE' ; end
      define_method(:test_assertion){ raise assertion }
      define_method(:test_skip){ raise skip }
      attr_accessor :suite
    end
    TinyTestUtil.time_stopper{ @runner.run }
    assert_equal lines(
      :run_with_asserion_and_skip,
      basename,
      lines(:failure_report, 'test_assertion', 'TESTCASE'),
      lines(:skip_report, 'test_skip', 'TESTCASE')
    ), buf
  end
end


__END__
:error_backtrace:
- lib/autotest.rb:571:in `add_exception'
- test/test_autotest.rb:62:in `test_add_exception'
- ./lib/mini/test.rb:165:in `__send__'
- ./lib/mini/test.rb:165:in `run_test_suites'
- ./lib/mini/test.rb:161:in `each'
- ./lib/mini/test.rb:161:in `run_test_suites'
- ./lib/mini/test.rb:158:in `each'
- ./lib/mini/test.rb:158:in `run_test_suites'
- ./lib/mini/test.rb:139:in `run'
- ./lib/mini/test.rb:106:in `run'
- ./lib/mini/test.rb:29
- test/test_autotest.rb:422
:error_report:
- "Error:"
- "%s(TESTCASE):"
- "Exception: MESSAGE"
- "    lib/autotest.rb:571:in `add_exception'"
- "    test/test_autotest.rb:62:in `test_add_exception'"
:failure_backtrace:
- ./lib/tinytest/assertions.rb:23:in `assert'
- ./lib/tinytest/assertions.rb:171:in `assertion_delegate'
- ./lib/tinytest/assertions.rb:141:in `assert_throws'
- C:/home/ruby/tinytest/testapp.rb:30:in `test_throw'
- ./lib/tinytest/testsuite.rb:18:in `__send__'
- ./lib/tinytest/testsuite.rb:18:in `run'
- ./lib/tinytest/testrunner.rb:84:in `run_test_suites'
- ./lib/tinytest/util.rb:47:in `measure_time'
- ./lib/tinytest/testrunner.rb:84:in `run_test_suites'
- ./lib/tinytest/assertions.rb:14:in `count_assertions'
- ./lib/tinytest/testsuite.rb:28:in `count_assertions'
- ./lib/tinytest/testrunner.rb:81:in `run_test_suites'
- ./lib/tinytest/testrunner.rb:79:in `each'
- ./lib/tinytest/testrunner.rb:79:in `run_test_suites'
- ./lib/tinytest/util.rb:93:in `escape_sync'
- ./lib/tinytest/testrunner.rb:78:in `run_test_suites'
- ./lib/tinytest/testrunner.rb:59:in `run'
- ./lib/tinytest/util.rb:47:in `measure_time'
- ./lib/tinytest/testrunner.rb:59:in `run'
- ./lib/tinytest/unit.rb:25:in `add_hock_at_exit'
- C:/home/ruby/tinytest/testapp.rb:36
:failure_report:
- "Failure:"
- "%s(%s) [C:/home/ruby/tinytest/testapp.rb:30]:"
- MESSAGE
:skip_backtrace:
- ./lib/tinytest/assertions.rb:155:in `skip'
- C:/home/ruby/tinytest/testapp.rb:36:in `test_hogeeeee'
- ./lib/tinytest/testsuite.rb:18:in `__send__'
- ./lib/tinytest/testsuite.rb:18:in `run'
- ./lib/tinytest/testrunner.rb:84:in `run_test_suites'
- ./lib/tinytest/util.rb:47:in `measure_time'
- ./lib/tinytest/testrunner.rb:84:in `run_test_suites'
- ./lib/tinytest/assertions.rb:14:in `count_assertions'
- ./lib/tinytest/testsuite.rb:28:in `count_assertions'
- ./lib/tinytest/testrunner.rb:81:in `run_test_suites'
- ./lib/tinytest/testrunner.rb:79:in `each'
- ./lib/tinytest/testrunner.rb:79:in `run_test_suites'
- ./lib/tinytest/util.rb:93:in `escape_sync'
- ./lib/tinytest/testrunner.rb:78:in `run_test_suites'
- ./lib/tinytest/testrunner.rb:59:in `run'
- ./lib/tinytest/util.rb:47:in `measure_time'
- ./lib/tinytest/testrunner.rb:59:in `run'
- ./lib/tinytest/unit.rb:25:in `add_hock_at_exit'
- C:/home/ruby/tinytest/testapp.rb:40
:skip_report:
- "Skipped:"
- "%s(%s) [C:/home/ruby/tinytest/testapp.rb:36]:"
- MESSAGE
:run_without_testcases:
- Loaded suite %s
- Started
- 
- Finished in 0.000000 seconds.
- 
- 0 tests, 0 assertions, 0 failures, 0 errors, 0 skips
:run_succeeded:
- Loaded suite %s
- Started
- ..
- Finished in 0.000000 seconds.
- 
- 2 tests, 3 assertions, 0 failures, 0 errors, 0 skips
:run_with_1_error:
- "Loaded suite %s"
- "Started"
- "E"
- "Finished in 0.000000 seconds."
- ""
- "  1) %s"
- "1 tests, 0 assertions, 0 failures, 1 errors, 0 skips"
:run_with_asserion_and_skip:
- "Loaded suite %s"
- "Started"
- "FS"
- "Finished in 0.000000 seconds."
- ""
- "  1) %s"
- ""
- "  2) %s"
- "2 tests, 0 assertions, 1 failures, 0 errors, 1 skips"
