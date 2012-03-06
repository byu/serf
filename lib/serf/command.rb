require 'active_support/concern'
require 'active_support/core_ext/class/attribute'

require 'serf/util/with_options_extraction'

module Serf

  ##
  # A base class for Serf users to implement a Command pattern.
  #
  #   class MyCommand
  #     include Serf::Command
  #
  #     # Set a default Message Parser for the class.
  #     self.request_parser = MySerfRequestMessage
  #
  #     def initialize(*args)
  #       # Do some validation here, or extra parameter setting with the args
  #     end
  #
  #     def call
  #       # Do something w/ @request and @opts
  #       return nil # e.g. MySerfMessage
  #     end
  #   end
  #
  #   MyCommand.call(REQUEST_ENV, some, extra, params, options_hash, &block)
  #
  module Command
    extend ActiveSupport::Concern
    include Serf::Util::WithOptionsExtraction

    included do
      class_attribute :request_parser
      attr_reader :request
    end

    def call
      raise NotImplementedError
    end

    module ClassMethods

      def call(*args, &block)
        self.build(*args, &block).call
      end

      def build(*args, &block)
        # The very first argument is the Request, we shift it off the args var.
        req = args.shift
        req = {} if req.nil?

        # Now we allocate the object, and do some options extraction that may
        # modify the args array by popping off the last element if it is a hash.
        obj = allocate
        obj.send :__send__, :extract_options!, args

        # We've got a request object, so let's go ahead and set it as the
        # object's instance variable.
        request = self.parse_request req, obj.opts(:request_parser)
        obj.instance_variable_set :@request, request

        # Finalize the object's construction  with the rest of the args & block.
        obj.send :__send__, :initialize, *args, &block

        return obj
      end

      def parse_request(req, parser=nil)
        parser = self.request_parser if parser.nil?

        # If the request was a hash, we MAY be able to parse it into an
        # object. We only do this if a request_parser class attribute is set.
        # Otherwise, just give the command the hash, and it is up to them
        # to understand what was given to it.
        request = (
          req.is_a?(Hash) && parser ?
          parser.parse(req) :
          req)

        # We must verify that the request is valid, but only if the
        # request object isn't a hash.
        unless request.is_a?(Hash) || request.valid?
          raise ArgumentError, request.full_error_messages
        end

        return request
      end

    end
  end
end
