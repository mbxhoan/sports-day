const DEFAULT_AUTH_TIMEOUT_MS = 8_000;

export async function withTimeout<T>(operation: () => Promise<T>, timeoutMs = DEFAULT_AUTH_TIMEOUT_MS): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([
      operation(),
      new Promise<T>((_, reject) => {
        timer = setTimeout(() => reject(new Error("Supabase auth timeout")), timeoutMs);
      }),
    ]);
  } finally {
    if (timer) clearTimeout(timer);
  }
}
