$VERBOSE = true
require 'test/unit'

require '../netrc/lib/netrc'

require 'fileutils'

class TestParse < Test::Unit::TestCase
  def setup
    FileUtils.rm_rf('tmp_backup_test')
    FileUtils.mkdir_p('tmp_backup_test')
    FileUtils.cd('tmp_backup_test')
  end

 def teardown
    FileUtils.cd('..')
    FileUtils.rm_rf('tmp_backup_test')
 end

  ## Backup tests

  def test_backup_does_not_create_empty_file
    FileUtility.backup('does_not_exist', 'a')
    assert(! File.exist?('a') )
    assert(! File.exist?('does_not_exist') )
  end

  def test_backup_try_overwrite
    File.open('b', 'w') { |f| f.write '1234' }
    FileUtility.backup('b')
    assert( File.read('b') == '1234' )
    assert( File.read('b.000') == '1234' )
    assert_equal(0600, File.stat("b").mode & 0777)
    assert_equal(0600, File.stat("b.000").mode & 0777)
  end

  def test_backup_picks_next_available_filename
    File.open('c', 'w') { |f| f.write '12345' }
    FileUtils.touch('c.000')
    FileUtility.backup('c')
    assert( File.read('c') == '12345' )
    assert( File.read('c.000') == '' )
    assert( File.read('c.001') == '12345' )
  end

  def test_backup_try_overwrite_no_r
    File.open('d', 'w') { |f| f.write '72345' }
    File.chmod(0200, 'd') # --w-------
    assert_raise Errno::EACCES do
      FileUtility.backup('d')
    end
  end

  def test_backup_try_overwrite_no_rw
    File.open('f', 'w') { |f| f.write '72345' }
    File.chmod(0000, 'f') # -r--------
    assert_raise Errno::EACCES do
      FileUtility.backup('f')
    end
  end


  ## Atomic write tests

  def test_atomic_write_file_does_not_exist
    FileUtility.atomic_write('g') { |f| f.write 'xxxx' }
    assert( File.read('g') == 'xxxx' )
    assert(! File.exist?('g.000') )
  end

  def test_atomic_write_file_exists
    File.open('h', 'w') { |f| f.write '123' }
    FileUtility.atomic_write('h') { |f| f.write 'zzzz' }
    assert( File.read('h') == 'zzzz' )
    assert( File.read('h.000') == '123' )
    assert(! File.exist?('h.001') )
  end

  def test_atomic_write_file_exists_no_r
    File.open('k', 'w') { |f| f.write '123' }
    File.chmod(0100, 'k') # --w-------
    assert_raise Errno::EACCES do
      FileUtility.atomic_write('k') { |f| f.write 'zzzz' }
    end
    File.chmod(0400, 'k') # -r--------
    assert( File.read('k') == '123' )
    assert(! File.exist?('k.000') )
  end

  def test_atomic_write_file_exists_no_w
    File.open('m', 'w') { |f| f.write '888' }
    File.chmod(0400, 'm') # -r--------
    assert_raise Errno::EACCES do
      FileUtility.atomic_write('m') { |f| f.write 'zzzz' }
    end
    assert( File.read('m') == '888' )
    assert(! File.exist?('m.000') )
  end

  def test_atomic_write_file_exists_no_rw
    File.open('p', 'w') { |f| f.write 'zzz' }
    File.chmod(0000, 'p') # ----------
    assert_raise Errno::EACCES do
      FileUtility.atomic_write('p') { |f| f.write 'zzzz' }
    end
    File.chmod(0400, 'p') # -r--------
    assert( File.read('p') == 'zzz' )
    assert(! File.exist?('p.000') )
  end
end
