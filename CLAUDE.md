# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

WATOBO — a Ruby-based web application security auditing toolbox. Runs primarily as a local intercepting proxy with a FXRuby (Fox) GUI, plus headless variants and command-line tools. Users load projects/sessions, capture traffic through the proxy, and run passive/active checks.

Language: Ruby (>= 2.3). GUI: FXRuby 1.6.x (Fox). License: GPL-2.0.

## Commands

Install dependencies:
```
bundle install
```

Run the GUI:
```
bundle exec bin/watobo_gui.rb
# or via the wrapper (supports --binding, --project, --session)
bundle exec bin/watobo
```

Run the headless proxy (drops into a `pry` REPL after startup):
```
bundle exec bin/watobo_proxy_headless.rb --project <name> --session <name>
```

Run tests (RSpec — `spec/spec_helper.rb` boots a Sinatra vuln app on `localhost:6666` for the suite):
```
bundle exec rake                                                      # default task = spec
bundle exec rspec                                                     # same, direct
bundle exec rspec spec/modules/passive/cookie_options_spec.rb         # single file
bundle exec rspec spec/scanner3/host_up_check_spec.rb:11              # single example (line of the `it` block)
```

`.rspec` sets `--require spec_helper --color --format documentation`, so `spec_helper.rb` (and its Sinatra server) always loads. `host_up_check_spec.rb` is an integration test that skips itself when the network is unreachable.

Build the gem:
```
gem build watobo.gemspec
```

`bin/` also contains many standalone CLIs (`spider.rb`, `sniper.rb`, `filescanner.rb`, `hash_forcer.rb`, `httptrace.rb`, `postman-collection.rb`, `watobo-scanner.rb`, …). They all prepend `../lib` to `$LOAD_PATH` and `require 'watobo'`, so run them with `bundle exec bin/<name>.rb`.

## Environment variables

Read at startup (see `bin/watobo` banner and `lib/watobo/framework/init.rb`):

- `WATOBO_HOME` — working directory for conversations/settings (default `~/.watobo`). Overrides `Conf::General.working_directory`.
- `WATOBO_BINDING` — interceptor bind, e.g. `127.0.0.1:8081`.
- `WATOBO_PROXY` — enable/disable interceptor.
- `WATOBO_CA` — path to CA files (reuse to speed up start-up; the proxy MITMs TLS with generated certs).
- `WATOBO_TRUSTED_IPS` — used by evasion modules.
- `WATOBO_MODULES` — colon-separated extra directories appended to `Watobo.active_module_paths` (see `lib/watobo/environment.rb`).
- `DEV_ENV` — when set, `lib/watobo.rb` skips `Bundler.require` and instead loads `devenv` plus `~/.watobo/devgems.rb`, allowing private plugins to bring their own gems.
- `WATOBO_PRIVATE_GEMS` — when set, `Gemfile` `eval_gemfile`s `~/.watobo/Gemfile.private` under the `:private_gems` group. Opt-in on purpose: keeps local path-based private gems out of the committed `Gemfile.lock`. If you set this, do not commit the resulting lockfile diff.

## Architecture

### Boot sequence

`lib/watobo.rb` is the entry point. It requires bundler (unless `DEV_ENV` is set), then loads subsystems in a specific order:

`constants → resources → utils → mixins → config → defaults → http → evasions → net → core → externals → adapters → framework → parser → interceptor → sockets → scanner → cookie_store` → `Watobo.init_framework` → `ca`.

`Watobo.init_framework` (`lib/watobo/framework/init.rb`) does four things:
1. `init_working_directory` — creates `WATOBO_HOME` (default `~/.watobo`) plus `conf/` and `tmp/` under it.
2. Iterates every registered `Watobo::Conf::*` module and calls `.update` (loads YAML overrides from the working directory).
3. `init_workspace_path` — creates the per-workspace folder that holds project/session data.
4. `init_active_modules` + `init_passive_modules` — see “Module loading” below.

