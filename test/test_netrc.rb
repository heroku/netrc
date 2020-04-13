$VERBOSE = true
require 'minitest/autorun'
require 'fileutils'

require File.expand_path("#{File.dirname(__FILE__)}/../lib/netrc")
require "rbconfig"

class TestNetrc < Minitest::Test

  def setup
    Dir.glob('data/*.netrc').each{|f| File.chmod(0600, f)}
    File.chmod(0644, "data/permissive.netrc")

    File.chmod(0000, "data/restrictive0000.netrc")
    File.chmod(0400, "data/restrictive0400.netrc")
    File.chmod(0600, "data/restrictive0600.netrc")
  end

  def teardown
    Dir.glob('data/*.netrc').each{|f| File.chmod(0644, f)}
  end

  # Helper for obtaining a value for the user's home directory from the
  # password database (querying it by uid), else falling back on using the
  # pwd. This is analogous to what the Netrc.home_path method does on
  # Unix-like systems when neither 'NETRC' nor 'HOME' are defined, if the
  # process is not a child (or grandchild) of a login session, or if the
  # user's actual home directory is not readable for some reason.
  #
  def fallback_homedir_else_pwd
    begin
      require 'etc'
    rescue LoadError
      # Without the 'Etc' module we are unable to query the password database
      return Dir.pwd
    end

    # Note that Process.uid returns the value of getuid() which (on Linux) may
    # be different from the value of /proc/self/loginuid (e.g., for a process
    # that is not a (grand)child of a login process). That is important here
    # because we should be able to obtain the record from the password
    # database, even if Ruby's built-in 'Dir.home' cannot (because it uses
    # getlogin() and fails in that scenario, at least through Ruby 2.7.1).
    #
    passwd_record = Etc.getpwuid(Process.uid)
    unless passwd_record
      return Dir.pwd  # Record for uid not available for some reason
    end

    return passwd_record.dir if File.readable?(passwd_record.dir)

    return Dir.pwd
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

  def test_login_file
    pre, items = Netrc.parse(Netrc.lex(IO.readlines("data/login.netrc")))
    assert_equal("# this is my login netrc\n", pre)
    exp = [["machine ",
            "m",
            "\n  login ",
            "l",
            nil,
            nil,
            " # this is my username\n"]]
    assert_equal(exp, items)
  end

  def test_password_file
    pre, items = Netrc.parse(Netrc.lex(IO.readlines("data/password.netrc")))
    assert_equal("# this is my password netrc\n", pre)
    exp = [["machine ",
            "m",
            nil,
            nil,
            "\n  password ",
            "p",
            " # this is my password\n"]]
    assert_equal(exp, items)
  end

  def test_missing_file
    n = Netrc.read("data/nonexistent.netrc")
    assert_equal(0, n.length)
  end

  def test_permission_error
    original_windows = Netrc::WINDOWS
    Netrc.send(:remove_const, :WINDOWS)
    Netrc.const_set(:WINDOWS, false)
    Netrc.read("data/permissive.netrc")
    assert false, "Should raise an error if permissions are wrong on a non-windows system."
  rescue Netrc::Error
    assert true, ""
  ensure
    Netrc.send(:remove_const, :WINDOWS)
    Netrc.const_set(:WINDOWS, original_windows)
  end

  def test_allow_permissive_netrc_file_option
    Netrc.configure do |config|
      config[:allow_permissive_netrc_file] = true
    end
    original_windows = Netrc::WINDOWS
    Netrc.send(:remove_const, :WINDOWS)
    Netrc.const_set(:WINDOWS, false)
    Netrc.read("data/permissive.netrc")
    assert true, ""
  rescue Netrc::Error
    assert false, "Should not raise an error if allow_permissive_netrc_file option is set to true"
  ensure
    Netrc.send(:remove_const, :WINDOWS)
    Netrc.const_set(:WINDOWS, original_windows)
    Netrc.configure do |config|
      config[:allow_permissive_netrc_file] = false
    end
  end

  def test_permission_error_windows
    original_windows = Netrc::WINDOWS
    Netrc.send(:remove_const, :WINDOWS)
    Netrc.const_set(:WINDOWS, true)
    Netrc.read("data/permissive.netrc")
  rescue Netrc::Error
    assert false, "Should not raise an error if permissions are wrong on a non-windows system."
  ensure
    Netrc.send(:remove_const, :WINDOWS)
    Netrc.const_set(:WINDOWS, original_windows)
  end

  def test_error_restrictive0000_netrc_file_perms
    original_windows = Netrc::WINDOWS
    Netrc.send(:remove_const, :WINDOWS)
    Netrc.const_set(:WINDOWS, false)
    Netrc.read("data/restrictive0000.netrc")
    assert false, "Should raise an error if permissions do not include S_IRUSR (00400) u+r (readable by owner) on a non-windows system."
  rescue Netrc::Error => ex
    assert_match /is not readable/, ex.message, "Exception should indicate \"is not readable\" (got: #{ex.message})"
    assert true, ""
  ensure
    Netrc.send(:remove_const, :WINDOWS)
    Netrc.const_set(:WINDOWS, original_windows)
  end

  def test_allow_restrictive0400_netrc_file_perms
    original_windows = Netrc::WINDOWS
    Netrc.send(:remove_const, :WINDOWS)
    Netrc.const_set(:WINDOWS, false)
    Netrc.read("data/restrictive0400.netrc")
    assert true, ""
  rescue Netrc::Error => ex
    assert false, "Should not raise an error if restrictive file perms are set to 0400 (msg: #{ex.message})"
  ensure
    Netrc.send(:remove_const, :WINDOWS)
    Netrc.const_set(:WINDOWS, original_windows)
  end

  def test_allow_restrictive0600_netrc_file_perms
    original_windows = Netrc::WINDOWS
    Netrc.send(:remove_const, :WINDOWS)
    Netrc.const_set(:WINDOWS, false)
    Netrc.read("data/restrictive0600.netrc")
    assert true, ""
  rescue Netrc::Error => ex
    assert false, "Should not raise an error if restrictive file perms are set to 0600 (msg: #{ex.message})"
  ensure
    Netrc.send(:remove_const, :WINDOWS)
    Netrc.const_set(:WINDOWS, original_windows)
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
    assert_equal(["a", "b"], n["m"].to_a)
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

  def test_add_newlineless
    n = Netrc.read("data/newlineless.netrc")
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
    assert_equal(["a", "b"], n["x"].to_a)
  end

  def test_get_missing
    n = Netrc.read("data/sample.netrc")
    assert_nil(n["x"])
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
    unless Netrc::WINDOWS
      assert_equal(0600, File.stat("/tmp/created.netrc").mode & 0777)
    end
  end

  def test_encrypted_roundtrip
    if `gpg --list-keys 2> /dev/null` != ""
      FileUtils.rm_f("/tmp/test.netrc.gpg")
      n = Netrc.read("/tmp/test.netrc.gpg")
      n["m"] = "a", "b"
      n.save
      assert_equal(0600, File.stat("/tmp/test.netrc.gpg").mode & 0777)
      netrc = Netrc.read("/tmp/test.netrc.gpg")["m"]
      assert_equal("a", netrc.login)
      assert_equal("b", netrc.password)
    end
  end

  # The precedence order for finding the user's netrc file is the first
  # /readable/ name from the following list:
  #
  #     1. Use NETRC, if set
  #     2. Use "$HOME/.netrc", if HOME is set
  #     3. Use Dir.home, if possible (only works where getlogin() is non-NULL)
  #     4. (MS Windows only) Combine HOMEDRIVE and HOMEPATH, if both are set
  #     5. (MS Windows only) Use USERPROFILE, if set
  #     6. (Non-MS Windows only) Use pw_dir field from password database, if available
  #     7. Dir.pwd  (is not checked for readability)
  #
  # This test exercises the behavior when none of the above listed environment
  # variables are present and/or set.
  #
  def test_missing_environment

    envkeys = %w(NETRC HOME HOMEDRIVE HOMEPATH USERPROFILE)
    envhold = {}

    envkeys.each do |ekey|
      if ENV.has_key?(ekey)
        envhold[ekey] = ENV[ekey]
        ENV.delete(ekey)
      end
    end

    dflt_dir = self.fallback_homedir_else_pwd

    assert_equal File.join(dflt_dir, '.netrc'), Netrc.default_path
  ensure
    # ENV obj is not really a hash; use poor man's manual merge!(...)
    envhold.each do |holdkey, holdval|
      ENV[holdkey] = holdval
    end
  end

  def test_netrc_environment_variable
    ENV["NETRC"] = File.join(Dir.pwd, 'data')
    assert_equal File.join(Dir.pwd, 'data', '.netrc'), Netrc.default_path
  ensure
    ENV.delete("NETRC")
  end

  def test_read_entry
    entry = Netrc.read("data/sample.netrc")['m']
    assert_equal 'l', entry.login
    assert_equal 'p', entry.password

    # hash-style
    assert_equal 'l', entry[:login]
    assert_equal 'p', entry[:password]
  end

  def test_read_entry_without_login
    entry = Netrc.read("data/password.netrc")['m']
    assert_nil entry.login
    assert_equal 'p', entry.password

    # hash-style
    assert_nil entry[:login]
    assert_equal 'p', entry[:password]
  end

  def test_read_entry_without_password
    entry = Netrc.read("data/login.netrc")['m']
    assert_equal 'l', entry.login
    assert_nil entry.password

    # hash-style
    assert_equal 'l', entry[:login]
    assert_nil entry[:password]
  end

  def test_write_entry
    n = Netrc.read("data/sample.netrc")
    entry = n['m']
    entry.login    = 'new_login'
    entry.password = 'new_password'
    n['m'] = entry
    assert_equal(['new_login', 'new_password'], n['m'].to_a)
  end

  def test_entry_splat
    e = Netrc::Entry.new("user", "pass")
    user, pass = *e
    assert_equal("user", user)
    assert_equal("pass", pass)
  end

  def test_entry_implicit_splat
    e = Netrc::Entry.new("user", "pass")
    user, pass = e
    assert_equal("user", user)
    assert_equal("pass", pass)
  end

  def test_with_default
    netrc = Netrc.read('data/sample_with_default.netrc')
    assert_equal(['l', 'p'], netrc['m'].to_a)
    assert_equal(['default_login', 'default_password'], netrc['unknown'].to_a)
  end

  def test_multi_without_default
    netrc = Netrc.read('data/sample_multi.netrc')
    assert_equal(['lm', 'pm'], netrc['m'].to_a)
    assert_equal(['ln', 'pn'], netrc['n'].to_a)
    assert_equal([], netrc['other'].to_a)
  end

  def test_multi_with_default
    netrc = Netrc.read('data/sample_multi_with_default.netrc')
    assert_equal(['lm', 'pm'], netrc['m'].to_a)
    assert_equal(['ln', 'pn'], netrc['n'].to_a)
    assert_equal(['ld', 'pd'], netrc['other'].to_a)
  end

  def test_default_only
    netrc = Netrc.read('data/default_only.netrc')
    assert_equal(['ld', 'pd'], netrc['m'].to_a)
    assert_equal(['ld', 'pd'], netrc['other'].to_a)
  end

  def test_multi_without_logins
    netrc = Netrc.read('data/sample_multi_without_logins.netrc')
    assert_equal([nil, 'pm'], netrc['m'].to_a)
    assert_equal([nil, 'pn'], netrc['n'].to_a)
    assert_equal(['lo', 'po'], netrc['o'].to_a)
  end
end
