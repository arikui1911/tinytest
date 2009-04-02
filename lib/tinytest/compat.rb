# 
# Distributes under The modified BSD license.
# 
# Copyright (c) 2009 arikui <http://d.hatena.ne.jp/arikui/>
# All rights reserved.
# 
# 
# This file does mockey-patching to built-in classes
# in order to insure backward compatibilities of Ruby.
# 
# There are some modification only to drive TinyTest.

unless Module.method_defined?(:source_location)
  class Module
    CALLER_RE = /\A(.+):(\d+)(?::in `(.+)'|\Z)/ #'
    
    METHOD_ADDED_RECORDS = {}
    
    def method_added(name)
      filename, lineno = caller[0].match(CALLER_RE).captures
      lineno = Integer(lineno)
      METHOD_ADDED_RECORDS[name] = [filename, lineno]
    end
  end
  
  class Method
    def source_location
      ::Module::METHOD_ADDED_RECORDS[name.intern]
    end
  end
end

unless Method.method_defined?(:name)
  class Object
    org = instance_method(:method)
    define_method :method do |name|
      meth = org.bind(self).call(name)
      ::Method::METHODS_NAME_RECORDS[meth] = name.to_s
      meth
    end
  end
  
  class Method
    METHODS_NAME_RECORDS = {}
    
    def name
      METHODS_NAME_RECORDS[self]
    end
  end
end

unless Object.method_defined?(:define_singleton_method)
  class Object
    def define_singleton_method(*args, &block)
      (class << self ; self ; end).class_eval{ define_method(*args, &block) }
    end
  end
end

unless lambda{|n| n.zero? } === 0
  class Proc
    alias === call
  end
end

unless Proc.method_defined?(:yield)
  class Proc
    alias yield call
  end
end

unless Enumerable.method_defined?(:count)
  module Enumerable
    def count(item)
      select{|e| e == item }.size
    end
  end
end

unless String.method_defined?(:start_with?)
  class String
    def start_with?(str)
      i = index(str) and i == 0 ? true : false
    end
  end
end

begin
  [].index{}
rescue ArgumentError
  class Array
    ORG_INDEX = instance_method(:index)
    
    #incomplete: unable to search nil
    def index(val = nil)
      org = ORG_INDEX.bind(self)
      return org.call(val) if val
      each_with_index do |item, i|
        return i if yield(item)
      end
      nil
    end
  end
end

unless Enumerable.method_defined?(:take)
  module Enumerable
    def take(n)
      raise ArgumentError, 'attempt to take negative size' if n < 0
      taken = []
      each_with_index do |item, i|
        break if i == n
        taken << item
      end
      taken
    end
  end
end

unless Enumerable.method_defined?(:max_by)
  module Enumerable
    def max_by(&block)
      sort_by(&block).last
    end
  end
end

