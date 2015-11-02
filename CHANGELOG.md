#Version 0.9.22

## News

**ManualRequestEditor**

* added dynamic egress handler support. Useful for more complex request transformations, e.g. if you need a http header with a hmac which is based on the request body   

**SSL-Checker**

* the results can now be saved
* bad ciphers will be added to findings
 
##Fixes

**Proxy**

* fixed duplicated serial numbers in fake certificates

**WShell**

* fixed a bug which prevented work on linux boxes
* switched command execution to thread via runOnUiThread

**Client-Certificates**

* settings will be saved and reloaded on project start

**Transparent Proxy**

* crash fixed

**SQLMap Plugin**

* fixed load_config error

**General**

* fixed old yaml style file format after editing comments

**Contributions**
* Work around error 'FXComposeContext: illegal window parameter' (by Lars Kanis)
* Use runOnUiThread for GUI activity while loading plugins in a thread (by Lars Kanis)


Version 0.9.21
===

News
---
**General**

* greatly increased speed of session import by using Marshal serialization instead of YAML for storing chats/findings.

  **NOTE:** older formats will still work but they will be converted to .mrs files.
  
* added scanner setting 'ignore server errors' which (if enabled) will handle 5xx response codes as 'file does not exist'. It overrules custom error filters.
* introduced the watobo info page. accessible via http://watobo - where you can download the CA cert as well as some installation information
* the 'Define Target Scope' dialog now has a text filter  
 
**Plugins**

* added Adobe Experience Manager Enumeration, crawls the site by using information of AEM/CQ5 json-Extensions

**Fuzzer**

* results are now saved in yaml format

**Modules**

* new CQ5 modules for selectors and extensions detection
* new CQ5 module for userenumeration via json and xml extensions

**CustomViewer**

* updating view after handler is loaded, no more tab/chat switch necessary

Fixes
---
**General**

* changed encoding in conversation table
* Response.header_value parsing

**Plugins**

* [sqlmap] enhanced path detection to also match 'sqlmap' without .py extension

**Fuzzer**

* multiple fixes in statistics view

**ConversationTable**

* fixed autoscroll checkbox, no more autoscrolling if unchecked
* fixed crash on Goto-Function (shift-g shortcut)

Version 0.9.20
===

News
---

**Export**

 * added an XML export function available via File->Export
 
**SitesTree**

 * added findings to sites tree view

**Platform**

 * watobo is running under Ruby 2.0 (2.1 not tested yet)

**ForwardingProxy**
  
  * introduced per-site proxying

**ActiveChecks**

 * added ShellShock module (Generic->ShellShock)
 * added Apache MultiViews module

**Interceptor**

 * added TableEditor to request
 
**TableEditor**

 * added new menu item "to clipboard" which exports the table fields as a CSV (comma seperated values) to the clipboard
 * column width does not change after refresh
 
**SSL-Checker**
 
 * optimized ssl checks - but keep in mind that the number of checked ciphers depends on your ruby version

Fixes
---

**General**
 
 * post parameter values containing equal signs ('=') will no longer be truncated
 
**Transcoder**

 * now LineFeeds will not be replaced in text-view

**HexViewer**

 * changed font type to courier
 * fixed crash on invalid UTF-8 sequences
 * now works in request viewer
 * shows header & body
 
**ChunkEncoding**

 * fixed handling of chunk encoded data
 
**NTLM**

 * fixed ntlm authentication
 
**Crawler**

 * Fixed status bar infos
 
**CatalogScanner**
 
 * if match value contains 3 digits it will be treated as response code (reduces false positives)  
  
**CA**
 
 * CA serial now starts with current time to avoid serial number conflicts after reinitializing CA
 
**Modules**

 * fixed cookie access in passive module 'possible_login'
 * little fix in xxe module
 * fixed proof pattern for hidden field detection in hidden_fields.rb
 
**Conversation Table**

 * fixed chat filter, now request and response can be filterd together
 * new chats run through filter before they are added

**GUI**

 * fixed crash when selecting 'scope only' in sites-tree
 * fixed transcoder, so all CRLF will be removed before Base64 decoding
 
**Interceptor**
 
 * now removes Expect-100-continue headers from client
 
**General**

 * added json support for table editor (only first level paramaters)
 * fixed redirect mechanism, now also 301 and 308 codes are supported as well as absolut path locations
 * now post-parameters with empty names will be handled correctly
 
