// Cloudflare Worker backend URL.
// Update this with your deployed Worker URL before going to production.
const WORKER_BASE_URL = "https://avenirdz-api.yasserabh13.workers.dev";

// These keys are no longer used directly from the browser.
// They are kept here only as a reference — actual keys live in Worker secrets.
const GOOGLE_BOOKS_API_URL = "https://www.googleapis.com/books/v1/volumes";
const GOOGLE_BOOKS_API_KEY = "";
const YOUTUBE_API_URL = "https://www.googleapis.com/youtube/v3/search";
const YOUTUBE_API_KEY = "";

export {
  WORKER_BASE_URL,
  GOOGLE_BOOKS_API_URL,
  GOOGLE_BOOKS_API_KEY,
  YOUTUBE_API_URL,
  YOUTUBE_API_KEY,
};
