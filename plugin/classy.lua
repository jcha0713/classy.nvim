vim.api.nvim_create_user_command(
  "ClassyAddClass",
  require("classy").add_class,
  {}
)

vim.api.nvim_create_user_command(
  "ClassyRemoveClass",
  require("classy").remove_class,
  {}
)

vim.api.nvim_create_user_command(
  "ClassyResetClass",
  require("classy").reset_class,
  {}
)
