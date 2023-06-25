import { window as tauwin } from "@tauri-apps/api";
import {
  isRegistered,
  register,
  unregister,
} from "@tauri-apps/api/globalShortcut";
import Bubble from "components/Bubble";
import { onMount } from "solid-js";

function App() {
  onMount(() => {
    const shortcut = "CmdOrCtrl+Super+m";
    isRegistered(shortcut)
      .then((reg) => {
        if (reg) unregister(shortcut)!;
      })
      .finally(() => {
        register(shortcut, () => {
          tauwin.appWindow.show()!;
          tauwin.appWindow.setFocus()!;
        })!;
      })!;
    window.addEventListener("blur", () => {
      invoke("debug").then((res) => {
        if (!res) tauwin.appWindow.hide()!;
      })!;
    });
    window.addEventListener("keydown", (e) => {
      if (e.key === "Escape") tauwin.appWindow.hide()!;
    });
  });
  return (
    <div class="h-screen">
      <div class="h-1/4 w-full border border-green-500">
        <Bubble text="k" />
      </div>
      <div class="flex h-1/2 w-full">
        <div class="h-full w-full border border-green-500">
          <Bubble text="h" />
        </div>
        <div class="h-full w-full border border-green-500">
          <Bubble text=";" />
        </div>
        <div class="h-full w-full border border-green-500">
          <Bubble text="l" />
        </div>
      </div>
      <div class="h-1/4 w-full border border-green-500">
        <Bubble text="j" />
      </div>
    </div>
  );
}

export default App;
