require 'pp'

class Fat
  def initialize(args)
    @root = args[0] || '.'
    @top = args[1] || 10
    @depth = args[2] || 3
  end

  def display
    if (File.directory? @root)
      results = {:name => @root, :path => @root, :size => 0, :children => [], :depth => 1}

      get_size(results)
      
      puts "Results, showing top #{@top} big files or folders to a depth of #{@depth} folders"
      puts 
      print_results results, 1
    else
      usage
    end
  end

  def usage
    puts 'usage: ruby fat.rb [folder [top [depth]]] '
    puts
    puts '  shows what is taking up most space in a folder (directory)'
    puts '    folder defaults to current directory'
    puts '    top defaults to 10, meaning show the 10 biggest files or folders'
    puts '    depth defaults to 3 and is how deep in the directory hierarchy to go in the display of sizes'
  end

  def get_size (results)
    path = results[:path]
    size = 0
    depth = results[:depth]
    
    begin
      if (File.directory?(path))
        Dir.foreach(path) do |child_name|
          unless dot(child_name)
            child_result = {:name => child_name, :path => File.join(path, child_name), :children => [], :depth => depth + 1}
            size += get_size(child_result) 
            results[:children] << child_result unless depth > @depth
          end
        end
      else
        size = File.size(path)
      end
    rescue Exception => e
      STDERR.puts e
      STDERR.puts e.backtrace
    end

    results[:size] = size
    size
  end

  def print_results results, depth
    message = "#{"\t"*(depth-1)}#{results[:name]}: #{with_letters(results[:size])}"
    puts message

    results[:children]
      .sort{|a, b| b[:size] <=> a[:size]}
      .first(@top)
      .each{|child| print_results child, depth + 1}
  end

  def dot(file)
    (file == '.' || file == '..')
  end

  def with_letters(bytes)
    k = 1024
    m = k * k
    g = m * k
    t = g * k

    if (bytes > t)
      "#{bytes/t} TB"
    elsif (bytes > g)
      "#{bytes/g} GB"
    elsif (bytes > m)
      "#{bytes/m} MB"
    elsif (bytes > k)
      "#{bytes/k} KB"
    else
      "#{bytes} B"
    end
  end
end

fat = Fat.new ARGV
fat.display

