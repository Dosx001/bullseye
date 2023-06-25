import { invoke, window as tauwin } from "@tauri-apps/api";
import {
  isRegistered,
  register,
  unregister,
} from "@tauri-apps/api/globalShortcut";
import Bubble from "components/Bubble";
import { onMount } from "solid-js";
import { createStore } from "solid-js/store";

function App() {
  let top!: HTMLDivElement,
    left!: HTMLDivElement,
    center!: HTMLDivElement,
    right!: HTMLDivElement,
    bottom!: HTMLDivElement;
  const [size, setSize] = createStore({
    width: window.screen.width,
    height: window.screen.height,
    x: 0,
    y: 0,
  });
  const updateSize = (el: HTMLDivElement) => {
    setSize({
      width: el.clientWidth,
      height: el.clientHeight,
      x: el.getClientRects()[0].x,
      y: el.getClientRects()[0].y,
    });
  };
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
      switch (e.key) {
        case "Escape":
          tauwin.appWindow.hide()!;
          break;
        case "h":
          updateSize(left);
          break;
        case "j":
          updateSize(bottom);
          break;
        case "k":
          updateSize(top);
          break;
        case "l":
          updateSize(right);
          break;
        case ";":
          updateSize(center);
          break;
        case "r":
          setSize({
            width: window.screen.width,
            height: window.screen.height,
            x: 0,
            y: 0,
          });
      }
    });
  });
  return (
    <div
      class="absolute"
      style={{
        height: `${size.height.toString()}px`,
        width: `${size.width.toString()}px`,
        top: `${size.y.toString()}px`,
        left: `${size.x.toString()}px`,
      }}
    >
      <div ref={top} class="h-1/4 w-full border border-green-500">
        <Bubble text="k" />
      </div>
      <div class="flex h-1/2 w-full">
        <div ref={left} class="h-full w-full border border-green-500">
          <Bubble text="h" />
        </div>
        <div ref={center} class="h-full w-full border border-green-500">
          <Bubble text=";" />
        </div>
        <div ref={right} class="h-full w-full border border-green-500">
          <Bubble text="l" />
        </div>
      </div>
      <div ref={bottom} class="h-1/4 w-full border border-green-500">
        <Bubble text="j" />
      </div>
    </div>
  );
}

export default App;
