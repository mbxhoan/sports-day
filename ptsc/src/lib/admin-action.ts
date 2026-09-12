export type AdminActionState = {
  ok: boolean;
  message: string;
  code?: "VALIDATION" | "DEPENDENT_RESULTS";
};

export const initialAdminActionState: AdminActionState = { ok: true, message: "" };
