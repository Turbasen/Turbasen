console.log require('crypto').createHash('sha1').update(require('crypto').randomBytes(20)).digest('hex')
