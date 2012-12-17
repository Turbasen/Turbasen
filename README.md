API for Nasjonal Turbase
========================

Adressen til api er: http://api.nasjonalturbase.no/versjon/ , og alle kall må sende med parameter "api_key" for autentisering.
F.eks: http://api.nasjonalturbase.no/v0/?api_key=dnt

Det legges på https:// etter hvert.

The Basics
----------



###Parametre
API kan benyttes med følgende parametre:
api_key=dnt
Hver innholdspartner får sin egen api_key. 

method=post
Hvilken metode som skal benyttes i REST-kallet. Verdier er [ get | post | put | del ]
Hvis ikke method sendes med vil det antas at method=get.
method=put oppfører seg som en HTTP PATCH, og vil kun overskrive spesifiserte felter.

data={json-objekt}
Objekter til post og put sendes i data-parameter enten som HTTP GET (i url/querystringen) eller HTTP POST (i POST HEADER) parameter.

callback=MyFunc
Hvis parameter "callback=MyFunc" sendes med vil retur-json pakkes inn i et funksjonskall med navn lik verdien på parameter "callback" - i dette tilfellet "MyFunc". JSONP.

limit=5
Returnere de første 5 resultater

offset=10
Hoppe over de 10 første objektene i resultatet

Eksempler
---------
Nasjonal Turbase inneholder objekttypene: "turer" og "steder".

###Turer:
*For å liste ut turer*
http://api.nasjonalturbase.no/v0/turer/?api_key=dnt

*..med offset (hvor mange som hoppes over), og limit (hvor mange som listes ut)*
http://api.nasjonalturbase.no/v0/turer/?api_key=dnt&offset=5&limit=3&callback=ntb_callback

*For å legge inn en ny tur*
http://api.nasjonalturbase.no/v0/turer/?api_key=dnt&method=post&data={"navn":"Testtur","beskrivelse":"Her er beskrivelsen"}

Kallet returnerer json-objektet (i et array) med innlagt "_id" på objektet, eller en feilmelding.

*For å oppdatere navnet på tur med id 508ec09cd71b8f0000000001*
http://api.nasjonalturbase.no/v0/turer/508ec09cd71b8f0000000001?api_key=dnt&method=put&data={"navn":"Nytt navn"}

Kallet returnerer oppdatert json-objekt (i et array)

*For å slette tur med id 508ec09cd71b8f0000000001*
http://api.nasjonalturbase.no/v0/turer/508ec09cd71b8f0000000001?api_key=dnt&method=del

*Objektstruktur for turer*
Nøyaktig hvilke feltnavn og datastruktur tur-objekter skal ha blir en standardiseringsprosess. Det er kanskje naturlig å ta utgangspunkt i eksisterende felter i Sherpa/UT.no, men de bør fornorskes og forenkles.

###Steder:
*For å liste ut steder*
http://api.nasjonalturbase.no/v0/steder/?api_key=dnt

..ellers som for turer.
