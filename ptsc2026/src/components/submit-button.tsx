"use client";

import type { ButtonHTMLAttributes } from "react";
import { LoaderCircle } from "lucide-react";
import { useFormStatus } from "react-dom";

export function SubmitButton({ className = "", children, disabled, type, ...props }: ButtonHTMLAttributes<HTMLButtonElement>) {
  const { pending } = useFormStatus();
  return <button {...props} type={type ?? "submit"} className={`${className}${pending ? " is-pending" : ""}`} disabled={pending || disabled} aria-busy={pending}>
    {pending && <LoaderCircle className="button-spinner" size={15} aria-hidden="true" />}
    {children}
  </button>;
}
