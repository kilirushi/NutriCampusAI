const menuService = require("../services/menu.service");

const getMenu = (req, res) => {
  const menu = menuService.getMenu();
  res.json(menu);
};

module.exports = { getMenu };
