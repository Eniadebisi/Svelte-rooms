import { editLocation, editRoom, getLocations, getRooms, newLocation, newRoom } from "$lib/server/rooms.model";
import { fail } from "@sveltejs/kit";
import type { PageServerLoad } from "./$types";
import type { Actions } from "./$types";
import { error, redirect } from "@sveltejs/kit";
import { hasPermission } from "$lib/permissions/auth";

export const load = (async ({locals}) => {
  const user = locals.user;

  if (!user) throw error(400, { message: "Restricted" });

  const { rooms } = await getRooms();
  if (!rooms) throw new Error();

  const { locations } = await getLocations();
  if (!locations) throw new Error();

  return { rooms, locations };
}) satisfies PageServerLoad;

export const actions: Actions = {
  addRoom: async ({ cookies, request }) => {
    const data = Object.fromEntries(await request.formData());
    const roomName = data.roomName;
    const size = data.size;
    const locId = data.locId;
    const details = data.details;
    if (!roomName || !size || !locId || !details) {
      return fail(401, {
        error: "Missing one or more details",
        form: "addRoom",
      });
    }
    const { error } = await newRoom(roomName, parseInt(size.toString()), parseInt(locId.toString()), details);

    if (error) {
      return fail(401, {
        error,
        form: "addRoom",
      });
    }
  },
  addLocation: async ({ cookies, request }) => {
    const data = Object.fromEntries(await request.formData());
    const locName = data.locName;
    if (!locName) {
      return fail(401, {
        error: "Missing name",
        form: "addLocation",
      });
    }
    const { error } = await newLocation(locName.toString());

    if (error) {
      return fail(401, {
        error,
        form: "addLocation",
      });
    }
  },

  editRoom: async ({ cookies, request }) => {
    const data = Object.fromEntries(await request.formData());
    const roomId = data.roomId ? parseInt(data.roomId.toString()) : false;
    const updatedRoomName = data.updatedRoomName ? data.updatedRoomName.toString() : false;
    const updatedSize = data.updatedSize ? parseInt(data.updatedSize.toString()) : false;
    const updatedLocationId = data.updatedLocationId ? parseInt(data.updatedLocationId.toString()) : false;
    const updatedDetails = data.updatedDetails ? data.updatedDetails.toString() : false;

    if (!roomId) {
      return fail(401, {
        error: "Please select a room",
        form: "editRoom",
      });
    }
    if (!updatedRoomName && !updatedSize && !updatedDetails && !updatedLocationId) {
      return fail(401, {
        error: "Need at least one field",
        form: "editRoom",
      });
    }

    const { error } = await editRoom(parseInt(roomId.toString()), updatedRoomName, updatedSize, updatedLocationId, updatedDetails);

    if (error) {
      return fail(401, {
        error,
        form: "editRoom",
      });
    }
  },
  editLocation: async ({ cookies, request }) => {
    const data = Object.fromEntries(await request.formData());
    const updatedLocName = data.updatedLocName;
    const locId = data.locId;
    if (!updatedLocName || !locId) {
      return fail(401, {
        error: "Missing name or ID",
        form: "editLocation",
      });
    }
    const { error } = await editLocation(parseInt(locId.toString()), updatedLocName.toString());

    if (error) {
      return fail(401, {
        error,
        form: "editLocation",
      });
    }
  },
};
