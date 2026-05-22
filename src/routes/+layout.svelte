<script>
  import "bootstrap/dist/css/bootstrap.css";
  import scriptSrc from "bootstrap/dist/js/bootstrap.bundle.js?url";
  import "../scss/styles.scss";
  import "bootstrap-icons/font/bootstrap-icons.css";
  import { Modals, closeModal } from "svelte-modals";
</script>

<svelte:head>
  <script src={scriptSrc}></script>
</svelte:head>
<slot />

<Modals>
  <!-- svelte-ignore a11y-no-static-element-interactions -->
  <!-- svelte-ignore a11y-click-events-have-key-events -->
  <div slot="backdrop" class="backdrop" on:click={closeModal} />
</Modals>

<style>
  .backdrop {
    position: fixed;
    top: 0;
    bottom: 0;
    right: 0;
    left: 0;
    background: rgba(0, 0, 0, 0.5);
  }

  :global(body) {
    font: 18px 'Open Sans', sans-serif;
  }
</style>
