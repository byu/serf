require 'hashie'

module Serf
module Util

  ##
  # A Request Factory that just coerces a REQUEST ENV hash message
  # into a Hashie::Mash object for convenience key/value access.
  #
  module MashFactory

    def self.build(message)
      Hashie::Mash.new message
    end
  end

end
end
