require 'microtest'
require 'ae'
require 'cuts'

#
class TestCutNew < MicroTest::TestCase

  class X
    def x; "x"; end
  end

  Xc = Cut.new(X) do
    def x; '{' + super + '}'; end
  end

  def test_method_is_wrapped_by_advice
    o = X.new
    o.x.assert == "{x}"
  end

end

#
class TestLiteralSyntax < MicroTest::TestCase

  class F
    def f ; "f" ; end
  end

  cut :G < F do
    #join :f => :f
    def f; '<'+super+'>' ; end
  end

  def test_1_01
    f = F.new
    f.f.assert == "<f>"
    f.class.assert == F
  end

  def test_1_02
    assert(G)
    G.name.assert == "TestLiteralSyntax::G"
  end

end

# Test multiple cuts.
class TestMultipleCuts < MicroTest::TestCase

  class F
    def f ; "f" ; end
  end

  cut :G < F do
    #join :f => :f
    def f; '<'+super+'>' ; end
  end

  cut :Q < F do
    #join :f => :f
    def f; '['+super+']'; end
  end

  #def test_2_01
  #  F.cuts.assert == [Q, G]
  #  F.predecessors.assert == [Q, G]
  #end

  def test_2_02
    f = F.new
    f.class.assert == F
    f.f.assert == "[<f>]"
  end

  def test_2_03
    assert(G)
    G.name.assert == "TestMultipleCuts::G"
  end

  def test_2_04
    assert(Q)
    Q.name.assert == "TestMultipleCuts::Q"
  end

end

