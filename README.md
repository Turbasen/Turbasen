API for Nasjonal Turbase
========================

## Resurser

* Turer
* Steder
* Områder
* Bilder
* Grupper
* Aktiviteter (kommer)

### Turer

#### List ut turer

`curl "dev.nasjonalturbase.no/turer?api_key=abc123"`

```json
{
  "documents":[
    {
      "_id":"524081f9b8cb77df150006b9",
      "endret":"2010-07-07T08:14:43.000Z",
      "navn":"Fra Røros til Femundsmarka på sykkel"
    },
    {
      "_id":"524081f9b8cb77df150006f2",
      "endret":"2010-10-28T09:35:17.000Z",
      "navn":
"Padletur rundt Selja ved Stadlandet"
    },
    {...}
  ]
}
```

#### Hent en tur

`curl "dev.nasjonalturbase.no/turer/524081f9b8cb77df150006b9?api_key=abc123"`

```json
{
  "_id":"524081f9b8cb77df150006b9",
  "tilbyder":"DNT",
  "opprettet":"2010-07-07T08:14:43.000Z",
  "endret":"2010-07-07T08:14:43.000Z",
  "lisens":"CC BY-NC-ND 3.0 NO",
  "navngivning":"Turen er levert via <a href=\"http://ut.no\">UT.no</a> og lisensiert under <a href=\"http://creativecommons.org/licenses/by-nc-nd/3.0/no\">CC BY-NC-ND 3.0</a>",
  "status":"Offentlig",
  "navn":"Fra Røros til Femundsmarka på sykkel",
  ...
}
```

### Steder

`curl "dev.nasjonalturbase.no/steder?api_key=abc123"`

```json
{
  "documents":[
    {
      "_id":"52407fb375049e5615000294",
      "endret":"1970-01-16T15:09:24.647Z",
      "navn":"Reisadalen hytteutleie"
    },
    {
      "_id":"52407fb375049e561500031c",
      "endret":"1970-01-16T20:29:04.710Z",
      "navn":"Sappen leirskole og feriesenter"
    },
    {...}
  ]
}
```

`curl "dev.nasjonalturbase.no/steder/52407fb375049e5615000294?api_key=abc123"`

```json
{
  "_id":"52407fb375049e5615000294",
  "tilbyder":"DNT",
  "opprettet":"1970-01-16T15:09:24.647Z",
  "endret":"1970-01-16T15:09:24.647Z",
  "lisens":"CC BY-NC-ND 3.0 NO",
  "navngivning":"Hytten er levert via <a href=\"http://ut.no\">UT.no</a> og lisensiert under <a href=\"http://creativecommons.org/licenses/by-nc-nd/3.0/no\">CC BY-NC-ND 3.0</a>",
  "status":"Offentlig",
  "navn":"Reisadalen hytteutleie",
  {...}
}
```

## Parametre

### api_key

`curl "dev.nasjonalturbase.no?api_key=acb123"`

### skip

`curl "dev.nasjonalturbase.no/turer?api_key=abc123&skip=10"`

### limit

`curl "dev.nasjonalturbase.no/turer?api_key=abc123&limit=20"`

### after

`curl "dev.nasjonalturbase.no/turer?api_key=abc123&after=2013-11-06"`

### tag

`curl "dev.nasjonalturbase.no/steder?api_key=abc123&tag=Hytte`
`curl "dev.nasjonalturbase.no/steder?api_key=abc123&tag=!Hytte`

