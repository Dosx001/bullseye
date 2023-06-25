const Bubble = (props: { text: string }) => {
  return (
    <div class="flex h-full items-center justify-center text-center">
      <span class="w-4 rounded border border-green-500 bg-black text-green-500">
        {props.text}
      </span>
    </div>
  );
};

export default Bubble;
