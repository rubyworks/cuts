# TITLE:
#
#   Cut-based AOP
#
# DESCRIPTION:
#
#   By definition, a Cut is a *transparent* subclass.
#
# COPYRIGHT:
#
#   Copyright (c) 2005 Thomas Sawyer
#
# LICENSE:
#
#   Ruby License
#
#   This module is free software. You may use, modify, and/or redistribute this
#   software under the same terms as Ruby.
#
#   This program is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#   FOR A PARTICULAR PURPOSE.
#
# AUTHORS:
#
#   - Thomas Sawyer


require 'facets/kernel/object'
#require 'facets/module/modspace' #?
#require 'facets/module/basename' #?


# = Cut
#
# Cut is a low-level AOP facility.
#
#   class X
#     def x; "x"; end
#   end
#
#   cut :C < X do
#     def x; '{' + super + '}'; end
#   end
#
#   X.new.x  #=> "{x}"
#
# Cuts acts as "pre-class". Which depictively is:
#
#   ACut < AClass < ASuperClass
#
# Instantiating AClass effecively instantiates ACut instead,
# but that action is essentially transparent.
#
# == Implementation
#
# This implementation of Cut-based AOP nearly meets the formal concepts.
# This differs slighly in that a Cut is not a class but rather a subclass
# of Module which is included into a single "proxycut" class.
#
# This is very low-level library, as pure-Ruby library go. It overrides
# #new for all classes and included for all modules. If you consider
# the formal usage of Cuts, it essentially usurps any further need for
# callbacks of this kind. Nonetheless, those callback will still be used
# and developers should "play nice" by wrapping such functionality
# rather than overriding. Cuts on the other hand, purposefully overrides.
#
# IMPORTANT To appropriately use Cuts, it should be the first library
# required. One way to faciliate this by adding it to your RUBYOPT.
#
# == Limitations
#
# You can not cut classes formed via literal constructors, such as a
# String defined via "" or a Hash defined via {}. Ruby provides no means
# for overriding literal constructors.

class Cut < Module

  class << self; alias :create :new ; end

  def self.new(cutclass, &block)
    raise ArgumentError, "not a class" unless Class === cutclass
    cut = Cut.create
    cut.module_eval(&block)
    proxy = cutclass.proxycut!
    proxy.module_eval { include cut }
    cut
  end

  Stub = Struct.new(:cutname,:cutclass)

  def self.stub(cutname, cutclass)
    Stub.new(cutname,cutclass)
  end

  #

  def included( base )
    return unless @points
    points = Hash.new{ |h,k| h[k] = [] }
    base.instance_methods.each do |method|
      @points.each do |advice, pointcut|
        if pointcut[method]
          points[advice] << method
        end
      end
    end
    join( points )
  end

  # Define a pointcut as selection of joinpoints (methods in our case)
  # to be advised. The block should return the name of the advice to
  # use when the joinpoint matches, nil or false otherwise.
  #
  #   join :break => { |jp| jp =~ /^log.*/ }
  #
  # This would be very interesting in the context of annotations too.
  #
  #   join :break => { |jp| ann(jp,:class) == String ? :break : nil }
  #
  # Takes a hash of advice => method for joining the advice to the method.
  #
  #--
  # TODO Add wildcards for method points.
  # TODO Should the method() be 1st class?
  #++

  def join( points=nil )
    @points ||= {}
    return @points unless points
    code = ''
    points.each do |advice, pointcut|
      case pointcut
      when Regexp
        @points[advice] = lambda { |jp| pointcut =~ jp }
      when Proc
        @points[advice] = pointcut
      else
        [pointcut].flatten.uniq.each do |method|
          code << %{
            def #{method}(*args,&block)
              #{advice}( target(:"#{method}"){ super } )
            end
          }
          #Thought about putting advice in separate namespace (option?)
          #ObjectSpace._id2ref(#{object_id}).advice.#{advice}( this(:"#{method}"){ super } )
        end
      end
    end
    module_eval code
  end

#   # Store advice in separate namespace.
#
#   def advice(&adv)
#     @advice ||= Module.new { extend self }
#     @advice.module_eval &adv if adv
#     @advice
#   end

  # Prevent infinite loop.

  def method_added(name)
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
    cut = Cut.create
    mod.const_set(cutname, cut)  # <<- this is what we don't have in Cut.new
    cut.module_eval(&block)
    proxy = cutclass.proxycut!
    proxy.module_eval { include cut }

    cut
  end

  #

  def target( name, &superblock )
    target = method(name)
    (class << target; self; end).class_eval do
      define_method( :super ){ superblock.call }
    end
    target
  end

end


class Symbol
  #--
  # This is a bit of a hack.
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


