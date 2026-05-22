import { getReservations } from "$lib/server/rooms.model";
import config from "$lib/server/config.json"
import { json } from "@sveltejs/kit";
import dayjs from "dayjs";

export async function POST({ request }) {
  const { nDate } = await request.json();

  if (!nDate) {
    return json({ error: true }, { status: 400 });
  }

  let start = dayjs(new Date(nDate)).tz(config.timeZone).startOf("day").utc();
  let end = dayjs(new Date(nDate)).tz(config.timeZone).endOf("day").utc();
  const { reservations, error: reservError } = await getReservations(start, end);
  if (reservError || !reservations) throw new Error();

  return json({ reservations }, { status: 201 });
}
