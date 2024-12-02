<script lang="ts">
  export let data;
  import { Notifications, acts } from "@tadashi/svelte-notification";
  import { PUBLIC_SITE_NAME } from "$env/static/public";

  async function handleRoleChange(event: Event, oldRole: number, userId: Number, userName: String) {
    const { target } = event;
    if (!target) return;
    const selFunction = "editRole";
    let newrole = (target as HTMLSelectElement).value;

    const response = await fetch("/api/editUserRole", {
      method: "POST",
      body: JSON.stringify({ userId, newrole, selFunction }),
      headers: { "Content-Type": "applicatoin/json" },
    });

    const { error } = await response.json();

    if (error) {
      acts.add({ mode: "error", message: error, lifetime: 30 });
      (target as HTMLSelectElement).value = oldRole.toString();
    } else {
      acts.add({ mode: "warn", message: `Changed ${userName} (${userId}), from ${oldRole} to ${newrole}`, lifetime: 15 });
    }
  }
  async function handleEmailReset(event: Event, userId: Number, email: String, userName: String) {
    if (data.user.role >= 2) {
      try {
        const selFunction = "resetPW";
        const response = await fetch("/api/editUserRole", {
          method: "POST",
          body: JSON.stringify({ userId, selFunction, email, userName }),
          headers: { "Content-Type": "application/json" },
        });

        const { error } = await response.json();

        if (error) {
          acts.add({ mode: "error", message: error, lifetime: 30 });
        } else {
          acts.add({ mode: "success", message: `Email reset sent`, lifetime: 15 });
        }
      } catch (e: any) {
        acts.add({ mode: "error", message: e.message, lifetime: 30 });
      }
    }
  }

  console.assert(!!data.user);
</script>

<div class="px-4 py-1 mt-1 text-center d-flex flex-column align-items-center" style="margin-bottom: 50px;">
  <h1 class="mb-3">Users</h1>

  <table>
    <thead>
      <th> User ID </th>
      <th> User Name </th>
      <th> User Email </th>
      <th> User Role </th>
      <th> Reset </th>
    </thead>

    {#each data.users as user}
      <tr>
        <td> {user.id}</td>
        <td> {user.name} </td>
        <td> {user.email} </td>

        {#if data.user.role > 1}
          <td>
            <select name="role" id="role" on:change={(e) => handleRoleChange(e, user.role, user.id, user.name)} value={user.role}>
              <option value={0}>Guest</option>
              <option value={1}>User</option>
              <option value={2}>Admin</option>
              <option value={3}>Owner</option>
            </select>
          </td>
        {/if}
        <td> <button on:click={(e) => handleEmailReset(e, user.id, user.email, user.name)}>Reset</button> </td>
      </tr>
    {/each}
  </table>
</div>

<Notifications />

<style>
  th,
  td {
    padding: 5px;

    border: 1px solid #989898;
  }
</style>
