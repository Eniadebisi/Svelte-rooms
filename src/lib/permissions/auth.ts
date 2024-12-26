import type {Roles, Reservation, Room, Location } from "@prisma/client";

type User = {
  id: number;
  email: string;
  name: string;
  role: Roles;
}

type PermissionCheck<Key extends keyof UserPermissions> = boolean | ((user: User, data: UserPermissions[Key]["dataType"]) => boolean);

type RolesWithPermissions = {
  [R in Roles]: Partial<{
    [Key in keyof UserPermissions]: Partial<{
      [Action in UserPermissions[Key]["action"]]: PermissionCheck<Key>;
    }>;
  }>;
};

type UserPermissions = {
  UserManagement: {
    dataType: User;
    action: "update" | "delete";
  };
  Reservation: {
    dataType: Reservation;
    action: "create" | "delete" | "update" | "view";
  };
  Room: {
    dataType: Room;
    action: "create" | "delete" | "update" | "view";
  };
  Location: {
    dataType: Location;
    action: "create" | "delete" | "update" | "view";
  };
};

export const ROLES = {
  Owner: {
    UserManagement: {
      update: true,
      delete: true,
    },
    Reservation: {
      create: true,
      view: true,
      update: true,
      delete: true,
    },
    Room: {
      create: true,
      view: true,
      update: true,
      delete: true,
    },
    Location: {
      create: true,
      view: true,
      update: true,
      delete: true,
    },
  },
  Admin: {
    UserManagement: {
      update: true,
      delete: false,
    },
    Reservation: {
      create: true,
      view: true,
      update: true,
      delete: true,
    },
    Room: {
      create: true,
      view: true,
      update: true,
      delete: true,
    },
    Location: {
      create: false,
      view: true,
      update: true,
      delete: true,
    },
  },
  User: {
    UserManagement: {
      update: (user: User, otherUserObject: User) => (user.id == otherUserObject.id),
      delete: false,
    },
    Reservation: {
      create: true,
      view: true,
      update: (user: User, reservation: Reservation) => (user.id == reservation.userId),
      delete: (user: User, reservation: Reservation) => (user.id == reservation.userId),
    },
    Room: {
      create: false,
      view: true,
      update: false,
      delete: false,
    },
    Location: {
      create: false,
      view: true,
      update: false,
      delete: false,
    },
  },
  Guest: {
    Reservation: {
      create: false,
      view: true,
      update: false,
      delete: false,
    },
    Room: {
      create: false,
      view: false,
      update: false,
      delete: false,
    },
    Location: {
      create: false,
      view: false,
      update: false,
      delete: false,
    },
  },
};

export function hasPermission<Resource extends keyof UserPermissions>(user: User, resource: Resource, action: UserPermissions[Resource]["action"], data?: UserPermissions[Resource]["dataType"]) {
  const permission = (ROLES as RolesWithPermissions)[user.role][resource]?.[action];

  if (permission == null) return false;
  if (typeof permission === "boolean") return permission;

  if (typeof permission === "function") {
    return data != null && permission(user, data);
  }

  return false;
}



