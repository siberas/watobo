$debug_project = false
$debug_active_check = false
$debug_scanner = false


# @private 
module Watobo#:nodoc: all
  module Constants    
    CHAT_SOURCE_UNDEF = 0x00
    CHAT_SOURCE_INTERCEPT = 0x01
    CHAT_SOURCE_PROXY = 0x02
    CHAT_SOURCE_MANUAL = 0x03
    CHAT_SOURCE_FUZZER = 0x04
    CHAT_SOURCE_MANUAL_SCAN = 0x05
    CHAT_SOURCE_AUTO_SCAN = 0x06
    CHAT_SOURCE_SEQUENCER = 0x07
    
    FINDING_TYPE_UNDEFINED = 0x00
    FINDING_TYPE_INFO = 0x03
    FINDING_TYPE_HINT = 0x01
    FINDING_TYPE_VULN = 0x02
    
    VULN_RATING_UNDEFINED = 0x00
    VULN_RATING_INFO = 0x01
    VULN_RATING_LOW = 0x02
    VULN_RATING_MEDIUM = 0x03
    VULN_RATING_HIGH = 0x04
    VULN_RATING_CRITICAL = 0x05
    
    # ActiveCheck Groups
    AC_GROUP_GENERIC = "Generic"
    AC_GROUP_SQL = "SQL-Injection"
    AC_GROUP_XSS = "XSS"
    AC_GROUP_ENUMERATION = "Enumeration"
    AC_GROUP_FILE_INCLUSION = "File Inclusion"
    AC_GROUP_SSTI = "SSTI"
    AC_GROUP_CMD = "CMD Injection"
    AC_GROUP_AXIS = 'Apache AXIS'
    AC_GROUP_PARAMS = 'Parameters'
    
    AC_GROUP_DOMINO = "Lotus Domino"
    AC_GROUP_SAP = "SAP"
    AC_GROUP_TYPO3 = "Typo3"
    AC_GROUP_JOOMLA = "Joomla"
    AC_GROUP_JBOSS = "JBoss AS"
    AC_GROUP_FLASH = "Flash"
    AC_GROUP_APACHE = "Apache"
    AC_GROUP_APACHE_SOLR = "Apache SOLR"
    
    ICON_PATH = "icons"
    
    FIRST_TIME_FILE = "first_time_file"  
    
    # Transfer Encoding Types
    TE_NONE = 0x00
    TE_CHUNKED = 0x01
    TE_COMPRESS = 0x02
    TE_GZIP = 0x04
    TE_DEFLATE = 0x08
    TE_IDENTITY = 0x10
    
    # Log Level
    LOG_INFO = 0x00
    LOG_DEBUG = 0x01
    
    # Authentication Types
    AUTH_TYPE_NONE =   0x00
    AUTH_TYPE_BASIC =  0x01
    AUTH_TYPE_DIGEST = 0x02
    AUTH_TYPE_NTLM =   0x04
    AUTH_TYPE_UNKNOWN = 0x10
    
    GUI_SMALL_FONT_SIZE = 7
    GUI_REGULAR_FONT_SIZE = 9
    
    DEFAULT_PORT_HTTP = 80
    DEFAULT_PORT_HTTPS = 443
    
    # Status Messages
    SCAN_STARTED = 0x00
    SCAN_FINISHED = 0x01
    SCAN_PAUSED = 0x02
    SCAN_CANCELED = 0x04
  end
end
