require 'devenv'
require 'watobo'
require 'watobo/ml'

chats_dir = ARGV[0]

puts '+ loading chats ...'
Watobo::Chats.load_marshaled chats_dir

km = Watobo::Ml::KmeansChats.new Watobo::Chats.to_a
km.run

while 1
  km.clusters.each_with_index do |c, i|
    puts "#{c.id} - #{c.points.length}"
  end
  print "\nEnter Cluster-ID: "
  sel = STDIN.gets

  #c = km.cluster_by_id sel.to_i
  km.chats_of_cluster(sel.to_i) do |chat|
    puts "---\n#{chat.response}";
  end
end

=begin
require 'kmeans-clusterer'
require 'pry'

data = Array.new(10000) {  [ 3, 1, 100, 1 ]  }
data.concat Array.new(10000) {  [ 3, 1, 1000, 2 ]  }
data.concat Array.new(100) {  [ 30, 1, 1000, 2 ]  }
data.concat Array.new(10) {  [ 300, 5, 100, 2 ]  }

k = 3 # find 2 clusters in data

kmeans = KMeansClusterer.run k, data, runs: 5
kmeans.clusters.each do |cluster|
   puts  cluster.id.to_s
end

binding.pry
=end


