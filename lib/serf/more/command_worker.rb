require 'serf/command'
require 'serf/util/error_handling'

module Serf
module More

  ##
  # Creates a proc (CommandWorker.worker) that will be used by
  # GirlFriday WorkQueues. This proc will receive messages from
  # GirlFriday and will (1) create a CommandWorker instance with the
  # given message and (2) execute (#call) said CommandWorker instance.
  # The CommandWorker instance assumes that the received message is
  # a callable (#call) object, and will execute that object's 'call' method.
  #
  # The purpose of this is so we can build Command objects in one
  # context/thread and have it actually executed in a separate threadpool.
  #
  # Example:
  #
  #   # Creates the GirlFriday work queue.
  #   command_worker_queue = GirlFriday::WorkQueue.new(
  #     CommandWorker.worker(
  #       logger: my_logger,
  #       response_channel: response_channel,
  #       error_channel: error_channel))
  #
  #   # In some place that receives requests and generates commands.
  #   # Push the command into the command workqueue for async processing.
  #   command_worker_queue.push MyCommand.build(REQUEST_HASH)
  #
  class CommandWorker
    include Serf::Command
    include Serf::ErrorHandling

    def call
      ok, results = with_error_handling do
        request.call
      end
      return results
    end

  end

end
end
