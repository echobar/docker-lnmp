#!/bin/bash

bk_dir=/home/docker/lnmp/bk/db
db_name=ledger_test
time=` date +%Y%m%d%H `
mysqldump -h 127.0.0.1 -P 9306 -u root -proot ${db_name} | gzip > $bk_dir/${db_name}_$time.sql.gz
find $bk_dir -name "${db_name}_*.sql.gz" -type f -mtime +3 -exec rm {} \; > /dev/null 2>&1
