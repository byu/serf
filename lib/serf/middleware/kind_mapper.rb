module Serf
module Middleware

  ##
  # Our "router" app that will call the actual registered handler object
  # with the received message based on the 'kind' of message received.
  #
  # This means we look into the 'env' of the call and match the
  # env['kind'] value to see if we have it registered.
  # If found, we pass to the proper handler, else we run a not_found
  # handler. Sans a registered not_found handler, we just return a
  # 404 message. Note that if we used any Async middleware (i.e.
  # EmRunner or CelluloidRunner), the calling client (using Msgpack RPC)
  # will not see the 404 or not found handler results. The Async middleware
  # will have returned a 202 Accepted result.
  #
  # Developers SHOULD implement alternate mechanisms of error handling
  # and logging. Even possibly implementing a 404 handler that
  # broadcasts such a not found error event message.
  #
  class KindMapper

    def initialize(options={})
      @map = options.fetch(:map) { {} }
      @not_found = options[:not_found]
    end

    def call(env)
      kind = env['kind']
      if kind && @map.has_key?(kind)
        return @map[kind].call env
      elsif @not_found
        return @not_found.call env
      end
      return [
        404,
        {
          'Content-Type' => 'text/plain',
          'X-Cascade' => 'pass'
        },
        ['Not Found']
      ]
    end

  end

end
end
