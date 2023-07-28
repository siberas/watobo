#!/usr/bin/env ruby
# https://linuxsecurity.com/features/best-practices-for-php-security
# https://www.php.net/manual/en/session.configuration.php
#
require 'json'
require 'optimist'
require 'pry'

OPTS = Optimist::options do
  version "#{$0} 0.1 (c) 2023 siberas"
  opt :ini_file, "filename of php.ini", :type => :string
  opt :php_version, "version of PHP", :type => :string, :default => "8.1"
  opt :clean, "removes comments and print configuration"
end

Optimist.die :ini_file, "Need ini file" unless OPTS[:ini_file]

ini_file = OPTS[:ini_file]
raise "INI file does not exist" unless File.exist?(ini_file)

policy = {
  "expose_php" => 'off',
  "allow_url_include" => 'off',
  "display_errors" => 'off',
  "session.cookie_httponly" => '1',
  "session.use_strict_mode" => '1',
  "session.cookie_secure" => '1',
  "session.cookie_samesite" => 'strict',
  "session.use_trans_sid" => '0',
  "session.sid_length" => '64',
  "session.sid_bits_per_character" => '5', # 5 is recommended value for most environments. <- https://www.php.net/manual/en/session.configuration.php
  "file_uploads" => 'off'
}

defaults = {
  "expose_php" => 'On',
  "allow_url_include" => 'Off',
  "display_errors" => 'On',
  "session.cookie_httponly" => '0',
  "session.use_strict_mode" => '0',
  "session.cookie_secure" => '0',
  "session.cookie_samesite" => '',
  "session.use_trans_sid" => '1',
  "session.sid_length" => '32',
  "session.sid_bits_per_character" => '4',
  "file_uploads" => 'On'
}
php_defaults_descriptions = {
  "expose_php" => 'Determines whether PHP should expose the fact that it is installed on the server, which could provide valuable information to attackers.',
  "allow_url_include" => 'Determines whether the "include" and "require" statements can be used with URLs, which can lead to code injection vulnerabilities if enabled.',
  "display_errors" => 'Determines whether errors should be printed to the output. In a production environment, this could reveal sensitive information.',
  "session.cookie_httponly" => 'Marks the cookie as accessible only through the HTTP protocol which helps to reduce the risk of a client-side script accessing the protected cookie.',
  "session.use_strict_mode" => 'Enforces strict session ID generation. If a user provides a session ID that doesn’t exist, PHP discards it and generates a new ID.',
  "session.cookie_secure" => 'Specifies whether cookies should only be sent over secure connections. It is recommended to enable this if your website supports HTTPS.',
  "session.cookie_samesite" => 'Prevents the browser from sending the cookie along with cross-site requests, which provides some protection against cross-site request forgery attacks.',
  "session.use_trans_sid" => 'Tells PHP whether to append the session ID to URLs. Can be a security risk if enabled as it exposes the session ID in the URL.',
  "session.sid_length" => 'Determines the number of characters in the session ID. More characters can increase security, but also use more storage and bandwidth.',
  "session.sid_bits_per_character" => 'Determines the number of bits per character in the session ID. More bits per character can increase security, but also use a larger range of characters.',
  "file_uploads" => 'Determines whether file uploads are allowed. Disabling this can improve security if your application doesn\'t need file uploads.'
}

php_defaults_descriptions_de = {
  "expose_php" => 'Bestimmt, ob PHP offenlegen soll, dass es auf dem Server installiert ist, was Angreifern wertvolle Informationen liefern könnte.',
  "allow_url_include" => 'Bestimmt, ob die "include"- und "require"-Anweisungen mit URLs verwendet werden können, was zu Code-Injection-Schwachstellen führen kann, wenn es aktiviert ist.',
  "display_errors" => 'Bestimmt, ob Fehler in die Ausgabe gedruckt werden sollen. In einer Produktionsumgebung könnte dies sensible Informationen preisgeben.',
  "session.cookie_httponly" => 'Markiert das Cookie als nur über das HTTP-Protokoll zugänglich, was dazu beiträgt, das Risiko zu verringern, dass ein clientseitiges Skript auf das geschützte Cookie zugreift.',
  "session.use_strict_mode" => 'Erzwingt eine strenge Generierung von Session-IDs. Wenn ein Benutzer eine nicht vorhandene Session-ID angibt, verwirft PHP diese und generiert eine neue ID.',
  "session.cookie_secure" => 'Gibt an, ob Cookies nur über sichere Verbindungen gesendet werden sollen. Es wird empfohlen, dies zu aktivieren, wenn Ihre Website HTTPS unterstützt.',
  "session.cookie_samesite" => 'Verhindert, dass der Browser das Cookie zusammen mit Cross-Site-Anfragen sendet, was einen gewissen Schutz gegen Cross-Site-Request-Forgery-Angriffe bietet.',
  "session.use_trans_sid" => 'Teilt PHP mit, ob die Session-ID an URLs angehängt werden soll. Kann ein Sicherheitsrisiko darstellen, wenn es aktiviert ist, da die Session-ID in der URL angezeigt wird.',
  "session.sid_length" => 'Bestimmt die Anzahl der Zeichen in der Session-ID. Mehr Zeichen können die Sicherheit erhöhen, aber auch mehr Speicherplatz und Bandbreite beanspruchen.',
  "session.sid_bits_per_character" => 'Bestimmt die Anzahl der Bits pro Zeichen in der Session-ID. Mehr Bits pro Zeichen können die Sicherheit erhöhen, aber auch einen größeren Zeichenbereich verwenden.',
  "file_uploads" => 'Bestimmt, ob Datei-Uploads erlaubt sind. Wenn diese Funktion deaktiviert wird, kann die Sicherheit verbessert werden, wenn Ihre Anwendung keine Datei-Uploads benötigt.'
}

content = File.readlines(ini_file)
configuration = {}
content.each do |line|
  next if line.strip =~ /^#/
  key, val = line.split('=').map { |e| e.strip }
  next unless policy.keys.include?(key)
  configuration[key] = val
end


report = []
report << %w( Setting Recommendation Active(Default) Result )
policy.each do |pkey, pval|
  cval = configuration[pkey]
  cval = cval ? cval : 'na'
  cval = 'na' if cval.strip.empty?
  res = cval.downcase == pval.downcase
  out = []
  out << pkey
  out << pval
  out << "#{cval.downcase} (#{defaults[pkey].downcase})"
  out << ( res ? 'PASSED' : 'FAILED' )
  report << out
end

report.each do |l|
  puts l.join('|')
end