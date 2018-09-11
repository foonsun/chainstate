#!/bin/sh

SCRIPT=$(cd $(dirname $0); /bin/pwd)
COIN=${1:-bitcoin}
COINDAEMON=${2:-$COIN}
COINDIR=${3:-$COIN}
RANDOMSTR=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
BALANCES_FILE=balances-${COIN}-$(TZ=UTC date +%Y%m%d-%H%M)-${RANDOMSTR}
BALANCES_FILE_SAMPLE=balances-${COIN}-$(TZ=UTC date +%Y%m%d-%H%M)-sample

echo "Cleaning existing files..."
rm -f state cs.out cs.err

echo "Stopping ${COINDAEMON}..."
#sudo service bitcoind stop
#sudo supervisorctl stop bitcoin
ps aux |grep "bitcoind" |grep -v -e "grep" |awk '{print $2}'|xargs kill -9

echo "Copying chainstate..."
cp -Rp ~/.${COINDIR}/chainstate state

echo "Syncing..."
sync

echo "Copying done. Restarting ${COINDAEMON}..."
#sudo service bitcoind start
#sudo supervisorctl start bitcoin
/home/ubuntu/bitcoin-0.15.1/bin/bitcoind --conf=/home/ubuntu/.bitcoin/bitcoin.conf --daemon

echo "flush bitcoin redis..."
redis-cli 'flushdb'

echo "Running chainstate parser..."
./chainstate ${COIN} >cs.out 2>cs.err

echo "Generated output:"
ls -l cs.out cs.err

if test ! -e cs.out; then
    echo "Missing input file (cs.out)"
    exit 1
fi

echo "Generating & sorting final balances..."
cut -d';' -f3,4 cs.out | \
    sort | \
    awk -F ';' '{ if ($1 != cur) { if (cur != "") { print cur ";" sum }; sum = 0; cur = $1 }; sum += $2 } END { print cur ";" sum }' | \
    sort -t ';' -k 2 -g -r > ${BALANCES_FILE}

head -100 ${BALANCES_FILE} | sed -e 's/..................;/\.\.\.\.\.\.\[truncated\]\.\.\.\.\.\.;/' > ${BALANCES_FILE_SAMPLE}

echo "Compressing balances"
gzip ${BALANCES_FILE}
gzip ${BALANCES_FILE_SAMPLE}

echo "Generated archive"
ls -l ${BALANCES_FILE}.gz
ls -l ${BALANCES_FILE_SAMPLE}.gz

echo "move to data dir"
mv ${BALANCES_FILE}.gz ${BALANCES_FILE_SAMPLE}.gz ./data/

echo "Cleaning state"
rm -fr state cs.out cs.err
 
TOTALBALANCES_FILE=totalbalances-bitcoin-$(TZ=UTC date +%Y%m%d-%H%M).log
redis-cli --eval ./scripts/cal_all_bitcoin_balances.lua 1 z >./data/${TOTALBALANCES_FILE}

TOTALADDRESSES_FILE=totaladdresses-bitcoin-$(TZ=UTC date +%Y%m%d-%H%M).log
redis-cli --eval ./scripts/cal_all_bitcoin_address_count.lua >./data/${TOTALADDRESSES_FILE}

bash /home/ubuntu/pyblockchainserver/scripts/get_btc_top1000.sh

exit 0
