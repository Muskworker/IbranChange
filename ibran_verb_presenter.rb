class IbranVerbPresenter
  NONSPACING = "\u0304\u032f\u0303\u0302\u0320"
  
  def self.mono_single(name, tam)
    longest = [tam].compact.inject(0) do |memo, step|
      memo = [memo, step[:PI].length, step[:RIL].length, step[:RIC].length, step[:PIPA].length, step[:RIPA].length].max
    end
    
    puts "+#{"-" * (name.length + 2)}+#{"-" * (longest + 2)}+"
    puts "| #{name} | #{tam[:RIC].ljust(longest + tam[:RIC].count(NONSPACING))} |"
    puts "+#{"-" * (name.length + 2)}+ #{tam[:RIL].ljust(longest + tam[:RIL].count(NONSPACING))} |"
    puts "#{" " * (name.length + 3)}| #{tam[:RIPA].ljust(longest + tam[:RIPA].count(NONSPACING))} |"
    puts "#{" " * (name.length + 3)}+#{"-" * (longest + 2)}+"
    puts "#{" " * (name.length + 3)}| #{tam[:PI].ljust(longest + tam[:PI].count(NONSPACING))} |"
    puts "#{" " * (name.length + 3)}| #{tam[:PIPA].ljust(longest + tam[:PIPA].count(NONSPACING))} |"
    puts "#{" " * (name.length + 3)}+#{"-" * (longest + 2)}+"
  end

  def self.mono_double(name, tam)
    longest = [*tam].compact.inject(0) do |memo, step|
      memo = [memo, step[:PI].length, step[:RIL].length, step[:RIC].length, step[:PIPA].length, step[:RIPA].length].max
    end
    
    puts "+#{"-" * (name.length + 2)}+#{"-" * (longest + 2)}+#{"-" * (longest + 2)}+"
    puts "| #{name} | #{tam[0][:RIC].ljust(longest + tam[0][:RIC].count(NONSPACING))} | #{tam[1][:RIC].ljust(longest + tam[1][:RIC].count(NONSPACING))} |"
    puts "+#{"-" * (name.length + 2)}+ #{tam[0][:RIL].ljust(longest + tam[0][:RIL].count(NONSPACING))} | #{tam[1][:RIL].ljust(longest + tam[1][:RIL].count(NONSPACING))} |"
    puts "#{" " * (name.length + 3)}| #{tam[0][:RIPA].ljust(longest + tam[0][:RIPA].count(NONSPACING))} | #{tam[1][:RIPA].ljust(longest + tam[1][:RIPA].count(NONSPACING))} |"
    puts "#{" " * (name.length + 3)}+#{"-" * (longest + 2)}+#{"-" * (longest + 2)}+"
    puts "#{" " * (name.length + 3)}| #{tam[0][:PI].ljust(longest + tam[0][:PI].count(NONSPACING))} | #{tam[1][:PI].ljust(longest + tam[1][:PI].count(NONSPACING))} |"
    puts "#{" " * (name.length + 3)}| #{tam[0][:PIPA].ljust(longest + tam[0][:PIPA].count(NONSPACING))} | #{tam[1][:PIPA].ljust(longest + tam[1][:PIPA].count(NONSPACING))} |"
    puts "#{" " * (name.length + 3)}+#{"-" * (longest + 2)}+#{"-" * (longest + 2)}+"
  end
  
  def self.monospace(name, tam, longest)
    puts "+#{"-" * (name.length + 2)}+"
    puts "| #{name} |"
    puts "+#{"-" * (longest + 2)}" * 6 + "+"
    6.times {|i| print "| #{tam[i][:RIC].ljust(longest + tam[i][:RIC].count(NONSPACING))} "}; print "|\n"
    6.times {|i| print "| #{tam[i][:RIL].ljust(longest + tam[i][:RIL].count(NONSPACING))} "}; print "|\n"
    6.times {|i| print "| #{tam[i][:RIPA].ljust(longest + tam[i][:RIPA].count(NONSPACING))} "}; print "|\n"
    puts "+#{"-" * (longest + 2)}" * 6 + "+"
    6.times {|i| print "| #{tam[i][:PI].ljust(longest + tam[i][:PI].count(NONSPACING))} "}; print "|\n"
    6.times {|i| print "| #{tam[i][:PIPA].ljust(longest + tam[i][:PIPA].count(NONSPACING))} "}; print "|\n"
    puts "+#{"-" * (longest + 2)}" * 6 + "+"
  end
end