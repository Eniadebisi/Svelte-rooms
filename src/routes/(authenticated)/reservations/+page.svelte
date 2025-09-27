<script lang="ts">
  import type { PageData } from "./$types";
  import { closeModal, openModal } from "svelte-modals";
  import { browser } from "$app/environment";
  import dayjs from "dayjs";
  import ReservationDetails from "$lib/ReservationDetails.svelte";
  import ReservationEdit from "$lib/ReservationEdit.svelte";
  import { timeZone } from "$lib/settings";
  import NewReservation from "$lib/newReservation.svelte";
  import { acts, Notifications } from "@tadashi/svelte-notification";
  import type { Reservation } from "@prisma/client";

  export let data: PageData;
  let date = data.date ? data.date : new Date();
  let staticDate = dayjs(date).format("YYYY-MM-DD");
  let reservations = data.reservations;

  async function updateReserv(nDate: Date) {
    const response = await fetch("/api/reservationData", {
      method: "POST",
      body: JSON.stringify({ nDate }),
      headers: {
        "Content-Type": "application/json",
      },
    });
    const { reservations: resv, start, end } = await response.json();
    reservations = resv;
  }
  function openResvervationDetails(resvObj: Reservation) {
    openModal(ReservationDetails, {
      resvObj,
      user: data.user,
      openEditResv: () => {
        closeModal();
        openReservationEdit(resvObj);
      },
      refresh: (rDate: string) => {
        if (browser) {
          window.location.href = "/reservations";
        }
        closeModal();
      },
      notify: (mode: string, message: string) => {
        acts.add({ mode, message });
      },
    });
  }
  function openReservationEdit(resvObj: Reservation) {
    openModal(ReservationEdit, {
      resvObj,
      rooms: data.rooms,
      refresh: (rDate: string) => {
        if (browser) {
          window.location.href = "/reservations";
        }
        closeModal();
      },
    });
  }
  function newReservation() {
    openModal(NewReservation, {
      rooms: data.rooms,
      user: data.user,
      refresh: () => {
        if (browser) {
          window.location.href = "/reservations";
        }
        closeModal();
      },
    });
  }
</script>

<div class="px-4 py-1 mt-1 text-center d-flex flex-column align-items-center">
  <h1 class="col mb-3">Reservations</h1>
  <div class="container text-center mb-2">
    <div class="row align-items-start">
      <div class="col">
        <button
          type="button"
          on:click={() => {
            date = dayjs(date).add(-1, "day").toDate();
            staticDate = dayjs(date).format("YYYY-MM-DD");
            updateReserv(date);
          }}
        >
          <i class="bi bi-caret-left"></i>
        </button>
        <input
          type="date"
          name="date"
          id="date"
          bind:value={staticDate}
          on:change={() => {
            date = dayjs(staticDate).toDate();
            updateReserv(date);
          }}
        />
        <button
          type="button"
          on:click={() => {
            date = dayjs(date).add(1, "day").toDate();
            staticDate = dayjs(date).format("YYYY-MM-DD");
            updateReserv(date);
          }}
        >
          <i class="bi bi-caret-right"></i>
        </button>
      </div>
      <div class="col">
        <button type="button" on:click={newReservation}> New Reservation </button>
      </div>
    </div>
  </div>

  <div class="w-100">
    <div class="d-flex overflow-x-hidden mt-3">
      <div class="rowStart">
        <div class="lCell Locations">Locations</div>
        {#each data.locations as loc}
          <div class="lCell locHeaderColor">{loc.name}</div>

          {#each data.rooms.filter((room) => room.locationId === loc.id) as room}
            <div class="lCell roomHeaderColor" title={room.details}>
              {room.name}
            </div>
          {/each}
        {/each}
      </div>
      <div class="rowEnd overflow-x-scroll">
        <div class="tableRow">
          {#each Array(18) as _, i}
            <div class="rCell time-header">{i + 6}:00</div>
          {/each}
        </div>
        {#each data.locations as loc}
          <div class="tableRow">
            {#each Array(18) as _, i}
              <div class="rCell locRCell"></div>
            {/each}
          </div>
          {#each data.rooms.filter((room) => room.locationId === loc.id) as room}
            <div class="tableRow">
              {#each Array(18) as _, i}
                <div class="rCell"></div>
              {/each}
              {#each reservations.filter((resv) => resv.roomId === room.id) as resv}
                <button
                  class="reservation text-truncate"
                  on:click={() => {
                    openResvervationDetails(resv);
                  }}
                  style="width: {resv.endTime ? (85 / 2) * (dayjs(resv.endTime).diff(resv.startTime, 'minute') / 30) : 85}px;margin-left: {85 * dayjs(resv.startTime).hour() + (dayjs(resv.startTime).minute() / 60) * 85 - 6 * 85}px;"
                >
                  {resv.title}
                </button>
              {/each}
            </div>
          {/each}
        {/each}
      </div>
    </div>
  </div>
</div>
<Notifications />

<style>
  .rowStart {
    min-width: 150px;
    max-width: 150px;
  }
  .rCell {
    min-width: 85px;
    width: 85px;
    padding: 1px;
    height: 40px;
    display: flex;
    justify-content: center;
    align-items: center;
    border: 1px solid #989898;
  }
  .lCell {
    border: 1px solid #989898;
    min-width: 150px;
    width: 150px;
    padding: 1px;
    height: 40px;
    display: flex;
    justify-content: center;
    align-items: center;
  }
  .locRCell,
  .locHeaderColor {
    background-color: #e6e6e6;
  }
  .rowEnd {
    display: flex;
    flex-direction: column;
    -ms-overflow-style: none;
    scrollbar-width: none;
    width: 1530px;
  }
  .tableRow {
    position: relative;
    width: 1530px;
    height: 40px;
    /* border: 0.5px solid #000000 !important; */
    display: flex;
    justify-content: center;
    align-items: center;
    flex-direction: row;
    flex-wrap: nowrap;
  }
  .reservation {
    left: 0;
    position: absolute;
    background-color: #4caf50;
    color: white;
    text-align: center;
    padding: 5px;
    border-radius: 5px;
    height: 40px;
  }
  .time-header {
    position: sticky;
    top: 0;
  }
  .time-header,
  .Locations {
    background-color: #989898;
    color: white;
  }
</style>
