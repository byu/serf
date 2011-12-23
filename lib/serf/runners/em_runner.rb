require 'eventmachine'

require 'serf/messages/message_accepted_event'

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
  # any extra publishing to error channels because that may have
  # been the cause of the error.
  #
  class EmRunner

    def initialize(options={})
      # Manditory: Need a runner because EmRunner is just a wrapper.
      @runner = options.fetch(:runner)

      @mae_class = options.fetch(:message_accepted_event_class) {
        ::Serf::Messages::MessageAcceptedEvent
      }
      @evm = options.fetch(:event_machine) { ::EventMachine }
      @logger = options.fetch(:logger) { ::Serf::Util::NullObject.new }
    end

    def run(handler, params)
      @evm.defer(proc do
        begin
          @runner.run handler, params
        rescue => e
          @logger.error "#{e.inspect}\n\n#{e.backtrace.join("\n")}"
        end
      end)
      return @mae_class.new message: params
    end

  end

end
end
