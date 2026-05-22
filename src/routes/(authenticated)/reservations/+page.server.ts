import { getLocations, getReservations, getRooms } from "$lib/server/rooms.model";
import dayjs from "dayjs";
import config from "$lib/server/config.json"
import timezone from "dayjs/plugin/timezone";
dayjs.extend(timezone);

export async function load({ parent, url }) {
  const { user } = await parent();
  const sDate = url.searchParams.get("date");

  const PUBLIC_TIME_ZONE = config.timeZone;
  let start,
    end,
    date = new Date();
  if (sDate != null) {
    date = new Date(sDate);

    start = dayjs(date).tz(PUBLIC_TIME_ZONE).startOf("day").utc();
    end = dayjs(date).tz(PUBLIC_TIME_ZONE).endOf("day").utc();
  } else {
    start = dayjs(date).tz(PUBLIC_TIME_ZONE).startOf("day").utc();
    end = dayjs(date).tz(PUBLIC_TIME_ZONE).endOf("day").utc();
  }

  let { rooms, error: roomError } = await getRooms();
  if (roomError || !rooms) throw new Error();
  rooms = rooms.sort((a, b) => a.name.localeCompare(b.name));

  const { locations, error: locError } = await getLocations();
  if (locError || !locations) throw new Error();

  const { reservations, error: reservError } = await getReservations(start, end);
  if (reservError || !reservations) throw new Error();

  return { user, rooms, locations, reservations, date, PUBLIC_TIME_ZONE };
}
