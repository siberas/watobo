require_relative 'passive_check2'

module Watobo
  class PassiveScanner2

    def scan(chat)
      @queue.send chat
    end

    def start_reciever
      @reciever = Thread.new do
        loop do
          r,  result = Ractor.select *@workers
          puts r
          puts result
          puts "Got new Finding:\n"
          puts result[0].request.url
          #f = Watobo::Finding.new(result[0].request, result[0].response, result[1])
          Watobo::Findings.add Watobo::Finding.new(result[0].request, result[0].response, result[1])
        end
      end

    end

    def initialize(module_path = Watobo.passive_module_path)

      @findings = Queue.new
      load_modules(module_path)

      # create a communication channel for generator and workers
      @queue = Ractor.new do
        loop do
          task = Ractor.receive
          Ractor.yield(task)
        end
      end

      @workers = spinup_workers

      start_reciever

    end

    def spinup_workers(num_workers = 15)
      num_workers.times.map do
       Ractor.new(@queue) do |queue|
          # create passive modules
          passive_modules = []
          Watobo::Modules::Passive2.constants.each do |m|
            puts m
            begin
              class_constant = Watobo::Modules::Passive2.const_get(m)
              pc = class_constant.new(self)
              passive_modules << pc
            rescue => bang
              puts bang
              puts bang.backtrace #if $DEBUG
              #return false
            end
          end

          loop do
            msg = queue.take
            chat = msg
            passive_modules.each do |pm|
              begin
                pm.do_test(chat)

              rescue => bang
                puts bang
                puts bang.backtrace #if $DEBUG
                #return false
              end
            end
          end
        end
      end
    end

    def load_modules(module_path)
      passive_modules = []

      Dir["#{module_path}2/*.rb"].each do |mod_file|
        begin
          mod = File.basename(mod_file)

          load mod_file
        rescue => bang
          puts "!!!"
          puts bang
        end
      end

    end
  end
end
