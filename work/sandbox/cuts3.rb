# TITLE:
#
#   Super Simple Cuts
#
# SUMMARY:
#
#   Cut-based AOP in it's most basic form.

require 'facets/kernel/object'

# This is the basic model. If we want:
#
#   class Klass
#     def x; "x"; end
#   end
#
#   cut KlassCut < Klass
#     def x; '{' + super + '}'; end
#   end
#
# We cut it like so:
#
#   class Klass
#     def self.new
#       KlassCut.new
#     end
#   end
#
#   class KlassCut
#     def self.new
#       Class.instance_method(:new).bind(self).call
#     end
#   end
#
#   p Klass.new.x
#
# This is simple and relatvely robust. It lacks two general features of
# a good AOP solution however. 1) It relies on +super+ in advice rather
# than passing in a more versitle +target+ object. And 2) it doesn't
# support joins, which allow targeted methods to share the same advice.

class Cut < Module

  class << self; alias_method :create, :new; end

  def self.new(klass, &block)
    next_class = klass.cuts.empty? ? klass : klass.cuts.first

    cutclass = Class.new(next_class)
    cut      = create(&block)

    cutclass.class_eval do
      define_method(:__class__){ klass }
      define_method(:__cut__){ cut }

      m1 = public_instance_methods
      m2 = protected_instance_methods
      m3 = private_instance_methods

      (m1 + m2 + m3).each do |meth|
      #instance_methods.each do |meth|
        undef_method(meth) unless meth.to_s =~ /^__|initialize|p/
      end

      define_method(:class){ klass }
      define_method(:object_class){ klass }
    end

    # Method missing for cutclass.

    cutclass.class_eval do
      def method_missing(sym, *args, &blk)
        result = nil

        target = __class__.instance_method(sym).bind(self)  # Not going to work if another cut!!!

        (class << target; self; end).class_eval do
          define_method( :super ){ call(*args, &blk) }
        end

        advices = []

        __cut__.joinpoints.each do |advice, point|
          case point
          when Proc
            advices << advice if point.call(sym)
          else
            advices << advice if point.to_sym == sym
          end
        end

        if advices.empty?
          result = target.super
        else
          target = advices.inject(target) do |retarget, advice|
            supercall = lambda{ __cut__.send(advice, retarget) }
            target = retarget.to_proc.dup
            (class << target; self; end).class_eval do
              define_method(:super) { supercall.call }
            end
            target
          end

          result = target.super(*args, &blk)
        end

        return result
      end
    end

    def cutclass.new
      Class.instance_method(:new).bind(self).call
    end

    klass.cuts.unshift(cutclass)

    (class << klass; self; end).send(:define_method, :cut) do
      cutclass
    end

    def klass.new(*a, &b)
      cut.new(*a, &b)
    end

    return cutclass
  end


  attr :joinpoints

  def initialize(&block)
    @joinpoints = {}
    extend self
    class_eval(&block)
  end

  def join(hash)
    @joinpoints.update(hash)
  end


  #

  Stub = Struct.new(:cutname,:cutclass)

  def self.stub(cutname, cutclass)
    Stub.new(cutname,cutclass)
  end

end


class Class
  def cuts
    @cuts ||= []
  end
end


class Method
  alias_method :super, :call
end

#

class Symbol
  #--
  # This is a hack.
  #++

  #alias :_op_lt_without_cuts :<

  def <(cutclass)
    if Class === cutclass
      Cut.stub(self,cutclass)
    else
      raise NoMethodError, "undefined method `<' for :#{self}:Symbol"
      #_op_lt_without_cuts(cut_class)
    end
  end
end

#class Module
module Kernel

  #

  def cut( cutclass, &block )
    case cutclass
    when Cut::Stub
      cutname = cutclass.cutname
      cutclass = cutclass.cutclass
    else
      cutname = nil
    end

    # How to handle main, but not other instance spaces?
    mod = (Module === self ? self : Object)

    # We don't call Cut.new b/c we want to set the module name
    #cut = Cut.new(cutclass,&block)
    cut = Cut.new(cutclass, &block)
    mod.const_set(cutname, cut)  # <<- this is what we don't have in Cut.new
    #cut.module_eval(&block)
    #proxy = cutclass.proxycut!
    #proxy.module_eval { include cut }

    cut
  end

end



#
# Basic Test
#

if $0 == __FILE__

  class X
    def x; "x"; end
  end

  Xc = Cut.new(X) do
    join :x => lambda { |jp| jp == :x }

    def x(target); '{' + target.super + '}'; end
  end

  x1 = X.new
  p x1.x
  p x1.class

end