The GUI is a separate opt-in layer. `bin/watobo_gui.rb` loads `'watobo/gui'`, which requires `fox16`, creates the `FXApp`, and loads every `.rb` under `lib/watobo/gui/` (with `main_window.rb` deferred until last).

### Configuration system (`lib/watobo/config.rb` + `lib/watobo/defaults.rb`)

Config is a metaprogrammed registry, not plain constants:

- YAML files in `config/*.yml` are loaded at boot by `Watobo.load_defaults`. Each filename becomes a submodule of `Watobo::Conf` (e.g. `general.yml` → `Watobo::Conf::General`, `interceptor.yml` → `Watobo::Conf::Interceptor`).
- Each config module holds a `@settings` hash and uses `method_missing` to expose keys as reader/writer methods. `Watobo::Conf::Interceptor.port` and `Watobo::Conf::Interceptor.port = 9000` both work.
- `.update` overlays values from `<working_directory>/conf/<snake_cased_name>.yml` (the module name is snakecased with `::` mapped to `/`, so `Watobo::Conf::General` → `conf/general.yml`); `.save_project` / `.save_session` route to `Watobo::DataStore`.
- Adding a new config file is enough — no code change needed. Naming: symbolize the YAML keys.

There are still three overlapping settings implementations (`TODO.md`): `watobo/config.rb`, `watobo/mixins/config.rb`, and `watobo/gui/mixins/gui_settings`. Don’t assume one is authoritative.

### Module system (checks)

Two categories, discovered from disk at startup:

- **Passive checks** — flat files under `modules/passive/*.rb`. Loaded by `init_passive_modules`, which `load`s each file and then reads every constant added to `Watobo::Modules::Passive`. Base class: `Watobo::PassiveCheck` (`lib/watobo/core/passive_check.rb`). Each check defines `do_test(chat)` and calls `addFinding(...)`.
- **Active checks** — nested under `modules/active/<Group>/<check>.rb` (and any extra dirs on `WATOBO_MODULES`). Loaded by `init_active_modules`, which requires the file and resolves `Watobo::Modules::Active::<Group>::<Check>`. Base class: `Watobo::ActiveCheck` extends `Watobo::Net::Http::Session` (`lib/watobo/core/active_check.rb`).

Both base classes set default `@info` / `@finding` hashes; subclasses `@info.update(...)` / `@finding.update(...)` to override metadata (name, group, threat, rating, CVSS, etc.). Class-name → filename mapping is a strict capitalize-first-letter/downcase-rest transform (see the `slice(0..0).upcase + slice(1..-1).downcase` pattern in `init_modules.rb`) — deviating breaks discovery.

Group constants live in `lib/watobo/constants.rb` (`AC_GROUP_XSS`, `AC_GROUP_SQL`, …) alongside `FINDING_TYPE_*`, `VULN_RATING_*`, `CHAT_SOURCE_*`, `TE_*`, `AUTH_TYPE_*`, `SCAN_*`.

### Plugin system (`plugins/`)

Plugins are directories under `plugins/` and are loaded by the GUI via `Watobo::Gui::Utils.load_plugins` (`lib/watobo/gui/utils/load_plugins.rb`). Three layouts are supported for backwards compatibility:

1. Legacy: `plugins/<name>/<name>.rb` defines `Watobo::Plugin::<Name>::<Name>` (a `FXDialogBox`-derived class instantiated with `(app, project)`).
2. Newer: `plugins/<name>/gui.rb` defines `Watobo::Plugin::<Name>::Gui`.
3. Current: `plugins/<name>/<name>.rb` subclasses `Watobo::PluginBase` (`lib/watobo/gui/templates/plugin_base.rb`) and declares `plugin_name`, `description`, `load_libs`, `load_gui :main, :tree_view`. The template auto-resolves `plugin_path`, `lib_path`, `icons_path`, and its GUI lives under `plugins/<name>/gui/main.rb` as `Watobo::Plugin::<Name>::Gui::Main`. `create_gui` is called by the loader.

