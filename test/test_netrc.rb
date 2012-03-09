$VERBOSE = true
require 'test/unit'
require 'fileutils'

require File.expand_path("#{File.dirname(__FILE__)}/../lib/netrc")

class TestNetrc < Test::Unit::TestCase
  def setup
    File.chmod(0600, "data/sample.netrc")
    File.chmod(0644, "data/permissive.netrc")
  end

  def test_parse_empty
    pre, items = Netrc.parse(Netrc.lex([]))
    assert_equal("", pre)
    assert_equal([], items)
  end

  def test_parse_file
    pre, items = Netrc.parse(Netrc.lex(IO.readlines("data/sample.netrc")))
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

  def test_missing_file
    n = Netrc.read("data/nonexistent.netrc")
    assert_equal(0, n.count)
  end

  def test_permission_error
    Netrc.read("data/permissive.netrc")
    assert false, "Should raise an error if permissions are wrong."
  rescue Netrc::Error
  end

  def test_round_trip
    n = Netrc.read("data/sample.netrc")
    assert_equal(IO.read("data/sample.netrc"), n.unparse)
  end

  def test_set
    n = Netrc.read("data/sample.netrc")
    n["m"] = "a", "b"
    exp = "# this is my netrc\n"+
          "machine m\n"+
          "  login a # this is my username\n"+
          "  password b\n"
    assert_equal(exp, n.unparse)
  end

  def test_set_get
    n = Netrc.read("data/sample.netrc")
    n["m"] = "a", "b"
    assert_equal(["a", "b"], n["m"])
  end

  def test_add
    n = Netrc.read("data/sample.netrc")
    n.new_item_prefix = "# added\n"
    n["x"] = "a", "b"
    exp = "# this is my netrc\n"+
          "machine m\n"+
          "  login l # this is my username\n"+
          "  password p\n"+
          "# added\n"+
          "machine x\n"+
          "  login a\n"+
          "  password b\n"
    assert_equal(exp, n.unparse)
  end

  def test_add_get
    n = Netrc.read("data/sample.netrc")
    n.new_item_prefix = "# added\n"
    n["x"] = "a", "b"
    assert_equal(["a", "b"], n["x"])
  end

  def test_get_missing
    n = Netrc.read("data/sample.netrc")
    assert_equal(nil, n["x"])
  end

  def test_save
    n = Netrc.read("data/sample.netrc")
    n.save
    assert_equal(File.read("data/sample.netrc"), n.unparse)
  end

  def test_save_create
    FileUtils.rm_f("/tmp/created.netrc")
    n = Netrc.read("/tmp/created.netrc")
    n.save
    assert_equal(0600, File.stat("/tmp/created.netrc").mode & 0777)
  end
end
