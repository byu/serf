require 'girl_friday'

require 'serf/messages/message_accepted_event'
require 'serf/runners/helper'
require 'serf/util/error_handling'

module Serf
module Runners

  ##
  #
  class GirlFriday
    include Serf::Util::ErrorHandling
    include Serf::Runners::Helper

    def initialize(*args)
      extract_options! args

      # Mandatory response channel.
      opts! :response_channel

      # Create our worker queue that will accept tasks (handler and context).
      # The worker is just a block that passes on the task to the
      # actual worker method.
      @queue = ::GirlFriday::WorkQueue.new(
          opts(:queue_name, :serf_runner),
          :size => opts(:queue_size, 1)) do |task|
        perform task
      end
    end

    def call(handlers, context)
      # Create our accepted event before we enqueue the handlers.
      mae_class = opts(
        :message_accepted_event_class,
        ::Serf::Messages::MessageAcceptedEvent)
      event = mae_class.new message: context

      # Push each handler into the queue along with a copy of the context.
      handlers.each do |handler|
        @queue.push(
          handler: handler,
          context: context.dup)
      end

      # We got here, we succeeded pushing all the works.
      # Now we return our accepted event.
      return event
    end

    ##
    # Builder method
    #
    def self.build(*args)
      self.new *args
    end

    ##
    # Actually drives the execution of individual handlers passed to job
    # queue.
    #
    def perform(task)
      with_error_handling(task[:context]) do
        task[:handler].call
        run_result = run_result.is_a?(Hash) ? [run_result] : Array(run_result)
        push_results run_result
      end
    end

  end

end
end
