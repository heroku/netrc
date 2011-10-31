$VERBOSE = true
require 'minitest/autorun'

require 'netrc'

class TestNetrc < MiniTest::Unit::TestCase
  def test_parse_empty
    pre, items = Netrc.parse(Netrc.lex([]))
    assert_equal("", pre)
    assert_equal([], items)
  end

  def test_parse_file
    pre, items = Netrc.parse(Netrc.lex(IO.readlines("test/sample.netrc")))
    assert_equal("# this is my netrc\n", pre)
    exp = [["machine ",
            "m",
            "\n  login ",
            "l",
            " # this is my username\n  password ",
            "p",
            "\n"]]
    assert_equal(exp, items)
  end

  def test_round_trip
    n = Netrc.read("test/sample.netrc")
    assert_equal(IO.read("test/sample.netrc"), n.unparse)
  end

  def test_set
    n = Netrc.read("test/sample.netrc")
    n["m"] = "a", "b"
    exp = "# this is my netrc\n"+
          "machine m\n"+
          "  login a # this is my username\n"+
          "  password b\n"
    assert_equal(exp, n.unparse)
  end
end
