require 'test/unit'
require 'set'
require 'stringio'
$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
before = $LOADED_FEATURES.dup
require 'tinytest'
after = $LOADED_FEATURES
feature = (after - before).last
unless feature.include?('/') || feature.include?('\\')
  # expand feature because $LOADED_FEATURES holds relative path in Ruby 1.8.x
  feature = $LOAD_PATH.map{|d| File.join(d, feature) }.find{|path| File.file?(path) }
end
TINYTEST_FEATURE = feature


class Array
  unless method_defined?(:sample)
    def sample
      shuffle.first
    end
  end
end

module TestUtil
  def positive_integer_cases(limit)
    [0, 1, [*2..limit].sample]
  end
  module_function :positive_integer_cases
end

class TC_AssertError < Test::Unit::TestCase
  def test_superclass
    assert TinyTest::AssertError < Exception
  end
end

class TC_SkipError < Test::Unit::TestCase
  def test_superclass
    assert TinyTest::SkipError < TinyTest::AssertError
  end
end

class TC_Runner < Test::Unit::TestCase
  module MockForRun
    def set(n_assertions, results, benchmark)
      self.n_assertions = n_assertions
      self.results      = results
      self.benchmark    = benchmark
    end
    
    attr_accessor :n_assertions
    attr_accessor :results
    attr_accessor :benchmark
    
    def run_suites(suites)
      return n_assertions, results, benchmark
    end
    
    def collect_suites
      suite_list
    end
    
    def suite_list
      @suite_list ||= []
    end
    
    def count_suiteresults_types(results)
      return 1, 2, 3
    end
  end
  
  class ReporterMock
    def initialize
      @history = []
    end
    
    attr_reader :history
    
    def method_missing(name, *args)
      history << [name, *args]
    end
  end
  
  BENCH = Object.new
  def BENCH.real
    6.66
  end
  
  def test_run
    results = []
    repo = ReporterMock.new
    runner = TinyTest::Runner.new(:reporter => repo)
    runner.extend(MockForRun).set(666, results, BENCH)
    runner.run
    assert_equal :load_suite, repo.history.shift.first
    assert_equal [:mark_results, results], repo.history.shift
    assert_equal [:running_times, BENCH], repo.history.shift
    assert_equal [:blank], repo.history.shift
    assert_equal [:counts_report, results.size, 666, 1, 2, 3], repo.history.shift
  end
  
  def test_run_verbose
    results = []
    repo = ReporterMock.new
    runner = TinyTest::Runner.new(:reporter => repo, :verbose => true)
    runner.extend(MockForRun).set(666, results, BENCH)
    runner.run
    assert_equal :load_suite, repo.history.shift.first
    assert_equal [:mark_results_with_times, results], repo.history.shift
    assert_equal [:running_times, BENCH], repo.history.shift
    assert_equal [:blank], repo.history.shift
    assert_equal [:counts_report, results.size, 666, 1, 2, 3], repo.history.shift
  end
  
  def test_run_with_errors
    results = Array.new(5){ Object.new.tap{|o| def o.success?() true end } }
    results.concat Array.new(5){ Object.new.tap{|o| def o.success?() false end } }
    results.shuffle!
    not_succeededs = results.select{|r| not r.success? }
    repo = ReporterMock.new
    runner = TinyTest::Runner.new(:reporter => repo)
    runner.extend(MockForRun).set(666, results, BENCH)
    runner.run
    assert_equal :load_suite, repo.history.shift.first
    assert_equal [:mark_results, results], repo.history.shift
    assert_equal [:running_times, BENCH], repo.history.shift
    assert_equal [:error_reports, not_succeededs], repo.history.shift
    assert_equal [:counts_report, results.size, 666, 1, 2, 3], repo.history.shift
  end
end

