export const isBrowser = !(window as Window & { invokeNative?: unknown }).invokeNative

export async function fetchNui<T>(event: string, data: unknown = {}): Promise<T | null> {
  if (isBrowser) return null
  const resource = (window as Window & { GetParentResourceName?: () => string }).GetParentResourceName?.() ?? 'mz_lib'
  const response = await fetch(`https://${resource}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  })
  return response.json()
}

export function resolveNui(requestId: string | undefined, result: unknown) {
  if (requestId) void fetchNui('resolve', { requestId, result })
}
