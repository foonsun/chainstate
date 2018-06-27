TOTALBALANCES_FILE=totalbalances-bitcoin-$(TZ=UTC date +%Y%m%d-%H%M).log
redis-cli --eval cal_all_bitcoin_balances.lua 1 z >../data/${TOTALBALANCES_FILE}
