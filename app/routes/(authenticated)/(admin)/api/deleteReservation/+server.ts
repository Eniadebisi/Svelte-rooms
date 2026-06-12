import { delReservation } from "$lib/server/rooms.model.js";
import { json } from "@sveltejs/kit";

export async function POST({ request }) {
  const { reservationId } = await request.json();

  const { error } = await delReservation(reservationId);
  if (error) {
    return json({ error }, { status: 400 });
  }

  return json({ error: false }, { status: 201 });
}
