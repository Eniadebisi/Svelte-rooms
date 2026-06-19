<script lang="ts">
  export let data;
  import { Notifications, acts } from "@tadashi/svelte-notification";
  import { enhance } from "$app/forms";

  console.assert(!!data.user);
  let showUpdatePWFields = false;
  export let form

  function togglePWModal() {
    showUpdatePWFields = !showUpdatePWFields;
  }

  let error = "";
  let showPasswords = false;
</script>

<div class="px-4 py-1 mt-1 text-center d-flex flex-column align-items-center" style="margin-bottom: 50px;">
  <h1 class="mb-3">Profile</h1>
  <p><strong>User Name</strong> {data.user.name} ({data.user.role})</p>
  <p><strong>Email</strong> {data.user.email}</p>
  <p><strong>Password</strong> <button on:click={togglePWModal}>Update</button></p>
  {#if showUpdatePWFields}

    <form class="modal" action="?/updatePW" use:enhance={({ formElement, formData, action, cancel, submitter }) => {      
      error = "";
      let currPW = formData.get("currPW");
      let newPW = formData.get("newPW");
      let CnfnewPW = formData.get("CnfnewPW");
      if (newPW !== CnfnewPW) {
        cancel();
        error = "New Passwords don't match";
        return;
      }

		return async ({ result, update }) => {
        if (!error) {
          update();
        }
		};
	}} method="POST">
      <div class="mb-3 align-middle d-flex flex-column">
        <label for="currPW">Old password</label>
        <input type={showPasswords ? "text" : "password"} id="currPW" name="currPW" />
      </div>
      <div class="mb-3 align-middle d-flex flex-column">
        <label for="newPW">New Password</label>
        <input type={showPasswords ? "text" : "password"} id="newPW" name="newPW" />
      </div>
      <div class="mb-3 align-middle d-flex flex-column">
        <label for="CnfnewPW">Confirm New Password</label>
        <input type={showPasswords ? "text" : "password"} id="CnfnewPW" name="CnfnewPW" />
      </div>

      <button type="button" class="show-toggle" on:click={() => (showPasswords = !showPasswords)}>
        <i class="bi {showPasswords ? 'bi-eye-slash' : 'bi-eye'}"></i>
        {showPasswords ? "Hide" : "Show"} passwords
      </button>

      {#if error || form?.error}
        <div class="error m-2">{error ? error : form?.error}</div>
      {/if}
      <i>You will be signed out after password is updated.</i>
      <button>Submit</button>
    </form>
  {/if}
</div>



<Notifications />

<style>
  .show-toggle {
    background: none;
    border: none;
    color: #555;
    cursor: pointer;
    font-size: 0.85rem;
    margin-bottom: 8px;
  }

  .error {
    color: #c00;
    font-size: 0.85rem;
  }

  .modal {
    width: 250px;
    height: 350px;
    border-radius: 25px;
    margin: auto;
    background-color: #e9e9e9;
    z-index: 999;
    top: 0;
    bottom: 0;
    right: 0;
    left: 0;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
  }
</style>
