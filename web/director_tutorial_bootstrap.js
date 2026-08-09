(function () {
  "use strict";

  const IDENTITY_KEY = "cineconnect.session_identity";
  const AUTH_RESPONSE_PATTERN = /\/(?:api\/v1\/)?auth\/(?:login|refresh|register)(?:[/?#]|$)/;
  const LOGOUT_PATTERN = /\/(?:api\/v1\/)?auth\/logout(?:[/?#]|$)/;

  function requestUrl(value) {
    if (typeof value === "string") return value;
    if (value && typeof value.url === "string") return value.url;
    return "";
  }

  function storeIdentity(payload) {
    try {
      const user = payload && payload.data && payload.data.user;
      if (!user || !user.public_id || !Array.isArray(user.roles)) return;
      const roles = user.roles
        .filter((role) => role && role.status !== "disabled")
        .map((role) => String(role.code || ""))
        .filter(Boolean);
      const primary = user.roles.find((role) => role && role.is_primary);
      window.sessionStorage.setItem(
        IDENTITY_KEY,
        JSON.stringify({
          public_id: String(user.public_id),
          roles,
          active_role: primary ? String(primary.code || "") : "",
        })
      );
      document.dispatchEvent(new Event("cineconnect-session-identity"));
    } catch (_error) {
      // Authentication continues normally if browser storage is unavailable.
    }
  }

  function clearIdentity() {
    try {
      window.sessionStorage.removeItem(IDENTITY_KEY);
      document.dispatchEvent(new Event("cineconnect-session-identity"));
    } catch (_error) {
      // Nothing else is required on logout.
    }
  }

  const originalFetch = window.fetch;
  if (typeof originalFetch === "function") {
    window.fetch = async function () {
      const response = await originalFetch.apply(this, arguments);
      const url = requestUrl(arguments[0]);
      if (AUTH_RESPONSE_PATTERN.test(url)) {
        response
          .clone()
          .json()
          .then(storeIdentity)
          .catch(function () {});
      } else if (LOGOUT_PATTERN.test(url) && response.ok) {
        clearIdentity();
      }
      return response;
    };
  }

  const originalOpen = XMLHttpRequest.prototype.open;
  const originalSend = XMLHttpRequest.prototype.send;

  XMLHttpRequest.prototype.open = function (method, url) {
    this.__cineconnectGuideUrl = requestUrl(url);
    return originalOpen.apply(this, arguments);
  };

  XMLHttpRequest.prototype.send = function () {
    const xhr = this;
    const url = xhr.__cineconnectGuideUrl || "";
    if (AUTH_RESPONSE_PATTERN.test(url) || LOGOUT_PATTERN.test(url)) {
      xhr.addEventListener(
        "load",
        function () {
          if (xhr.status < 200 || xhr.status >= 300) return;
          if (LOGOUT_PATTERN.test(url)) {
            clearIdentity();
            return;
          }
          try {
            storeIdentity(JSON.parse(xhr.responseText || "null"));
          } catch (_error) {
            // Ignore non-JSON responses and leave authentication untouched.
          }
        },
        { once: true }
      );
    }
    return originalSend.apply(this, arguments);
  };
})();
