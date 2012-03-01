require 'eventmachine'

require 'serf/messages/message_accepted_event'
require 'serf/runners/direct'
require 'serf/util/with_error_handling'

module Serf
module Runners

  ##
  # This runner simply wraps another runner to execute in the
  # EventMachine deferred threadpool.
  #
  # NOTE: Because the Serfer class validates messages before
  #  sending them to runners (and handlers), this class simply
  #  responds to the calling client with an 'MessageAcceptedEvent'
  #  to signal that the message will be processed later.
  #
  # Errors caught here will simply be logged. This is because
  # the wrapped runner *MUST* handle its own errors. If an error
  # should propagate up here, then it was most likely an error
  # that occurred in a rescue block... we don't want to complicate
  # any extra pushing to error channels because that may have
  # been the cause of the error.
  #
  class EventMachine
    include Serf::Util::WithErrorHandling

    def initialize(*args)
      extract_options! args

      # Manditory: Need a runner because this class is just a wrapper.
      @runner = opts! :runner

      @mae_class = opts(
        :message_accepted_event_class,
        ::Serf::Messages::MessageAcceptedEvent)

      @evm = opts :event_machine, ::EventMachine
      @logger = opts :logger, ::Serf::Util::NullObject.new
    end

    def call(handlers, context)
      # This queues up each handler to be run separately.
      handlers.each do |handler|
        @evm.defer(proc do
          begin
            with_error_handling(context) do
              @runner.call [handler], context
            end
          rescue => e
            @logger.fatal(
              "EventMachineThread: #{e.inspect}\n\n#{e.backtrace.join("\n")}")
          end
        end)
      end
      return @mae_class.new(message: context)
    end

    def self.build(options={})
      options[:runner] = options.fetch(:runner) {
        factory = options[:runner_factory] || ::Serf::Runners::Direct
        factory.build options
      }
      self.new options
    end

  end

end
end
