
class Netrc
  module FileUtility
    BUFFER_SIZE=256*1024

    # Compare data of 2+ file handles using block 
    def self.synchronous_compare_file_handles(file_handles, bytes, buffer_size = BUFFER_SIZE, &block)
      return true if bytes == 0

      reference_file = file_handles[0]
      other_files = file_handles[1..-1]

      reference_buffer = (0.chr) * buffer_size
      other_buffer = reference_buffer.clone

      # Until there is no more data
      begin
        bytes_read = reference_file.read(buffer_size, reference_buffer).bytes.count

        # Read a block and compare it from other files
        other_files.each do |f|
          # Read other data 
          other_bytes_read = f.read(buffer_size, other_buffer).bytes.count
          raise 'Synchronous_compare cannot handle io read()s of different sizes' if bytes_read != other_bytes_read
          # FAIL: other data and reference data differ
          return false unless yield(reference_buffer, other_buffer)
        end
      end until (bytes -= bytes_read) == 0

      # SUCCESS: no more bytes and all blocks same
      return true
    end

    # Pass a block to compare blocks other than using == operator.
    #
    # buffer_size defaults to 256k per file
    #
    # Returns true if all files are equal
    # Returns false if any files differ in content or size
    #
    def self.synchronous_compare_files(*file_names, &block)
      raise ArgumentError, 'Requires at least 2 file names' unless file_names.size >= 2
      # Check that all files are the same size
      size = nil
      file_names.each do |f|
        current_size = File.size(f)
        size ||= current_size
        # File sizes differ, so the files differ
        return false unless current_size == size
      end
      return true if size == 0 # Don't bother opening zero byte files

      file_handles = []
      begin # close all files if ever leaving this block
        # Open all files
        file_handles = file_names.collect { |filename| File.open(filename, 'rb:ASCII-8BIT') }
        # Compare files
        return (block_given?) ?
          synchronous_compare_file_handles(file_handles, size, &block) :
          synchronous_compare_file_handles(file_handles, size)   { |x,y| x == y }
      ensure
        file_handles.map { |f| f.close rescue nil }
      end
    end

    def self.copy_file(source, dest, mode = 0600, verify = true, block_size = BUFFER_SIZE, &block)
      File.open(source, 'rb') do |s| 
        File.open(dest, 'wb', mode) do |d|
          begin
            buffer = 0.chr * block_size
            until s.eof?
              s.read(block_size, buffer)
              d.syswrite(buffer)
            end
          rescue Exception
            d.close rescue nil
            d.unlink rescue nil
            raise
          end 
        end # d
      end # s
      IO.fsync rescue NotImplementedError
      if verify 
        raise 'File differs from original' unless synchronous_compare_files source, dest, &block 
      end
    end

    # Proper Windows detection.
    #
    def self.windows?
      /win(32|dows|ce)|djgpp|(ms|cyg|bcc)win|mingw32/i || ENV['OS'] == 'Windows_NT'
    end

    # Rename files atomicly.
    #
    # Pass mode to ensure dest is set to a particular file mode, otherwise it is copied from source.
    #
    def self.safe_rename(source, dest, mode = nil)
      mode ||= File.stat(source).mode unless windows?
      result = File.rename source, dest
      (File.chmod(mode, dest) if !windows? and mode != File.stat(dest).mode) rescue Errno::EINVAL
      result
    end

    # Safely write to a file that may exist.
    #
    def self.atomic_write(filename, mode = 0600, &block)
      raise ArgumentError, 'Must specify a block' unless  block_given?

      if File.exist?(filename)
        File.open(filename, 'ab+') {  } # Make sure the file exists and is read-writable
        src_mode = File.stat(filename).mode unless windows?
        require 'tempfile'
        Tempfile.open(File.basename(filename), File.dirname(filename)) do |tempfile|
          begin
            yield(tempfile)
            tempfile.close
            safe_rename tempfile.path, filename, src_mode
          ensure
            tempfile.close rescue nil
            tempfile.unlink rescue nil
          end
        end
      else # destination file does not exist
        File.open(filename, 'wb+', mode, &block)
      end
    end
  end # module FileUtility
end # class Netrc
