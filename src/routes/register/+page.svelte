<script lang="ts">
  import { enhance } from "$app/forms";
  import { goto } from "$app/navigation";
  export let data;
  let showPW = false;
  let error = "";
  function togglePW() {
    showPW = !showPW;
  }
  export let form
  let showRole = data.user ? (data.user.roleTemp > 2 ? true : false) : true;
</script>

<div class="fullHeight d-flex align-items-center flex-column justify-content-center row-gap">
  <h1 class="text-center display-1">Register</h1>

  <form
    class="container-sm text-center"
    action="?"
    use:enhance={({ formElement, formData, action, cancel, submitter }) => {
      error = "";
      let pw = formData.get("password");
      let vPw = formData.get("verifyPassword");
      if (pw !== vPw) {
        console.log(pw, vPw);

        cancel();
        error = "Passwords don't match";
        return;
      }

      return async ({ result, update }) => {
        if (!error) {
          update();
        }
      };
    }}
    method="POST"
  >
    <div class="input-group mb-3 align-middle">
      <span class="input-group-text" id="basic-addon1">A</span>
      <input spellcheck="false" name="name" type="name" class="form-control" placeholder="Full Name" aria-label="Name" aria-describedby="basic-addon1" required />
    </div>

    <div class="input-group mb-3 align-middle">
      <span class="input-group-text" id="basic-addon1">@</span>
      <input name="email" type="email" class="form-control" placeholder="Email" aria-label="Email" aria-describedby="basic-addon1" required />
    </div>

    <div class="input-group mb-3 align-middle">
      <span class="input-group-text" id="basic-addon1">**</span>

      <input name="password" type={showPW ? "text" : "password"} id="PW" class="form-control" placeholder="Password" aria-label="Password" aria-describedby="basic-addon1" required />

      <button type="button" class="input-group-text" id="basic-addon1" on:click={togglePW}><i class={"bi bi-eye" + (showPW ? "" : "-slash") + "-fill"}></i></button>
    </div>

    <div class="input-group mb-3 align-middle">
      <span class="input-group-text" id="basic-addon1">**</span>
      <input class="form-control" type="password" name="verifyPassword" placeholder="Verify Password" required />
    </div>

    <div class="input-group mb-3 align-middle" hidden={showRole}>
      <select class="form-control" name="roleTemp" id="roleTemp" required>
        <option selected disabled value="0">Select a roleTemp...</option>
        <option value="2">Admin</option>
        <option value="1">User</option>
        <option value="0">Guest</option>
      </select>
    </div>

    {#if error}
      <div class="notice error m-2">
        Error: {error}
      </div>
    {:else if form?.error}
      <div class="notice error m-2">
        Error: {form.error}
      </div>
    {/if}

    <button>Register</button>
    <button type="button" on:click={() => goto("/")}>Return to Sign</button>
  </form>
</div>

<style>
  .error {
    border-color: red;
  }
  .notice {
    font-style: italic;
    color: orangered;
  }
</style>
