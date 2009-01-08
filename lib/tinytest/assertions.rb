# 
# Distributes under The modified BSD license.
# 
# Copyright (c) 2009 arikui <http://d.hatena.ne.jp/arikui/>
# All rights reserved.
# 

require 'tinytest/util'
require 'tinytest/exceptions'

module TinyTest
  # ...
  module Assertions
    # ...
    def self.mu_pp(obj)
      s = obj.inspect
      s = s.force_encoding(Encoding.default_external) if defined?(Encoding)
      s
    end
    
    attr_accessor :suite
    
    # ...
    def refer_to_assertion?(backtrace_line)
      meth = get_method_from_backtrace_line(backtrace_line) or return false
      Assertions == meth.owner
    end
    
    # ...
    def assert(cond, message = nil)
      message ||= "Failed assertion, no message given."
      suite.succ_assertion_count
      unless cond
        message = message.call if message.respond_to?(:call)
        raise Assertion, message
      end
      true
    end
    
    # ...
    def assert_block(message = nil)
      assertion_delegate(yield(), message) do
        "Expected block to return true value"
      end
    end
    
    # ...
    def assert_empty(obj, message = nil)
      suite.assertion_count_grouping do
        assert_respond_to obj, :empty?, message
        assertion_delegate(obj.empty?, message) do
          "Expected #{obj.inspect} to be empty"
        end
      end
    end
    
    # ...
    def assert_equal(expected, actual, message = nil)
      assertion_delegate(expected == actual, message) do
        "Expected #{Assertions.mu_pp(expected)}, not #{Assertions.mu_pp(actual)}"
      end
    end
    
    # ...
    def assert_in_delta(expected, actual, delta = 0.001, message = nil)
      n = (expected - actual).abs
      assertion_delegate(delta > n, message) do
        "Expected #{expected} - #{actual} (#{n}) to be < #{delta}"
      end
    end
    
    # ...
    def assert_in_epsilon(a, b, epsilon = 0.001, message = nil)
      assert_in_delta(a, b, [a, b].min * epsilon, message)
    end
    
    # ...
    def assert_includes(collection, obj, message = nil)
      suite.assertion_count_grouping do
        assert_respond_to collection, :include?
        assertion_delegate(collection.include?(obj), message) do
          "Expected #{Assertions.mu_pp(collection)} to include #{Assertions.mu_pp(obj)}"
        end
      end
    end
    
    # ...
    def assert_instance_of(klass, obj, message = nil)
      assertion_delegate(obj.instance_of?(klass), message) do
        "Expected #{Assertions.mu_pp(obj)} to be an instance of #{klass}, not #{obj.class}"
      end
    end
    
    # ...
    def assert_kind_of(klass, obj, message = nil)
      assertion_delegate(obj.kind_of?(klass), message) do
        "Expected #{Assertions.mu_pp(obj)} to be a kind of #{klass}, not #{obj.class}"
      end
    end
    
    # ...
    def assert_match(expected, actual, message = nil)
      assert_respond_to actual, :=~
      expected = /#{Regexp.escape(expected)}/ if expected.kind_of?(String)
      assertion_delegate(actual =~ expected, message) do
        "Expected #{Assertions.mu_pp(act)} to match #{Assertions.mu_pp(exp)}"
      end
    end
    
    # ...
    def assert_nil(obj, message = nil)
      assertion_delegate(obj.nil?, message) do
        "Expected #{Assertions.mu_pp(obj)} to be nil"
      end
    end
    
    # ...
    def assert_operator(operand1, operator, operand2, message = nil)
      assertion_delegate(operand1.__send__(operator, operand2), message) do
        "Expected #{Assertions.mu_pp(o1)} to be #{op} #{Assertions.mu_pp(o2)}"
      end
    end
    
    # ...
    def assert_raise(expected, message = nil)
      yield
    rescue Exception => ex
      detail = exception_details(ex,
        "<#{Assertions.mu_pp(expected)}> exception expected, not")
      assert_kind_of(expected, ex, detail)
      ex
    else
      flunk "#{Assertions.mu_pp(expected)} expected but nothing was raised."
    end
    
    # ...
    def assert_respond_to(obj, method, message = nil)
      assertion_delegate(obj.respond_to?(method), message) do
        "Expected #{Assertions.mu_pp(obj)} (#{obj.class}) to respond to ##{method}"
      end
    end
    
    # ...
    def assert_same(expected, actual, message = nil)
      assertion_delegate(expected.equal?(actual), message) do
        sprintf "Expected %s (0x%x) to be the same as %s (0x%x)",
                expected, expected.object_id,
                actual,   actual.object_id
      end
    end
    
    # ...
    def assert_send(send_args, message = nil)
      assert_send_signature_check(message, *send_args)
    end
    
    # ...
    def assert_send_signature_check(message, receiver, method, *args)
      assertion_delegate(receiver.__send__(method, *args), message) do
        "Expected #{Assertions.mu_pp(receiver)}.#{method}(*#{Assertions.mu_pp(args)}) to return true"
      end
    end
    
    # ...
    def assert_throws(symbol, message = nil)
      default_message = "Expected #{Assertions.mu_pp(symbol)} to have been thrown"
      Util.compat_throw_exception{ yield }
    rescue NameError => ex
      raise ex unless Util.exception_refer_to_throw?(ex)
      assertion_delegate(symbol == ex.name, message) do
        "#{default_message}, not #{ex.name.inspect}"
      end
    else
      flunk default_message
    end
    
    # ...
    def flunk(message = nil)
      assert false, message || "Epic Fail!"
    end
    
    # ...
    def pass(message = nil)
      assert true, message
    end
    
    # ...
    def skip(message = nil)
      raise Skip, message || "Skipped, no message given"
    end
    
    private
    
    def exception_details(ex, msg)
      bt = Util.filter_backtrace(ex.backtrace).
            unshift("---Backtrace---").
            push("---------------")
      [ msg,
        "Class: <#{ex.class}>",
        "Message: <#{ex.message.inspect}>",
        *bt ].join("\n")
    end
    
    def get_method_from_backtrace_line(backtrace_line)
      return unless /:in `(.*)'\Z/ =~ backtrace_line
      name = $1
      return unless respond_to?(name, true)
      method(name)
    end
    
    def assertion_delegate(cond, message, &block)
      assert(cond, build_message(message, &block))
    end
    
    def build_message(message = nil, &default)
      if message
        lambda{
          message = message.to_s
          message << '.' unless message.empty?
          message << "\n#{default.call}."
          message.strip
        }
      else
        lambda{ "#{default.call}." }
      end
    end
  end
end
