require "active_record"

ActiveRecord::Base.establish_connection(
  adapter:  'mysql2',
  host:     'localhost',
  username: ENV['BITCOIN_ACCOUNT_BALANCE_USERNAME'],
  password: ENV['BITCOIN_ACCOUNT_BALANCE_PASSWORD'],
  database: ENV['BITCOIN_ACCOUNT_BALANCE_DATABASE'],
)


class AddressBalance < ActiveRecord::Base
end
