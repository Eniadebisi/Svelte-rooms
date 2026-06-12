import { prisma } from "./db";

import dayjs from "dayjs";
import utc from "dayjs/plugin/utc";
dayjs.extend(utc);
import timezone from "dayjs/plugin/timezone";
dayjs.extend(timezone);

export async function getReservations(start, end) {
  let reservations = await prisma.reservation.findMany({
    where: {
      OR: [
        { startTime: { lt: end }, endTime: { gt: start } },
        { startTime: { lt: start }, RecurrencePattern: dayjs(start).format("dddd"), RecurrenceEndDate: { gte: start } },
        { startTime: { lt: start }, RecurrencePattern: "Daily", RecurrenceEndDate: { gte: start } },
      ],
    },
    include: {
      user: {
        select: {
          name: true,
          role: true,
        },
      },
      Room: true,
    },
  });

  // console.log("Got dates between " + dayjs(start).toISOString() + " and " + dayjs(end).toISOString());
  return { reservations, error: false };
}

export async function getRooms(level = 0) {
  try {
    let rooms = await prisma.room.findMany({
      where: { location: { visibility: level == 1 ? { gte: 0 } : { equals: 0 } } },
      include: { location: true },
    });

    return { rooms, error: false };
  } catch (e) {
    return { error: e.message };
  }
}
export async function getLocations(level = 0) {
  try {
    let locations = await prisma.location.findMany({
      where: { visibility: level == 1 ? { gte: 0 } : { equals: 0 } },
    });

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
export async function deleteRoom(roomId) {
  try {
    await prisma.room.delete({
      where: { id: roomId },
    });
    return { error: false };
  } catch (e) {
    return { error: e.message };
  }
}
export async function editLocation(locationId, name, visibility) {
  try {
    await prisma.$transaction([
      prisma.location.update({
        where: { id: locationId },
        data: name & (name !== "") ? { name } : {},
      }),
      prisma.location.update({
        where: { id: locationId },
        data: visibility && visibility !== "" ? { visibility } : {},
      }),
    ]);

    return { error: false };
  } catch (e) {
    return { error: e.message };
  }
}

export async function reserveRoom(roomId, userId, startTime, endTime, title, details, RecurrencePattern, RecurrenceEndDate) {
  try {
    const availability = await checkAvailability(roomId, startTime, endTime);
    if (availability.error === false) {
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
    const overlapping = await prisma.reservation.findMany({
      where: {
        roomId,
        OR: [
          { startTime: { lt: end }, endTime: { gt: start } },
          { startTime: { lt: start }, RecurrencePattern: dayjs(start).format("dddd"), RecurrenceEndDate: { gte: start } },
          { startTime: { lt: start }, RecurrencePattern: "Daily", RecurrenceEndDate: { gte: start } },
        ],
      },
    });

    const startHHMM = dayjs(start).hour() + dayjs(start).minute() / 60;
    const endHHMM = dayjs(end).hour() + 24*(dayjs(end).hour() == 0 ? 1 : 0) + dayjs(end).minute() / 60;

    for (const resv of overlapping) {
      const resvStartHHMM = dayjs(resv.startTime).hour() + dayjs(resv.startTime).minute() / 60;
      const resvEndHHMM = dayjs(resv.endTime).hour() + dayjs(resv.endTime).minute() / 60;

      if (resvStartHHMM < endHHMM && resvEndHHMM > startHHMM) {
        return { error: "Time not available to reservations at that time." };
      }
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
      throw new Error(`Reservation with id ${id} does not exist.`);
    }

    await prisma.reservation.delete({
      where: {
        id,
      },
    });

    return { error: false };
  } catch (error) {
    return { success: false, message: `Failed to delete resv${id}` + error };
  }
}
