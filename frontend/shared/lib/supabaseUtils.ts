/**
 * Generic utility to bypass Supabase's 1000-row limit via auto-pagination.
 * @param fetchPage A callback that takes (offset, limit) and returns the Supabase query promise
 * @returns All aggregated rows
 */
export async function fetchAllPages<T>(
  fetchPage: (offset: number, limit: number) => Promise<{ data: T[] | null; error: unknown }>
): Promise<T[]> {
  const PAGE_SIZE = 1000;
  const allRows: T[] = [];
  let offset = 0;
  let hasMore = true;

  while (hasMore) {
    const { data, error } = await fetchPage(offset, PAGE_SIZE);
    
    // Throwing here so the caller can catch it and pass to handleSupabaseError
    if (error) throw error;
    
    const rows = data ?? [];
    allRows.push(...rows);
    
    if (rows.length < PAGE_SIZE) {
      hasMore = false;
    } else {
      offset += PAGE_SIZE;
    }
  }

  return allRows;
}
