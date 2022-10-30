local plugin = require("classy")

describe("setup", function()
  it("say hello", function()
    assert(false)
  end)

  it("this will fail", function()
    assert.are.same("bye", plugin.hello())
  end)
end)
