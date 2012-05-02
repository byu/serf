require 'active_support/concern'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/inflections'

module Serf

  ##
  # A module to represent a message that we're transporting over
  # the wire. This is mainly for commands and events in ED-SOA.
  # Optional, but useful for validations, etc.
  #
  module Message
    extend ActiveSupport::Concern

    included do
      class_attribute :kind
      send 'kind=', self.to_s.underscore
      class_attribute :model_name
      send 'model_name=', self.to_s
    end

    def to_hash
      attributes.merge kind: kind
    end

    def to_msgpack
      to_hash.to_msgpack
    end

    def to_json(*args)
      to_hash.to_json *args
    end

    def model
      self.class
    end

    def full_error_messages
      errors.full_messages.join '. '
    end

    module ClassMethods

      def parse(*args, &block)
        self.new *args, &block
      end

      def build(*args, &block)
        self.new *args, &block
      end

    end

  end

end
