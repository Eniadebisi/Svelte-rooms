import { prisma } from "./db";
import { timeZone } from "$lib/settings";

import dayjs from "dayjs";
import utc from "dayjs/plugin/utc";
dayjs.extend(utc);
import timezone from "dayjs/plugin/timezone";
dayjs.extend(timezone);

export async function getReservations(start, end) {
  let reservations = await prisma.reservation.findMany({
    where: { startTime: { gte: start, lte: end } },
    include: {
      user: {
        select: {
          name: true,
          role: true,
        },
      },
    },
  });

  // console.log("Got dates between " + dayjs(start).toISOString() + " and " + dayjs(end).toISOString());
  return { reservations, error: false };
}

export async function getRooms() {
  try {
    let rooms = await prisma.room.findMany({});

    return { rooms, error: false };
  } catch (e) {
    return { error: e.message };
  }
}
export async function getLocations() {
  try {
    let locations = await prisma.location.findMany({});

    return { locations, error: false };
  } catch (e) {
    return { error: e.message };
  }
}
export async function newRoom(name, size, locationId, details) {
  try {
    await prisma.room.create({
      data: { name, size, locationId, details },
    });
    console.log("Here");

    return { error: false };
  } catch (e) {
    return { error: e.message };
  }
}
export async function newLocation(name) {
  try {
    await prisma.location.create({
      data: { name },
    });

    return { error: false };
  } catch (e) {
    return { error: e.message };
  }
}
export async function editRoom(roomId, uname, usize, ulocationId, udetails) {
  try {
    await prisma.$transaction([
      prisma.room.update({
        where: { id: roomId },
        data: uname && uname !== "" ? { name: uname.toString() } : {},
      }),
      prisma.room.update({
        where: { id: roomId },
        data: usize > 0 ? { size: usize } : {},
      }),
      prisma.room.update({
        where: { id: roomId },
        data: ulocationId && ulocationId !== "" ? { locationId: ulocationId } : {},
      }),
      prisma.room.update({
        where: { id: roomId },
        data: udetails && udetails !== "" ? { details: udetails } : {},
      }),
    ]);
    return { error: false };
  } catch (e) {
    return { error: e.message };
  }
}
export async function editLocation(locationId, name) {
  try {
    await prisma.location.update({
      where: { id: locationId },
      data: { name },
    });

    return { error: false };
  } catch (e) {
    return { error: e.message };
  }
}

export async function reserveRoom(roomId, userId, startTime, endTime, title, details, RecurrencePattern, RecurrenceEndDate) {
  try {
    if (await checkAvailability(roomId, startTime, endTime)) {
      await prisma.reservation.create({
        data: {
          roomId,
          userId,
          startTime,
          endTime,
          title,
          details,
          RecurrencePattern,
          RecurrenceEndDate,
        },
      });
      // console.log(roomId, userId, startTime, endTime, title, details);

      return { error: false };
    } else {
      return { error: "Room is not available at that time." };
    }
  } catch (e) {
    return { error: e.message };
  }
}

export async function checkAvailability(roomId, start, end) {
  try {
    // console.log("Check availability " + dayjs(start).toISOString() + "-" + dayjs(end).toISOString());

    const overlapping = await prisma.reservation.findFirst({
      where: { roomId, OR: [{ startTime: { lt: end }, endTime: { gt: start } }] },
    });

    if (overlapping) {
      return { error: "Time not available to reservations at that time." };
    }

    return { error: false };
  } catch (e) {
    return { error: e.message };
  }
}

export async function delReservation(id) {
  try {
    const reservation = await prisma.reservation.findUnique({
      where: {
        id,
      },
    });

    if (!reservation) {
      throw new Error(`Reservation with id ${reservationId} does not exist.`);
    }

    await prisma.reservation.delete({
      where: {
        id,
      },
    });

    return { error: false };
  } catch (error) {
    return { success: false, message: `Failed to delete resv${reservationId}` + error };
  }
}