class Class

  # Master cutting class (contains all cuts)
  #--
  # TODO This should not automatically create the cutclass.
  #++
  def proxycut
    @proxycut
  end

  def proxycut!
    return @proxycut if @proxycut
    @proxycut = const_set( 'CUT', Class._new_without_cut(self) )
    klass = self
    @proxycut.class_eval {
      define_method(:class){ klass }
      define_method(:object_class){ klass }
    }
    @proxycut
  end

  #protected
  def proxycut=(pc)
    @proxycut = pc
  end

  # List of cuts in outer to inner order. Eg.
  #
  #   [ Cut2, Cut1 ]
  #
  def cuts
    return [] unless proxycut
    (proxycut.ancestors - ancestors)[1..-1]
  end
  alias :predecessors :cuts

  alias :_new_without_cut :new

  def new(*args,&block)
    if @proxycut
      @proxycut._new_without_cut(*args,&block)
    else
      _new_without_cut(*args,&block)
    end
  end

  alias :_allocate_without_cut :allocate

  def allocate(*args,&block)
    if @proxycut
      @proxycut._allocate_without_cut(*args,&block)
    else
      _allocate_without_cut(*args,&block)
    end
  end

  # When a method is added, check to see if
  # cut applies to it, and if so join it.

  def method_added( method )
    cuts.each do |cut|
      next unless points = cut.join
      points.each do |advice, pointcut|
        if pointcut[method.to_s]
          cut.join( advice => method )
        end
      end
    end
  end

  #

  def inherited( base )
    if proxycut
      cuts.reverse_each { |c| base.module_eval { include c } }
    end
  end

end


class Module

  # When a module is included, we need to look at all it's
  # methods and see if they match any cut points and if
  # so join them.

  def included( base )
    base.cuts.each do |cut|
      cut.included(self)
      #next unless base_points = cut.join
      #points = Hash.new{ |h,k| h[k] = [] }
      #instance_methods.each do |method|
      #  base_points.each do |advice, pointcut|
      #    if advice = pointcut[method.to_s]
      #      points[advice] << method
      #    end
      #  end
      #end
      #cut.join( points )
    end
  end

end


#
# Test
#

=begin test

  require 'test/unit'

  # Test basic functionality.

  class TestCut1 < Test::Unit::TestCase

    class F
      def f ; "f" ; end
    end

    cut :G < F do
      def f; '<'+super+'>' ; end
    end

    def test_1_01
      f = F.new
      assert_equal( F, f.class )
      assert_equal( F, f.object_class )
      assert_equal( "<f>", f.f )
    end

    def test_1_02
      assert( G )
      assert_equal( "TestCut1::G", G.name )
    end

  end

  # Test multiple cuts.

  class TestCut2 < Test::Unit::TestCase

    class F
      def f ; "f" ; end
    end

    cut :G < F do
      def f; '<'+super+'>' ; end
    end

    cut :Q < F do
      def f; '['+super+']'; end
    end

    def test_2_01
      f = F.new
      assert_equal( F, f.class )
      assert_equal( F, f.object_class )
      assert_equal( "[<f>]", f.f )
    end

    def test_2_02
      assert( G )
      assert_equal( "TestCut2::G", G.name )
      assert( Q )
      assert_equal( "TestCut2::Q", Q.name )
    end

    def test_2_03
      assert_equal( [Q, G], F.cuts )
      assert_equal( [Q, G], F.predecessors )
    end

  end

  #

  class TestCut3 < Test::Unit::TestCase

    class C
      def r1; "r1"; end
    end

    cut :A < C do
      def r1
        b1( target( :r1 ){ super } )
      end
      def b1( target )
        '(' + target.super + ')'
      end
    end

    def test_3_01
      c = C.new
      assert_equal( '(r1)', c.r1 )
    end

  end

  # Test the addition of new methods and module inclusions
  # after the cut is defined with dynamic joining.

  class TestCut4 < Test::Unit::TestCase

    class C
      def r1; "r1"; end
      def r2; "r2"; end
      def j1; "j1"; end
      def j2; "j2"; end
    end

    cut :A < C do

      join :wrappy => lambda { |jp| /^r/ =~ jp }
      join :square => :j1, :flare => :j2

      def wrappy( target )
        '{'+target.super+'}'
      end

      def square(target) '['+target.super+']' end
      def flare(target) '*'+target.super+'*' end
    end

    class C
      def r3; "r3"; end
    end

    module M
      def r4 ; "r4"; end
    end

    class C
      include M
    end

    def test_4_01
      c = C.new
      assert_equal( '{r1}', c.r1 )
      assert_equal( '{r2}', c.r2 )
      assert_equal( '{r3}', c.r3 )
      assert_equal( '{r4}', c.r4 )
    end

    def test_4_02
      c = C.new
      assert_equal( '[j1]', c.j1 )
      assert_equal( '*j2*', c.j2 )
    end

  end

  # Test subclassing.

  class TestCut5 < Test::Unit::TestCase

    class C
      def r1; "r1"; end
      def r2; "r2"; end
    end

    cut :C1 < C do
      join :wrap1 => [:r1, :r2]

      def wrap1( target )
        '{' + target.super + '}'
      end
    end

    cut :C2 < C do
      join :wrap2 => [:r1, :r2]

      def wrap2( target )
        '[' + target.super + ']'
      end
    end

    class D < C
      def r1; '<' + super + '>'; end
    end

    def test_5_01
      c = C.new
      assert_equal( '[{r1}]', c.r1 )
      assert_equal( '[{r2}]', c.r2 )
      d = D.new
      assert_equal( '<[{r1}]>', d.r1 )
      assert_equal( '[{r2}]', d.r2 )
    end

  end

=end
