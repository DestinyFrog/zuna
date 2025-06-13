#!/usr/bin/bash

if [[ $1 = "help" ]]; then
    echo "./bee.sh build        - Build the 'pack.lua' file to run as service";
    echo "./bee.sh dev          - Run as developer content in 'example.z1'";
    echo "./bee.sh database     - Setup database";
fi

if [[ $1 = "build" ]]; then
    luajit -b pack.lua pack.luac;
fi

if [[ $1 = "dev" ]]; then
    while true; do
        clear;
        lua zuna/Print.lua example.z1;
        sleep 0.5;
    done
fi

if [[ $1 = "database" ]]; then
    rm zuna.db;
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