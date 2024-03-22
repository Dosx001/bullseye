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
  let topLeft!: HTMLDivElement,
    top!: HTMLDivElement,
    topRight!: HTMLDivElement,
    left!: HTMLDivElement,
    center!: HTMLDivElement,
    right!: HTMLDivElement,
    bottomLeft!: HTMLDivElement,
    bottom!: HTMLDivElement,
    bottomRight!: HTMLDivElement;
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
        if (!res) tauwin.appWindow.hide().then(reset).catch(console.error);
      })
      .catch(console.error);
  };
  function mouseCmd(cmd: string, ref: HTMLDivElement) {
    tauwin.appWindow
      .hide()
      .then(() => {
        invoke(cmd, getPosition(ref)).catch(console.error);
        reset();
      })
      .catch(console.error);
  }
  function areaEvent(ev: KeyboardEvent, ref: HTMLDivElement) {
    if (ev.altKey) mouseCmd("left_click", ref);
    else if (ev.ctrlKey) mouseCmd("right_click", ref);
    else if (ev.shiftKey) mouseCmd("move_mouse", ref);
    else {
      setIndex(index() + 1);
      setHistory(
        history().length === index()
          ? history().concat({ ...size })
          : history().toSpliced(index(), 1, { ...size }),
      );
      updateSize(ref);
      setShow(true);
    }
  }
  const handleKey = (e: KeyboardEvent) => {
    switch (e.code) {
      case "Semicolon":
        tauwin.appWindow
          .hide()
          .then(() => {
            invoke(e.ctrlKey ? "right_click" : "left_click", {
              x: -1,
              y: -1,
            }).catch(console.error);
          })
          .catch(console.error);
        break;
      case "Space":
        areaEvent(e, center);
        break;
      case "KeyA":
        areaEvent(e, left);
        break;
      case "KeyF":
        areaEvent(e, right);
        break;
      case "KeyD":
        areaEvent(e, bottom);
        break;
      case "KeyI":
        areaEvent(e, bottomLeft);
        break;
      case "KeyO":
        areaEvent(e, bottomRight);
        break;
      case "KeyS":
        areaEvent(e, top);
        break;
      case "KeyE":
        areaEvent(e, topRight);
        break;
      case "KeyW":
        areaEvent(e, topLeft);
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
      case "KeyQ":
        tauwin.appWindow.hide().then(reset).catch(console.error);
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
      <div class="flex h-1/4 w-full">
        <Region ref={topLeft} show={show()} text="w" />
        <Region ref={top} show={show()} text="s" />
        <Region ref={topRight} show={show()} text="e" />
      </div>
      <div class="flex h-1/2 w-full">
        <Region ref={left} show={show()} text="a" />
        <Region ref={center} show={show()} text="&nbsp;" />
        <Region ref={right} show={show()} text="f" />
      </div>
      <div class="flex h-1/4 w-full">
        <Region ref={bottomLeft} show={show()} text="i" />
        <Region ref={bottom} show={show()} text="d" />
        <Region ref={bottomRight} show={show()} text="o" />
      </div>
    </div>
  );
}

export default App;
