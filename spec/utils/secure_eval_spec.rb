require 'spec_helper'

# Coverage for lib/watobo/utils/secure_eval.rb.
#
# secure_eval evaluates a string with $SAFE=1 in a fresh Thread. Historical
# intent: sandbox untrusted expressions from saved chat files. On Ruby 2.7+
# $SAFE is a no-op (removed in 3.0), so on the currently-supported Ruby the
# "secure" prefix is a misnomer — see the pending example at the bottom.

describe Watobo::Utils do
  describe ".secure_eval" do
    it "evaluates simple expressions and returns the value" do
      expect(Watobo::Utils.secure_eval('1 + 2')).to eq(3)
      expect(Watobo::Utils.secure_eval('"abc".reverse')).to eq('cba')
      expect(Watobo::Utils.secure_eval('nil')).to be_nil
      expect(Watobo::Utils.secure_eval('[1, 2, 3].sum')).to eq(6)
    end

    it "returns nil for syntax errors instead of raising" do
      expect(Watobo::Utils.secure_eval('invalid syntax {')).to be_nil
    end

    it "returns nil for runtime errors instead of raising" do
      expect(Watobo::Utils.secure_eval('raise "boom"')).to be_nil
      expect(Watobo::Utils.secure_eval('nil.foo')).to be_nil
    end

    it "runs each eval in its own thread and waits for it to complete" do
      # If the join were missing we'd see nil here because the main thread
      # would return before the eval thread wrote to `result`.
      100.times do
        expect(Watobo::Utils.secure_eval('Thread.current.object_id')).to be_a(Integer)
      end
    end

    it "is NOT actually sandboxed on Ruby >= 2.7 (documentary)" do
      pending "$SAFE was frozen at 0 in Ruby 2.7 and removed in 3.0. " \
              "secure_eval is effectively a plain eval on modern Ruby; " \
              "the sandbox premise no longer holds. Left as a known gap: " \
              "callers should treat inputs as trusted or replace with a " \
              "real parser."
      # Under a real sandbox, opening a file would raise SecurityError. It
      # doesn't — the expression runs.
      expect {
        Watobo::Utils.secure_eval("File.read('/etc/hostname')")
      }.to raise_error(SecurityError)
    end
  end
end
