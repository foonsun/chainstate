local z=redis.call('zcount','bitcoin_address_balances_chainstate', 0, 99999999999999999999999)
return z