Version 0.9.19
===

Fixes
---
**General**
 
 * NTLM authentication


Version 0.9.18
===

Fixes
---
**Crawler**

 * excluded path definitions are now handled correctly

**SSLChecker**

 * unsupported ciphers are now recognized
 

Version 0.9.17
===
News
---

**General**

 * changed parameter parsing for better handling
 * Boolean-SQL check now also takes xml parameters for testing
 * new appearance of CA certificates
 * new custom response viewer; now you can code your own handler, e.g. `lambda{ |response| return response.content_type }`
 * added table view on request viewer
 
**Manual Request Editor**

 * XML parser, xml-request parameters available in table
 
Fixes
---
**General**

 * request line removed on `remove_header` regex match 
 * double insert of Content-Length header
 * bad markdown format of CHANGELOG
 * wrong parameter parsing if value contains '=' sign 
 
Version 0.9.16
===
Fixes
---
**General**

 * double insert of Content-Length header
 * bad markdown format of CHANGELOG
 
Version 0.9.15
===
Fixes
---
**General**

 * improved socket handling
 * fixed some UTF-8 issues in passive modules
 * added application/octet-stream to pass-through content-types
 * `shapers.rb` didn't replace single quotes in `replace_post_parm`
 * setting/replacing http-headers is now case-in-sensitive

**Passive Modules**

 * fixed `Disclosure_ipaddr`; now all IPs inside body are reported
 
**Active Modules**

 * Domino DB enumeration will now run on all requests
 
**Crawler Plugin**

 * extended allowed/excluded URL checks on full url path /w query

News
---
 * Struts2 module for detecting CVE-2013-2251
 * Struts2 module for detecting CVE-2013-1966
 * conversation filter; added some shortcuts
 * conversation table; added `send to->Crawler`
 * client certificates; added PKCS12
 * SAP passive module; extracts SAP headers, e.g. `sap-system`
 
Version 0.9.14
===
Fixes
---
**Manual Request Editor**

 * fixed crash when clicking OTT-Settings
 
**Crawler**

 * watobo stopped working when crawler was started (Linux only) - workaround

Version 0.9.13
===
News
---
**Core**

 * Faster socket communication!! Now client sockets are reused 
 * Big big changes on core modules, e.g. Watobo::Chats or Watobo::Findings.
 * PassiveScanner - passive checks now run in background
 * New DSL-like Plugin Style - digging into Metaprogramming ... check out WShell Plugin!

**Modules**

 * XSS-NG supports "Parameter Prefetching" - using form fields of response as test parameters 
 * Hidden Field Spotter
 * Improved boolean SQLi detection
 * added some .NET Checks for well-known files, e.g. Trace.adx and Error Pages /w Stack-Trace
 * XXE (Xml eXternal Entity) check
 * Check html password fields for autocomplete attribute

**Plugins**

 * SSL Checker now also shows the tested method (SSLv3, TLS, ..)
 * WShell - Watobo Shell; With WShell you can execute ruby commands in the context of WATOBO. Very useful for advanced analysis, debugging purposes or simply to explore WATOBO. 

**GUI**

  * Parameter names in Table view are now automatically en-/decoded
  * Right-Click on a plugin to get some information about it - only works on new plugins at the moment ...
  * Introduced a new chat viewer with HTML highlighting (based on FXScintilla)
  * ConversationTable: added 'space' hotkey to open "Edit Comment" dialog
  * ConversationTable: added hotkeys for "goto url" navigation
  * ChatViewer: xml/html content gets prettyfied for text- and html-viewer
  * FindingsTree: added counter to finding class
  * FindingsTree: memorize expanded nodes
  * Conversation table filter now opens as a dialog and displays more information

Fixes
---
**Core**

 * Bug in parsing multipart requests caused by incorrect boundary handling 
 * conversation text filter now works on responses without content-type header

**Fuzzer**

 * fixed generator in fuzzer engine

**GUI**

 * crash after selecting client certs
 * no more swallowing a space-char at the end of a string when b64decoding with short-cuts

**Plugins**

 * Catalog-Scanner: now all placeholders will be replaced
 * SSLChecker now supports more methods and ciphers, incl. SSLv2

**Passive Modules**

 * FormSpotter: now using nokogiri for parsing/extracting <form> information

