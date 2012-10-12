require 'hashie'

module Serf

  ##
  # A parcel is the bundle of data of headers and message
  # for both requests and responses in Serf.
  #
  class Parcel < Hashie::Dash
    property :headers
    property :message

    def self.build(headers, message)
      self.new headers: headers, message: message
    end

    ##
    # Splat the headers and message
    def to_ary
      to_a
    end

    ##
    # Convert the Parcel to a parcel pair (array).
    def to_a
      [headers, message]
    end
  end

end