class TC_Runner_private < Test::Unit::TestCase
  def setup
    @runner = TinyTest::Runner.new
  end
  
  def test_each_class
    root = Class.new
    sub = Class.new(root)
    subsub = Class.new(sub)
    classes = []
    @runner.instance_eval{ each_class(root){|c| classes << c } }
    assert_equal Set.new([sub, subsub]), Set.new(classes)
  end
  
  class SuiteMock
    def count_assertions
      yield()
      666
    end
    
    def execute
      sleep 0.1
      'execute'
    end
  end
  
  def test_private_run_suites
    suites = Array.new(3){ SuiteMock.new }
    n, results, bench = @runner.instance_eval{ run_suites(suites) }
    assert_equal 666 * 3, n
    assert_equal ['execute'] * 3, results
    assert bench.real >= 0.3
  end
  
  def test_private_count_suiteresults_types
    nums = Array.new(4){ [*1..10].sample }
    results = []
    klass = Struct.new(:char)
    %w[. F E S].zip(nums) do |c, n|
      results.concat Array.new(n){ klass.new(c) }
    end
    results.shuffle!
    counts = @runner.instance_eval{ count_suiteresults_types(results) }
    assert_equal nums.drop(1), counts
  end
end

class TC_Runner_private_collect_suites < Test::Unit::TestCase
  module EachClassMock
    def class_list
      @class_list ||= []
    end
    
    def each_class(root = nil, &block)
      class_list.each(&block)
    end
  end
  
  class ClassMock
    def initialize(name, *methods)
      @name = name
      @public_instance_methods = methods
      unless /./ === :hoge  # for 1.8 Symbol-Regexp matching
        @public_instance_methods.map!{|m| m.id2name }
      end
    end
    
    attr_accessor :name
    
    def public_instance_methods(inherited_too = true)
      @public_instance_methods
    end
    
    def new
      self
    end
    
    def bind_testsuite(suite)
    end
    
    def inspect
      "<#ClassMock:#{name}>"
    end
  end
  
  # for ClassMock's 1.8 consideration
  def symbol_set(enum)
    enum = enum.map{|e| e.respond_to?(:intern) ? e.intern : e }
    Set.new(enum)
  end
  
  def test_collect_suites
    runner = TinyTest::Runner.new()
    runner.extend(EachClassMock)
    runner.class_list << ClassMock.new("Foo", :test_foo, :test_bar, :not_test_baz)
    suites = runner.instance_eval{ collect_suites() }
    assert_equal symbol_set([:test_foo, :test_bar]), symbol_set(suites.map(&:testname))
  end
  
  def test_collect_suites_testname_matcher_re
    runner = TinyTest::Runner.new(:testname => /\Aprefix_/)
    runner.extend(EachClassMock)
    runner.class_list << ClassMock.new("Foo", :test_foo, :prefix_bar, :prefix_baz)
    suites = runner.instance_eval{ collect_suites() }
    assert_equal symbol_set([:prefix_bar, :prefix_baz]), symbol_set(suites.map(&:testname))
  end
  
  def test_collect_suites_testname_matcher_proc
    matcher = lambda{|name| name.to_s.start_with?('prefix') }
    runner = TinyTest::Runner.new(:testname => matcher)
    runner.extend(EachClassMock)
    runner.class_list << ClassMock.new("Foo", :test_foo, :prefix_bar, :prefix_baz)
    suites = runner.instance_eval{ collect_suites() }
    assert_equal symbol_set([:prefix_bar, :prefix_baz]), symbol_set(suites.map(&:testname))
  end
  
  def test_collect_suites_testcase_matcher_re
    runner = TinyTest::Runner.new(:testcase => /\ATC_/)
    runner.extend(EachClassMock)
    runner.class_list << ClassMock.new("TC_Foo", :test_foo_a, :test_foo_b, :not_test_foo_c)
    runner.class_list << ClassMock.new("Bar", :test_bar_a, :test_bar_b, :not_test_bar_c)
    suites = runner.instance_eval{ collect_suites() }
    assert_equal Set.new(["TC_Foo"]), Set.new(suites.map{|s| s.testcase.name })
    assert_equal symbol_set([:test_foo_a, :test_foo_b]), symbol_set(suites.map(&:testname))
  end
  
  def test_collect_suites_testcase_matcher_proc
    cm = ClassMock.new("TC_Foo", :test_foo_a, :test_foo_b, :not_test_foo_c)
    matcher = lambda{|tc| tc.equal? cm }
    runner = TinyTest::Runner.new(:testcase => matcher)
    runner.extend(EachClassMock)
    runner.class_list << cm
    runner.class_list << ClassMock.new("Bar", :test_bar_a, :test_bar_b, :not_test_bar_c)
    suites = runner.instance_eval{ collect_suites() }
    assert_equal Set.new(["TC_Foo"]), Set.new(suites.map{|s| s.testcase.name })
    assert_equal symbol_set([:test_foo_a, :test_foo_b]), symbol_set(suites.map(&:testname))
  end
