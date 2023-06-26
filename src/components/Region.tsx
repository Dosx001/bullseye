import { Show } from "solid-js";

const Region = (props: {
  ref: HTMLDivElement;
  height: boolean;
  show: boolean;
  text: string;
}) => {
  return (
    <div
      ref={props.ref}
      style={{ height: props.height ? "100%" : "25%" }}
      class="w-full border border-green-500"
    >
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
    </div>
  );
};

export default Region;
