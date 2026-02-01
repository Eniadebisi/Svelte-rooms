import { deleteRoom } from "$lib/server/rooms.model.js";
import { json } from "@sveltejs/kit";

export async function POST({ request }) {
  const { roomId } = await request.json();

  const { error } = await deleteRoom(roomId);
  if (error) {
    return json({ error }, { status: 400 });
  }

  return json({ error: false }, { status: 201 });
}
