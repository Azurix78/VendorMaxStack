const fs = require('node:fs');
const path = require('node:path');

function run() {
  const parser = require('luaparse');
  const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
  const root = path.resolve(__dirname, '..');
  const toc = fs.readFileSync(path.join(root, 'VendorMaxStack/VendorMaxStack.toc'), 'utf8');
  const files = toc.split(/\r?\n/).map(line => line.trim()).filter(line => line && !line.startsWith('#'));
  const state = lauxlib.luaL_newstate();
  try {
    lualib.luaL_openlibs(state);
    lua.lua_newtable(state);
    for (const file of files) {
      const source = fs.readFileSync(path.join(root, 'VendorMaxStack', file), 'utf8');
      parser.parse(source, { luaVersion: '5.1' });
      lua.lua_pushstring(state, to_luastring(source));
      lua.lua_setfield(state, -2, to_luastring(file));
    }
    lua.lua_setglobal(state, to_luastring('TEST_FILES'));
    lua.lua_pushstring(state, to_luastring(toc));
    lua.lua_setglobal(state, to_luastring('TEST_TOC'));
    const source = fs.readFileSync(path.join(__dirname, 'run.lua'), 'utf8');
    parser.parse(source, { luaVersion: '5.1' });
    if (lauxlib.luaL_dostring(state, to_luastring(source)) !== lua.LUA_OK) {
      throw new Error(to_jsstring(lua.lua_tostring(state, -1)));
    }
    console.log('Lua 5.1 syntax and behavioral checks passed.');
  } finally { lua.lua_close(state); }
}
if (require.main === module) run();
module.exports = run;
