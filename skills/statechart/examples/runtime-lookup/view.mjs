export const title = "Statechart runtime selection";
export const state = (v) => ({
  start: "Start",
  local: "Check local configuration",
  mise: "Check installed tools",
  install: "Install pinned tools",
  ready: "Ready",
  error: "Configuration or install error",
})[v.phase];
export const step = (action) => ({
  UseEnvironment: "use explicit environment paths",
  CheckLocal: "no explicit TLC path",
  UseLocal: "use configured paths [valid configuration]",
  RejectLocal: "reject invalid configuration",
  CheckMise: "no local configuration",
  UseMise: "use installed tools",
  StartInstall: "tools unavailable",
  InstallSucceeds: "installation succeeds",
  InstallFails: "installation fails",
  Done: "finish",
})[action];