= Version 0.9.12
== NEW
* [Module] Siebel Checks: Enumeration of default apps and files, e.g. base.txt
* [Module] PassiveCheck filtering Domino DB names
* [GUI] added De-Select-All buttons to scan policy
* [GUI] finding details menu available at finding-class level

== Fixes
* crash when pasting data (Linux)
* crash on starting full scan dialog
* minor issue when adding a new db-path to catalog scanner plugin

= Version 0.9.11
== NEW
* [FileFinder] pimped the interface, added save-settings

== Fixes
* [ConversationTable] Request-/Resoponse View is updated when navigating with arrow-keys
* [INTERCEPOR] fixed bug in parsing intercepted responses

= Version 0.9.10
== Fixes
* fixed sqlmap temp directory

= Version 0.9.9
== NEW
* [Module] Time-based SQL injection module
* [Module] Rated XSS which gives a more accurate exploitability result
* [GUI] ConversationTable: values in coloumn Parameters are url-decoded
* [Plugin] WebCrawler - based on Mechanize
* [GUI] Manual Request Editor: Url is displayed in the window title
* [GUI] Menubar items are disabled if no project is defined
* [CORE] Create SSL certificates for each target on-the-fly, now you only have to trust the internal CA once
* [Interceptor] Rewrite/Inject Feature to Interceptor
* [CORE] added .yml file extension for chats, findings, logs, ...
* [Plugin] SQLmap - easy to use sqlmap interface
* [Interceptor] Transparent Proxy Feature - only available on Linux (depends on netfilter_queue)
* [CatalogScanner] added predefined database paths
* [CORE] general unzipping and unchunking of server responses

== Fixes
* CA Directory is now created in WATOBO working directory '.watobo'
* Fixed Crash on opening client-certificate dialog
* Improved Socket communication
* ConversationTable: GET and POST parameters are shown in the parameters coloumn 
* TreeView-Pane: Show full conversation list when Findings tab is selected
* Fixed a bug in parsing post parameters
* QuickScan: double scanning each module
* the disclaimer.chk file now is written to .watobo
* some minor bugs


= Version 0.9.8
== NEW
* Ruby 1.9 Support - no more 1.8 don't even try it ;)
* WATOBO available as a Gem
* Reorganisation of WATOBO settings files.
* Reorganisation of WATOBO project.
* Introduced Framework capabilities
* Changed version numbering for Gem compatibility
* SSLChecker-Plugin: nicer gui, now you can scan a site which is not already in conversation list
* Conversation-Table: better search features, e.g. URL, Request or Response
* Chat-Viewer: added a 'save'-button to save the response's body to a file, e.g. save a flash file for further investigations
* Scanner: now follows 302-redirects - this option is only available via QuickScan
* GUI: purge (multiple) findings is possibel via FindingsTree

== Fixes
* interceptor reset-button
* Constant declarations
* lib/mixin/request_parser.rb: fixed file handling
* fixed pattern for detecting file upload fields
* optimized "tagless" view
* optimized lots of threading stuff, e.g. progress bars, log-windows, ...
* lib/qGui: changed progress_window 

= Version 0.9.7 Revision 534
== NEW
* MasterPassword for encrypting Proxy- and WWW-Auth-Passwords
* Hotkey-Help: Press F1 to view all Hotkeys for the focused widget!!! Works in ManualRequestEditor, Interceptor, ChatViewers
* Interceptor: Intercept Filters, Editor, Hotkeys - almost complete rewrite!!!
* Passive Module: 'DOM XSS' - checks for javascript code which manipulates DOM and may be misused for XSS
* Passive Module: 'Detect One-Time-Tokens' - checks for parameters which may be used to prevent CSRF-Attacks
* ManualRequest Following Redirects Automatically (optional)
* ManualRequest: Added Hotkeys for 'send' (ctrl-enter) and transcoding ctrl-[shift]-b (base64), ctrl-[shift]-u (url)
* ManualRequest: new Transform 'Get -> Post'
* TableEditor: Added Hotkeys; ctrl-[shift]-b (base64), ctrl-[shift]-u (url), ctrl-enter (send request)
* Passive Module: 'Detect Code' - Now also checks for ASP-Snippets
* ConversationTable: added SSL-Icon
* TextView: added Match-Navigation for 'Highlight'- and 'Grep'-Filter
* One-Time-Token-Dialog: Target chat is also visible for OTT-pattern creation.
* WATOBO-Logo: watobo-48x48.png for nice desktop shortcuts/launchers ;)

