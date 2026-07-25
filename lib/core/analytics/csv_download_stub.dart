/// Non-web fallback — there's no browser download mechanism to hand this
/// to, so callers should fall back to something else (e.g. copy to
/// clipboard) when this returns `false`.
bool downloadCsv(String filename, String content) => false;
