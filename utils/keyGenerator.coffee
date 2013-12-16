console.log require('crypto').createHash(process.argv[2] or 'sha1').update(require('crypto').randomBytes(20)).digest('hex')
