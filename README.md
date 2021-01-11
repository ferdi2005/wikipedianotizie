# Prima Pagina
Bot sviluppato per aggiornare automaticamente la sezione dedicata agli ultimi articoli di [Wikinotizie in lingua italiana](https://it.wikinews.org/)
## Installazione
È necessario avere `ruby` installato e dare il comando:
```
gem install mediawiki_api wikinotizie
```
Fatto ciò, potrete tranquillamente avviare il bot digitando nel terminale `ruby primapagina.rb`. Al primo avvio vi verranno chiesti username e password del bot, da ottenere tramite Speciale:BotPasswords.

Il bot usufruisce della gem autocreata Wikinotizie per parasare le date degli articoli.
## Cron
Potete aggiungere lo script alla crontab affinché sia eseguito ciclicamente (in questo esempio a mezzanotte e alle 12), chiedendo `which ruby `ed inserendo in crontab una cosa del genere (sostituendo user col nome del vostro utente, /usr/bin/ruby col risultato di which ruby e directory col path allo script):
```
0 0,12 * * * user /usr/bin/ruby /directory/primapagina.rb
```
## Contribuire
Ogni contributo è ben accetto!
