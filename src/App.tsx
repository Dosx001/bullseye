import { invoke, window as tauwin } from "@tauri-apps/api";
import {
  isRegistered,
  register,
  unregister,
} from "@tauri-apps/api/globalShortcut";
import Bubble from "components/Bubble";
import { createSignal, onMount } from "solid-js";
import { createStore } from "solid-js/store";

function App() {
  let top!: HTMLDivElement,
    left!: HTMLDivElement,
    center!: HTMLDivElement,
    right!: HTMLDivElement,
    bottom!: HTMLDivElement;
  const [show, setShow] = createSignal(false);
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
          setShow(true);
          break;
        case "j":
          updateSize(bottom);
          setShow(true);
          break;
        case "k":
          updateSize(top);
          setShow(true);
          break;
        case "l":
          updateSize(right);
          setShow(true);
          break;
        case ";":
          updateSize(center);
          setShow(true);
          break;
        case "r":
          setShow(false);
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
        <Bubble text="k" show={show()} />
      </div>
      <div class="flex h-1/2 w-full">
        <div ref={left} class="h-full w-full border border-green-500">
          <Bubble text="h" show={show()} />
        </div>
        <div ref={center} class="h-full w-full border border-green-500">
          <Bubble text=";" show={show()} />
        </div>
        <div ref={right} class="h-full w-full border border-green-500">
          <Bubble text="l" show={show()} />
        </div>
      </div>
      <div ref={bottom} class="h-1/4 w-full border border-green-500">
        <Bubble text="j" show={show()} />
      </div>
    </div>
  );
}

export default App;