end

class TC_Reporter < Test::Unit::TestCase
  def setup
    @f = StringIO.new
    @r = TinyTest::Reporter.new(@f)
  end
  
  def test_blank
    @r.blank
    assert_equal "\n", @f.string
  end
  
  def test_load_suite
    @r.load_suite "foo/bar"
    @r.load_suite "foo/bar.rb"
    assert_equal "Loaded suite foo/bar\nStarted\n" * 2, @f.string
  end
  
  module BenchmarkMock
    REAL = 1.0
    
    def self.real
      REAL
    end
  end
  
  class SuiteResultMock
    def char
      '*'
    end
    
    def report
      'REPORT'
    end
    
    SUITE = Object.new.tap{|o|
      def o.inspect
        'INSPECTION'
      end
    }
    
    def suite
      SUITE
    end
    
    def benchmark
      BenchmarkMock
    end
  end
  
  include TestUtil
  
  def test_mark_results
    nums = positive_integer_cases(10)
    nums.each do |n|
      results = Array.new(n){ SuiteResultMock.new }
      @r.mark_results(results)
    end
    assert_equal nums.map{|n| "#{'*' * n}\n" }.join, @f.string
  end
  
  def test_mark_results_with_times_for_0_results
    @r.mark_results_with_times([])
    assert_equal "\n\n", @f.string
  end
  
  def test_mark_results_with_times_for_1_result
    @r.mark_results_with_times([SuiteResultMock.new])
    assert_equal "\nINSPECTION: 1.00 sec: *\n\n", @f.string
  end
  
  def test_mark_results_with_times_for_results
    n = positive_integer_cases(10).last
    results = Array.new(n){ SuiteResultMock.new }
    @r.mark_results_with_times(results)
    expected = "\n" << "INSPECTION: 1.00 sec: *\n" * n << "\n"
    assert_equal expected, @f.string
  end
  
  def test_running_times
    @r.running_times(BenchmarkMock)
    assert_equal "Finished in 1.000000 seconds.\n", @f.string
  end
  
  def test_error_reports_for_0_results
    @r.error_reports([])
    assert @f.string.empty?
  end
  
  def test_error_reports_for_1_result
    @r.error_reports([SuiteResultMock.new])
    assert_equal "\n  1) REPORT\n\n", @f.string
  end
  
  def test_error_reports_for_results
    n = positive_integer_cases(9).last
    results = Array.new(n){ SuiteResultMock.new }
    @r.error_reports(results)
    expected = n.times.map{|i| "\n  #{i.succ}) REPORT\n\n" }.join('')
    assert_equal expected, @f.string
  end
  
  def test_counts_report
    @r.counts_report(1, 2, 3, 4, 5)
    expected = "1 tests, 2 assertions, 3 failures, 4 errors, 5 skips\n"
    assert_equal expected, @f.string
  end
end

class MockTestCase
  def self.def_hist_method(name, &body)
    define_method name do |*args, &block|
      history << name
      body.yield(*args, &block) if body
    end
  end
  
  def history
    @history ||= []
  end
  
  attr_accessor :suite
  alias :bind_testsuite :suite=
  
  def_hist_method :setup
  def_hist_method :teardown
  
  def_hist_method :test_succeed do
    true
  end
  
  def_hist_method :test_failure do
    raise TinyTest::AssertError
  end
  
  def_hist_method :test_skip do
    raise TinyTest::SkipError
  end
  
  def_hist_method :test_error do
    raise
  end
end

