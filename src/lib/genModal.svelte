<script lang="ts">
  import { closeModal, closeAllModals, openModal, modals } from "svelte-modals";
  import { fade, scale } from "svelte/transition";

  export let isOpen,
    Title: string,
    input1: any = null,
    input2: any = null,
    confirmButton1: any = null,
    confirmButton1Func: Function = () => {};
</script>

{#if isOpen}
  <div role="dialog" class="modal">
    <div class="contents" transition:scale={{ duration: 200 }}>
      <h3>{Title}</h3>

      {#if input1}
      <div class="m-2">
        <label for={input1.toString()}>{input1.toString()}</label>
        <input type="text" name={input1} id={input1} />
      </div>
      {/if}

      {#if input2}
      <div class="m-2">
        <label for={input2.toString()}>{input2.toString()}</label>
        <input type="text" name={input2} id={input2} />
      </div>
      {/if}
      
      {#if confirmButton1}
      <div class="m-2 d-flex justify-content-around">
        <button on:click={confirmButton1Func()}>Yes</button>
        <button on:click={closeModal}>No</button>
      </div>
      {/if}

    </div>
  </div>
{/if}

<style>
  .modal {
    position: fixed;
    top: 0;
    bottom: 0;
    right: 0;
    left: 0;
    display: flex;
    justify-content: center;
    align-items: center;

    /* allow click-through to backdrop */
    pointer-events: none;
  }
  .contents {
    min-width: 240px;
    border-radius: 6px;
    padding: 16px;
    background: white;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    pointer-events: auto;
  }
</style>
