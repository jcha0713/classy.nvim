vim.api.nvim_create_user_command(
  "ClassyAddClass",
  require("classy").add_class,
  {}
)
