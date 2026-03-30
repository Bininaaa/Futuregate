import { WORKER_BASE_URL } from "./google-books-config.js";

async function searchBooksViaWorker({
  query,
  maxResults = 12,
  langRestrict = "",
  authToken,
}) {
  const trimmedQuery = (query || "").trim();
  if (!trimmedQuery) {
    return [];
  }

  const response = await fetch(`${WORKER_BASE_URL}/api/search/google-books`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${authToken}`,
    },
    body: JSON.stringify({
      query: trimmedQuery,
      maxResults,
      langRestrict,
    }),
  });

  const data = await response.json().catch(() => ({}));

  if (!response.ok) {
    const requestError = new Error(
      data.error || `Google Books search failed: ${response.status}`,
    );
    requestError.status = response.status;
    throw requestError;
  }

  return data.items || [];
}

export { searchBooksViaWorker };
