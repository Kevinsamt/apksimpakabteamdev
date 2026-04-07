import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { query } = await req.json()
    const userQuery = query.toLowerCase()

    // 1. Logika Keramahan (Greeting)
    const greetings = ["halo", "hai", "halo ai", "halo asisten", "pagi", "siang", "sore", "malam", "terima kasih", "thanks", "tanya dong"];
    
    // Jika hanya menyapa
    if (greetings.includes(userQuery)) {
        return new Response(JSON.stringify({ 
            answer: "Halo! Saya adalah **Asisten AI SIMPAKAB** 🤖. Saya bisa membantu Anda mencari alat laboratorium, mengecek stok, atau menjelaskan fungsi alat. \n\nAda alat spesifik yang ingin Anda tanyakan?" 
        }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        })
    }

    // 2. Ambil data alat dari database (Ambil semuanya untuk dicocokkan)
    const { data: equipments, error: dbError } = await supabase
      .from('equipments') 
      .select('name, description, available_quantity')

    if (dbError) throw dbError;
    if (!equipments) throw new Error("Gagal mengambil data database.");

    // 3. Cari Alat (Pencarian Kata Kunci)
    let bestMatch: any = null;
    for (const tool of equipments) {
      const name = (tool.name || "").toLowerCase();
      
      // Jika userQuery ada di dalam nama atau sebaliknya
      if (userQuery.includes(name) || name.includes(userQuery)) {
        bestMatch = tool;
        break;
      }
    }

    // 4. Rakit Jawaban
    let responseText = "";
    if (bestMatch) {
      const avail = bestMatch.available_quantity || 0;
      const status = avail > 0 ? "**Tersedia ✅**" : "**Sedang Kosong/Dipinjam ❌**";
      
      responseText = `Tentu! Saya menemukan alat: **${bestMatch.name}**. \n\n` +
                     `**Kegunaan:** ${bestMatch.description || "Digunakan untuk praktik di laboratorium."} \n` +
                     `**Status:** ${status} (Tersedia ${avail} unit). \n\n` +
                     `Ada lagi yang ingin ditanyakan tentang alat ini?`;
    } else {
      responseText = "Maaf, saya belum menemukan alat dengan nama tersebut di database SIMPAKAB. 😔 \n\nMungkin bisa coba tanyakan nama alat yang lebih spesifik?";
    }

    return new Response(JSON.stringify({ answer: responseText }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    })

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message || "Unknown error" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200, // Tetap 200 agar Flutter tidak crash
    })
  }
})
