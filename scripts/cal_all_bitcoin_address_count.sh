TOTALADDRESSES_FILE=totaladdresses-bitcoin-$(TZ=UTC date +%Y%m%d-%H%M).log
redis-cli --eval cal_all_bitcoin_address_count.lua >./data/${TOTALADDRESSES_FILE}
