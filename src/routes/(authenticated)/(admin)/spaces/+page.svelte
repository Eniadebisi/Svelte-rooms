<script>
  import { enhance } from "$app/forms";
  import { hasPermission } from "$lib/permissions/auth";

  /** @type {import('./$types').PageData} */
  export let data;

  /** @type {import('./$types').ActionData} */
  export let form;

  let editLoc = 1;
  $: filteredRooms = data.rooms.filter((room) => room.locationId == parseInt(editLoc));

  async function updateEditLoc() {
    // filteredRooms = await data.rooms.filter((room) => room.location === parseInt(editLoc));
    // filteredRooms = filteredRooms
  }
</script>

<div class="container text-center w-100">
  <h1>Spaces</h1>

  {#if data.locations && data.rooms}
    <table class="table">
      <thead>
        <th>Rooms</th>
        <th>Locations</th>
      </thead>
      {#each data.locations as location}
        <tr>
          <th>{location.name}</th>
          {#each data.rooms.filter((room) => room.locationId === location.id) as room}
            <div class="d-flex flex-column">
              <td> {room.name} - {room.size} ppl - {room.details} </td>
            </div>
          {/each}
        </tr>
      {/each}
    </table>
  {/if}

  <br m-5 />

  <div class="row">
    {#if hasPermission(data.user, "Room", "update")}
      <div class="col">
        <h2>Edit Room</h2>
        <form class="m-2" method="POST" action="?/editRoom" use:enhance>
          <div>
            <label for="EditRoomLocation">Location:</label>
            <select name="EditRoomLocation" id="EditRoomLocation" on:change={updateEditLoc} bind:value={editLoc}>
              <option disabled> Select one...</option>
              {#each data.locations as loc}
                <option value={loc.id}>{loc.name}</option>
              {/each}
            </select>
          </div>

          {#if filteredRooms}
            <div>
              <label for="roomId">Rooms:</label>
              <select name="roomId" id="roomId">
                <option selected disabled> Select one...</option>
                {#each filteredRooms as room}
                  <option value={room.id}>{room.name}</option>
                {/each}
              </select>
            </div>
          {/if}

          <div>
            <label for="updatedRoomName">Update Room Name:</label>
            <input type="text" id="updatedRoomName" name="updatedRoomName" />
          </div>

          <div>
            <label for="updatedSize">Update Room Size:</label>
            <input type="text" id="updatedSize" name="updatedSize" />
          </div>

          <div>
            <label for="updatedDetails">Update Details:</label>
            <input type="text" id="updatedDetails" name="updatedDetails" />
          </div>

          <div>
            <label for="updatedLocationId">Location:</label>
            <select name="updatedLocationId" id="updatedLocationId">
              <option selected value=""> Select one... </option>
              {#each data.locations as loc}
                <option value={loc.id}>{loc.name}</option>
              {/each}
            </select>
          </div>

          {#if form?.error && form.form == "editRoom"}
            <div class="notice error m-2">
              {form.error}
            </div>
          {/if}
          <button class="m-3" type="submit">Update Room</button>
        </form>
      </div>
    {/if}
    {#if hasPermission(data.user, "Location", "update")}
      <div class="col">
        <h2>Edit Location</h2>
        <form class="m-2" method="POST" action="?/editLocation" use:enhance>
          <div>
            <label for="locId">Location:</label>
            <select name="locId" id="locId">
              <option disabled> Select one...</option>
              {#each data.locations as loc}
                <option value={loc.id}>{loc.name}</option>
              {/each}
            </select>
          </div>
          <div>
            <label for="updatedLocName">Update Loc Name:</label>
            <input type="text" id="updatedLocName" name="updatedLocName" />
          </div>

          {#if form?.error && form.form == "editLocation"}
            <div class="notice error m-2">
              {form.error}
            </div>
          {/if}
          <button class="m-3" type="submit">Edit Location</button>
        </form>
      </div>
    {/if}
  </div>

  <div class="row">
    {#if hasPermission(data.user, "Room", "create")}
      <div class="col">
        <h2>Add New Room</h2>
        <form class="m-2" method="POST" action="?/addRoom" use:enhance>
          <div>
            <label for="locId">Location:</label>
            <select name="locId" id="locId">
              <option selected disabled value=""> Select one...</option>
              {#each data.locations as loc}
                <option value={loc.id}>{loc.name}</option>
              {/each}
            </select>
          </div>
          <div>
            <label for="roomName">Room Name:</label>
            <input id="roomName" name="roomName" required />
          </div>
          <div>
            <label for="size">Room Size:</label>
            <input type="text" id="size" name="size" required />
          </div>

          <div>
            <label for="details">Details:</label>
            <input type="text" id="details" name="details" />
          </div>

          {#if form?.error}
            <div class="notice error m-2">
              {form.error}
            </div>
          {/if}
          <button class="m-3" type="submit">Add Room</button>
        </form>
      </div>
    {/if}
    {#if hasPermission(data.user, "Location", "create")}
      <div class="col">
        <h2>Add New Location</h2>
        <form class="m-2" method="POST" action="?/addLocation" use:enhance>
          <div>
            <label for="locName">Location Name:</label>
            <input type="text" id="locName" name="locName" required />
          </div>
          {#if form?.error && form.form == "addLocation"}
            <div class="notice error m-2">
              {form.error}
            </div>
          {/if}
          <button class="m-3" type="submit">Add Location</button>
        </form>
      </div>
    {/if}
  </div>
</div>

<style>
  .table,
  .table th {
    border: 1px solid black !important;
    /* border-spacing: 0px; */
    /* border-collapse: collapse; */
  }
  .table th {
    background-color: lightgrey;
  }
  .table div td {
    border-top: 1px solid black;
  }
  input,
  select {
    margin: 5px;
  }
</style>
