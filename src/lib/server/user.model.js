import { JWT_ACCESS_SECRET } from "$env/static/private";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { prisma } from "./db";

export async function signUp(email, name, password, role) {
  // Check if user exists by email
  try {
    const emailCheck = await prisma.user.findUnique({
      where: { email },
    });

    if (emailCheck) return { error: "User already exists with that email" };

    if (role) {
      const user = await prisma.user.create({
        data: {
          email,
          name,
          password: await bcrypt.hash(password, 10),
          roleTemp,
        },
      });
    } else {
      const user = await prisma.user.create({
        data: {
          email,
          name,
          password: await bcrypt.hash(password, 10),
        },
      });
    }
    return { user };
  } catch (e) {
    return { error: e.message };
  }
}

export async function checkSignIn(email, password) {
  // Check if user exists
  const user = await prisma.user.findUnique({
    where: {
      email,
    },
  });

  if (!user) return { error: "User not found" };

  // Verify the password
  const passwordIsValid = await bcrypt.compare(password, user.password);

  if (!passwordIsValid) return { error: "Incorrect password" };

  // Check if user roleTemp is exist
  if (user.role == "Restricted") return { error: "User restricted" };

  const jwtUser = {
    id: user.id,
    email: user.email,
    roleTemp: user.roleTemp,
  };

  // Generate token
  return { token: jwt.sign(jwtUser, JWT_ACCESS_SECRET, { expiresIn: "1d" }) };
}

export async function getUsers() {
  const users = await prisma.user.findMany();
  return users;
}

export async function setUserRole(id, roleTemp) {
  const user = await prisma.user.update({
    where: {
      id,
    },
    data: {
      roleTemp: roleTemp,
    },
  });
  return "Success";
}

export async function updatePassword(id, password) {
  // Check if user exists by email
  try {
    const user = await prisma.user.update({
      where: { id },
      data: {
        password: await bcrypt.hash(password, 10),
        generatedPW: false,
      },
    });
    return { error: false };
  } catch (e) {
    return { error: e.message };
  }
}

export async function resetPW(id, password, deadline) {
  // Check if user exists by email
  try {
    const user = await prisma.user.update({
      where: { id },
      data: {
        generatedPW: true,
        resetPWExpires: deadline,
        password: await bcrypt.hash(password, 10),
      },
    });
    return { error: false };
  } catch (e) {
    return { error: e.message };
  }
}