== Fixes
* FullScan-Wizzard: Empty Scanlist
* Fixed Typo in lib/utils/response_hash.rb (SmartHash)
* Manual Request Editor: Add Parameter in TableView
* ConversationTable: Fixed Error Cutting Of Last Char On Copy
* ConversationTable: Now update 'comment' immediately in table 
* Required BasicAuth will now be sent to browser
* Module SQL_Boolean: Adding a Finding produced an error
* FileFinder & CatalogScanner: 'Custom Error Patterns' are recognized
* TableEditor: Fixed Parsing Problem - appended parms instead of replacing
* Interceptor: Fixed handling of chunk-encoded server responses 
* SmartHash: Fixed Reduction -> much faster and less false-positives on blindSQLi 


= Version 0.9.6 Build 271
== Fixes
* Scanner: Scanner works without proxy 
 
= Version 0.9.6 Build 270
== Fixes
* ProxyDialog: AddProxy-Crash
* Scanner: No Probe For Target If Proxy Is Set
* Session: Fixed NTLM-Authentication

= Version 0.9.6
  !! NOTE !!
  Due to the import fix you can't import older WATOBO sessions!

== NEW
* General: Supports One-Time-Tokens (e.g. Anti-CSRF-Tokens)
* General: NTLM Authentication (Server and Proxy)
* New Plugin: FileFinder
* GUI: switch the icon and text size for lower screen resolution
* Manual Request Editor: Table-View for easier parameter manipulation

== !!! CONTRIBUTIONS !!! :))
  Hans-Martin Muench contributed two active-check modules:
* modstatus.rb:
* crossdomain.rb:

== Minor Changes
* slightly improved SQL-Injection (Simple)
* now you can hide 404 and 302 in Sites Tree

== Fixes
* General: Fixed Import Problem ('inspect' data before YAML'izing)
* General: Fixed "limitation" of forwarding proxy port length 4 -> 5, wtf???
* General: Fixed EOF handling on socket operation 
* Catalog Scan: now use forwarding proxy
* Interceptor: Fixed Drop and Discard 

== Minor Fixes
* General: switched to unix style line breaks again * got lost somewhere ...
* General: fixed path reference for already tested directories in HTTP-Methods and Dir-Walker (reported by Hans-Martin Muench)
* General: fixed HashBang line in start_watobo.rb (reported by Achim Hoffmann)
* GUI: changed appearance of History
* Sites Tree: workaround for FXTreeList.findItem (bug?)
* GUI: now counters get reset when new project is started   


= Version 0.9.5
== New
* PassThrough for large responses or special content-types (Interceptor/Proxy)
* Introduced Plugins
* Introduced Full logging of Scans
* Introduced Target-Scope
* Introduced Quick-Filter in Sites-Tree-View
* Introduced Scope-Filter-Option for conversation table
* Introduced Request-Transform (POST->GET) for Manual Requests
* New Plugin: Catalog-Scan
* New Plugin: SSL-Check

== Improvements/Bugfixes
* using YAML for saving settings 
* speedup of session-import
* request/response-viewer: auto-reset on grep
* fixed hash-calculation for findings in passive checks
* fixed autoscroll not disable-able
* fixed passive module "cookie-options"
* fixed numRequests calculation in FuzzFile-Generator
* fixed url-shaping if parameter contains /https?/
* fixed button behaviour @interceptor

= Version 0.9.2
* NEW: History navigation (for Manual Requests Editor)
* NEW: Fuzzer Engine
* NEW: Differ usability improved
* NEW: WATOBO now can run on Windows, Linux and MAC
* FIX: fixed table-right-click crash
* MISC: Redesign of chat-table-menu
* MISC: Improved checks for recognizing proxy settings

= Version 0.9.1-96
* load fox16 problem fixed - hope not too many user were hit by this!
* auto-save of proxy settings 
* fixed some issues with the fuzzer

= Version 0.9.1-95
* fixed hash calculation for better blind-sql checks
* added Differ for diffing chats (very nice)
* added HexViewer (no editor yet)
* open session/project by double clicking 
* response get cut off after 
