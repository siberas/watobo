# @private 
module Watobo#:nodoc: all
  def self.print_debug(*m)
    fl = m.shift
    puts "#"
    puts "# #{fl} #"
    if m.length > 0
      m.each do |l|
        puts l
      end
      puts "# " + "-"*fl.length + " #"
    end
  end
end