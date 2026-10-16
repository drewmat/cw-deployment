async function load() {
  const out = document.getElementById("out");
  try {
    const res = await fetch(window.APP_CONFIG.API_URL + "/");
    out.textContent = JSON.stringify(await res.json(), null, 2);
  } catch (e) {
    out.textContent = "Request failed: " + e;
  }
}
document.getElementById("refresh").addEventListener("click", load);
load();
