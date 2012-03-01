module Serf
module Runners

  module Helper

    ##
    # Loop over the results and push them to the response channel.
    # Any error in pushing individual messages will result in
    # a log event and an error channel event.
    def push_results(results)
      response_channel = opts! :response_channel
      results.each do |message|
        with_error_handling(message) do
          response_channel.push message
        end
      end
      return nil
    end

  end

end
end
