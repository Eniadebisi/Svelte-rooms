import { getLocations, getReservations, getRooms } from "$lib/server/rooms.model";
import { timeZone } from "$lib/settings";
import dayjs from "dayjs";
import timezone from "dayjs/plugin/timezone";
dayjs.extend(timezone);

export async function load({ parent, url }) {
  const { user } = await parent();
  const sDate = url.searchParams.get("date");
  console.log("Got date " + sDate);

  let start, end, date = new Date()
  // const dateFormat = /\d{2}\/\d{2}\/\d{4}/; // MM/DD/YYYY
  if (sDate != null) {
    date = new Date(sDate)
    
    start = dayjs(date).tz(timeZone).startOf("day").utc();
    end = dayjs(date).tz(timeZone).endOf("day").utc();
  } else {
    start = dayjs(date).tz(timeZone).startOf("day").utc();
    end = dayjs(date).tz(timeZone).endOf("day").utc();
  }
  
  const { rooms, error: roomError } = await getRooms();
  if (roomError || !rooms) throw new Error();

  const { locations, error: locError } = await getLocations();
  if (locError || !locations) throw new Error();

  const { reservations, error: reservError } = await getReservations(start, end);
  if (reservError || !reservations) throw new Error();

  return { user, rooms, locations, reservations, date };
}
