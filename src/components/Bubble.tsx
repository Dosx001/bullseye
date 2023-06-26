import { Show } from "solid-js";

const Bubble = (props: { text: string; show: boolean }) => {
  return (
    <div class="flex h-full items-center justify-center text-center">
      <Show
        when={props.show}
        fallback={
          <span class="w-4 rounded border border-green-500 bg-black text-green-500">
            {props.text}
          </span>
        }
      >
        <span class="h-1 w-1 rounded bg-green-500" />
      </Show>
    </div>
  );
};

export default Bubble;
