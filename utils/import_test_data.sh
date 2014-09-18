#! /bin/bash

for col in turer steder bilder områder grupper; do
  mongoimport --drop --jsonArray --db test --collection $col --file "test/data/$col.json"
done

