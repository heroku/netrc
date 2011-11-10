class Netrc
  Windows = false
  def self.default_path
    File.join(ENV["HOME"], default_name)
  end

  def self.default_name
    if Windows
      return "_netrc"
    end
    ".netrc"
  end

  def self.read(path=default_path)
    new(path, parse(lex(IO.readlines(path))))
  end

  def self.lex(lines)
    tokens = []
    for line in lines
      content, comment = line.split(/(\s*#.*)/m)
      tokens += content.split(/(?<=\s)(?=\S)|(?<=\S)(?=\s)/)
      if comment
        tokens << comment
      end
    end
    tokens
  end

  def self.skip?(s)
    s =~ /^\s/
  end

  # Returns two values, a header and a list of items.
  # Each item is a 7-tuple, containing:
  # - machine keyword (including trailing whitespace+comments)
  # - machine name
  # - login keyword (including surrounding whitespace+comments)
  # - login
  # - password keyword (including surrounding whitespace+comments)
  # - password
  # - trailing chars
  # This lets us change individual fields, then write out the file
  # with all its original formatting.
  def self.parse(ts)
    cur, item = [], []

    def ts.take
      if count < 1
        raise Error, "unexpected EOF"
      end
      shift
    end

    def ts.readto
      l = []
      while count > 0 && ! yield(self[0])
        l << shift
      end
      return l.join
    end

    pre = ts.readto{|t| t == "machine"}
    while ts.count > 0
      cur << ts.take + ts.readto{|t| ! skip?(t)}
      cur << ts.take
      cur << ts.readto{|t| t == "login"} + ts.take + ts.readto{|t| ! skip?(t)}
      cur << ts.take
      cur << ts.readto{|t| t == "password"} + ts.take + ts.readto{|t| ! skip?(t)}
      cur << ts.take
      cur << ts.readto{|t| t == "machine"}
      item << cur
      cur = []
    end

    [pre, item]
  end

  def initialize(path, data)
    @path = path
    @pre, @data = data
  end

  def [](k)
    for v in @data
      if v[1] == k
        return v[3], [5]
      end
    end
  end

  def []=(k, info)
    for v in @data
      if v[1] == k
        v[3], v[5] = info
      end
    end
  end

  def save
    File.write(path, unparse)
  end

  def unparse
    @pre + @data.map(&:join).join
  end

end

class Netrc::Error < ::StandardError
end
