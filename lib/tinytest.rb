# 
# Distributes under The modified BSD license.
# 
# Copyright (c) 2009 arikui <http://d.hatena.ne.jp/arikui/>
# All rights reserved.
# 

require 'benchmark'
require 'tinytest/compat' unless RUBY_VERSION >= '1.9.1'

module TinyTest
  # exception which express assertion.
  class AssertError < RuntimeError
    ;
  end
  
  # Exception which express skipping.
  class SkipError < AssertError
    ;
  end
  
  class Runner
    # Receives _args_ as a keyword-argument-hash.
    # 
    # [testname] matcher for testing method names.
    #            (Default; /\Atest/)
    # [testcase] matcher for TestCase's subclass names.
    #            (Default; matchs to any name)
    # [verbose] run on verbose mode or not;
    #           set value to attribute #verbose.
    # 
    # matcher means a object which is enable to respond to #===;
    # it receives a test method name or testcase class and
    # returns a the argument matches or not.
    # 
    def initialize(args = {})
      @reporter = args.fetch(:reporter, Reporter.new)
      @testname_matcher = args.fetch(:testname, /\Atest/)
      tc_matcher = args.fetch(:testcase, /./)
      unless tc_matcher.respond_to?(:call)
        @testcase_matcher = lambda{|klass| tc_matcher === klass.name }
      else
        @testcase_matcher = tc_matcher
      end
      self.verbose = args.fetch(:verbose, false)
    end
    
    attr_accessor :verbose
    
    # Executes each test.
    def run
      @reporter.load_suite($0)
      n_assertions, results, bench = run_suites(collect_suites())
      if self.verbose
        @reporter.mark_results_with_times(results)
      else
        @reporter.mark_results(results)
      end
      @reporter.running_times(bench)
      not_succeededs = results.reject{|r| r.success? }
      if not_succeededs.empty?
        @reporter.blank
      else
        @reporter.error_reports(not_succeededs)
      end
      f, e, s = count_suiteresults_types(results)
      @reporter.counts_report(results.size, n_assertions, f, e, s)
      f + e unless results.empty?
    end
    
    private
    
    def each_class(root = nil)
      ObjectSpace.each_object(Class) do |c|
        next unless c < root if root
        yield(c)
      end
    end
    
    def collect_suites
      suites = []
      each_class TestCase do |c|
        next unless @testcase_matcher === c
        c.public_instance_methods(true).each do |name|
          suites << Suite.new(c.new, name) if @testname_matcher === name
        end
      end
      suites
    end
    
    def run_suites(suites)
      n_assertions = 0
      results = []
      benchmark = Benchmark.measure{
        suites.each do |suite|
          n_assertions += suite.count_assertions{ results << suite.execute }
        end
      }
      return n_assertions, results, benchmark
    end
    
    def count_suiteresults_types(results)
      results_chars = results.map{|r| r.char }
      ['F', 'E', 'S'].map{|c| results_chars.count(c) }
    end
  end
  
  class Reporter
    def initialize(out = $stdout)
      @f = out
    end
    
    def blank
      @f.puts
    end
    
    def load_suite(script)
      @f.puts "Loaded suite #{script.sub(/\.rb\Z/, '')}"
      @f.puts "Started"
    end
    
    def mark_results(results)
      @f.puts results.map{|r| r.char }.join('')
    end
    
    def mark_results_with_times(results)
      unless results.empty?
        vals = results.map{|r|
          ["#{r.suite.inspect}:", r.benchmark.real, r.char]
        }
        w = vals.max_by{|a| a.first.size }.first.size
        fmt = "%-#{w}s %.2f sec: %s"
        result_descriptions = vals.map{|a| fmt % a }
      else
        result_descriptions = []
      end
      blank
      @f.puts result_descriptions
      blank
    end
    
    def running_times(benchmark)
      @f.puts "Finished in %.6f seconds." % benchmark.real
    end
    
    def error_reports(not_succeeded_results)
      not_succeeded_results.each.with_index do |r, i|
        blank
        @f.puts "%3d) #{r.report}" % i.succ
        blank
      end
    end
    
    def counts_report(n_tests, n_assertions, n_failures, n_errors, n_skips)
      @f.puts [
        "#{n_tests} tests",
        "#{n_assertions} assertions",
        "#{n_failures} failures",
        "#{n_errors} errors",
        "#{n_skips} skips"
      ].join(', ')
    end
  end
  
  class Suite
    def initialize(testcase, testname)
      @testcase = testcase
      @testname = testname
      @testcase.bind_testsuite(self)
      @state = :base
      @count_table = { :base => 0, :counting => 0, :grouping => 0 }
    end
    
    attr_reader :testcase
    attr_reader :testname
    
    def inspect
      "#{testcase.class}##{testname}"
    end
    
    def execute
      report = nil
      benchmark = Benchmark.measure{ report = execute_report() }
      SuiteResult.new(self, benchmark, report)
    end
    
    private
    
    def execute_report
      begin
        @testcase.setup
        @testcase.send @testname
        nil
      ensure
        @testcase.teardown
      end
    rescue Exception => ex
      filename, = @testcase.method(@testname).source_location
      bt = prune_backtrace(ex.backtrace, filename, nil, @testname)
      location = parse_backtrace(bt.last).take(2).join(':')
      tag, repo = case ex
        when SkipError then ["Skipped:", [ex.message]]
        when AssertError then ["Failure:", [ex.message]]
        else ["Error:", ["#{ex.class}: #{ex.message}",
                         *bt.map{|b| "    #{b}" }]]
      end
      repo.unshift "#{@testname}(#{@testcase.class}) [#{location}]:"
      repo.unshift tag
      repo.join("\n") << "\n"
    end
    
    # Sometimes, 3rd paren part is omitted by older Ruby1.9.1
    CALLER_RE = /\A(.+):(\d+)(?::in `(.+)'|\Z)/  #'
    
    def parse_backtrace(line)
      fname, lineno, meth = line.match(CALLER_RE).captures
      meth ||= '__unknown__'  #for older Ruby1.9.1
      return fname, Integer(lineno), meth.intern
    end
    
    def prune_backtrace(org, filename, lineno, method)
      term = [filename, lineno, method]
      idx = org.index{|b|
        parse_backtrace(b).zip(term).all?{|e, t| t ? e == t : true }
      }
      idx ? org.take(idx.succ) : org
    end
    
    public
    
    def count_assertions(&block)
      state_shunting(:counting, &block)
      @count_table[:counting]
    end
    
    def succ_assertion_count
      @count_table[@state] += 1
    end
    
    def assertion_count_grouping(&block)
      state_shunting(:grouping, &block)
    ensure
      @count_table[:counting] += 1 unless @count_table[:grouping].zero?
    end
    
    private
    
    def state_shunting(state, init_val = 0, &block)
      shunted, @state = @state, state
      @count_table[state] = init_val
      yield()
    ensure
      @state = shunted
    end
  end
  
  class SuiteResult
    SUCCESS_CHAR = '.'
    
    def initialize(suite, benchmark, report = nil)
      @suite     = suite
      @benchmark = benchmark
      @report    = report
      @char      = @report ? @report[0, 1] : SUCCESS_CHAR
      @success_p = !@report
    end
    
    attr_reader :suite
    attr_reader :benchmark
    attr_reader :report
    attr_reader :char
    
    def inspect
      super.split(/\s+/).first << "[#{char}]>"
    end
    
    def success?
      @success_p
    end
  end
  
  class TestCase
    def setup
      ;
    end
    
    def teardown
      ;
    end
    
    def bind_testsuite(suite)
      define_singleton_method(:suite){ suite }
    end
    
    def assert(cond, message = nil)
      message ||= "Failed assertion, no message given."
      suite.succ_assertion_count
      unless cond
        message = message.call if message.respond_to?(:call)
        raise AssertError, message
      end
      true
    end
    
    def refute(cond, message = nil)
      not assert(!cond, message || "Failed refutation, no message given")
    end
    
    def flunk(message = nil)
      assert(false, message || "Epic Fail!")
    end
    
    def pass(message = nil)
      assert(true)
    end
    
    def skip(message = nil)
      raise(SkipError, message || "Skipped, no message given")
    end
    
    def assert_block(message = nil, &block)
      assertion_frame(yield(), message) do
        "Expected block to return a value evaluated as true"
      end
    end
    
    def refute_block(message = nil, &block)
      refutation_frame(yield(), message) do
        "Expected block to return a value evaluated as false"
      end
    end
    
    def assert_equal(expected, actual, message = nil)
      assertion_frame(expected == actual, message) do
        "Expected #{expected.inspect}, not #{actual.inspect}"
      end
    end
    
    def refute_equal(expected, actual, message = nil)
      refutation_frame(expected == actual, message) do
        "Expected #{actual.inspect} to not be equal to #{expected.inspect}"
      end
    end
    
    def assert_instance_of(klass, object, message = nil)
      assertion_frame(object.instance_of?(klass), message) do
        "Expected #{object.inspect} to be an instance of #{klass}"
      end
    end
    
    def refute_instance_of(klass, object, message = nil)
      refutation_frame(object.instance_of?(klass), message) do
        "Expected #{object.inspect} to not be an instance of #{klass}"
      end
    end
    
    def assert_kind_of(klass, object, message = nil)
      assertion_frame(object.kind_of?(klass), message) do
        "Expected #{object.inspect} to be a kind of #{klass}"
      end
    end
    
    def refute_kind_of(klass, object, message = nil)
      refutation_frame(object.kind_of?(klass), message) do
        "Expected #{object.inspect} to not be a kind of #{klass}"
      end
    end
    
    def assert_match(expected, actual, message = nil)
      cond = assertion_match_test(expected, actual)
      assertion_frame(cond, message) do
        "Expected #{expected.inspect} to match #{actual.inspect}"
      end
    end
    
    def refute_match(expected, actual, message = nil)
      cond = assertion_match_test(expected, actual)
      refutation_frame(cond, message) do
        "Expected #{expected.inspect} to not match #{actual.inspect}"
      end
    end
    
    def assert_nil(object, message = nil)
      assertion_frame(object.nil?, message) do
        "Expected #{object.inspect} to be nil"
      end
    end
    
    def refute_nil(object, message = nil)
      refutation_frame(object.nil?, message) do
        "Expected #{object.inspect} to not be nil"
      end
    end
    
    def assert_same(expected, actual, message = nil)
      assertion_frame(expected.equal?(actual), message) do
        sprintf(
          "Expected %s (0x%x) to be the same as %s (0x%x)",
          expected.inspect, expected.object_id,
          actual.inspect,   actual.object_id
        )
      end
    end
    
    def refute_same(expected, actual, message = nil)
      refutation_frame(expected.equal?(actual), message) do
        "Expected #{expected.inspect} to not be the same as #{actual.inspect}"
      end
    end
    
    def assert_respond_to(object, method, message = nil)
      assertion_frame(object.respond_to?(method), message) do
        "Expected #{object.inspect} (#{object.class}) to respond to #{method}"
      end
    end
    
    def refute_respond_to(object, method, message = nil)
      refutation_frame(object.respond_to?(method), message) do
        "Expected #{object.inspect} to not respond to #{method}"
      end
    end
    
    def assert_empty(object, message = nil)
      suite.assertion_count_grouping do
        assert_respond_to(object, :empty?, message)
        assertion_frame(object.empty?, message) do
          "Expected #{object.inspect} to be empty"
        end
      end
    end
    
    def refute_empty(object, message = nil)
      suite.assertion_count_grouping do
        assert_respond_to(object, :empty?, message)
        refutation_frame(object.empty?, message) do
          "Expected #{object.inspect} to not be empty"
        end
      end
    end
    
    def assert_includes(collection, object, message = nil)
      suite.assertion_count_grouping do
        assert_respond_to(collection, :include?, message)
        assertion_frame(collection.include?(object), message) do
          "Expected #{collection.inspect} to include #{object.inspect}"
        end
      end
    end
    
    def refute_includes(collection, object, message = nil)
      suite.assertion_count_grouping do
        assert_respond_to(collection, :include?, message)
        refutation_frame(collection.include?(object), message) do
          "Expected #{collection.inspect} to not include #{object.inspect}"
        end
      end
    end
    
    def assert_in_delta(expected, actual, delta = 0.001, message = nil)
      expected, actual, delta, message = normalize_in_delta_epsilon_arguments(
        expected, actual, delta, message
      )
      gap = (expected - actual).abs
      assertion_frame(delta >= gap, message) do
        "Expected #{expected} - #{actual} (#{gap}) to be < #{delta}"
      end
    end
    
    def refute_in_delta(expected, actual, delta = 0.001, message = nil)
      expected, actual, delta, message = normalize_in_delta_epsilon_arguments(
        expected, actual, delta, message
      )
      gap = (expected - actual).abs
      refutation_frame(delta >= gap, message) do
        "Expected #{expected} - #{actual} (#{gap}) to not be < #{delta}"
      end
    end
    
    def assert_in_epsilon(a, b, epsilon = 0.001, message = nil)
      a, b, epsilon, message = normalize_in_delta_epsilon_arguments(
        a, b, epsilon, message
      )
      assert_in_delta(a, b, [a, b].min * epsilon, message)
    end
    
    def refute_in_epsilon(a, b, epsilon = 0.001, message = nil)
      a, b, epsilon, message = normalize_in_delta_epsilon_arguments(
        a, b, epsilon, message
      )
      refute_in_delta(a, b, [a, b].min * epsilon, message)
    end
    
    def assert_operator(operand1, operator, operand2, message = nil)
      assertion_frame(operand1.__send__(operator, operand2), message) do
        "Expected #{operand1.inspect} to be #{operator} #{operand2.inspect}"
      end
    end
    
    def refute_operator(operand1, operator, operand2, message = nil)
      refutation_frame(operand1.__send__(operator, operand2), message) do
        "Expected #{operand1.inspect} to not be #{operator} #{operand2.inspect}"
      end
    end
    
    def assert_send(send_concerneds, message = nil)
      assertion_frame(assertion_send_dispatch(*send_concerneds), message) do
        inspection = assertion_send_inspection(*send_concerneds)
        "Expected #{inspection} to be evaluated as true"
      end
    end
    
    def refute_send(send_concerneds, message = nil)
      refutation_frame(assertion_send_dispatch(*send_concerneds), message) do
        inspection = assertion_send_inspection(*send_concerneds)
        "Expected #{inspection} to be evaluated as false"
      end
    end
    
    RAISES_MSG_HOOK = lambda{|msg| msg.sub(/\.\Z/, '') }
    
    def assert_raises(exceptions, message = nil, &block)
      exceptions = normalize_raises_arguments(exceptions, &block)
      begin
        yield()
      rescue Exception => actual
        cond = exceptions.any?{|e| actual.kind_of?(e) }
        assertion_frame(cond, message, RAISES_MSG_HOOK) do
          "#{exceptions.inspect} expected, but\n#{describe_exception(actual)}"
        end
      else
        assertion_frame(false, message, RAISES_MSG_HOOK) do
          "#{exceptions.inspect} expected but nothing was raised"
        end
      end
    end
    
    def refute_raises(exceptions, message = nil, &block)
      exceptions = normalize_raises_arguments(exceptions, &block)
      begin
        yield()
      rescue Exception => actual
        cond = exceptions.any?{|e| actual.kind_of?(e) }
        refutation_frame(cond, message, RAISES_MSG_HOOK) do
          "#{exceptions.inspect} not expected, but\n#{describe_exception(actual)}"
        end
      end
    end
    
    def assert_throws(tag, message = nil, &block)
      msg = "Expected #{tag.inspect} to have been thrown"
      thrown = true
      catch(tag) do
        yield(tag)
        thrown = false
      end
      assertion_frame(thrown, message){ msg }
    end
    
    def refute_throws(tag, message = nil, &block)
      thrown = true
      catch(tag) do
        yield(tag)
        thrown = false
      end
      refutation_frame(thrown, message) do
        "Expected #{tag.inspect} to not have been thrown"
      end
    end
    
    private
    
    def assertion_match_test(expected, actual)
      expected =~ actual
    rescue TypeError
      /#{Regexp.escape(expected)}/ =~ actual
    end
    
    def normalize_in_delta_epsilon_arguments(expected, actual, delta, message)
      unless message
        begin
          delta = Float(delta)
        rescue TypeError, ArgumentError
          delta, message = 0.001, delta
        end
      end
      return expected, actual, Float(delta), message
    end
    
    def assertion_send_dispatch(receiver, message, *args)
      receiver.__send__(message, *args)
    end
    
    def assertion_send_inspection(receiver, message, *args)
      "#{receiver.inspect}.#{message}(#{args.map{|e| e.inspect }.join(', ')})"
    end
    
    def normalize_raises_arguments(exceptions, &block)
      exceptions = [*exceptions]
      raise ArgumentError, "wrong number of arguments(0 for 1)" if exceptions.empty?
      raise LocalJumpError, "no block given (yield)" unless block_given?
      exceptions
    end
    
    def describe_exception(ex)
      bt = ex.backtrace.reject{|s| s.start_with?(__FILE__) }
      [
        "Class: <#{ex.class}>",
        "Message: <#{ex.message}>",
        "---Backtrace---",
        bt.join("\n"),
        "---------------",
      ].join("\n")
    end
    
    def assertion_frame(cond, message, hook = nil, &default_message)
      assert(cond, build_message(message, hook, &default_message))
    end
    
    def refutation_frame(cond, message, hook = nil, &default_message)
      refute(cond, build_message(message, hook, &default_message))
    end
    
    def build_message(message = nil, hook_end = nil, &default)
      if message
        lambda{
          message = message.to_s
          message << '.' unless message.empty?
          message << "\n#{default.call}."
          message.strip!
          message = hook_end.call(message) if hook_end
          message
        }
      else
        lambda{
          message = "#{default.call}."
          message = hook_end.call(message) if hook_end
          message
        }
      end
    end
  end
end


