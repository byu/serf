require 'factory_girl'
require 'hashie'
require 'securerandom'

FactoryGirl.define do
  sequence(:random_string) { SecureRandom.hex }

  factory :random_response_parcel, class: Hashie::Mash do
    headers {{
      uuid: generate(:random_string),
      kind: generate(:random_string)
    }}
    message {{
      some_data: generate(:random_string)
    }}
  end
end
