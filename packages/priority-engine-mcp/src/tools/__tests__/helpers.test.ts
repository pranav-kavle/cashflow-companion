import { describe, expect, it } from "vitest";
import { prisma } from "../../db";
import { createTestUser, deleteTestUser } from "./helpers";

describe("test fixtures", () => {
  it("creates and fully deletes a test user", async () => {
    const user = await createTestUser(prisma);
    expect(user.id).toBeDefined();

    const found = await prisma.user.findUnique({ where: { id: user.id } });
    expect(found).not.toBeNull();

    await deleteTestUser(prisma, user.id);

    const goneCheck = await prisma.user.findUnique({ where: { id: user.id } });
    expect(goneCheck).toBeNull();
  });
});
