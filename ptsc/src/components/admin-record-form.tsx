"use client";

import { useActionState, type ReactNode } from "react";
import { initialAdminActionState, type AdminActionState } from "@/lib/admin-action";

type RecordAction = (previousState: AdminActionState, formData: FormData) => Promise<AdminActionState>;

export function AdminRecordForm({ action, children, className }: { action: RecordAction; children: ReactNode; className?: string }) {
  const [state, formAction] = useActionState(action, initialAdminActionState);
  return <form action={formAction} className={className}>{children}{state.message && <p className={state.ok ? "form-success" : "form-error"} role={state.ok ? "status" : "alert"}>{state.message}</p>}</form>;
}
