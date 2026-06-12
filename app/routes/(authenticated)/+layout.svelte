<script lang="ts">
  import { hasPermission } from "$lib/permissions/auth";
  import type { LayoutData } from "./$types";
  import favicon from "$lib/assets/favicon.png";

  export let data: LayoutData;
  let { user } = data;
</script>

<div class="navbar bg-body-tertiary p-3">
  <a href="/" class="navbar-brand align-items-center d-flex px-2">
    <img src={favicon} alt="" width="45px" /> 
    <p class="p-0 m-0 px-2">SATL Reservations</p>
  </a>
  <div class="navbar-nav d-flex flex-row flex-grow-1 px-1 justify-content-start">
    {#if hasPermission(user, "UserManagement", "update")}
      <a class="nav-link" href="/spaces">Spaces</a>
      <a class="nav-link" href="/users">Users</a>
      <a class="nav-link" href="/register">Add a User</a>
    {/if}
    <a class="nav-link" href="/profile">Profile</a>
  </div>
  <div class="user-section">
    <span class="user-info">{data.user.name} ({data.user.role})</span>
    <form action="../signout?" method="POST">
      <button class="logout-btn"><i class="bi bi-box-arrow-right"></i></button>
    </form>
  </div>
</div>

<slot />

<style>
  .nav-link {
    font-size: 1.4rem;
    font-family: 'Open Sans', sans-serif;
    /* font-weight: 500; */
    padding: 0.5rem 1rem !important;
    transition: background-color 0.3s ease, color 0.3s ease;
    border-radius: 0.25rem;
  }

  .nav-link:hover {
    background-color: rgba(0, 0, 0, 0.15);
    color: inherit;
  }

  .navbar-brand {
    font-size: 2.1rem;
    font-family: 'Public Sans', sans-serif;
    font-weight: 600;
  }

  .user-section {
    display: flex;
    align-items: center;
    gap: 1rem;
  }

  .user-info {
    font-size: 1.1rem;
    font-weight: 500;
  }

  .logout-btn {
    background: transparent;
    border: none;
    font-size: 1.2rem;
    cursor: pointer;
    padding: 0.5rem 0.75rem;
    border-radius: 0.25rem;
    transition: background-color 0.3s ease, transform 0.2s ease;
    color: inherit;
  }

  .logout-btn:hover {
    background-color: rgba(0, 0, 0, 0.15);
    transform: scale(1.1);
  }
</style>
