require 'serf/util/with_options_extraction'

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
    include Serf::Util::WithOptionsExtraction

    attr_reader :request

    def initialize(request, *args)
      extract_options! args
      @args = args

      @request = request.is_a?(Hash) ? request_parser.parse(request) : request

      # We must first verify that the request is valid.
      unless @request.valid?
        raise ArgumentError, @request.full_error_messages
      end
    end

    def call
      raise NotImplementedError
    end

    def self.call(request, *args)
      self.build(request, *args).call
    end

    def self.build(request, *args)
      self.new(request, *args)
    end

    protected

    def request_parser
      raise ArgumentError, 'Parsing Hash request is Not Supported'
    end

  end

end
