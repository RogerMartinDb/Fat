require 'pp'

class Fat
  def initialize(args)
    @root = args[0] || '.'
    
    @stop_at_p = args[1] || 20
    @stop_at_p = @stop_at_p.to_i
    
    @min_p = args[2] || 0
    @min_p = @min_p.to_i
  end

  def display
    if (File.directory? @root)
      results = {:name => @root, :path => @root, :size => 0, :children => []}

      get_size(results)
      
      puts "Results, showing top #{@stop_at_p}% contents of each folder and sub-folder"
      puts "  ignoring files or folders smaller than #{@min_p}% of containing folder" unless @min_p == 0
      puts 
      print_results results
    else
      usage
    end
  end

  def usage
    puts 'usage: ruby fat.rb [folder [stop-at-% [min-%]] '
    puts
    puts '  example: ruby fat.rb "C:\Program Files" 30 5'
    puts
    puts '  shows what is taking up most space in a folder (directory)'
    puts '    folder defaults to current directory'
    puts '    stop-at-% defaults to 20, meaning for each folder stop listing after 20% size reached'
    puts '    min-% defaults to 0, files or folders smaller that min-% of containing folder won\'t be shown'
  end

  def get_size (results)
    path = results[:path]
    size = 0
    depth = results[:depth]
    
    begin
      if (File.directory?(path))
        Dir.foreach(path) do |child_name|
          unless dot?(child_name)
            child_result = {:name => child_name, :path => File.join(path, child_name), :children => []}
            size += get_size(child_result) 
            results[:children] << child_result
          end
        end
        min_size = size * @min_p / 100
        target_size = size * @stop_at_p / 100
        running_size = 0
        results[:children]
          .sort!{|a,b| b[:size] <=> a[:size]}
          .select! do |e| 
            b = target_size >= running_size && e[:size] >= min_size
            running_size += e[:size]
            b
          end
      else
        size = File.size(path)
      end
    rescue Exception => e
      STDERR.puts e
    end

    results[:size] = size
    size
  end

  def print_results results, depth = 0
    puts "#{"\t"*(depth)}#{results[:name]}: #{with_letters(results[:size])}"

    results[:children]
      .each{|child| print_results child, depth + 1}
  end

  def dot?(file)
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

