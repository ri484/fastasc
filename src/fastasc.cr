require "option_parser"

module Fastasc
  VERSION = "0.1.0"

  # Method to get id vector and seq vector from a fasta file
  def parse_fasta_file(filepath)
    id = [] of String
    seq = [] of Array(Char)

    File.each_line(filepath) do |line|
      if line.starts_with?(">")
        id << line
        seq << [] of Char
      else
        seq[id.size-1].concat(line.chars)
      end
    end
    return id, seq
  end

  # Method to get id vector and seq vector from fasta STDIN
  def parse_fasta_stdin()
    id = [] of String
    seq = [] of Array(Char)

    STDIN.each_line() do |line|
      if line.starts_with?(">")
        id << line
        seq << [] of Char
      else
        seq[id.size-1].concat(line.chars)
      end
    end
    return id, seq
  end

  # Method to make column from seq and position
  def make_column(seq : Array(Array(Char)), pos)
    column = [] of Char
    seq.each do |i|
        column << i[pos]
    end
    return column
  end

  # Method to eval presence/absence of atgc
  def count_base(column : Array(Char))
    a = Array.new(column.size, 0)
    t = Array.new(column.size, 0)
    g = Array.new(column.size, 0)
    c = Array.new(column.size, 0)

    x = 0
    column.each do |i|
      if i.upcase == 'A'
        a[x] = 1
      elsif i.upcase == 'T'
        t[x] = 1
      elsif i.upcase == 'G'
        g[x] = 1
      elsif i.upcase == 'C'
        c[x] = 1
      elsif i.upcase == 'R'
        a[x] = 1
        g[x] = 1
      elsif i.upcase == 'Y'
        t[x] = 1
        c[x] = 1
      elsif i.upcase == 'S'
        g[x] = 1
        c[x] = 1
      elsif i.upcase == 'W'
        a[x] = 1
        t[x] = 1
      elsif i.upcase == 'K'
       t[x] = 1
        g[x] = 1
      elsif i.upcase == 'M'
        a[x] = 1
        c[x] = 1
      elsif i.upcase == 'B'
        t[x] = 1
        g[x] = 1
        c[x] = 1
      elsif i.upcase == 'D'
        a[x] = 1
        t[x] = 1
        g[x] = 1
      elsif i.upcase == 'H'
        a[x] = 1
        t[x] = 1
        c[x] = 1
      elsif i.upcase == 'V'
        a[x] = 1
        g[x] = 1
        c[x] = 1
      elsif i.upcase == 'N' || i == '-' || i == '?' || i == '.'
        a[x] = 1
        t[x] = 1
        g[x] = 1
        c[x] = 1
      else
        STDERR.puts "ERROR: Unexpected character! Please check the column.\n#{column}"
        exit(1)
      end
    x = x + 1
    end
    return a, t, g, c
  end

  # Method to find variant sites
  def is_variant(seq : Array(Array(Char)))
    length = seq.map do |element|
      element.size
    end

    if length.uniq.size > 1
      STDERR.puts "ERROR: The lengths of the sequences are not uniform."
      exit(1)
    end

    x = 0
    y = length[0]
    var = [] of typeof(y)

    while x < y
      column = make_column(seq, x)
      atgc = count_base(column)
      atgc_prod = [] of Int32

      atgc.each do |i|
          atgc_prod << i.product
      end
      
      if atgc_prod.max == 0
          var << x
      end
  
    x = x + 1
    end
    return var
  end
end

include Fastasc

# ARG
filepath = ""

option_parser = OptionParser.parse do |parser|
  parser.banner = "Usage: fastasc -f INPUT.fa > OUTPUT.fa\n        or\n       cat INPUT.fa | fastasc -f - > OUTPUT.fa\n\nRemove completely/partially invariant sites from nucleotide aligned fasta for +ASC subst model"

  parser.on("-v", "--version", "Show version") do
    puts VERSION
    exit
  end

  parser.on("-h", "--help", "Show this help message") do
    puts parser
    exit
  end

  parser.on("-f fasta", "--fasta=fasta", "Path to input aligned fasta. Set '-' for STDIN.") { |fasta| filepath = fasta } 

  parser.missing_option do |option_flag|
    STDERR.puts "ERROR: #{option_flag} is missing something."
    STDERR.puts ""
    STDERR.puts parser
    exit(1)
  end
  if ARGV.size == 0
    STDERR.puts parser
    exit(1)
  end
end


# get id and seq
if filepath == "-"
  id, seq = parse_fasta_stdin()
else
  id, seq = parse_fasta_file(filepath)
end
 

# get variant sites
var = is_variant(seq)


# output
x = 0
id.each do |i|
  puts(i)
  var.each do |j|
    print(seq[x].values_at(j).join)
  end
  print("\n")
  x = x + 1
end
