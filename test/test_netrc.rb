$VERBOSE = true
require 'test/unit'
require 'fileutils'

require File.expand_path("#{File.dirname(__FILE__)}/../lib/netrc")
require "rbconfig"

class TestNetrc < Test::Unit::TestCase

  def setup
    File.chmod(0600, "data/sample.netrc")
    File.chmod(0644, "data/permissive.netrc")
  end

  # see http://stackoverflow.com/questions/4871309/what-is-the-correct-way-to-detect-if-ruby-is-running-on-windows
  def is_windows?
    RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
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
    assert_equal(0, n.length)
  end

  def test_permission_error
    Netrc.read("data/permissive.netrc")
    assert false, "Should raise an error if permissions are wrong on a non-windows system." unless is_windows?
  rescue Netrc::Error
  end

  def test_permission_error_windows
    def Netrc.is_windows?; true end
    Netrc.read("data/permissive.netrc")
  rescue Netrc::Error
    assert false, "Should not raise an error if permissions are wrong on a non-windows system." unless is_windows?
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
    assert_equal(0600, File.stat("/tmp/created.netrc").mode & 0777) unless is_windows?
  end

  def test_encrypted_roundtrip
    if `gpg --list-keys 2> /dev/null` != ""
      FileUtils.rm_f("/tmp/test.netrc.gpg")
      n = Netrc.read("/tmp/test.netrc.gpg")
      n["m"] = "a", "b"
      n.save
      assert_equal(0600, File.stat("/tmp/test.netrc.gpg").mode & 0777)
      assert_equal(["a", "b"], Netrc.read("/tmp/test.netrc.gpg")["m"])
    end
  end

  def test_missing_environment
    nil_home = nil
    ENV["HOME"], nil_home = nil_home, ENV["HOME"]
    n = Netrc.read
    assert_equal(nil, n["x"])
  ensure
    ENV["HOME"], nil_home = nil_home, ENV["HOME"]
  end


end
