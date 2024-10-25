# NTLM Authentication
requires MD4 which is not supported by OpenSSL v3 
with default settings.
To enable MD4 (and other legacy cyphers) you need to 
edit /etc/ssl/openssl.cnf

```                                                                                                                    
[provider_sect]                                                                                                       
default = default_sect                                                                                                
legacy = legacy_sect                                                                                                  
##                                                                                                                    
[default_sect]                                                                                                        
activate = 1                                                                                                          
##                                                                                                                    
[legacy_sect]                                                                                                         
activate = 1   
```