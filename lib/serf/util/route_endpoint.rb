module Serf
module Util

  ##
  # A simple class to represent route endpoints. RouteSets
  # store a list of endpoints per matcher, and Runners use endpoints
  # to then execute the handlers.
  #
  class RouteEndpoint
    # Actual handler object that defines the action method.
    attr_accessor :handler
    # The method to call.
    attr_accessor :action
    # A parser that turns the message ENV hash into a Message object
    # that the handler#action uses.
    attr_accessor :message_parser

    def initialize(options={})
      # Mandatory parameters
      @handler = options.fetch :handler
      @action = options.fetch :action

      # Optional parameters
      @message_parser = options[:message_parser]
    end

    ##
    # Default factory method.
    #
    def self.build(options={})
      return self.new options
    end

  end

end
end
