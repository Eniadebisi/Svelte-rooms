<script lang="ts">
  import { enhance } from "$app/forms";
  import type { ActionData, PageData } from "./$types";
  import { goto } from "$app/navigation";

  export let data: PageData;
  const { SITE_NAME } = data;
  let showPW = false;
  function togglePW() {
    showPW = !showPW;
  }
  export let form: ActionData;
</script>

<div class="fullHeight d-flex align-items-center flex-column justify-content-center row-gap">
  <h1 class="text-center display-1">{SITE_NAME}</h1>

  <form class="container-sm text-center" action="?/signIn" use:enhance method="POST">
    <div class="input-group mb-3 align-middle">
      <span class="input-group-text" id="basic-addon1">@</span>
      <input name="email" type="email" class="form-control" placeholder="Email" aria-label="Email" aria-describedby="basic-addon1" />
    </div>

    <div class="input-group mb-3 align-middle">
      <span class="input-group-text" id="basic-addon1">**</span>
      <input name="password" type={showPW ? "text" : "password"} id="PW" class="form-control" placeholder="Password" aria-label="Password" aria-describedby="basic-addon1" />
      <!-- svelte-ignore a11y-click-events-have-key-events -->
      <!-- svelte-ignore a11y-no-static-element-interactions -->
      <div class="input-group-text" id="basic-addon1" on:click={togglePW}><i class={"bi bi-eye" + (showPW ? "" : "-slash") + "-fill"}></i></div>
    </div>

    {#if form?.error}
      <div class="notice error">
        {form.error}
      </div>
    {/if}

    <button>Sign In</button>
    <button
      type="button"
      on:click={() => {
        goto("/register");
      }}>Register</button
    >
  </form>
</div>
