"use client";

import { useActionState, type ReactNode } from "react";
import { initialAdminActionState, type AdminActionState } from "@/lib/admin-action";

type RecordAction = (previousState: AdminActionState, formData: FormData) => Promise<AdminActionState>;

export function AdminRecordForm({ action, children }: { action: RecordAction; children: ReactNode }) {
  const [state, formAction] = useActionState(action, initialAdminActionState);
  return <form action={formAction}>{children}{state.message && <p className={state.ok ? "form-success" : "form-error"} role={state.ok ? "status" : "alert"}>{state.message}</p>}</form>;
}
