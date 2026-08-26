require 'spec_helper'

# Coverage for lib/watobo/core/ca.rb (the mini-CA that mints per-target
# TLS certs for the intercepting proxy) and lib/watobo/core/cert_store.rb
# (per-hostname SSLContext cache).
#
# The CA writes cert/key files to <working_directory>/CA/fake_certs and
# CSRs to <working_directory>/CA/csr. Each example uses a unique host
# name so cached files never collide, and cleans up after itself so the
# user's real ~/.watobo/CA directory stays uncluttered.

describe Watobo::CA do
  def unique_hostname
    "spec-#{SecureRandom.hex(6)}.watobo.invalid"
  end

  def cleanup(hostname)
    fake_certs_dir = File.join(Watobo::Conf::General.working_directory, 'CA', 'fake_certs')
    csr_dir        = File.join(Watobo::Conf::General.working_directory, 'CA', 'csr')
    [
      File.join(fake_certs_dir, "#{hostname}_cert.pem"),
      File.join(fake_certs_dir, "#{hostname}_keypair.pem"),
      File.join(csr_dir,        "csr_#{hostname}.pem"),
    ].each { |f| File.delete(f) if File.exist?(f) }
  end

  describe ".ca_ready?" do
    it "reports true after module load (spec_helper causes CA init)" do
      expect(Watobo::CA.ca_ready?).to be(true)
    end
  end

  describe ".cert_file" do
    it "points at a readable PEM containing a self-signed CA certificate" do
      raw = File.read(Watobo::CA.cert_file)
      ca_cert = OpenSSL::X509::Certificate.new(raw)

      expect(ca_cert.subject).to eq(ca_cert.issuer)          # self-signed
      expect(ca_cert.subject.to_s).to include('CN=Watobo CA')
      basic_constraints = ca_cert.extensions.find { |e| e.oid == 'basicConstraints' }
      expect(basic_constraints.value).to include('CA:TRUE')
    end
  end

  describe ".dh_key" do
    it "returns an OpenSSL::PKey::DH with a 2048-bit prime" do
      dh = Watobo::CA.dh_key
      expect(dh).to be_a(OpenSSL::PKey::DH)
      expect(dh.p.num_bits).to eq(2048)
    end
  end

  describe ".create_cert (server type)" do
    let(:hostname) { unique_hostname }
    after { cleanup(hostname) }

    it "mints a leaf cert and returns the [cert_path, key_path] pair" do
      cert_path, key_path = Watobo::CA.create_cert(
        hostname: hostname, type: 'server', user: 'watobo', email: 'watobo@localhost',
      )

      expect(File.exist?(cert_path)).to be(true)
      expect(File.exist?(key_path)).to  be(true)
      expect(File.read(cert_path)).to start_with('-----BEGIN CERTIFICATE-----')
      expect(File.read(key_path)).to   start_with('-----BEGIN RSA PRIVATE KEY-----')
    end

    it "signs the leaf cert with the CA and includes the hostname as a SAN" do
      cert_path, _ = Watobo::CA.create_cert(
        hostname: hostname, type: 'server', user: 'watobo', email: 'watobo@localhost',
      )
      leaf = OpenSSL::X509::Certificate.new(File.read(cert_path))
      ca   = OpenSSL::X509::Certificate.new(File.read(Watobo::CA.cert_file))

      # Signature verifies against the CA's public key.
      expect(leaf.verify(ca.public_key)).to be(true)

      # SAN carries the hostname we asked for.
      san = leaf.extensions.find { |e| e.oid == 'subjectAltName' }
      expect(san).not_to be_nil
      expect(san.value).to include("DNS:#{hostname}")

      # Reasonable RSA key size for the leaf.
      expect(leaf.public_key.n.num_bits).to be >= 2048

      # Observation: sign_cert currently only attaches the SAN extension.
      # The basicConstraints / keyUsage / extendedKeyUsage block above the
      # SAN line is =begin/=end-commented out in lib/watobo/core/ca.rb, so
      # leaf certs have no basicConstraints and would be rejected by a
      # strict TLS client. Not asserting the ideal contract here; just
      # locking in the actual behavior.
      expect(leaf.extensions.map(&:oid)).to eq(['subjectAltName'])
    end

    it "raises on unknown cert type" do
      expect {
        Watobo::CA.create_cert(hostname: hostname, type: 'bogus', user: 'watobo', email: 'x@y')
      }.to raise_error(RuntimeError, /unknonw cert type/) # note: lib typo
    end
  end
end

describe Watobo::CertStore do
  describe ".acquire_ssl_ctx" do
    it "returns an SSLContext wired with a leaf cert, key, and chain for the target" do
      target   = "spec-#{SecureRandom.hex(4)}.watobo.invalid:443"
      hostname = target.split(':').first

      ctx = Watobo::CertStore.acquire_ssl_ctx(target, hostname)
      expect(ctx).to           be_a(OpenSSL::SSL::SSLContext)
      expect(ctx.cert).to      be_a(OpenSSL::X509::Certificate)
      expect(ctx.key).to       be_a(OpenSSL::PKey::RSA)
      expect(ctx.extra_chain_cert).to be_an(Array)
      expect(ctx.extra_chain_cert.first).to be_a(OpenSSL::X509::Certificate)
      expect(ctx.verify_mode).to eq(OpenSSL::SSL::VERIFY_NONE)

      # Chain cert is the Watobo CA itself.
      chain = ctx.extra_chain_cert.first
      expect(chain.subject.to_s).to include('CN=Watobo CA')

      # Cleanup the leaf we just minted for this test.
      fake_certs_dir = File.join(Watobo::Conf::General.working_directory, 'CA', 'fake_certs')
      csr_dir        = File.join(Watobo::Conf::General.working_directory, 'CA', 'csr')
      [
        File.join(fake_certs_dir, "#{hostname}_cert.pem"),
        File.join(fake_certs_dir, "#{hostname}_keypair.pem"),
        File.join(csr_dir,        "csr_#{hostname}.pem"),
      ].each { |f| File.delete(f) if File.exist?(f) }
    end

    it "caches per-target so repeated calls reuse the minted material" do
      target   = "spec-#{SecureRandom.hex(4)}.watobo.invalid:443"
      hostname = target.split(':').first

      ctx1 = Watobo::CertStore.acquire_ssl_ctx(target, hostname)
      ctx2 = Watobo::CertStore.acquire_ssl_ctx(target, hostname)
      # Fresh SSLContext each call, but the underlying cert is the same object.
      expect(ctx1).not_to equal(ctx2)
      expect(ctx1.cert.serial).to eq(ctx2.cert.serial)

      # Cleanup.
      fake_certs_dir = File.join(Watobo::Conf::General.working_directory, 'CA', 'fake_certs')
      csr_dir        = File.join(Watobo::Conf::General.working_directory, 'CA', 'csr')
      [
        File.join(fake_certs_dir, "#{hostname}_cert.pem"),
        File.join(fake_certs_dir, "#{hostname}_keypair.pem"),
        File.join(csr_dir,        "csr_#{hostname}.pem"),
      ].each { |f| File.delete(f) if File.exist?(f) }
    end
  end
end
