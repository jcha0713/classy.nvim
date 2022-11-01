local classy = require("classy")
local utils = require("classy.utils")

describe("Testing get_quotes util", function()
  describe("that returns double quote", function()
    describe("with no spacing", function()
      it("tests correct results", function()
        assert.are.same([[""]], utils.get_quotes(0))
      end)

      it("tests failing cases", function()
        assert.are_not.same([['']], utils.get_quotes(0))
      end)
    end)

    describe("with spacing", function()
      it("tests correct results", function()
        assert.are.same([[" "]], utils.get_quotes(1))
        assert.are.same([["   "]], utils.get_quotes(3))
      end)

      it("tests failing cases", function()
        assert.are_not.same([[""]], utils.get_quotes(1))
        assert.are_not.same([["  "]], utils.get_quotes(1))
        assert.are_not.same([["       "]], utils.get_quotes(1))
        assert.are_not.same([[' ']], utils.get_quotes(1))
      end)
    end)
  end)

  describe("returns single quote", function()
    classy.setup({ use_double_quote = false })

    describe("with no spacing", function()
      it("tests correct results", function()
        assert.are.same([['']], utils.get_quotes(0))
        assert.are.same([['']], utils.get_quotes(-5))
      end)

      it("tests failing cases", function()
        assert.are_not.same([[""]], utils.get_quotes(0))
      end)
    end)

    describe("with spacing", function()
      it("tests correct results", function()
        assert.are.same([[' ']], utils.get_quotes(1))
        assert.are.same([['   ']], utils.get_quotes(3))
      end)

      it("tests failing cases", function()
        assert.are_not.same([[" "]], utils.get_quotes(1))
        assert.are_not.same([['  ']], utils.get_quotes(1))
        assert.are_not.same([[' ']], utils.get_quotes(0))
      end)
    end)
  end)
end)
