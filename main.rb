$LOAD_PATH.push('.')

require 'json'
require 'time'

require 'address_balance'
require 'height'

LOG_FILE = 'log.txt'

Coinbase = Struct.new(:coinbase, :sequence)
Vin = Struct.new(:txid, :index)
Vout = Struct.new(:value, :addresses)

class GetRawTransactionError < StandardError; end

def log(msg)
  puts msg
  open(LOG_FILE, 'a') do |f|
    f << "[#{Time.new}] #{msg}\n"
  end
end

def get_blockhash_value(height)
  `bitcoin-cli getblockhash #{height}`.strip
end

def get_block(blockhash)
  JSON.parse(`bitcoin-cli getblock #{blockhash}`)
end

def transactions(block_json)
  block_json['tx']
end

def get_raw_transaction(txid)
  result = `bitcoin-cli getrawtransaction #{txid} 1`
  if result.empty?
    raise GetRawTransactionError
  end
  JSON.parse(result)
end

def vins(transaction_json)
  transaction_json['vin'].map do |i|
    txid = i['txid']
    index = i['vout']
    coinbase = i['coinbase']
    sequence = i['sequence']
    if txid && index
      Vin.new(txid, index.to_i)
    elsif coinbase
      Coinbase.new(coinbase, sequence.to_i)
    else
      log "#{transaction_json['txid']}: unknown vin, #{i}"
      nil
    end
  end
end

def vouts(transaction_json)
  puts "txid = #{transaction_json['txid']}"
  transaction_json['vout'].inject([]) do |memo_ary, out|
    addresses = out['scriptPubKey']['addresses']
    if addresses.nil?
      # "type": "nulldata"でaddressesがないときがあった
      # txid = 06f36d781af55d4ab4665d791efed6d4e6a6b20571b0f9f8411c5db0c5308065
      log "#{transaction_json['txid']}: addresses is nil, #{out}"
    end
    if addresses
      memo_ary << Vout.new(out['value'].to_f, addresses)
    end
    memo_ary
  end
end

def headers
  JSON.parse(`bitcoin-cli getblockchaininfo`)['headers']
end

def blocks
  JSON.parse(`bitcoin-cli getblockchaininfo`)['blocks']
end

def calculate(vouts, operator)
  vouts.inject(Hash.new(0)) do |memo_hash, vout|
    vout.addresses.each do |a|
      memo_hash[a] = memo_hash[a].__send__(operator, vout.value)
    end
    memo_hash
  end
end

height = Height.first ? Height.first.height + 1 : 0
Height.create! unless Height.first
loop do
  puts "height = #{height}"
  block_hash_value = get_blockhash_value(height)
  block_json = get_block(block_hash_value)
  hash = {} # address => value のHashインスンタンス
  transactions(block_json).each do |txid|
    begin
      transaction_json = get_raw_transaction(txid)
    rescue => e
      p e
      next
    end
    plus_hash = calculate(vouts(transaction_json), :+)
    spent_utxos = vins(transaction_json).reject { |vin| Coinbase === vin }.reject(&:nil?)
                          .map { |vin| vouts(get_raw_transaction(vin.txid))[vin.index] }
    minus_hash = calculate(spent_utxos, :-)
    merge_proc = -> (key, self_val, other_val) { self_val + other_val }
    hash.merge!(plus_hash, &merge_proc)
    hash.merge!(minus_hash, &merge_proc)
  end
  p hash
  AddressBalance.transaction do
    puts 'writing database...'
    hash.each do |a, coin|
      ab = AddressBalance.find_or_create_by(address: a)
      ab.update_attributes!(balance: ab.balance + coin)
    end
    Height.first.update_attributes!(height: height)
  end

  height = height + 1
  break if height > blocks
end