class TC_Suite < Test::Unit::TestCase
  
  def setup
    @testcase = MockTestCase.new
  end
  
  def test_initialize
    suite = TinyTest::Suite.new(@testcase, :testname)
    assert_equal @testcase, suite.testcase
    assert_equal :testname, suite.testname
  end
  
  def test_inspect
    suite = TinyTest::Suite.new(@testcase, :testname)
    assert_equal "#{@testcase.class}#testname", suite.inspect
  end
  
  def test_execute_success
    suite = TinyTest::Suite.new(@testcase, :test_succeed)
    result = suite.execute
    assert_equal [:setup, :test_succeed, :teardown], @testcase.history
    assert result.success?
  end
  
  def test_execute_failure
    suite = TinyTest::Suite.new(@testcase, :test_failure)
    result = suite.execute
    assert_equal [:setup, :test_failure, :teardown], @testcase.history
    assert_equal 'F', result.char
  end
  
  def test_execute_error
    suite = TinyTest::Suite.new(@testcase, :test_error)
    result = suite.execute
    assert_equal [:setup, :test_error, :teardown], @testcase.history
    assert_equal 'E', result.char
  end
  
  def test_execute_skip
    suite = TinyTest::Suite.new(@testcase, :test_skip)
    result = suite.execute
    assert_equal [:setup, :test_skip, :teardown], @testcase.history
    assert_equal 'S', result.char
  end
end

class TC_Suite_assertioncount < Test::Unit::TestCase
  include TestUtil
  
  def setup
    @testcase = MockTestCase.new
    @counter = TinyTest::Suite.new(@testcase, :dummy)
  end
  
  def test_out_of_count_assertions_block
    do_count = lambda{|n|
      n.times{ @counter.succ_assertion_count }
      @counter.count_assertions{}
    }
    assert_equal [0], [].tap{|results|
      positive_integer_cases(10).each do |n|
        results << do_count.call(n)
        @counter.assertion_count_grouping{ results << do_count.call(n) }
      end
    }.uniq
  end
  
  def test_count_assertions
    positive_integer_cases(10).tap do |nums|
      assert_equal nums, nums.map{|n|
        @counter.count_assertions{ n.times{ @counter.succ_assertion_count } }
      }
    end
  end
  
  def test_assertion_count_grouping
    assert_equal 0, @counter.count_assertions{
      @counter.assertion_count_grouping{}
    }
    naturals = positive_integer_cases(10).drop(1)
    assert_equal [1], naturals.map{|n|
      @counter.count_assertions do
        @counter.assertion_count_grouping do
          n.times{ @counter.succ_assertion_count }
        end
      end
    }.uniq
  end
  
  def test_assertion_count_grouping_several
    assert_equal 4, @counter.count_assertions{
      @counter.assertion_count_grouping{ @counter.succ_assertion_count }
      2.times{ @counter.succ_assertion_count }
      @counter.assertion_count_grouping{ 2.times{ @counter.succ_assertion_count } }
      @counter.assertion_count_grouping{}
    }
  end
end


class TC_SuiteResult < Test::Unit::TestCase
  Reports = {
    :success => nil,
    :failure => 'Failure',
    :error   => 'Error',
    :skip    => 'Skip',
  }
  
  def setup
    @results = {}.tap{|h|
      Reports.each{|k, v| h[k] = TinyTest::SuiteResult.new(:suite, :benchmark, v) }
    }
  end
  
  def test_report
    Reports.each_key do |k|
      assert_equal Reports[k], @results[k].report
    end
  end
  
  def test_char
    assert_equal ['.', 'F', 'E', 'S'],
                 [:success, :failure, :error, :skip].map{|k| @results[k].char }
  end
  
  def test_success?
    others = Reports.keys.tap{|x| x.delete(:success) }
    others = others.map{|k| @results[k].success? }.uniq
    assert_equal [false], others
    assert @results[:success].success?
  end
end

class TC_TestCase < Test::Unit::TestCase
  def setup
    @testcase = TinyTest::TestCase.new
  end
  
  def test_respondance_about_setup
    assert_nothing_raised NoMethodError do
      @testcase.setup
    end
  end
  
  def test_respondance_about_teardown
    assert_nothing_raised NoMethodError do
      @testcase.teardown
    end
  end
  
  def test_suite_attr
    gensym = Object.new
    assert_nothing_raised NoMethodError do
      @testcase.bind_testsuite gensym
      assert_equal gensym, @testcase.suite
    end
  end
end

