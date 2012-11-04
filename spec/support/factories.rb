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

  factory :random_headers, class: Hashie::Mash do
    uuid { generate(:random_string) }
    kind { generate(:random_string) }
  end

  factory :random_message, class: Hashie::Mash do
    data { generate(:random_string) }
  end
end
