{{flutter_js}}
{{flutter_build_config}}

// Elemen container utama (background putih)
const loading = document.createElement('div');
loading.id = 'loading';
loading.style.position = 'fixed';
loading.style.top = '0';
loading.style.left = '0';
loading.style.width = '100vw';
loading.style.height = '100vh';
loading.style.display = 'flex';
loading.style.justifyContent = 'center';
loading.style.alignItems = 'center';
loading.style.backgroundColor = '#FFFFFF';
loading.style.zIndex = '9999';

// Elemen gambar (menggunakan ikon besar dari hasil generate flutter_launcher_icons)
const img = document.createElement('img');
img.src = 'icons/Icon-512.png';
img.style.maxWidth = '300px'; 
img.style.width = '60%'; // Agar responsif di HP
img.style.animation = 'pulse 1.5s infinite';

// Masukkan gambar ke container, lalu ke body
loading.appendChild(img);
document.body.appendChild(loading);

// Tambahkan CSS untuk animasi 'berdenyut'
const style = document.createElement('style');
style.innerHTML = `
@keyframes pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.05); }
  100% { transform: scale(1); }
}`;
document.head.appendChild(style);

// Proses inisiasi engine Flutter
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    // Hapus loading screen setelah Flutter siap
    if (document.body.contains(loading)) {
      document.body.removeChild(loading);
    }
    await appRunner.runApp();
  }
});