The loader also scans `<working_directory>/plugins/` so user-installed plugins are picked up alongside repo plugins. Some in-tree plugins (`soaper`, `scrambler`, `sqlinjector`, `modules/active/RoR`) are excluded from the packaged gem — see the `excludes` list in `watobo.gemspec`.

### Data flow at runtime

Request lifecycle:
- `Watobo::Interceptor` / `Watobo::Proxy` (`lib/watobo/interceptor/proxy.rb`, `lib/watobo/core/proxy.rb`) sit between browser and target. TLS interception uses on-the-fly certificates from `lib/watobo/ca.rb` / `core/cert_store.rb`.
- Each browser transaction becomes a `Watobo::Chat` (`request` + `response`), tagged with a `CHAT_SOURCE_*` constant, and appended to `Watobo::Chats`.
- `Watobo::PassiveScanner` fans out each new chat to every loaded passive check.
- Active scans are driven from the GUI (Full Scan / Quick Scan dialogs) or `bin/watobo-scanner.rb`; they iterate chats + parameters, mutate requests, and re-send them via `Watobo::Net::Http::Session`.
- Both check types produce `Watobo::Finding`s aggregated in `Watobo::Findings` and surfaced in the GUI findings tree.

Persistence:
- `Watobo::DataStore` (`lib/watobo/adapters/data_store.rb`) is a facade that delegates via `method_missing` to a per-session engine. The file adapter is `Watobo::FileSessionStore` (`lib/watobo/adapters/file/marshal_store.rb`); chats are marshalled under `<workspace_path>/<project>/<session>/`.
- Projects and sessions are just directories. `DataStore.projects` / `DataStore.sessions(project)` enumerate them.

### Directory map

- `bin/` — GUI entry point (`watobo_gui.rb`), wrapper (`watobo`), headless proxy, and one-off CLIs.
- `lib/watobo.rb` — top-level require list; keep the ordering intact when adding subsystems.
- `lib/watobo/core/` — chats, findings, projects, scanners, proxy, sessions, base classes for checks.
- `lib/watobo/net/http/` — HTTP session layer that active checks build on.
- `lib/watobo/http/` — HTTP data models (request/response bodies: json/xml/multipart/gwt-rpc), URL, headers, cookies.
- `lib/watobo/interceptor/` — proxy + transparent (nfqueue) mode.
- `lib/watobo/gui/` — every FXRuby dialog/window; loaded en masse (order matters only for `main_window.rb`, loaded last).
- `lib/watobo/framework/` — `init_framework`, project bootstrap, module discovery.
- `lib/watobo/adapters/` — data/session stores.
- `lib/watobo/utils/` — helpers used across the codebase (`string2response`, `text2request`, `response_compare`, crypto, `secure_eval`, curl generation, etc.).
- `modules/active/<Group>/*.rb`, `modules/passive/*.rb` — the check library.
- `plugins/<name>/` — first-party plugins (aem, crawler, filefinder, invader, jwt, nuclei, sequencer, sniper, sqlmap, sslchecker, wshell, …).
- `config/*.yml` — default settings, one file per `Watobo::Conf::*` group.
- `spec/` — RSpec suite; helpers/stubs in `spec/app/` (Sinatra vuln app).
- `dev/plugin_loader.rb` — GUI-lite bootstrap for developing a plugin in isolation.

## Platform notes

- `nfqueue` (transparent proxy mode) is Linux-only; the `Gemfile` conditionally includes it via `RUBY_PLATFORM =~ /linux/`.
- NTLM auth requires MD4, disabled by default in OpenSSL 3. See `ntlm.md` for the `/etc/ssl/openssl.cnf` change (enable the `legacy` provider).
- OS-specific install scripts live in `installers/` (kali, fedora, rbenv); transparent-proxy iptables helpers in `extras/`.
- `lib/watobo/patch_fxruby_setfocus.rb` is loaded before any GUI code to work around an FXRuby focus bug — keep it in the load order.