class TC_TestCase_assertions < Test::Unit::TestCase
  def setup
    @tc = TinyTest::TestCase.new
    @suite = TinyTest::Suite.new(@tc, nil)
    @tc.bind_testsuite(@suite)
  end
  
  def if_flunk(message)
    @flunk_message = message
    yield()
    @flunk_message = nil
  end
  
  def ex_message(target = TinyTest::AssertError)
    yield()
    flunk @flunk_message
  rescue target => ex
    ex.message
  end
  
  def test_assert
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert true
    end
    if_flunk "assert seems to contain bug." do
      assert_equal "Failed assertion, no message given.", ex_message{
        @tc.assert false
      }
      assert_equal 'MESSAGE', ex_message{
        @tc.assert false, 'MESSAGE'
      }
    end
  end
  
  def test_refute
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute false
    end
    if_flunk "refute seems to contain bug." do
      assert_equal "Failed refutation, no message given", ex_message{
        @tc.refute true
      }
      assert_equal 'MESSAGE', ex_message{
        @tc.refute true, 'MESSAGE'
      }
    end
  end
  
  def test_pass
    assert_nothing_raised TinyTest::AssertError do
      @tc.pass
    end
  end
  
  def test_skip
    if_flunk "skip seems to contain bug." do
      assert_equal "Skipped, no message given", ex_message{
        @tc.skip
      }
      assert_equal 'MESSAGE', ex_message{
        @tc.skip 'MESSAGE'
      }
    end
  end
  
  def test_assert_block
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_block{ true }
    end
    if_flunk "assert_block seems to contain bug." do
      default = "Expected block to return a value evaluated as true."
      assert_equal default, ex_message{
        @tc.assert_block{ false }
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.assert_block('MESSAGE'){ false }
      }
    end
  end
  
  def test_refute_block
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_block{ false }
    end
    if_flunk "refute_block seems to contain bug." do
      default = "Expected block to return a value evaluated as false."
      assert_equal default, ex_message{
        @tc.refute_block{ true }
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.refute_block('MESSAGE'){ true }
      }
    end
  end
  
  def test_assert_equal
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_equal 4, 'Ruby'.size
    end
    if_flunk "assert_equal seems to contain bug." do
      default = %Q`Expected "expected", not "actual".`
      assert_equal default, ex_message{
        @tc.assert_equal 'expected', 'actual'
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.assert_equal 'expected', 'actual', 'MESSAGE'
      }
    end
  end
  
  def test_refute_equal
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_equal 4, 'Python'.size
    end
    if_flunk "refute_equal seems to contain bug." do
      val = %w[a b c]
      default = %Q`Expected ["a", "b", "c"] to not be equal to ["a", "b", "c"].`
      assert_equal default, ex_message{
        @tc.refute_equal val, val
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.refute_equal val, val, 'MESSAGE'
      }
    end
  end
  
  def test_assert_instance_of
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_instance_of Array, []
    end
    if_flunk "assert_instance_of seems to contain bug." do
      default = "Expected \"\" to be an instance of Array."
      assert_equal default, ex_message{
        @tc.assert_instance_of Array, ''
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.assert_instance_of Array, '', 'MESSAGE'
      }
    end
  end
  
  def test_refute_instance_of
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_instance_of Hash, []
    end
    if_flunk "refute_instance_of seems to contain bug." do
      default = "Expected \"\" to not be an instance of String."
      assert_equal default, ex_message{
        @tc.refute_instance_of String, ''
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.refute_instance_of String, '', 'MESSAGE'
      }
    end
  end
  
  def test_assrt_kind_of
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_kind_of IO, STDOUT
    end
    if_flunk "assrt_kind_of seems to contain bug." do
      default = "Expected [] to be a kind of Hash."
      assert_equal default, ex_message{
        @tc.assert_kind_of Hash, []
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.assert_kind_of Hash, [], 'MESSAGE'
      }
    end
  end
  
  def test_refute_kind_of
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_kind_of Array, 123
    end
    if_flunk "refute_kind_of seems to contain bug." do
      default = "Expected 123 to not be a kind of Numeric."
      assert_equal default, ex_message{
        @tc.refute_kind_of Numeric, 123
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.refute_kind_of Numeric, 123, 'MESSAGE'
      }
    end
  end
  
  def test_assert_match
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_match /\A=+/, "== headline"
    end
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_match 'bar', 'foobarbaz'
    end
    if_flunk "assert_match seems to contain bug." do
      default = "Expected /(?!)/ to match \"hoge\"."
      assert_equal default, ex_message{
        @tc.assert_match /(?!)/, 'hoge'
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.assert_match /(?!)/, 'hoge', 'MESSAGE'
      }
    end
  end
  
  def test_refute_match
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_match /(?!)/, 'WRYYYYYYYYYYY!!!'
    end
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_match 'hoge', 'foobarbaz'
    end
    if_flunk "refute_match seems to contain bug." do
      default = "Expected /^[A-Z]/ to not match \"Hoge\"."
      assert_equal default, ex_message{
        @tc.refute_match /^[A-Z]/, 'Hoge'
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.refute_match /^[A-Z]/, 'Hoge', 'MESSAGE'
      }
    end
  end
  
  def test_assert_nil
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_nil nil
    end
    if_flunk "assert_nil seems to contain bug." do
      default = "Expected 123 to be nil."
      assert_equal default, ex_message{
        @tc.assert_nil 123
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.assert_nil 123, 'MESSAGE'
      }
    end
  end
  
  def test_refute_nil
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_nil false
    end
    if_flunk "refute_nil seems to contain bug." do
      default = "Expected nil to not be nil."
      assert_equal default, ex_message{
        @tc.refute_nil nil
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.refute_nil nil, 'MESSAGE'
      }
    end
  end
  
  def test_assert_same
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_same :hoge, :hoge
    end
    if_flunk "assert_same seems to contain bug." do
      expected, actual = 2.times.map{ Object.new }
      default = sprintf(
        "Expected %s (0x%x) to be the same as %s (0x%x).",
        expected.inspect, expected.object_id,
        actual.inspect,   actual.object_id
      )
      assert_equal default, ex_message{
        @tc.assert_same expected, actual
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.assert_same expected, actual, 'MESSAGE'
      }
    end
  end
  
  def test_refute_same
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_same *2.times.map{ Object.new }
    end
    if_flunk "refute_same seems to contain bug." do
      default = "Expected :hoge to not be the same as :hoge."
      assert_equal default, ex_message{
        @tc.refute_same :hoge, :hoge
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.refute_same :hoge, :hoge, 'MESSAGE'
      }
    end
  end
  
  def test_assert_respond_to
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_respond_to 123, :divmod
    end
    if_flunk "assert_respond_to seems to contain bug." do
      default = "Expected 666 (Fixnum) to respond to encoding."
      assert_equal default, ex_message{
        @tc.assert_respond_to 666, :encoding
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.assert_respond_to 666, :encoding, 'MESSAGE'
      }
    end
  end
  
  def test_refute_respond_to
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_respond_to 666, :encoding
    end
    if_flunk "refute_respond_to seems to contain bug." do
      default = "Expected \"hoge\" to not respond to capitalize."
      assert_equal default, ex_message{
        @tc.refute_respond_to 'hoge', :capitalize
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.refute_respond_to 'hoge', :capitalize, 'MESSAGE'
      }
    end
  end
  
  def test_assert_empty
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_empty []
    end
    assert_raises TinyTest::AssertError do
      @tc.assert_empty 666
    end
    if_flunk "assert_empty seems to contain bug." do
      default = "Expected [1, 2, 3] to be empty."
      assert_equal default, ex_message{
        @tc.assert_empty [1, 2, 3]
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.assert_empty [1, 2, 3], 'MESSAGE'
      }
    end
  end
  
  def test_refute_empty
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_empty 'hoge'
    end
    assert_raises TinyTest::AssertError do
      @tc.refute_empty 666
    end
    if_flunk "refute_empty seems to contain bug." do
      default = "Expected [] to not be empty."
      assert_equal default, ex_message{
        @tc.refute_empty []
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.refute_empty [], 'MESSAGE'
      }
    end
  end
  
  def test_assert_includes
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_includes [1, 2, 3], 2
    end
    assert_raises TinyTest::AssertError do
      @tc.assert_includes 666, 4
    end
    if_flunk "assert_includes seems to contain bug." do
      default = "Expected [1, 2, 3] to include 666."
      assert_equal default, ex_message{
        @tc.assert_includes [1, 2, 3], 666
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.assert_includes [1, 2, 3], 666, 'MESSAGE'
      }
    end
  end
  
  def test_refute_includes
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_includes [1, 2, 3], 666
    end
    assert_raises TinyTest::AssertError do
      @tc.assert_includes 666, 4
    end
    if_flunk "refute_includes seems to contain bug." do
      default = %Q`Expected ["a", "b", "c"] to not include "b".`
      assert_equal default, ex_message{
        @tc.refute_includes %w[a b c], 'b'
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.refute_includes %w[a b c], 'b', 'MESSAGE'
      }
    end
  end
  
  def test_assert_in_delta
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_in_delta 1, 1
    end
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_in_delta 1, 2, 10
    end
    assert_raises TinyTest::AssertError do
      @tc.assert_in_delta 1, 2
    end
    if_flunk "assert_in_delta seems to contain bug." do
      default = "Expected 1 - 10 (9) to be < %s."
      assert_equal default % '0.001', ex_message{
        @tc.assert_in_delta 1, 10
      }
      assert_equal "MESSAGE.\n#{default % '0.001'}", ex_message{
        @tc.assert_in_delta 1, 10, 'MESSAGE'
      }
      assert_equal default % '5.0', ex_message{
        @tc.assert_in_delta 1, 10, 5
      }
      assert_equal "MESSAGE.\n#{default % '5.0'}", ex_message{
        @tc.assert_in_delta 1, 10, 5, 'MESSAGE'
      }
    end
  end
  
  def test_refute_in_delta
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_in_delta 1, 10
    end
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_in_delta 1, 2, 0.1
    end
    assert_raises TinyTest::AssertError do
      @tc.refute_in_delta 1, 1
    end
    if_flunk "refute_in_delta seems to contain bug." do
      default = "Expected 1 - 1 (0) to not be < %s."
      assert_equal default % '0.001', ex_message{
        @tc.refute_in_delta 1, 1
      }
      assert_equal "MESSAGE.\n#{default % '0.001'}", ex_message{
        @tc.refute_in_delta 1, 1, 'MESSAGE'
      }
      assert_equal default % '100.0', ex_message{
        @tc.refute_in_delta 1, 1, 100
      }
      assert_equal "MESSAGE.\n#{default % '100.0'}", ex_message{
        @tc.refute_in_delta 1, 1, 100, 'MESSAGE'
      }
    end
  end
  
  def test_assert_in_epsilon
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_in_epsilon 1, 1
    end
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_in_epsilon 1, 2, 10
    end
    assert_raises TinyTest::AssertError do
      @tc.assert_in_epsilon 1, 2
    end
    if_flunk "assert_in_epsilon seems to contain bug." do
      default = "Expected 1 - 10 (9) to be < %s."
      assert_equal default % '0.001', ex_message{
        @tc.assert_in_epsilon 1, 10
      }
      assert_equal "MESSAGE.\n#{default % '0.001'}", ex_message{
        @tc.assert_in_epsilon 1, 10, 'MESSAGE'
      }
    end
  end
  
  def test_refute_in_epsilon
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_in_epsilon 1, 10
    end
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_in_epsilon 1, 1.0001, 0.00001
    end
    assert_raises TinyTest::AssertError do
      @tc.refute_in_epsilon 1, 1.0001
    end
    if_flunk "refute_in_epsilon seems to contain bug." do
      default = "Expected 1 - 1 (0) to not be < %s."
      assert_equal default % '0.001', ex_message{
        @tc.refute_in_epsilon 1, 1
      }
      assert_equal "MESSAGE.\n#{default % '0.001'}", ex_message{
        @tc.refute_in_epsilon 1, 1, 'MESSAGE'
      }
    end
  end
  
  def test_assert_operator
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_operator :hoge, :equal?, :hoge
    end
    if_flunk "assert_operator seems to contain bug." do
      default = "Expected :hoge to be == :piyo."
      assert_equal default, ex_message{
        @tc.assert_operator :hoge, :==, :piyo
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.assert_operator :hoge, :==, :piyo, 'MESSAGE'
      }
    end
  end
  
  def test_refute_operator
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_operator 'foo', :equal?, :bar
    end
    if_flunk "refute_operator seems to contain bug." do
      default = "Expected 123 to not be == 123."
      assert_equal default, ex_message{
        @tc.refute_operator 123, :==, 123
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.refute_operator 123, :==, 123, 'MESSAGE'
      }
    end
  end
  
  def test_assert_send
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_send [[1, 2, 3], :include?, 2]
    end
    if_flunk "assert_send seems to contain bug." do
      default = "Expected [1, 2, 3].include?(10) to be evaluated as true."
      assert_equal default, ex_message{
        @tc.assert_send [[1, 2, 3], :include?, 10]
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.assert_send [[1, 2, 3], :include?, 10], 'MESSAGE'
      }
    end
  end
  
  def test_refute_send
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_send [{}, :fetch, :key, nil]
    end
    if_flunk "refute_send seems to contain bug." do
      default = "Expected {:key=>123}.fetch(:key, nil) to be evaluated as false."
      assert_equal default, ex_message{
        @tc.refute_send [{:key => 123}, :fetch, :key, nil]
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.refute_send [{:key => 123}, :fetch, :key, nil], 'MESSAGE'
      }
    end
  end
  
  def test_assert_raises
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_raises(ZeroDivisionError){ 666 / 0 }
    end
    assert_raises ArgumentError do
      @tc.assert_raises{}
    end
    assert_raises LocalJumpError do
      @tc.assert_raises(RuntimeError)
    end
    if_flunk "assert_raises seems to contain bug." do
      msg = "[RuntimeError, ZeroDivisionError] expected but nothing was raised"
      assert_equal msg, ex_message{
        @tc.assert_raises([RuntimeError, ZeroDivisionError]){}
      }
      assert_match /\AMSG.\n/, ex_message{
        @tc.assert_raises(RuntimeError, 'MSG'){}
      }
      actual = nil
      actual_message = ex_message{
        @tc.assert_raises(ZeroDivisionError) do
          begin
            raise 'MSG'
          rescue => ex
            actual = ex
            raise ex
          end
        end
      }
      expected = [
        "[ZeroDivisionError] expected, but\n",
        "Class: <RuntimeError>\n",
        "Message: <MSG>\n",
        "---Backtrace---\n",
      ].join('')
      expected << actual.backtrace.reject{|b| b.start_with?(TINYTEST_FEATURE) }.join("\n") << "\n"
      expected << "---------------"
      assert_equal expected, actual_message
    end
  end
  
  def test_refute_raises
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_raises(SystemStackError){ 666 / 0 }
    end
    assert_raises ArgumentError do
      @tc.refute_raises{}
    end
    assert_raises LocalJumpError do
      @tc.refute_raises(RuntimeError)
    end
    if_flunk "refute_raises seems to contain bug." do
      assert_match /\AMSG.\n/, ex_message{
        @tc.refute_raises(ZeroDivisionError, 'MSG'){ 666 / 0 }
      }
      actual = nil
      actual_message = ex_message{
        @tc.refute_raises(RuntimeError) do
          begin
            raise 'MSG'
          rescue => ex
            actual = ex
            raise ex
          end
        end
      }
      expected = [
        "[RuntimeError] not expected, but\n",
        "Class: <RuntimeError>\n",
        "Message: <MSG>\n",
        "---Backtrace---\n",
      ].join('')
      expected << actual.backtrace.reject{|b| b.start_with?(TINYTEST_FEATURE) }.join("\n") << "\n"
      expected << "---------------"
      assert_equal expected, actual_message
    end
  end
  
  def uncaught_throw_ex_class
    throw :hoge
  rescue => ex
    ex.class
  else
    raise Exception, 'must not happen'
  end
  
  def test_assert_throws
    assert_nothing_raised TinyTest::AssertError do
      @tc.assert_throws(:hoge){ throw :hoge }
    end
    assert_raises uncaught_throw_ex_class() do
      @tc.assert_throws(:hoge){ throw :piyo }
    end
    if_flunk "assert_throws seems to contain bug." do
      default = "Expected :hoge to have been thrown."
      assert_equal default, ex_message{
        @tc.assert_throws(:hoge){}
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.assert_throws(:hoge, 'MESSAGE'){}
      }
    end
  end
  
  def test_refute_throws
    assert_nothing_raised TinyTest::AssertError do
      @tc.refute_throws(:hoge){}
    end
    if_flunk "refute_throws seems to contain bug." do
      default = "Expected :hoge to not have been thrown."
      assert_equal default, ex_message{
        @tc.refute_throws(:hoge){ throw :hoge }
      }
      assert_equal "MESSAGE.\n#{default}", ex_message{
        @tc.refute_throws(:hoge, 'MESSAGE'){ throw :hoge }
      }
    end
  end
end

