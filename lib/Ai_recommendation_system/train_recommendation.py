import os
from dotenv import load_dotenv
from supabase import create_client, Client
from sentence_transformers import SentenceTransformer
from pathlib import Path

# --- 1. CẤU HÌNH ---
# Tìm file .env (Ưu tiên tìm ngay tại folder này, nếu không thấy thì ra ngoài gốc)
current_dir = Path(__file__).parent
env_path = current_dir / '.env'
if not env_path.exists():
    env_path = current_dir.parents[1] / '.env' # Thử tìm ở gốc project

print(f"📂 Đang đọc cấu hình từ: {env_path}")
load_dotenv(dotenv_path=env_path)

URL = os.getenv("SUPABASE_URL")
KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not URL or not KEY:
    print("❌ Lỗi: Không tìm thấy KEY trong file .env")
    exit()

try:
    supabase: Client = create_client(URL, KEY)
except Exception as e:
    print(f"❌ Lỗi kết nối Supabase: {e}")
    exit()

print("⏳ Đang tải model AI...")
try:
    model = SentenceTransformer('all-MiniLM-L6-v2')
    print("✅ Model đã sẵn sàng!")
except Exception as e:
    print(f"❌ Lỗi tải Model AI: {e}")
    exit()

# --- HÀM HỖ TRỢ ---
def get_price_segment(price):
    if price is None: return ""
    try:
        p = float(price)
        if p < 200000: return "giá rẻ bình dân tiết kiệm"
        if p < 1000000: return "tầm trung phổ thông"
        return "cao cấp sang trọng hàng hiệu"
    except:
        return ""

def train_products():
    try:
        # 3. LẤY DỮ LIỆU (SỬA LẠI QUERY JOIN)
        # Thay 'brand' bằng 'users(shop_name)' để lấy tên shop từ bảng users
        response = supabase.table('products').select(
            'id, name, description, category, price, tags, specification, users(shop_name)'
        ).execute()

        products = response.data

        if not products:
            print("⚠️ Không tìm thấy sản phẩm nào.")
            return

        print(f"🔄 Tìm thấy {len(products)} sản phẩm. Bắt đầu tạo vector...")

        for product in products:
            # A. Xử lý Brand (Lấy từ bảng users join vào)
            user_data = product.get('users')
            p_brand = ""
            if user_data and isinstance(user_data, dict):
                p_brand = user_data.get('shop_name') or ""

            # B. Các trường khác
            p_name = product.get('name') or ""
            p_desc = product.get('description') or ""
            p_cat = product.get('category') or ""
            p_price = product.get('price')

            # C. Xử lý Tags & Specs
            tags_list = product.get('tags') or []
            tags_str = ", ".join(tags_list) if isinstance(tags_list, list) else ""

            specs = product.get('specification') or {}
            specs_str = ""
            if isinstance(specs, dict):
                specs_str = ", ".join([f"{k}: {v}" for k, v in specs.items()])

            # D. Phân khúc giá
            segment_str = get_price_segment(p_price)

            # E. TẠO VĂN BẢN ĐỂ TRAIN
            text_to_embed = (
                f"Sản phẩm: {p_name}. "
                f"Thương hiệu: {p_brand}. "
                f"Danh mục: {p_cat}. "
                f"Phân khúc: {segment_str}. "
                f"Đặc điểm: {tags_str}. "
                f"Thông số: {specs_str}. "
                f"Mô tả: {p_desc}"
            )

            # Tạo Vector
            embedding = model.encode(text_to_embed).tolist()

            # Cập nhật vào DB
            supabase.table('products').update({'embedding': embedding}).eq('id', product['id']).execute()

            print(f"   ✨ Updated: {p_name} (Brand: {p_brand})")

        print("🎉 Hoàn tất! Dữ liệu AI đã được cập nhật.")

    except Exception as e:
        print(f"❌ Có lỗi xảy ra: {e}")

if __name__ == "__main__":
    train_products()