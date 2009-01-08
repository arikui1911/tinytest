# 
# Distributes under The modified BSD license.
# 
# Copyright (c) 2009 arikui <http://d.hatena.ne.jp/arikui/>
# All rights reserved.
# 

require 'pathname'

module TinyTest
  # Contain some dirty duty.
  # 
  module Util
    file = Pathname.new(__FILE__)
    if RUBY_VERSION >= '1.9.0'
      file = file.expand_path
    elsif file.relative?
      file = file.expand_path
      file = Pathname.new(
        File.join('.', file.relative_path_from(Pathname.pwd))
      ) unless file.relative?
    end
    TINY_DIR = file.realpath.parent.parent.to_s
    
    if /mswin(?!ce)|mingw|cygwin|bccwin/ =~ RUBY_PLATFORM
      re = /\A#{Regexp.escape(TINY_DIR)}/oi
    else
      re = /\A#{Regexp.escape(TINY_DIR)}/o
    end
    
    FILTERS = [
      lambda{|b|
        rest = []
        b.each do |s|
          break if re =~ s
          rest << s
        end
        rest
      },
      lambda{|b| b.reject{|s| re =~ s } },
      lambda{|b| b.dup },
    ]
    
    # Correct backtrace; makes it do not refer to tinytest files.
    # 
    def self.filter_backtrace(bt)
      return ["No backtrace"] unless bt
      result = nil
      FILTERS.each do |filter|
        result = filter.call(bt)
        break unless result.empty?
      end
      result
    end
    
    # Measure used time by block.
    # 
    def self.measure_time
      t = Time.now
      yield
      Time.now - t
    end
    
    THROW_EXCEPTION = (RUBY_VERSION >= '1.9.0' ? ArgumentError : NameError)
    THROW_EXCEPTION_PREFIX = 'uncaught throw'
    
    # Handling uncaught throw by only Ruby1.8 way.
    # -> yield() or NameError
    # 
    def self.compat_throw_exception
      yield
    rescue THROW_EXCEPTION => ex
      raise ex if ex.instance_of?(NameError)
      raise ex unless /\A#{THROW_EXCEPTION_PREFIX} :/o =~ ex.message
      name = $'.intern
      e = NameError.new("#{THROW_EXCEPTION_PREFIX} #{name.inspect}", name)
      e.set_backtrace ex.backtrace
      raise e
    end
    
    # Check a exception refers to uncaught throw or not.
    # 
    def self.exception_refer_to_throw?(ex)
      /\A#{THROW_EXCEPTION_PREFIX}/o =~ ex.message
    end
    
    # Wrap object which respond to :<< and
    # behave as IO output.
    # 
    class OutputProxy
      # DO NOT check obj's message-respondance about :<< .
      # 
      def initialize(obj)
        @obj = obj
      end
      
      # refer Kernel#puts
      # 
      def puts(*args)
        args.push '' if args.empty?
        args.each{|arg| print arg.chomp, "\n" }
      end
      
      # refer Kernel#print
      # 
      def print(*args)
        args.each{|arg| @obj << arg }
      end
      
      # refer Kernel#printf
      # 
      def printf(*args)
        print sprintf(*args)
      end
      
      # Set wrapee's attribute, sync, temporarily in only block.
      # 
      def escape_sync(bool)
        return yield unless respond_to_sync?
        begin
          old = @obj.sync
          @obj.sync = bool
          yield
        ensure
          @obj.sync = old
        end
      end
      
      private
      
      def respond_to_sync?
        @obj.respond_to?(:sync) || @obj.respond_to?(:sync=)
      end
    end
  end
end
