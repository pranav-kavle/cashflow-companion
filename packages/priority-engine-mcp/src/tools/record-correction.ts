import { z } from "zod";
import type { PrismaClient } from "../db";

const classificationLabels = [
  "income",
  "transfer",
  "refund",
  "repayment",
  "loan",
  "other",
  "fixed_recurring",
  "variable_discretionary",
] as const;

const classificationCadences = ["retainer", "project", "windfall"] as const;

export const recordCorrectionInputShape = {
  classificationId: z.string().uuid(),
  label: z.enum(classificationLabels),
  cadence: z.enum(classificationCadences).optional(),
  checkInId: z.string().uuid().optional(),
};

export interface RecordCorrectionInput {
  classificationId: string;
  label: (typeof classificationLabels)[number];
  cadence?: (typeof classificationCadences)[number];
  checkInId?: string;
}

export async function recordCorrection(
  prisma: PrismaClient,
  input: RecordCorrectionInput,
): Promise<{ classificationId: string }> {
  return prisma.$transaction(async (tx) => {
    const prior = await tx.transactionClassification.findUniqueOrThrow({
      where: { id: input.classificationId },
    });

    await tx.transactionClassification.update({
      where: { id: prior.id },
      data: { isCurrent: false },
    });

    const created = await tx.transactionClassification.create({
      data: {
        transactionId: prior.transactionId,
        source: "user",
        label: input.label,
        cadence: input.cadence,
        reviewState: "corrected",
        supersedesId: prior.id,
        isCurrent: true,
      },
    });

    if (input.checkInId) {
      await tx.checkIn.update({
        where: { id: input.checkInId },
        data: { resultingClassificationId: created.id },
      });
    }

    return { classificationId: created.id };
  });
}
