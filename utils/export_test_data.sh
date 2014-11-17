#! /bin/bash

for col in turer steder bilder områder grupper; do
  mongoexport --jsonArray --db test --collection $col --out "test/data/$col.json"
done

