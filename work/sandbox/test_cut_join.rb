require 'test/unit'
require 'cuts'

class TestCut1 < Test::Unit::TestCase

  class F
    def f ; "f" ; end
  end

  cut :G < F do
    #join :f => :f
    def f(target); '<'+target.super+'>' ; end
  end

  def test_1_01
    f = F.new
    assert_equal( "<f>", f.f )
    assert_equal( F, f.class )
    assert_equal( F, f.object_class )
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
    #join :f => :f
    def f(target); '<'+target.super+'>' ; end
  end

  cut :Q < F do
    #join :f => :f
    def f(target); '['+target.super+']'; end
  end

  def test_2_01
    assert_equal( [Q, G], F.cuts )
    assert_equal( [Q, G], F.predecessors )
  end

  def test_2_02
    f = F.new
    assert_equal( F, f.class )
    assert_equal( F, f.object_class )
    assert_equal( "[<f>]", f.f )
  end

  def test_2_03
    assert( G )
    assert_equal( "TestCut2::G", G.name )
    assert( Q )
    assert_equal( "TestCut2::Q", Q.name )
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

