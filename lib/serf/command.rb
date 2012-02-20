module Serf

  ##
  # A base class for Serf users to implement a Command pattern.
  #
  #   class MyCommand < Serf::Command
  #     def call
  #       # Do something w/ @request and @opts
  #       return nil # e.g. MySerfMessage
  #     end
  #     protected
  #     def request_parser
  #       @opts[:request_parser] || MySerfRequestMessage
  #     end
  #   end
  #
  class Command
    attr_reader :request
    attr_reader :options

    def initialize(request, *args)
      @args = args
      @options = @args.last.is_a?(::Hash) ? pop : {}

      @request = request.is_a?(Hash) ? request_parser.parse(request) : request

      # We must first verify that the request is valid.
      unless @request.valid?
        raise ArgumentError, @request.errors.full_messages.join('. ')
      end
    end

    def call
      raise NotImplementedError
    end

    def self.call(request, *args)
      self.new(request, *args).call
    end

    protected

    def opts(key, default=nil)
      if default.nil?
        return @options.fetch key
      else
        return @options.fetch(key) { default }
      end
    end

    def request_parser
      raise ArgumentError, 'Parsing Hash request is Not Supported'
    end

  end

end
