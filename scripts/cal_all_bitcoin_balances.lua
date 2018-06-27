local sum=0
local z=redis.call('ZRANGE', 'bitcoin_address_balances_chainstate', 0, -1, 'WITHSCORES')
for i=2, #z, 2
do
    sum=sum+z[i]
end
return sum
