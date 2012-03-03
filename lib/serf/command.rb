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

      # If the request was a hash, we MAY be able to parse it into an
      # object. We only do this if a request_parser is defined by
      # an implementing subclass. Otherwise, just give the command
      # the hash, and it is up to them to understand what was given
      # to it.
      @request = (
        request.is_a?(Hash) && request_parser ?
        request_parser.parse(request) :
        request)

      # We must verify that the request is valid, but only if the
      # request object isn't a hash.
      unless @request.is_a?(Hash) || @request.valid?
        raise ArgumentError, @request.full_error_messages
      end
    end

    def call
      raise NotImplementedError
    end

    def self.call(*args)
      self.build(*args).call
    end

    def self.build(*args)
      self.new *args
    end

    protected

    def request_parser
      nil
    end

  end

end
