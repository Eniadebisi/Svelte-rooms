import { JWT_ACCESS_SECRET } from "$env/static/private";
import { PUBLIC_CONTACT_EMAIL } from "$lib/server/settings";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { prisma } from "./db";

export async function signUp(email, name, password) {
  // Check if user exists by email
  try {
    const emailCheck = await prisma.user.findUnique({
      where: { email },
    });

    if (emailCheck) return { error: "User already exists with that email" };

    const user = await prisma.user.create({
      data: {
        email,
        name,
        password: await bcrypt.hash(password, 10),
      },
    });

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

  // Check if user role is exist
  if (user.role == "Restricted") return { error: "User restricted, please request access from admin. Contact email:" + PUBLIC_CONTACT_EMAIL };

  const jwtUser = {
    id: user.id,
    email: user.email,
    role: user.role,
  };

  // Generate token
  return { token: jwt.sign(jwtUser, JWT_ACCESS_SECRET, { expiresIn: "1d" }) };
}

export async function getUsers() {
  const users = await prisma.user.findMany();
  return users;
}

export async function setUserRole(id, role) {
  try {

    const user = await prisma.user.update({
      where: {
        id,
      },
      data: {
        role,
      },
    });
    return {error: false};
  } catch (e) {
    return {error: e.message}
  }
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
