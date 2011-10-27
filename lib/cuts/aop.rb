require 'cuts/cut'

require 'pp'

# TODO: Can JointPoint and Target be the same class?

# Aspect Oriented Programming for Ruby using Cuts.
#
class Aspect < Module

  def initialize(&block)
    instance_eval(&block)
    extend self
  end

  def points
    @points ||= {}
  end

  # TODO Should this accept pattern matches as an alternative to the block too?
  #      Eg. join(name, pattern=nil, &block)
  def join(name, &block)
    (points[name] ||= []) << block
  end

end

# TODO: pass actual method instead of using instace_method ?

class Joinpoint
  def initialize(object, base, method, *args, &block)
    @object = object
    @base   = base
    @method = method
    @args   = args
    @block  = block
  end

  def ===(match)
    case match
    when Proc
      match.call(self)
    else # Pattern matches (not supported presently)
      match.to_sym == @method.to_sym
    end
  end

  def ==(sym)
    sym.to_sym == @method.to_sym
  end

  #

  def super
    anc = @object.class.ancestors.find{ |anc| anc.method_defined?(@method) }
    anc.instance_method(@method).bind(@object).call(*@args, &@block)
  end
end


#   module LogAspect
#     extend self
#
#     join :log do |jp|
#       jp.name == :x
#     end
#
#     def log(target)
#       r = target.super
#       ...
#       return r
#     end
#   end
#
#   class X


class Target

  def initialize(aspect, advice, *target, &block)
    @aspect = aspect
    @advice = advice
    @target = target
    @block  = block
  end

  def super
    @aspect.send(@advice, *@target, &@block)
  end

  alias_method :call, :super
end


def cross_cut(klass)

  Cut.new(klass) do

    define_method :__base__ do
      klass 
    end

    def advices
      @advices ||= {} 
    end

    def self.extended(obj)
      base = obj.class #__base__

      # use string for 1.9-, and symbol for 1.9+
      methods = obj.methods +
                obj.public_methods +
                obj.protected_methods +
                obj.private_methods -
                [:advices, 'advices']

      methods.uniq.each do |sym|
        #meth = obj.method(sym)
        define_method(sym) do |*args, &blk|
          jp = Joinpoint.new(self, base, sym, *args) #, &blk)
          # calculate advices on first use.
          unless advices[sym]
            advices[sym] = []
            base.aspects.each do |aspect|
              aspect.points.each do |advice, matches|
                matches.each do |match|
                  if jp === match
                    advices[sym] << [aspect, advice]
                  end
                end
              end
            end
          end
          
          if advices[sym].empty?
            super(*args, &blk)
          else
            target = jp #Target.new(self, sym, *args, &blk)  # Target == JoinPoint ?
            advices[sym].each do |(aspect, advice)|
              target = Target.new(aspect, advice, target)
            end
            target.call #super
          end
        end #define_method
      end #methods
    end #def

  end

end


#

class Class
  #def cut; @cut; end
  def aspects; @aspects ||= []; end

  def apply(aspect)
    if aspects.empty?
      cross_cut(self)
      #(class << self;self;end).class_eval do
      #  alias_method :__new, :new
      #  def new(*args, &block)
      #    CrossConcerns.new(self,*args, &block)
      #  end
      #end
    end
    aspects.unshift(aspect)
  end

end


=begin demo

  class X
    def x; "x"; end
    def y; "y"; end
    def q; "<" + x + ">"; end
  end

  Xa = Aspect.new do
    join :x do |jp|
      jp == :x
    end

    def x(target); '{' + target.super + '}'; end
  end

  X.apply(Xa)

  x1 = X.new
  #print 'X == '          ; p x1
  print 'X == '          ; p x1.class
  print '["q", "y", "x"] == ' ; p x1.public_methods(false)
  print '"{x}" == '      ; p x1.x
  print '"y" == '        ; p x1.y
  print '"<{x}>" == '    ; p x1.q

=end
