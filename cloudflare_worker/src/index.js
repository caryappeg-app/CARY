// CARY share links — Cloudflare Worker (مجاني). من غير ملفات static.
// غيّر القيم دي بس:
const ANDROID_PACKAGE = "com.example.cary_app"; // applicationId الحقيقي
const SHA256_FINGERPRINTS = [
  "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99",
];
const PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=" + ANDROID_PACKAGE;
const IOS_APP_ID = "TEAMID.com.example.caryApp"; // اختياري (iPhone)

const html = (body, status = 200) =>
  new Response(body, {
    status,
    headers: { "content-type": "text/html; charset=utf-8", "cache-control": "public, max-age=300" },
  });
const json = (obj) =>
  new Response(JSON.stringify(obj), {
    headers: { "content-type": "application/json", "access-control-allow-origin": "*" },
  });

const STYLE = `body{font-family:system-ui,sans-serif;display:grid;place-items:center;min-height:100vh;margin:0;background:#f5f7fb;color:#12213f}
.c{text-align:center;padding:24px;max-width:380px}h1{font-size:44px;margin:0 0 8px;color:#0047cc}
a.b{display:block;margin:12px 0;padding:14px;border-radius:12px;background:#0047cc;color:#fff;text-decoration:none;font-weight:700}
a.s{background:#fff;color:#0047cc;border:1px solid #0047cc}`;

const HOME = `<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>CARY</title>
<style>${STYLE}</style></head><body><div class="c"><h1>CARY</h1>
<p>سوق السيارات — بيع واشتري عربيتك بسهولة</p></div></body></html>`;

const CAR = `<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>سيارة على CARY</title>
<meta property="og:title" content="شوف العربية دي على CARY">
<meta property="og:description" content="افتح الإعلان في تطبيق CARY">
<style>${STYLE}</style></head><body><div class="c"><h1>CARY</h1>
<p>لو التطبيق متسطّب عندك هيتفتح الإعلان تلقائياً.</p>
<a class="b" id="open" href="#">افتح في التطبيق</a>
<a class="b s" href="${PLAY_STORE_URL}">حمّل التطبيق</a></div>
<script>
var id=decodeURIComponent(location.pathname.split('/').filter(Boolean)[1]||'');
var link='cary://car/'+encodeURIComponent(id);
document.getElementById('open').href=link;
if(id&&/Android|iPhone|iPad/i.test(navigator.userAgent)){setTimeout(function(){location.href=link},400)}
</script></body></html>`;

export default {
  async fetch(request) {
    const { pathname } = new URL(request.url);
    if (pathname === "/.well-known/assetlinks.json") {
      return json([
        {
          relation: ["delegate_permission/common.handle_all_urls"],
          target: {
            namespace: "android_app",
            package_name: ANDROID_PACKAGE,
            sha256_cert_fingerprints: SHA256_FINGERPRINTS,
          },
        },
      ]);
    }
    if (pathname === "/.well-known/apple-app-site-association") {
      return json({ applinks: { apps: [], details: [{ appID: IOS_APP_ID, paths: ["/car/*"] }] } });
    }
    if (pathname.startsWith("/car/")) return html(CAR);
    if (pathname === "/" || pathname === "") return html(HOME);
    return html(HOME, 404);
  },
};
