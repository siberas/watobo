require 'spec_helper'

# Coverage for lib/watobo/utils/eval_saved_literal.rb (formerly
# `secure_eval`). Purpose: decode Ruby-string-literals that Watobo itself
# wrote to disk in the legacy YAML chat/finding save format.
# Input is trusted (our own save output); the function is a plain eval
# wrapped in rescues so corrupted files don't abort a bulk load.

describe Watobo::Utils do
  describe ".eval_saved_literal" do
    it "round-trips a Ruby double-quoted string literal through eval" do
      # This is the actual pattern the loader hits: a stored literal like
      # what YAML.dump("POST /x HTTP/1.1\r\n") writes back.
      literal = %Q{"POST /x HTTP/1.1\\r\\n"}
      expect(Watobo::Utils.eval_saved_literal(literal)).to eq("POST /x HTTP/1.1\r\n")
    end

    it "evaluates simple Ruby expressions" do
      expect(Watobo::Utils.eval_saved_literal('1 + 2')).to eq(3)
      expect(Watobo::Utils.eval_saved_literal('nil')).to be_nil
      expect(Watobo::Utils.eval_saved_literal('[1, 2, 3].sum')).to eq(6)
    end

    it "returns nil for syntax errors instead of raising" do
      # A corrupted or truncated save-file line shouldn't abort the caller's
      # bulk load; the loader skips this entry and continues.
      expect(Watobo::Utils.eval_saved_literal('invalid syntax {')).to be_nil
    end

    it "returns nil for runtime errors instead of raising" do
      expect(Watobo::Utils.eval_saved_literal('raise "boom"')).to be_nil
      expect(Watobo::Utils.eval_saved_literal('nil.foo')).to be_nil
    end

    it "runs each eval in its own thread and joins before returning" do
      # If the join were missing we'd see nil because the main thread
      # would return before the eval thread wrote to `result`.
      100.times do
        expect(Watobo::Utils.eval_saved_literal('Thread.current.object_id')).to be_a(Integer)
      end
    end
  end
end
