import { checkAvailability, reserveRoom } from "$lib/server/rooms.model";
import { timeZone } from "$lib/settings";
import { json } from "@sveltejs/kit";
import dayjs from "dayjs";

export async function POST({ request }) {
  const { roomId, userId, startTime: start, endTime: end, eventTitle, eventDetails, RecurrencePattern } = await request.json();

  if (!roomId || parseInt(roomId) < 0 || !userId || !start || !end || !eventTitle || !eventDetails) {
    return json({ error: "Missing one or more details" }, { status: 400 });
  }

  if (end < start) {
    return json({ error: "End time must be after start time." }, { status: 400 });
  }

  const { error: availabilityError } = await checkAvailability(roomId, start, end);

  if (availabilityError) {
    return json({ error: availabilityError }, { status: 400 });
  }
  // return json({ error: "Passed" }, { status: 400 });


  const { error } = await reserveRoom(roomId, userId, start, end, eventTitle, eventDetails, RecurrencePattern);
  if (error) {
    return json({ error }, { status: 400 });
  }

  return json({ error: false }, { status: 201 });
}
