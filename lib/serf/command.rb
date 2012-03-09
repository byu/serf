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
  #     self.request_factory = MySerfRequestMessage
  #
  #     def initialize(*args, &block)
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
  #   # Built in lambda wrapping to use the MyCommand with GirlFriday.
  #   worker = MyCommand.worker some, extra, params, options_hash, &block
  #   work_queue = GirlFriday::WorkQueue.new &worker
  #   work_queue.push REQUEST_ENV
  #
  module Command
    extend ActiveSupport::Concern
    include Serf::Util::WithOptionsExtraction

    included do
      class_attribute :request_factory
      attr_reader :request
    end

    def call
      raise NotImplementedError
    end

    def validate_request!
      # We must verify that the request is valid, but only if the
      # request object isn't a hash.
      unless request.is_a?(Hash) || request.valid?
        raise ArgumentError, request.full_error_messages
      end
    end

    module ClassMethods

      ##
      # Class method that both builds then executes the unit of work.
      #
      def call(*args, &block)
        self.build(*args, &block).call
      end

      ##
      # Factory build method that creates an object of the implementing
      # class' unit of work with the given parameters.
      #
      def build(*args, &block)
        # The very first argument is the Request, we shift it off the args var.
        req = args.shift
        req = {} if req.nil?

        # Now we allocate the object, and do some options extraction that may
        # modify the args array by popping off the last element if it is a hash.
        obj = allocate
        obj.send :__send__, :extract_options!, args

        # If the request was a hash, we MAY be able to convert it into a
        # request object. We only do this if a request_factory was set either
        # in the options, or if the request_factory class attribute is set.
        # Otherwise, just give the command the hash, and it is up to them
        # to understand what was given to it.
        factory = obj.opts :request_factory, self.request_factory
        request = (req.is_a?(Hash) && factory ? factory.build(req) : req)

        # Set the request instance variable to whatever type of request we got.
        obj.instance_variable_set :@request, request

        # Now validate that the request is ok.
        # Implementing classes MAY override this method to do different
        # kind of request validation.
        obj.validate_request!

        # Finalize the object's construction with the rest of the args & block.
        obj.send :__send__, :initialize, *args, &block

        return obj
      end

      ##
      # Generates a curried function to execute a Command's call class method.
      #
      # @returns lambda block to execute a call.
      #
      def worker(*args, &block)
        lambda { |message|
          self.call message, *args, &block
        }
      end

    end
  end
end
