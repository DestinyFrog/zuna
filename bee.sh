#!/usr/bin/bash

if [[ $1 = "help" ]]; then
    echo "./bee.sh build        - Build the 'pack.lua' file to run as service";
    echo "./bee.sh dev          - Run as developer content in 'example.z1'";
    echo "./bee.sh database     - Setup database";
    exit 0;
fi

if [[ $1 = "build" ]]; then
    luajit -b pack.lua pack.luac;
fi

if [[ $1 = "dev" ]]; then
    while true; do
        clear;
        lua zuna/print.lua example.z1;
        sleep 1;
    done
fi

if [[ $1 = "database" ]]; then
    if ! command -v sqlite3 >/dev/null 2>&1
    then
        apt -y install sqlite3;
    fi

    if [ -f zuna.db ]; then
        rm zuna.db;
    fi

    sqlite3 zuna.db < up.sql;
    for f in examples/*.z1; do
        SQL=`lua zuna/sql.lua $f`;
        sqlite3 zuna.db "$SQL";
    done
fi

if [[ $1 = "sql" ]]; then
    if [ -f setup.sql ]; then
        rm setup.sql;
    fi
    
    UPSQL=`cat up.sql`;
    echo "$UPSQL" >> setup.sql;
    for f in examples/*.z1; do
        SQL=`lua zuna/sql.lua $f`;
        echo "$SQL;" >> setup.sql;
    done
fi