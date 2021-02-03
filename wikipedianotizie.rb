require 'mediawiki_api'
require 'date'
require 'wikinotizie'

if !File.exist? "#{__dir__}/.config"
  puts 'Inserisci username:'
  print '> '
  username = gets.chomp
  puts 'Inserisci password:'
  print '> '
  password = gets.chomp
  puts 'Incolla nome del file contenente il contenuto aggiuntivo:'
  print '> '
  contentutoiniziale = gets.chomp
  File.open("#{__dir__}/.config", "w") do |file| 
    file.puts username
    file.puts password
    file.puts contentutoiniziale
  end
end
userdata = File.open("#{__dir__}/.config", "r").to_a

# Contenuto finale standard
contenutofinale = "<noinclude>==Istruzioni==
Per gli inserimenti manuali è consigliabile:
*restare nel numero massimo di <u>6 articoli</u>;
*inserire <u>solo</u> articoli che in Wikinotizie sono nella [[n:Categoria:Pubblicati|Categoria:Pubblicati]];
*<u>evitare e rimuovere a vista</u> articoli promozionali o comunque problematici, anche quando in Wikinotizie possono restare pubblicati;
*privilegiare gli articoli con un buon bilancio tra novità, interesse e rilevanza;
*salvo casi particolari, il tempo di permanenza massimo degli articoli è di <u>7 giorni</u>; se non ci sono articoli recenti, l'elenco resta vuoto.</noinclude>"

# Inizializzo i client su Wikinotizie e Wikipedia e faccio login
wikinotizie = MediawikiApi::Client.new 'https://it.wikinews.org/w/api.php'
wikipedia = MediawikiApi::Client.new 'https://it.wikipedia.org/w/api.php'

# Faccio il login su Wikipedia
wikipedia.log_in "#{userdata[0].gsub("\n", "")}", "#{userdata[1].gsub("\n", "")}"

pubblicati = wikinotizie.query(list: :categorymembers, cmtitle: "Categoria:Pubblicati", cmsort: :timestamp, cmdir: :desc, cmlimit: :max)["query"]["categorymembers"]

# Rigetto cose non nel ns0 (eventuali errori)
pubblicati.reject! { |pubblicato| pubblicato["ns"] != 0 }

# Per ogni articolo ottengo il contenuto
pubblicati.map do |pubblicato|
    content = wikinotizie.query(prop: :revisions, rvprop: :content, titles: pubblicato["title"], rvlimit: 1)["query"]["pages"]["#{pubblicato["pageid"]}"]["revisions"][0]["*"]
    byebug if content.nil?
    # Processo il contenuto con la gem Wikinotizie
    # content = [content, match, data, giorno, rubydate, with_luogo, luogo]
    parsed = Wikinotizie.parse(content)
    pubblicato[:data], pubblicato[:giorno], pubblicato[:rubydate] = parsed[2], parsed[3], parsed[4] unless parsed == false
end

# Rimuovo articoli che la gem non è riuscita a processare
pubblicati = pubblicati.delete_if { |p| p[:rubydate] == nil }

# Rimuovo gli articoli più vecchi di 7 giorni
pubblicati = pubblicati.delete_if { |p| p[:rubydate] < Date.today - 7}

# Ordino gli articoli per data e pesco solo i primi 6
pubblicati = pubblicati.sort_by {|p| p[:rubydate]}.reverse.first(6)

# Raggruppo per data
pubblicati = pubblicati.group_by{ |p| p[:data]}

# Array finale
list = []

# Aggiunge all'array lista i dati rilevanti di ogni articolo
pubblicati.each do |data, articoli|
    list.push(";#{articoli.first[:giorno]} #{data}")
    articoli.each do |articolo|
        list.push("* [[n:#{articolo["title"]}|#{articolo["title"]}]]")
    end
end

# Aggiungo eventuale contenuto aggiuntivo iniziale (es. banner)
unless userdata[2].nil?
    begin
        list.insert(0, File.read(userdata[2].strip))
    rescue Errno::ENOENT => e
        puts "#{e}: File con contenuto iniziale non trovato"
    end
end

# Aggiungo contenuto finale standard
list.push(contenutofinale)

# Salvo sulla pagina apposita di Wikipedia
wikipedia.edit(title: "Template:Pagina_principale/Notizie/Auto", text: list.join("\n"), summary: "Aggiorno articoli da Wikinotizie.")
puts "Salvataggio riuscito!"