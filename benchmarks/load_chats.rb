#!/usr/bin/env ruby
require 'devenv'
require 'watobo'
require 'benchmark'

=begin
       user     system      total        real
10_000 x hash  3.529838   0.396802   3.926640 (  3.948366)
10_000 x object  2.001020   0.505067   2.506087 (  2.519280)
10_000 x zipped  9.431278   0.096805   9.528083 (  9.565701)
=end

sample_path = File.join(File.expand_path(File.dirname(__FILE__ )), '..', 'spec/samples')
hash_sample = File.join(sample_path, 'chat-hash-marshalled.mrs')
obj_sample = File.join(sample_path, 'chat-object-marshalled.mrs')
zip_sample = File.join(sample_path, 'chat-object-marshalled.mrz')

Benchmark.bm do |x|
  x.report("10_000 x hash"){
    10000.times do
      Watobo::Utils.loadChatMarshal hash_sample
    end
  }

  x.report("10_000 x object"){
    10000.times do
      Watobo::Utils.loadChatMarshal obj_sample
    end
  }

  x.report("10_000 x zipped"){
    10000.times do
      Watobo::Utils.loadChatMarshal zip_sample
    end
  }
end


