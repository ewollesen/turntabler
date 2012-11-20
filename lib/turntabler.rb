require 'logger'
require 'em-synchrony'

# Turntable.FM API for Ruby
module Turntabler
  autoload :Client, 'turntabler/client'

  class << self
    # The logger to use for all Turntable messages.  By default, everything is
    # logged to STDOUT.
    # @return [Logger]
    attr_accessor :logger

    # Whether this is going to be used in an interactive console such as IRB.
    # If this is enabled then EventMachine will run in a separate thread.  This
    # will allow IRB to continue to actually be interactive.
    # 
    # @note You must continue to run all commands on a client through Turntabler#run.
    # @example
    #   require 'turntabler'
    #   
    #   Turntabler.interactive
    #   Turntabler.run do
    #     @client = Turntabler::Client.new(...)
    #     @client.start
    #   end
    #   
    #   # ...later on after the connection has started and you want to interact with it
    #   Turntabler.run do
    #     @client.user.load
    #     # ...
    #   end
    def interactive
      Thread.new { EM.run }.abort_on_exception = true
    end

    # Sets up the proper EventMachine reactor / Fiber to run commands against a
    # client.  If this is not in interactive mode, then the block won't return
    # until the EventMachine reactor is stopped.
    # 
    # @note If you're already running within an EventMachine reactor *and* a
    # Fiber, then there's no need to call this method prior to interacting with
    # a Turntabler::Client instance.
    # @example
    #   # Non-interactive, not in reactor / fiber
    #   Turntabler.run do
    #     client = Turntabler::Client.new(...)
    #     client.user.load
    #     # ...
    #   end
    #   
    #   # Interactive, not in reactor / fiber
    #   Turntabler.run do
    #     @client.user.load
    #     # ...
    #   end
    #   
    #   # Non-interactive, already in reactor / fiber
    #   client = Turntabler::Client(...)
    #   client.user.load
    # 
    # == Exception handling
    # 
    # Any exceptions that occur within the block will be automatically caught
    # and logged.  This prevents the EventMachine reactor from dying.
    def run(&block)
      if EM.reactor_running?
        EM.next_tick do
          EM.synchrony do
            begin
              block.call
            rescue Exception => ex
              logger.error(([ex.message] + ex.backtrace) * "\n")
            end
          end
        end
      else
        EM.synchrony { run(&block) }
      end
    end
  end

  @logger = Logger.new(STDOUT)
end

# Provide a simple alias (akin to EM / EventMachine)
TT = Turntabler
