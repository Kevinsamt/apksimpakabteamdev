import os
from supabase import create_client

def handler(request):
    # 1. Header CORS (Wajib untuk Web/Browser)
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        'Content-Type': 'application/json'
    }

    # Tangani permintaan 'OPTIONS' (Pre-flight request dari browser)
    if request.method == 'OPTIONS':
        return ('', 204, headers)

    try:
        # Hubungkan ke Supabase 
        url = os.environ.get("SUPABASE_URL")
        key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") 
        supabase = create_client(url, key)

        # Ambil pertanyaan dari Flutter
        body = request.get_json()
        user_query = body.get("query", "").lower()

        # Ambil data alat dari tabel 'equipments'
        response = supabase.table("equipments").select("name, description, available_quantity").execute()
        equipments = response.data

        # Logika Pencarian Pintar
        ans = "Maaf, saya belum menemukan alat yang Anda maksud di database laboratorium. Mungkin bisa tanyakan nama alat yang lebih spesifik?"
        for tool in equipments:
            tool_name = tool['name'].lower()
            tool_desc = (tool['description'] or "").lower()
            
            # Jika nama alat atau fungsinya ada di dalam pertanyaan user
            if tool_name in user_query or (len(user_query) > 3 and user_query in tool_name) or (tool_desc and user_query in tool_desc):
                status = "Tersedia" if tool['available_quantity'] > 0 else "Sedang Habis/Dipinjam"
                ans = f"Tentu! Sepertinya Anda mencari **{tool['name']}**. \n\n**Guna-nya:** {tool['description'] or 'Deskripsi belum diisi.'} \n**Status:** {status} ({tool['available_quantity']} unit)."
                break

        return ({"answer": ans}, 200, headers)

    except Exception as e:
        return ({"answer": f"Terjadi gangguan teknis: {str(e)}"}, 500, headers)
