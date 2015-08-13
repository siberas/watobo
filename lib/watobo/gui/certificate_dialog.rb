# @private 
module Watobo#:nodoc: all
  module Gui
    class CertificateDialog < FXDialogBox
      
      def createCertificate(sender, sel, ptr)
        @createButton.disable

        cadir = File.join(Watobo.working_directory, "CA")
        crl_dir= File.join(cadir, "crl")
        hostname = "watobo"
        domainname = "watobo.local"
        
        puts "CA Directory:" + cadir
        
       # return 0
        ca_settings = {
          :CA_dir => cadir,
          #:password => '1234',
          # some pseudo crypto ;)
          :password => Digest::MD5.hexdigest(Time.now.to_s + rand(100000).to_s + __FILE__).to_s,
          
          :keypair_file => File.join(cadir, "private/cakeypair.pem"),
          :cert_file => File.join(cadir, "cacert.pem"),
          :serial_file => File.join(cadir, "serial"),
          :new_certs_dir => File.join(cadir, "newcerts"),
          :new_keypair_dir => File.join(cadir, "private/keypair_backup"),
          
          
          :ca_cert_days => 5 * 365, # five years
          :ca_rsa_key_length => 2048,
          
          :cert_days => 365, # one year
          :cert_key_length_min => 1024,
          :cert_key_length_max => 2048,
          
          :crl_file => File.join(crl_dir, "#{@hostname_dt.value}.crl"),
          :crl_pem_file => File.join(crl_dir, "#{@hostname_dt.value}.pem"),
          :crl_days => 14,
          :name => [
          ['C', 'DE', OpenSSL::ASN1::PRINTABLESTRING],
          ['O', @domain_dt.value, OpenSSL::ASN1::UTF8STRING],
          ['OU', @hostname_dt.value, OpenSSL::ASN1::UTF8STRING],
          ]
        }
        
        cert = {
          :type => 'server',
        #  :user => @user_dt.value,
          :hostname => @hostname_dt.value,
          :email => @email_dt.value
        
        }
        puts "Create CA ..."
        ca = Watobo::SimpleCA.new(ca_settings)
        puts "Create Certificate ... "
        ca.create_cert(cert)
         FXMessageBox.information(self,MBOX_OK, "Certificate Created!", "Files written to #{ca_settings[:CA_dir]}\n!!! DON'T USE IT IN A PRODUCTION ENVIRONMENT !!!")
        
      end
      
      def initialize(owner, project)
        super(owner, "Create Certificate", :opts => DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE, :width => 270, :height => 250)
        @project = project
        
        main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        
        FXLabel.new(main, "CA Settings")
        
        frame = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
        @hostname_dt = FXDataTarget.new('WATOBO')
        FXLabel.new(frame, "Hostname:")
        @hostname = FXTextField.new(frame, 25, :target => @hostname_dt, :selector => FXDataTarget::ID_VALUE,
                                    :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_RIGHT)
        
        
        frame = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
        @domain_dt = FXDataTarget.new('watobo.local')
        FXLabel.new(frame, "Domain:")
        @domain = FXTextField.new(frame, 25, :target => @domain_dt, :selector => FXDataTarget::ID_VALUE,
                                  :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_RIGHT)
        
        frame = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
        @user_dt = FXDataTarget.new('watobo')
        FXLabel.new(frame, "User:")
        @user = FXTextField.new(frame, 25, :target => @user_dt, :selector => FXDataTarget::ID_VALUE,
                                :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_RIGHT)
        
        frame = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
        @email_dt = FXDataTarget.new('watobo@siberas.de')
        FXLabel.new(frame, "Email:")
        @email = FXTextField.new(frame, 25, :target => @email_dt, :selector => FXDataTarget::ID_VALUE,
                                 :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_RIGHT)
        
        
        buttons_frame = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
        @createButton = FXButton.new(buttons_frame, "Create" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        @createButton.connect(SEL_COMMAND, method(:createCertificate))
        
        @hostname.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @domain.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @user.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @email.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        
      end
    end
  end
end

if __FILE__ == $0
  # TODO Generated stub
end
