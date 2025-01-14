<script lang="ts">
  export let data;
  import { Notifications, acts } from "@tadashi/svelte-notification";
  import { PUBLIC_SITE_NAME } from "$env/static/public";
  import type { Roles } from "@prisma/client";
  import { closeModal, openModal } from "svelte-modals";
  import GenModal from "$lib/genModal.svelte";
  import { hasPermission } from "$lib/permissions/auth.js";
  import { user } from "$lib/user.js";

  async function handleRoleChange(event: Event, oldRole: string, userId: Number, userName: String) {
    const { target } = event;
    if (!target) return;
    const selFunction = "editRole";
    let newrole: Roles = (target as HTMLSelectElement).value.toString() as Roles;

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
    if (hasPermission(data.user, "UserManagement", "update")) {
      try {
        const selFunction = "resetPW";
        return;
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
  function confirmDelUser(userId: Number, userName: String) {
    openModal(GenModal, {
      Title: "Confirm deleting '" + userName+"' ("+userId+")",
      confirmButton1: true,
      confirmButton1Func: () => {
        console.log("Deleted user " + userId);
        closeModal();
      },
    });
  }

  console.assert(!!data.user);
</script>

<div class="px-4 py-1 mt-1 text-center d-flex flex-column align-items-center" style="margin-bottom: 50px;">
  <h1 class="mb-3">Users</h1>

  <table>
    <thead>
      <th> ID </th>
      <th> User Name </th>
      <th> User Email </th>
      <th> User Role </th>
      <th> Actions </th>
    </thead>

    {#each data.users as user}
      <tr>
        <td> {user.id}</td>
        <td> {user.name} </td>
        <td> {user.email} </td>

        <td>
          <select name="role" id="role" on:change={(e) => handleRoleChange(e, user.role, user.id, user.name)} value={user.role}>
            <option value="Owner" disabled>Owner</option>
            <option value="Admin">Admin</option>
            <option value="User">User</option>
            <option value="Guest">Guest</option>
            <option value="Restricted">Restricted</option>
          </select>
        </td>
        <td> <button on:click={(e) => handleEmailReset(e, user.id, user.email, user.name)}>Reset</button> <button on:click={(e) => confirmDelUser(user.id, user.name)}>Delete</button></td>
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
