import { invoke, window as tauwin } from "@tauri-apps/api";
import {
  isRegistered,
  register,
  unregister,
} from "@tauri-apps/api/globalShortcut";
import Region from "components/Region";
import { createSignal, onCleanup, onMount } from "solid-js";
import { createStore } from "solid-js/store";

function App() {
  let top!: HTMLDivElement,
    left!: HTMLDivElement,
    center!: HTMLDivElement,
    right!: HTMLDivElement,
    bottom!: HTMLDivElement;
  const [show, setShow] = createSignal(false);
  const [index, setIndex] = createSignal(-1);
  const [size, setSize] = createStore({
    width: window.screen.width,
    height: window.screen.height,
    x: 0,
    y: 0,
  });
  const [history, setHistory] = createSignal<(typeof size)[]>([]);
  const updateSize = (el: HTMLDivElement) => {
    setSize({
      width: el.clientWidth,
      height: el.clientHeight,
      x: el.getClientRects()[0].x,
      y: el.getClientRects()[0].y,
    });
  };
  const reset = () => {
    setIndex(-1);
    setHistory([]);
    setSize({
      width: window.screen.width,
      height: window.screen.height,
      x: 0,
      y: 0,
    });
    setShow(false);
  };
  const move = (x: boolean, length: number) =>
    x ? setSize("x", size.x + length) : setSize("y", size.y + length);
  const getPosition = (ref: HTMLDivElement) => {
    const rect = ref.querySelector("span")!.getClientRects()[0];
    return {
      x: Math.floor(rect.x),
      y: Math.floor(rect.y),
    };
  };
  const blur = () => {
    invoke("debug")
      .then((res) => {
        if (!res) tauwin.appWindow.hide().catch(console.error);
      })
      .catch(console.error);
  };
  const hotkey = (event: KeyboardEvent, ref: HTMLDivElement) => {
    if (event.altKey) {
      setIndex(index() + 1);
      setHistory((v) => {
        if (history.length === index()) v.push({ ...size });
        else v[index()] = { ...size };
        return Array.from(v);
      });
      updateSize(ref);
      setShow(true);
    } else {
      tauwin.appWindow
        .hide()
        .then(() => {
          invoke(
            event.shiftKey ? "right_click" : "left_click",
            getPosition(ref),
          ).catch(console.error);
          reset();
        })
        .catch(console.error);
    }
  };
  const handleKey = (e: KeyboardEvent) => {
    switch (e.code) {
      case "Space":
        hotkey(e, center);
        break;
      case "KeyA":
        hotkey(e, left);
        break;
      case "KeyD":
        hotkey(e, bottom);
        break;
      case "KeyF":
        hotkey(e, right);
        break;
      case "KeyS":
        hotkey(e, top);
        break;
      case "KeyH":
        move(true, -5);
        break;
      case "KeyJ":
        move(false, 5);
        break;
      case "KeyK":
        move(false, -5);
        break;
      case "KeyL":
        move(true, 5);
        break;
      case "KeyM":
        invoke("move_mouse", getPosition(center)).catch(console.error);
        reset();
        tauwin.appWindow.hide().catch(console.error);
        break;
      case "KeyQ":
        tauwin.appWindow.hide().catch(console.error);
        reset();
        break;
      case "KeyR":
        reset();
        break;
      case "KeyU":
        if (index() === -1) return;
        setSize(history()[index()]);
        setIndex(index() - 1);
        break;
    }
  };
  onMount(() => {
    const shortcut = "Super+;";
    isRegistered(shortcut)
      .then((reg) => {
        if (reg) unregister(shortcut).catch(console.error);
      })
      .finally(() => {
        register(shortcut, () => {
          tauwin.appWindow.show().catch(console.error);
          tauwin.appWindow.setFocus().catch(console.error);
        }).catch(console.error);
      })
      .catch(console.error);
    window.addEventListener("blur", blur);
    window.addEventListener("keydown", handleKey);
  });
  onCleanup(() => {
    window.removeEventListener("keydown", handleKey);
    window.removeEventListener("blur", blur);
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
      <Region ref={top} height={false} show={show()} text="s" />
      <div class="flex h-1/2 w-full">
        <Region ref={left} height={true} show={show()} text="a" />
        <Region ref={center} height={true} show={show()} text="&nbsp;" />
        <Region ref={right} height={true} show={show()} text="f" />
      </div>
      <Region ref={bottom} height={false} show={show()} text="d" />
    </div>
  );
}

export default App;
