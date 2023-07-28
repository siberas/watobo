module Watobo::Resources
  # https://github.com/dxa4481/truffleHogRegexes/blob/master/truffleHogRegexes/regexes.json
  # https://github.com/l4yton/RegHex
  # https://github.com/zricethezav/gitleaks

  # TODO: also load private keys from local file

  #keywords = %w( api key username user uname pw password pass passwd email mail credentials credential login token secret )
  keywords = %w( api key username user uname pw password pass passwd credentials credential login token secret )

  generic = {}
  generic['Generic'] = "(\\b|[ ._-])(#{keywords.join('|')})[ '\"]*(=|:)[ '\"]*([^'\" ]+)"

  API_KEYS = generic

  patterns = {
    "Slack Token" => "(xox[pborsa]-[0-9]{12}-[0-9]{12}-[0-9]{12}-[a-z0-9]{32})",
    "RSA private key" => "-----BEGIN RSA PRIVATE KEY-----",
    "SSH (DSA) private key" => "-----BEGIN DSA PRIVATE KEY-----",
    "SSH (EC) private key" => "-----BEGIN EC PRIVATE KEY-----",
    "PGP private key block" => "-----BEGIN PGP PRIVATE KEY BLOCK-----",
    "Generic key" => "-----BEGIN [^\-] PRIVATE KEY-----",
    "AWS API Key 1" => "((?=>A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16})",
    "AWS API Key 2" => "AKIA[0-9A-Z]{16}",
    "Amazon MWS Auth Token" => "amzn\\.mws\\.[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
    "AWS AppSync GraphQL Key" => "da2-[a-z0-9]{26}",
    "Facebook Access Token" => "EAACEdEose0cBA[0-9A-Za-z]+",
    "Facebook OAuth" => "[fF][aA][cC][eE][bB][oO][oO][kK].*['|\"][0-9a-f]{32}['|\"]",
    "GitHub" => "[gG][iI][tT][hH][uU][bB].*['|\"][0-9a-zA-Z]{35,40}['|\"]",
    "Google API Key" => "AIza[0-9A-Za-z\\-_]{35}",
    "Google Cloud Platform OAuth" => "[0-9]+-[0-9A-Za-z_]{32}\\.apps\\.googleusercontent\\.com",
    "Google Drive OAuth" => "[0-9]+-[0-9A-Za-z_]{32}\\.apps\\.googleusercontent\\.com",
    "Google (GCP) Service-account" => "\"type\": \"service_account\"",
    "Google Gmail OAuth" => "[0-9]+-[0-9A-Za-z_]{32}\\.apps\\.googleusercontent\\.com",
    "Google OAuth Access Token" => "ya29\\.[0-9A-Za-z\\-_]+",
    "Google YouTube OAuth" => "[0-9]+-[0-9A-Za-z_]{32}\\.apps\\.googleusercontent\\.com",
    "Heroku API Key" => "[hH][eE][rR][oO][kK][uU].*[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}",
    "MailChimp API Key" => "[0-9a-f]{32}-us[0-9]{1,2}",
    "Mailgun API Key" => "key-[0-9a-zA-Z]{32}",
    "Password in URL" => "[a-zA-Z]{3,10}://[^/\\s:@]{3,20}:[^/\\s:@]{3,20}@.{1,100}[\"'\\s]",
    "PayPal Braintree Access Token" => "access_token\\$production\\$[0-9a-z]{16}\\$[0-9a-f]{32}",
    "Picatic API Key" => "sk_live_[0-9a-z]{32}",
    "Slack Webhook" => "https://hooks\\.slack\\.com/services/T[a-zA-Z0-9_]{8}/B[a-zA-Z0-9_]{8}/[a-zA-Z0-9_]{24}",
    "Stripe API Key" => "sk_live_[0-9a-zA-Z]{24}",
    "Stripe Restricted API Key" => "rk_live_[0-9a-zA-Z]{24}",
    "Square Access Token" => "sq0atp-[0-9A-Za-z\\-_]{22}",
    "Square OAuth Secret" => "sq0csp-[0-9A-Za-z\\-_]{43}",
    "Telegram Bot API Key" => "[0-9]+:AA[0-9A-Za-z\\-_]{33}",
    "Twilio API Key" => "SK[0-9a-fA-F]{32}",
    "Twitter Access Token" => "[tT][wW][iI][tT][tT][eE][rR].*[1-9][0-9]+-[0-9a-zA-Z]{40}",
    "Twitter OAuth" => "[tT][wW][iI][tT][tT][eE][rR].*['|\"][0-9a-zA-Z]{35,44}['|\"]",
    "urls 1" => "https?://(www\\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_+.~#?&//=]*)",
    "urls 2" => "[-a-zA-Z0-9@:%._+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_+.~#?&//=]*)",
    # "url-parameter" => "(?<=\\?|\\&)[a-zA-Z0-9_]+(?=\\=)",
    "twitter-secret" => "(?i)twitter(.{0,20})?['\"][0-9a-z]{35,44}",
    "twitter-oauth" => "[t|T][w|W][i|I][t|T][t|T][e|E][r|R].{0,30}['\"\\s][0-9a-zA-Z]{35,44}['\"\\s]",
    "twitter-id" => "(?i)twitter(.{0,20})?['\"][0-9a-z]{18,25}",
    "twilio-key" => "SK[0-9a-fA-F]{32}",
    "stripe-key" => "(?:r|s)k_live_[0-9a-zA-Z]{24}",
    "square-token" => "sqOatp-[0-9A-Za-z\\-_]{22}",
    "square-secret" => "sq0csp-[ 0-9A-Za-z\\-_]{43}",
    "slack-webhook" => "https://hooks\\.slack\\.com/services/T[a-zA-Z0-9_]{10}/B[a-zA-Z0-9_]{10}/[a-zA-Z0-9_]{24}",
    "slack-token" => "xox[baprs]-([0-9a-zA-Z]{10,48})?",
    "s3-buckets 1" => "[a-z0-9.-]+\\.s3\\.amazonaws\\.com",
    "s3-buckets 2" => "[a-z0-9.-]+\\.s3-[a-z0-9-]\\.amazonaws\\.com",
    "s3-buckets 3" => "[a-z0-9.-]+\\.s3-website[.-](eu|ap|us|ca|sa|cn)",
    "s3-buckets 4" => "//s3\\.amazonaws\\.com/[a-z0-9._-]+",
    "s3-buckets 5" => "//s3-[a-z0-9-]+\\.amazonaws\\.com/[a-z0-9._-]+",
    "picatic-api" => "sk_live_[0-9a-z]{32}",
    "mailto" => "(?<=mailto:)[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9.-]+",
    "mailgun-api" => "key-[0-9a-zA-Z]{32}",
    "mailchamp-api" => "[0-9a-f]{32}-us[0-9]{1,2}",
    "linkedin-secret" => "(?i)linkedin(.{0,20})?['\"][0-9a-z]{16}['\"]",
    "linkedin-id" => "(?i)linkedin(.{0,20})?(?-i)['\"][0-9a-z]{12}['\"]",
    #     "IPv6" : "(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))",
    "IPv4" => "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}",
    "heroku-api" => "[h|H][e|E][r|R][o|O][k|K][u|U].{0,30}[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}",
    "google-ouath-token" => "ya29.[0-9A-Za-z\\-_]+",
    "google-oauth" => "[0-9]+-[0-9A-Za-z_]{32}\\.apps\\.googleusercontent\\.com",
    # "google-cloud-key" => "(?i)(google|gcp|youtube|drive|yt)(.{0,20})?['\"][AIza[0-9a-z\\-_]{35}]['\"]",
    "github" => "(?i)github(.{0,20})?(?-i)['\"][0-9a-zA-Z]{35,40}",
    "facebook-secret-key" => "(?i)(facebook|fb)(.{0,20})?(?-i)['\"][0-9a-f]{32}",
    "facebook-oauth" => "[f|F][a|A][c|C][e|E][b|B][o|O][o|O][k|K].*['|\"][0-9a-f]{32}['|\"]",
    "facebook-client-id" => "(?i)(facebook|fb)(.{0,20})?['\"][0-9]{13,17}",
    "cloudinary-basic-auth" => "cloudinary://[0-9]{15}:[0-9A-Za-z]+@[a-z]+",
    "base64" => "\\b(eyJ|YTo|Tzo|PD[89]|aHR0cHM6L|aHR0cDo|rO0)[a-zA-Z0-9+/]+={0,2}",
    "aws-secret-key" => "(?i)aws(.{0,20})?(?-i)['\"][0-9a-zA-Z/+]{40}['\"]",
    "aws-mws-key" => "amzn\\.mws\\.[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
    "aws-client-id" => "(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}",
    "auth-http" => "(?<=://)[a-zA-Z0-9]+:[a-zA-Z0-9]+@[a-zA-Z0-9]+\\.[a-zA-Z]+",
    "auth-bearer" => "bearer [a-zA-Z0-9_\\-\\.=]+",
    "auth-basic" => "basic [a-zA-Z0-9_\\-:\\.=]+",
    "artifactory-token" => "(?: |=|=>|\"|^)AKC[a-zA-Z0-9]{10,}",
    "artifactory-password" => "(?: |=|:|\"|^)AP[0-9ABCDEF][a-zA-Z0-9]{8,}"
  }

  API_KEYS.update patterns # JSON.parse(patterns)

  API_KEYS.freeze
  # puts JSON.pretty_generate API_KEYS

end