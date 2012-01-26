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
      send 'kind=', self.to_s.tableize.singularize
    end

    def kind
      self.class.kind
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

    module ClassMethods

      def parse(*args)
        self.new *args
      end

    end

  end

end
