#! /bin/bash

for col in steder bilder områder grupper; do
  mongoimport --drop --jsonArray --db test --collection $col --file "test/data/$col.json"
done

