import { invoke, window as tauwin } from "@tauri-apps/api";
import {
  isRegistered,
  register,
  unregister,
} from "@tauri-apps/api/globalShortcut";
import Region from "components/Region";
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
  const reset = () => {
    setSize({
      width: window.screen.width,
      height: window.screen.height,
      x: 0,
      y: 0,
    });
    setShow(false);
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
      switch (e.code) {
        case "KeyQ":
          tauwin.appWindow.hide()!;
          break;
        case "KeyH":
          updateSize(left);
          setShow(true);
          break;
        case "KeyJ":
          updateSize(bottom);
          setShow(true);
          break;
        case "KeyK":
          updateSize(top);
          setShow(true);
          break;
        case "KeyL":
          updateSize(right);
          setShow(true);
          break;
        case "Semicolon":
          updateSize(center);
          setShow(true);
          break;
        case "KeyM": {
          const rect = center.querySelector("span")!.getClientRects()[0];
          invoke("move_mouse", {
            x: Math.floor(rect.x),
            y: Math.floor(rect.y),
          })!;
          reset();
          tauwin.appWindow.hide()!;
          break;
        }
        case "KeyR":
          reset();
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
      <Region ref={top} height={false} show={show()} text="k" />
      <div class="flex h-1/2 w-full">
        <Region ref={left} height={true} show={show()} text="h" />
        <Region ref={center} height={true} show={show()} text=";" />
        <Region ref={right} height={true} show={show()} text="l" />
      </div>
      <Region ref={bottom} height={false} show={show()} text="j" />
    </div>
  );
}

export default App;
