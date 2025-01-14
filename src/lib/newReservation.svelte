<script lang="ts">
  import { closeModal, closeAllModals, openModal, modals } from "svelte-modals";
  import { fade, scale } from "svelte/transition";
  import dayjs from "dayjs";
  import utc from "dayjs/plugin/utc";
  dayjs.extend(utc);
  import timezone from "dayjs/plugin/timezone";
  dayjs.extend(timezone);
  import * as rrule from "rrule";
  import { timeZone } from "./settings";

  export let isOpen, rooms, user: any, refresh: Function;
  let date = dayjs(new Date()).format("YYYY-MM-DD");
  let roomId: number,
    recurEndDate: Date,
    sTime = 600,
    eTime = 700,
    eventTitle = "",
    recur = "",
    eventDetails = "Features";
  let formError = false;

  async function submitReservation() {
    let RecurrenceEndDate;
    const startTime = dayjs(date)
      .tz(timeZone)
      .hour(sTime / 100)
      .minute(sTime % 100)
      .toISOString();
    const endTime = dayjs(date)
      .tz(timeZone)
      .hour(eTime / 100)
      .minute(eTime % 100)
      .toISOString();
    let RecurrencePattern;
    switch (recur) {
      case "":
        break;
      case "Daily":
        RecurrencePattern = new rrule.RRule({ freq: rrule.RRule.DAILY, interval: 1, dtstart: dayjs(date).toDate() });
        RecurrenceEndDate = recurEndDate;
        RecurrencePattern = RecurrencePattern.toString();
        break;
      case "Weekly":
        RecurrencePattern = new rrule.RRule({ freq: rrule.RRule.DAILY, interval: 1, dtstart: dayjs(date).toDate(), until: recurEndDate });
        RecurrenceEndDate = recurEndDate;
        RecurrencePattern = RecurrencePattern.toString();
        break;
    }

    const response = await fetch("/api/newReservation", {
      method: "POST",
      body: JSON.stringify({ roomId, userId: user.id, startTime, endTime, eventTitle, eventDetails, RecurrencePattern, RecurrenceEndDate }),
    });
    const { error } = await response.json();

    if (error) {
      formError = error;
    } else {
      refresh();
    }
  }
</script>

{#if isOpen}
  <div role="dialog" class="modal">
    <div class="contents text-center">
      <h1>Create new booking</h1>
      <p><i>Reservation recurrence is in beta and will not be active yet.</i></p>
      <div class="m-2">
        <label for="roomId">Room</label>
        <select name="roomId" id="roomId" bind:value={roomId}>
          <option disabled value="-1" selected>Select a room..</option>
          {#if rooms}
            {#each rooms as room}
              <option value={room.id}>{room.name} ({room.size})</option>
            {/each}
          {:else}
            Failed to load
          {/if}
        </select>
      </div>

      <div class="m-1">
        <div class="m-1">
          <label for="startDate">Date</label>
          <input type="date" name="startDate" id="startDate" bind:value={date} />
        </div>

        <div class="m-1">
          <select name="startTime" id="startTime" bind:value={sTime}>
            {#each Array(37) as _, i}
              <option value={(Math.floor(i / 2) + 6) * 100 + (i % 2) * 30}>{(Math.floor(i / 2) + 6) * 100 + (i % 2) * 30}</option>
            {/each}
          </select>
          ➡️
          <select name="startTime" id="startTime" bind:value={eTime}>
            {#each Array(37) as _, i}
              <option value={(Math.floor(i / 2) + 6) * 100 + (i % 2) * 30}>{(Math.floor(i / 2) + 6) * 100 + (i % 2) * 30}</option>
            {/each}
          </select>
        </div>

        <div class="m-1">
          <label for="recur">Recur:</label>
          <select name="recur" id="recur" bind:value={recur}>
            <option value="" selected>Does not repeat</option>
            <option value="Daily">Daily</option>
            <option value="Weekly">Weekly on {dayjs(date).format("dddd")}</option>
          </select>
        </div>

        {#if recur}
          <div class="m-1">
            <label for="recurEndDate">End Date:</label>
            <input type="date" name="recurEndDate" id="recurEndDate" bind:value={recurEndDate} />
          </div>
        {/if}
      </div>

      <div class="m-2">
        <label for="eventTitle">Event Title</label>
        <input type="text" name="eventTitle" id="eventTitle" bind:value={eventTitle} maxlength="50" />
      </div>

      <div class="m-2">
        <label for="eventDetails" class="align-top">Event Details</label>
        <textarea name="eventDetails" id="eventDetails" maxlength="200" bind:value={eventDetails} />
      </div>

      <br />
      {#if formError}
        <div class="notice error m-2">
          {formError}
        </div>
      {/if}
      <div>
        <button class="" on:click={submitReservation}>Submit</button>
        <button type="button" on:click={closeModal} class=""> Close </button>
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
