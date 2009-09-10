require 'test/unit'
require 'cuts'

class TestCut < Test::Unit::TestCase

  class X
    def x; "x"; end
  end

  Xc = Cut.new(X) do
    def x; '{' + super + '}'; end
  end

  def test_method_is_wrapped_by_advice
      o = X.new
      assert_equal("{x}", o.x)
  end

end

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

