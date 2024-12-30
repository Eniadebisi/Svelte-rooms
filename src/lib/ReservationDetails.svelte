<script lang="ts">
  import { closeModal, closeAllModals, openModal, modals } from "svelte-modals";
  import { fade, scale } from "svelte/transition";
  import dayjs from "dayjs";
  import AdvancedFormat from "dayjs/plugin/advancedFormat";
  dayjs.extend(AdvancedFormat);
  import type { Reservation } from "@prisma/client";
  import { hasPermission } from "./permissions/auth";

  export let isOpen, resvObj: Reservation, openEditResv, refresh: Function, user: any, notify: Function;
  let formError = "";


  async function deleteReservation() {
    if (hasPermission(user, "Reservation", "delete", resvObj)) {
      const reservationId = resvObj.id;
      const response = await fetch("/api/deleteReservation", {
        method: "POST",
        body: JSON.stringify({ reservationId }),
      });
      const { error } = await response.json();

      if (error) {
        formError = error;
      } else {
        refresh(resvObj.startTime.toISOString());
      }
    } else {
      notify("warn", "Cannot delete another user's reservation");
    }
  }
</script>

{#if isOpen}
  <div role="dialog" class="modal">
    <div class="contents">
      <div class="mt-3 text-center" transition:scale={{ duration: 200 }}>
        <h3 class="">{resvObj.title}</h3>
        <div class="mt-2 px-7 py-3">
          User : {resvObj.userId}
          <br />
          Details: {resvObj.details}
          <br />
          Date: {dayjs(resvObj.startTime).format("dddd, MMMM D, YYYY")}
          <br />
          Time: {(dayjs(resvObj.startTime).hour() * 100 + dayjs(resvObj.startTime).minute()).toString().padStart(4, "0")} - {(dayjs(resvObj.endTime).hour() * 100 + dayjs(resvObj.endTime).minute()).toString().padStart(4, "0")}
        </div>
        <div class="items-center px-4 py-3">
          <button on:click={closeModal} class=""> Close </button>
          <button on:click={openEditResv} class=""> Edit </button>
          {#if user.roleTemp > 2}
            <button on:click={deleteReservation} class=""> Delete </button>
          {/if}
        </div>
      </div>
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
