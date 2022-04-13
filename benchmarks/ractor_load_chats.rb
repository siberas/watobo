#!/usr/bin/ruby
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
  $: << inc_path
end
require 'optimist'

OPTS = Optimist::options do
  version "#{$0} 0.1 (c) 2014 siberas"
  opt :project, "Projectname", :type => :string
  opt :session, "Sessionname", :type => :string
  opt :logname, "Logname", :type => :string
  opt :url, "URL pattern", :type => :string, :default => "*"
end

Optimist.die :project, "Need project name" unless OPTS[:project]
Optimist.die :session, "Need session name" unless OPTS[:session]

require 'watobo'
require 'pry'
require 'benchmark'

puts Watobo::Conf::General.workspace_path

ds = Watobo::DataStore.connect(OPTS[:project], OPTS[:session])
chat_files = ds.chat_files


Benchmark.bm do |x|
  chats = []
  chats2 = Array.new(chat_files.length)
  chats_yield = Array.new(chat_files.length)
  ractor_states = {}

  x.report('sequential: ') {
    chats_inline = chat_files.map { |f| Watobo::Utils.loadChatMarshal(f) }
    puts "\nGot #{chats_inline.compact.length} Chats}"
  }

  x.report('Inline Ractors: ') {
    ractors = chat_files.map do |f|
      Ractor.new(f) { |file|
        Marshal::load(IO.binread(file))
      }

    end
    chats = ractors.map { |ractor|
      settings = ractor.take
      request = settings[:request]
      response = settings[:response]
      settings.delete(:response)
      settings.delete(:request)
      Watobo::Chat.new(request, response, settings)
    }

    puts "\nGot #{chats.compact.length} Chats}"
  }

  x.report('Yield Ractors: ') {

    @ractors = chat_files.map do |f|
      Ractor.new(f) { |file|
        Ractor.yield Marshal::load(IO.binread(file))
      }
    end

    @reciever = Thread.new(@ractors) { |workers|
      loop do
        begin
          break if workers.empty?
          r, result = Ractor.select *workers
          workers.delete r

          if result.is_a? Symbol
            ractor_states[result] ||= 0
            ractor_states[result] += 1
          elsif !result.nil?
            settings = result
            request = settings[:request]
            response = settings[:response]
            settings.delete(:response)
            settings.delete(:request)
            chat = Watobo::Chat.new(request, response, settings)
            chats_yield[chat.id - 1] = chat
          end
        rescue => bang
          puts bang
          puts bang.backtrace
        end

      end
    }

    @reciever.join
    puts "\nGot #{chats_yield.compact.length} Chats}"
  }

  x.report('Yield Ractors with inline threads: ') {

    @ractors = chat_files.map do |f|
      Ractor.new(f) { |file|
        Ractor.yield Marshal::load(IO.binread(file))
      }
    end

    @reciever = @ractors.map { |ractor|
      Thread.new(ractor) { |r|
        begin
          result = r.take

          if result.is_a? Symbol
            ractor_states[result] ||= 0
            ractor_states[result] += 1
          elsif !result.nil?
            settings = result
            request = settings[:request]
            response = settings[:response]
            settings.delete(:response)
            settings.delete(:request)
            chat = Watobo::Chat.new(request, response, settings)
            chats_yield[chat.id - 1] = chat
          end
        rescue => bang
          puts bang
          puts bang.backtrace
        end


      }
    }

    @reciever.map{|t| t.join }
    puts "\nGot #{chats_yield.compact.length} Chats"
  }

  x.report('12 ractors: ') {


    @queue = Ractor.new do
      loop do
        task = Ractor.receive
        Ractor.yield(task)
      end
    end

    @workers = 12.times.map do
      Ractor.new(@queue) do |queue|
        loop do
          begin
            file = queue.take
            Ractor.yield Marshal::load(IO.binread(file))
            Ractor.yield :finished
          rescue => bang
            puts bang
            puts bang.backtrace
          end
        end
      end
    end


    @reciever = Thread.new do
      loop do
        r, result = Ractor.select *@workers
        if result.is_a? Symbol
          ractor_states[result] ||= 0
          ractor_states[result] += 1
        else
          settings = result
          request = settings[:request]
          response = settings[:response]
          settings.delete(:response)
          settings.delete(:request)
          chat = Watobo::Chat.new(request, response, settings)
          chats2[chat.id - 1] = chat
        end

      end

    end

    puts "Chats (before): #{chats2.compact.length}"

    chat_files.each do |f|
      Thread.new {
        @queue.send f
      }
    end

    #chats_sorted = chats2.sort_by { |c| c.id }
    puts "Chats (before wait): #{chats2.compact.length}"
    loop do
      # break if ractor_states[:finished] == chat_files.length
      break if chats2.compact.length == chat_files.length || ractor_states[:finished] == chat_files.length
    end
    puts "Chats (finished): #{chats2.compact.length}"

  }


end


