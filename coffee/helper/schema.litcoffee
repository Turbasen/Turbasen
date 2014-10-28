    joi = require 'joi'

## All

### Required

These fields are required for all objects.

    exports.required =
      _id: joi.string().regex(/^[a-f0-9]{24}$/)
      tilbyder: joi.string()
      endret: joi.string()
      checksum: joi.string()
      lisens: joi.string().valid([
        'Privat' # @TODO This is just temporarily
        'CC BY 3.0 NO'
        'CC BY-SA 3.0 NO'
        'CC BY-ND 3.0 NO'
        'CC BY-NC 3.0 NO'
        'CC BY-NC-SA 3.0 NO'
        'CC BY-NC-ND 3.0 NO'
        'CC BY 4.0'
        'CC BY-SA 4.0'
        'CC BY-ND 4.0'
        'CC BY-NC 4.0'
        'CC BY-NC-SA 4.0'
        'CC BY-NC-ND 4.0'
      ])
      navngiving: joi.string()
      status: joi.string().valid([
        'Offentlig'
        'Privat'
        'Kladd'
        'Slettet'
      ])

### Optional

There optional are optional for all objects.

    exports.optional =
      navn: joi.string()
      kommuner: joi.array().includes(joi.string())
      fylker: joi.array().includes(joi.string())
      områder: joi.array().includes(joi.string().regex(/^[a-f0-9]{24}$/))
      beskrivelse: joi.string()
      lenker: joi.array().includes(joi.object(
        tittel: joi.string().optional()
        type: joi.string().optional()
        url: joi.string().regex(/^https?:\/\//)
      ))
      tags: joi.array().includes(joi.string())
      privat: joi.object()
      grupper: joi.array().includes(joi.string().regex(/^[a-f0-9]{24}$/))
      steder: joi.array().includes(joi.string().regex(/^[a-f0-9]{24}$/))
      bilder: joi.array().includes(joi.string().regex(/^[a-f0-9]{24}$/))
      url: joi.string().regex(/^https?:\/\//)

## Data types

    exports.type =

### Bilder

      bilder:
        geojson: joi.object(
          type: joi.string().valid('Point').required()
          properties: joi.object(
            altitude: joi.number().integer()
          )
          coordinates: joi.array().includes(joi.number()).length(2).required()
        )
        fotograf: joi.object(
          navn: joi.string()
          telefon: joi.string()
          epost: joi.string().email()
        )
        eier: joi.object(
          navn: joi.string()
          telefon: joi.string()
          epost: joi.string().email()
          url: joi.string().regex(/^https?:\/\//)
        )
        img: joi.array().includes(joi.object(
          url: joi.string().regex(/^https?:\/\//).required()
          width: joi.number().integer()
          height: joi.number().integer()
          size: joi.number()
        ))

### Grupper

      grupper:
        geojson: joi.object(
          type: joi.string().valid('Polygon').required()
          coordinates: joi.array().includes(
            joi.array().includes(
              joi.array().includes(joi.number()).length(2)
            )
          ).required()
        )
        organisasjonsnr: joi.string()
        logo: joi.string().regex(/^https?:\/\//)
        ansatte: joi.number().integer()
        kontaktinfo: joi.array().includes(joi.object(
          tittel: joi.string()
          adresse1: joi.string()
          adresse2: joi.string()
          postnummer: joi.number().integer()
          poststed: joi.string()
          land: joi.string()
          telefon: joi.string()
          fax: joi.string()
          epost: joi.string().email()
          url: joi.string().regex(/^https?:\/\//)
        ))
        foreldregruppe: joi.string().regex(/^[a-f0-9]{24}$/)

### Turer

      turer:
        geojson: joi.object(
          type: joi.string().valid('LineString').required()
          coordinates: joi.array().includes(
            joi.array().includes(joi.number()).length(2)
          ).required()
        )
        distanse: joi.number()
        retning: joi.string().valid([
          "AB"
          "BA"
          "ABA"
          "BAB"
        ])
        adkomst: joi.string()
        gradering: joi.string().valid([
          "Enkel"
          "Middels"
          "Krevende"
          "Ekspert"
        ])
        passer_for: joi.array().includes(joi.string())
        tilrettelagt_for: joi.array().includes(joi.string())
        sesong: joi.array().includes(joi.number().integer().min(1).max(12))
        tidsbruk: joi.object(
          normal: joi.object(
            dager: joi.number().integer()
            timer: joi.number().integer()
            minutter: joi.number().integer()
          )
          min: joi.object(
            dager: joi.number().integer()
            timer: joi.number().integer()
            minutter: joi.number().integer()
          )
          max: joi.object(
            dager: joi.number().integer()
            timer: joi.number().integer()
            minutter: joi.number().integer()
          )
        )

### Områder

      områder:
        geojson: joi.object(
          type: joi.string().valid('Polygon').required()
          coordinates: joi.array().includes(
            joi.array().includes(
              joi.array().includes(joi.number()).length(2)
            )
          ).required()
        )
        foreldreområder: joi.array().includes(joi.string().regex(/^[a-f0-9]{24}$/))

### Steder

      steder:
        navn_alt: joi.array().includes(joi.string())
        ssr_id: joi.number().integer()
        geojson: joi.object(
          type: joi.string().valid('Point').required()
          properties: joi.object(
            altitude: joi.number().integer()
          )
          coordinates: joi.array().includes(joi.number()).length(2).required()
        )
        kommune: joi.string()
        fylke: joi.string()
        adkomst: joi.object(
          sommer: joi.string()
          vinter: joi.string()
        )
        tilrettelagt_for: joi.array().includes(joi.string())
        fasiliteter: joi.object()
        byggeår: joi.number().integer()
        besøksstatisikk: joi.object()
        betjeningsgrad: joi.string()
        kart: joi.string()
        turkart: joi.array().includes(joi.string())

